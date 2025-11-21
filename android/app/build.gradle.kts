plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.pocketpt"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.pocketpt"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        
        // Enable ML Kit features
        multiDexEnabled = true
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    // Temporary: sign release with debug keystore to validate installability on device
    signingConfigs {
        create("release") {
            val homeDir = System.getProperty("user.home")
            storeFile = file("$homeDir/.android/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Use the temporary release signing above (debug keystore)
            signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        // remove these two lines
        // sourceCompatibility = JavaVersion.VERSION_11
        // targetCompatibility = JavaVersion.VERSION_11
        // ✅ use JVM toolchain instead
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // ✅ Set Java 17 toolchain
    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }
    
    // Enable ML Kit features / JNI packaging
    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc.so")
        pickFirst("**/libfbjni.so")
        pickFirst("**/libpytorch_jni.so")
        pickFirst("**/libpytorch_module.so")
    }
    
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // ONNX Runtime for pose estimation model
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.16.0")
    
    // PyTorch Android (full) for pose estimation
    implementation("org.pytorch:pytorch_android:1.10.0")
    implementation("org.pytorch:pytorch_android_torchvision:1.10.0")
}

