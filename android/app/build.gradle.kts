plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.testora.student"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.testora.student"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Enable code shrinking, obfuscation and optimization (uses R8 by default)
            isMinifyEnabled = true
            isShrinkResources = true  // Optional but recommended – removes unused resources

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Keep using debug signing for now (change to release signing when uploading to Play Store)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ✅ Core Android + Firebase dependencies


    // ✅ Razorpay SDK (latest as of 2025)
    implementation("com.razorpay:checkout:1.6.41") {
        exclude(group = "com.guardsquare", module = "proguard-annotations")
    }
}

// ✅ Exclude proguard annotations globally
configurations.all {
    exclude(group = "com.guardsquare", module = "proguard-annotations")
}

flutter {
    source = "../.."
}
