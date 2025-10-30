plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.studentbrigade"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.studentbrigade"

        // Si ya tienes estas props definidas por Flutter, déjalas así;
        // si no, pon números/literales (p.ej. minSdk = 23).
        minSdk = flutter.minSdkVersion
        targetSdk = 33
        versionCode = 1
        versionName = "1.0"

        // ✅ Kotlin DSL:
        manifestPlaceholders.putAll(
            mapOf(
                "auth0Domain" to "dev-wahfof5ie3r5xpns.us.auth0.com",
                "auth0Scheme" to "com.example.studentbrigade" // o "https" si usarás App Links
            )
        )
        // Alternativa equivalente:
        // manifestPlaceholders["auth0Domain"] = "dev-wahfof5ie3r5xpns.us.auth0.com"
        // manifestPlaceholders["auth0Scheme"] = "com.example.studentbrigade"
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
