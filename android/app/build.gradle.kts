plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.example.flutter_application_museo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_application_museo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Inyectar claves de Firebase desde .env para Analytics nativo (JSON-less)
        val envFile = project.rootProject.file("../.env")
        val env = Properties()
        if (envFile.exists()) {
            env.load(FileInputStream(envFile))
        }
        
        resValue("string", "google_app_id", env.getProperty("FIREBASE_APP_ID_ANDROID") ?: "")
        resValue("string", "google_api_key", env.getProperty("FIREBASE_API_KEY_ANDROID") ?: "")
        resValue("string", "project_id", env.getProperty("FIREBASE_PROJECT_ID") ?: "")
        resValue("string", "gcm_defaultSenderId", env.getProperty("FIREBASE_MESSAGING_SENDER_ID") ?: "")
        resValue("string", "google_storage_bucket", env.getProperty("FIREBASE_STORAGE_BUCKET") ?: "")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
