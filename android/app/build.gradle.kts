import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

val envKeystorePath = System.getenv("KEYSTORE_PATH")
    ?: run {
        val vaultSecretKeystore = rootProject.file("../.secrets/release.keystore")
        if (vaultSecretKeystore.exists()) vaultSecretKeystore.absolutePath else null
    }
val envKeystorePassword = System.getenv("STORE_PASSWORD") ?: System.getenv("KEYSTORE_PASSWORD") ?: System.getenv("KEY_STORE_PASSWORD")
val envKeyAlias = System.getenv("KEY_ALIAS")
val envKeyPassword = System.getenv("KEY_PASSWORD")

android {
    namespace = "no.naturinorge.naturinorge_guide"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile") ?: envKeystorePath
            val storePasswordProp = keystoreProperties.getProperty("storePassword") ?: envKeystorePassword
            val keyAliasProp = keystoreProperties.getProperty("keyAlias") ?: envKeyAlias
            val keyPasswordProp = keystoreProperties.getProperty("keyPassword") ?: envKeyPassword

            if (storeFilePath != null && storePasswordProp != null && keyAliasProp != null && keyPasswordProp != null) {
                val resolvedFile = file(storeFilePath)
                if (resolvedFile.exists()) {
                    storeFile = resolvedFile
                    storePassword = storePasswordProp
                    keyAlias = keyAliasProp
                    keyPassword = keyPasswordProp
                }
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "no.naturinorge.naturinorge_guide"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            signingConfig = if (releaseSigning.storeFile != null) {
                releaseSigning
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
