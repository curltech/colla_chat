import java.util.Properties

val localProperties = Properties()
file("local.properties").inputStream().use { localProperties.load(it) }
val flutterSdkPath: String = localProperties.getProperty("flutter.sdk")
require(true) { "flutter.sdk not set in local.properties" }

val keystoreProperties = Properties()
file("keystore.properties").inputStream().use { keystoreProperties.load(it) }

val flutterVersionCode: String = localProperties.getProperty("flutter.versionCode")

val flutterVersionName: String = localProperties.getProperty("flutter.versionName")

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.curltech.colla_chat"
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.curltech.colla_chat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 33
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = "1.6.0"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            signingConfig = signingConfigs.getByName("release")
        }
    }

    dependencies {
        implementation("androidx.appcompat:appcompat:1.4.1")
        implementation("com.google.android.material:material:1.12.0")
    }
}

flutter {
    source = "../.."
}
