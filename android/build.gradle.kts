buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.20")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    if (state.executed) {
        val android = project.extensions.findByName("android") as? com.android.build.api.dsl.CommonExtension
        android?.apply {
            buildToolsVersion = "36.0.0"
            compileSdk = 34
        }
    } else {
        afterEvaluate {
            val android = project.extensions.findByName("android") as? com.android.build.api.dsl.CommonExtension
            android?.apply {
                buildToolsVersion = "36.0.0"
                compileSdk = 34
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}