import com.android.build.api.dsl.Packaging
import java.util.Properties

val localProperties = Properties()
file("../local.properties").inputStream().use { localProperties.load(it) }
val flutterSdkPath: String = localProperties.getProperty("flutter.sdk")
require(true) { "flutter.sdk not set in local.properties" }

val keystoreProperties = Properties()
file("../keystore.properties").inputStream().use { keystoreProperties.load(it) }

val flutterVersionCode: String = localProperties.getProperty("flutter.versionCode")

val flutterVersionName: String = localProperties.getProperty("flutter.versionName")

plugins {
    id("com.android.application")
    id("kotlin-android")
    // id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android") version "2.1.0"
}

android {
    namespace = "io.curltech.colla_chat"
    compileSdk = 36
    ndkVersion = "29.0.13113456"

    // Fixes duplicate libraries build issue,
    // when your project uses more than one plugin that depend on C++ libs.
    // pickFirst = 'lib/**/libc++_shared.so'
    fun Packaging.() {
        // Fixes duplicate libraries build issue,
        // when your project uses more than one plugin that depend on C++ libs.
        // pickFirst = 'lib/**/libc++_shared.so'
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.curltech.colla_chat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 33
        targetSdk = 35
        versionCode = 1
        versionName = "1.7.0"
        multiDexEnabled = true
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
        getByName("release") {
            isShrinkResources = true
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }
    buildToolsVersion = "35.0.1"

    dependencies {
        implementation("androidx.appcompat:appcompat:1.7.0")
        implementation("com.google.android.material:material:1.12.0")
        implementation("com.google.gms:google-services:4.3.15")
    }
}

flutter {
    source = "../.."
}
