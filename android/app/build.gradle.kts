plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ramadhan.app.ramadhan_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.ramadhan.app.ramadhan_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        setProperty("archivesBaseName", "RamadhanApp")
    }

    signingConfigs {
        create("release") {
            val keystoreFile = file("app-release.keystore")
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = "ramadhan2026"
                keyAlias = "ramadhanapp"
                keyPassword = "ramadhan2026"
            }
        }
    }

    buildTypes {
        release {
            val keystoreFile = file("app-release.keystore")
            signingConfig = if (keystoreFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Keep notification plugin classes from being stripped by R8
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    applicationVariants.all {
        if (buildType.name == "release") {
            outputs.forEach { output ->
                val impl = output as com.android.build.gradle.internal.api.BaseVariantOutputImpl
                impl.outputFileName = "RamadhanApp.apk"
            }
        }
    }
}

tasks.configureEach {
    if (name == "assembleRelease") {
        doLast {
            val flutterApkDir = file("${project.layout.buildDirectory.get()}/outputs/flutter-apk")
            val releaseApk = file("${project.layout.buildDirectory.get()}/outputs/apk/release/RamadhanApp.apk")
            if (releaseApk.exists()) {
                copy {
                    from(releaseApk)
                    into(flutterApkDir)
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
