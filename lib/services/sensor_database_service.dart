import 'package:firebase_database/firebase_database.dart';
import 'encryption_service.dart';

class SensorDatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // 1. Pag-save ng Encrypted Sensor Data
  Future<void> uploadSensorData({
    required double waterLevel,
    required double phLevel,
    required double temperature,
  }) async {
    try {
      // Isulat ang sensor data bilang isang malinaw na string o JSON format
      String rawData = "water:$waterLevel,ph:$phLevel,temp:$temperature,time:${DateTime.now().toIso8601String()}";

      // I-encrypt ang buong string
      String encryptedPayload = EncryptionService.encryptData(rawData);

      // I-save sa Realtime Database sa ilalim ng 'secure_sensors' node
      await _dbRef.child('secure_sensors').push().set({
        'payload': encryptedPayload,
        'timestamp': ServerValue.timestamp,
      });

      print("Encrypted sensor data successfully stored!");
    } catch (e) {
      print("Error saving encrypted data: $e");
    }
  }

  // 2. Pagbasa at pag-decrypt ng Sensor Data
  void listenToEncryptedSensors(Function(Map<String, dynamic> decryptedData) onDataReceived) {
    _dbRef.child('secure_sensors').onChildAdded.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && data['payload'] != null) {
        String encryptedPayload = data['payload'];

        // I-decrypt ang data mula sa Firebase
        String decryptedString = EncryptionService.decryptData(encryptedPayload);

        // I-parse pabalik sa magagamit na values (halimbawa: split by comma)
        // Format: water:X,ph:Y,temp:Z,time:T
        print("Decrypted raw: $decryptedString");
      }
    });
  }
}