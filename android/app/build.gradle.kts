plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // 🔥 Firebase plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "tr.com.hemo.hemo_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 🔥 Java 8 Desugaring özelliğini aktif ettik
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        // Flutter paket uyumluluğu için 1.8 standartlarına çektik
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "tr.com.hemo.hemo_app"

        // MultiDex desteği büyük kütüphaneler (Firebase gibi) için şarttır
        multiDexEnabled = true

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Versiyonu 2.0.3'ten 2.1.4'e yükselttik
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}