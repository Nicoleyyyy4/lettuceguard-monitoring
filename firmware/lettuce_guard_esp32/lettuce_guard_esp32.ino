/*
 * LettuceGuard - ESP32 IoT Hydroponics Controller
 * ------------------------------------------------
 * Hardware Sensors:
 *  - DHT22 (Air Temp & Humidity): GPIO 4
 *  - DS18B20 Waterproof Probe (Water Temp): GPIO 15
 *  - Analog pH Sensor: GPIO 34 (ADC1 CH6)
 *  - HC-SR04 Ultrasonic (Reservoir Water Level): Trig GPIO 5, Echo GPIO 18
 *  - Analog TDS / EC Meter: GPIO 35 (ADC1 CH7)
 *  - Water circulation relay input: GPIO 26 (active-high by default)
 *
 * Cloud Sync:
 *  - Transmits sensor payloads over Wi-Fi to Firebase Realtime Database
 *  - Live Node: /devices/lettuceguard_node_01/current.json
 *  - History Snapshot Node: /devices/lettuceguard_node_01/history.json
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <ArduinoJson.h>
#include <string.h>

// --- Wi-Fi & Firebase Configuration ---
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Firebase Realtime Database Base URL (without trailing slash)
const char* FIREBASE_HOST = "https://lettuceguard-bd1f4-default-rtdb.firebaseio.com";
const char* DEVICE_ID = "lettuceguard_node_01";

// Optional Firebase Secret / Auth Token
const char* FIREBASE_AUTH = "";

// --- Pin Definitions ---
#define DHTPIN 4
#define DHTTYPE DHT22

#define ONE_WIRE_BUS 15

#define PH_PIN 34
#define TDS_PIN 35

#define TRIG_PIN 5
#define ECHO_PIN 18

// Use an isolated relay module; never drive a pump directly from an ESP32 GPIO.
// Change this pin/active level to match the actual relay wiring.
#define WATER_PUMP_RELAY_PIN 26
constexpr bool WATER_PUMP_RELAY_ACTIVE_LOW = false;
constexpr float WATER_PUMP_START_C = 23.0;
constexpr float WATER_PUMP_STOP_C = 22.0;
constexpr float WATER_PUMP_MIN_LEVEL_PCT = 25.0;

// --- Tank Physical Constants ---
const float RESERVOIR_DEPTH_CM = 30.0; // Total height from sensor to tank bottom

// --- Calibration Parameters ---
const float PH_7_VOLTAGE = 1.65; // Voltage at neutral pH 7.0 (3.3V ADC scale)
const float PH_SLOPE = 0.18;     // Voltage difference per pH unit

// --- Sensor Objects ---
DHT dht(DHTPIN, DHTTYPE);
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature ds18b20(&oneWire);

// --- Timing Variables ---
unsigned long lastSampleTime = 0;
const unsigned long SAMPLE_INTERVAL_MS = 3000; // Update current reading every 3 seconds
unsigned long lastWifiAttempt = 0;
bool waterPumpActive = false;
const char* waterPumpReason = "temperature_normal";

unsigned long lastHistoryTime = 0;
const unsigned long HISTORY_INTERVAL_MS = 300000; // Push history snapshot every 5 minutes

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n--- Initializing LettuceGuard ESP32 Controller ---");

  // Initialize Pins
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  digitalWrite(TRIG_PIN, LOW);

  pinMode(PH_PIN, INPUT);
  pinMode(TDS_PIN, INPUT);

  // Initialize relay OFF before switching the pin to output to avoid a startup pulse.
  digitalWrite(WATER_PUMP_RELAY_PIN, WATER_PUMP_RELAY_ACTIVE_LOW ? HIGH : LOW);
  pinMode(WATER_PUMP_RELAY_PIN, OUTPUT);

  // Initialize Sensors
  dht.begin();
  ds18b20.begin();

  // Start Wi-Fi without blocking local pump control while the network connects.
  connectWiFi();
  lastWifiAttempt = millis();
}

void loop() {
  unsigned long currentMillis = millis();

  // Retry Wi-Fi in the background; pump automation continues while offline.
  if (WiFi.status() != WL_CONNECTED &&
      currentMillis - lastWifiAttempt >= 10000) {
    lastWifiAttempt = currentMillis;
    connectWiFi();
  }

  // 1. Regular Sampling & Current Payload Push
  if (currentMillis - lastSampleTime >= SAMPLE_INTERVAL_MS) {
    lastSampleTime = currentMillis;
    processAndSendSensorData(false);
  }

  // 2. Periodic History Log Push
  if (currentMillis - lastHistoryTime >= HISTORY_INTERVAL_MS) {
    lastHistoryTime = currentMillis;
    processAndSendSensorData(true);
  }
}

void connectWiFi() {
  Serial.print("Starting Wi-Fi connection to: ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

void processAndSendSensorData(bool isHistorySnapshot) {
  // --- 1. Read DHT22 (Air Temp & Humidity) ---
  float airTempC = dht.readTemperature();
  float airHumidity = dht.readHumidity();
  bool dht22Error = isnan(airTempC) || isnan(airHumidity);

  // --- 2. Read DS18B20 (Water Temperature) ---
  ds18b20.requestTemperatures();
  float waterTempC = ds18b20.getTempCByIndex(0);
  bool ds18b20Error = isnan(waterTempC) ||
                      waterTempC == -127.00 || waterTempC == 85.00;

  // --- 3. Read HC-SR04 (Ultrasonic Water Level) ---
  float distanceCm = readUltrasonicDistance();
  bool ultrasonicError = (distanceCm <= 0.0 || distanceCm > 400.0);

  float waterLevelPct = 0.0;
  if (!ultrasonicError) {
    float waterDepthCm = RESERVOIR_DEPTH_CM - distanceCm;
    waterLevelPct = (waterDepthCm / RESERVOIR_DEPTH_CM) * 100.0;
    if (waterLevelPct < 0.0) waterLevelPct = 0.0;
    if (waterLevelPct > 100.0) waterLevelPct = 100.0;
  }

  // Run pump locally from sensor readings, independent of Firebase availability.
  updateWaterPump(waterTempC, ds18b20Error, waterLevelPct, ultrasonicError);

  // --- 4. Read Analog pH Sensor ---
  int rawAdcPh = readAnalogAverage(PH_PIN, 10);
  bool adcSaturation = (rawAdcPh >= 4090 || rawAdcPh <= 10);

  float phVoltage = (rawAdcPh / 4095.0) * 3.3;
  // Temperature compensated pH formula
  float tempCompFactor = 1.0 + 0.003 * ((ds18b20Error ? 20.0 : waterTempC) - 25.0);
  float phValue = 7.0 + ((PH_7_VOLTAGE - phVoltage) / PH_SLOPE) * tempCompFactor;

  bool phError = adcSaturation || (phValue < 0.0 || phValue > 14.0);
  bool phUncalibrated = (phValue < 3.0 || phValue > 11.0) && !phError;

  // --- 5. Read Analog TDS Meter ---
  int rawAdcTds = readAnalogAverage(TDS_PIN, 10);
  float tdsVoltage = (rawAdcTds / 4095.0) * 3.3;
  float tdsCompensation = 1.0 + 0.02 * ((ds18b20Error ? 20.0 : waterTempC) - 25.0);
  float compensatedVoltage = tdsVoltage / tdsCompensation;
  float tdsPpm = (133.42 * pow(compensatedVoltage, 3) - 255.86 * pow(compensatedVoltage, 2) + 857.39 * compensatedVoltage) * 0.5;
  bool tdsError = (tdsPpm < 0.0 || tdsPpm > 3000.0);

  // --- Determine System Health Status ---
  String systemStatus = "OK";
  if (dht22Error || ds18b20Error || phError || ultrasonicError || tdsError || adcSaturation) {
    systemStatus = "ERROR";
  } else if (phValue < 5.5 || phValue > 6.5 ||
             waterTempC < 18.0 || waterTempC > 22.0 ||
             airTempC < 18.0 || airTempC > 26.0 ||
             waterLevelPct < 25.0) {
    systemStatus = "WARNING";
  }

  // --- Construct JSON Payload ---
  StaticJsonDocument<512> doc;

  doc["airTemperature"] = dht22Error ? 0.0 : round(airTempC * 10.0) / 10.0;
  doc["airHumidity"] = dht22Error ? 0.0 : round(airHumidity * 10.0) / 10.0;
  doc["waterTemperature"] = ds18b20Error ? 0.0 : round(waterTempC * 10.0) / 10.0;
  doc["waterPumpActive"] = waterPumpActive;
  doc["waterPumpReason"] = waterPumpReason;
  doc["waterPumpOnThresholdC"] = WATER_PUMP_START_C;
  doc["waterPumpOffThresholdC"] = WATER_PUMP_STOP_C;
  doc["ph"] = phError ? 0.0 : round(phValue * 100.0) / 100.0;
  doc["tds"] = tdsError ? 0.0 : round(tdsPpm);

  JsonObject waterLevel = doc.createNestedObject("waterLevel");
  waterLevel["percentage"] = ultrasonicError ? 0.0 : round(waterLevelPct * 10.0) / 10.0;
  waterLevel["distanceCm"] = ultrasonicError ? 0.0 : round(distanceCm * 10.0) / 10.0;
  waterLevel["reservoirDepthCm"] = RESERVOIR_DEPTH_CM;

  doc["systemStatus"] = systemStatus;

  JsonObject sensorErrors = doc.createNestedObject("sensorErrors");
  sensorErrors["dht22Error"] = dht22Error;
  sensorErrors["ds18b20Error"] = ds18b20Error;
  sensorErrors["phError"] = phError;
  sensorErrors["ultrasonicError"] = ultrasonicError;
  sensorErrors["tdsError"] = tdsError;
  sensorErrors["adcSaturation"] = adcSaturation;
  sensorErrors["phUncalibrated"] = phUncalibrated;

  // Firebase resolves this to Unix epoch milliseconds for both endpoints.
  // millis() is MCU uptime and cannot identify historical wall-clock times.
  JsonObject serverTimestamp = doc.createNestedObject("timestamp");
  serverTimestamp[".sv"] = "timestamp";

  String jsonString;
  serializeJson(doc, jsonString);

  Serial.print("Generated Payload: ");
  Serial.println(jsonString);

  // --- Push Payload to Firebase Realtime DB ---
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    String endpoint;

    if (isHistorySnapshot) {
      // POST to /devices/lettuceguard_node_01/history.json
      endpoint = String(FIREBASE_HOST) + "/devices/" + DEVICE_ID + "/history.json";
      if (strlen(FIREBASE_AUTH) > 0) endpoint += "?auth=" + String(FIREBASE_AUTH);

      http.begin(endpoint);
      http.addHeader("Content-Type", "application/json");
      int httpCode = http.POST(jsonString);
      Serial.printf("Firebase History POST Result Code: %d\n", httpCode);
      http.end();
    } else {
      // PUT to /devices/lettuceguard_node_01/current.json
      endpoint = String(FIREBASE_HOST) + "/devices/" + DEVICE_ID + "/current.json";
      if (strlen(FIREBASE_AUTH) > 0) endpoint += "?auth=" + String(FIREBASE_AUTH);

      http.begin(endpoint);
      http.addHeader("Content-Type", "application/json");
      int httpCode = http.PUT(jsonString);
      Serial.printf("Firebase Current PUT Result Code: %d\n", httpCode);
      http.end();
    }
  }
}

void setWaterPump(bool active, const char* reason) {
  const bool stateChanged = waterPumpActive != active;
  const bool reasonChanged = strcmp(waterPumpReason, reason) != 0;
  waterPumpActive = active;
  waterPumpReason = reason;
  const int activeLevel = WATER_PUMP_RELAY_ACTIVE_LOW ? LOW : HIGH;
  const int inactiveLevel = WATER_PUMP_RELAY_ACTIVE_LOW ? HIGH : LOW;
  if (stateChanged) {
    digitalWrite(WATER_PUMP_RELAY_PIN, active ? activeLevel : inactiveLevel);
  }
  if (stateChanged || reasonChanged) {
    Serial.printf("Water circulation pump %s (%s)\n",
                  active ? "ON" : "OFF", reason);
  }
}

void updateWaterPump(float waterTempC, bool temperatureError,
                     float waterLevelPct, bool waterLevelError) {
  // Fail safe: never run the pump without valid water temperature and level data.
  if (temperatureError) {
    setWaterPump(false, "water_temperature_sensor_error");
    return;
  }
  if (waterLevelError || waterLevelPct < WATER_PUMP_MIN_LEVEL_PCT) {
    setWaterPump(false, "low_or_unavailable_water_level");
    return;
  }

  // Hysteresis keeps the relay from rapidly switching around 23 C.
  if (!waterPumpActive && waterTempC >= WATER_PUMP_START_C) {
    setWaterPump(true, "water_temperature_high");
  } else if (waterPumpActive && waterTempC <= WATER_PUMP_STOP_C) {
    setWaterPump(false, "water_temperature_recovered");
  } else if (waterPumpActive) {
    waterPumpReason = "circulating_until_22c";
  } else {
    waterPumpReason = "temperature_normal";
  }
}

float readUltrasonicDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000); // 30ms timeout
  if (duration == 0) return -1.0;

  return duration * 0.0343 / 2.0;
}

int readAnalogAverage(int pin, int samples) {
  long sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(pin);
    delay(2);
  }
  return sum / samples;
}
