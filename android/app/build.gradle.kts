import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Credenciais de assinatura, fora do Git (ver `android/key.properties.example`).
// Ausente, o release cai na chave de debug: `flutter run --release` continua
// funcionando na sua máquina, e o `assembleRelease` avisa que o artefato não
// serve para publicar.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "app.memora.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Definitivo: publicado, o `applicationId` não pode mais mudar.
        applicationId = "app.memora.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Assinar o release com a chave de debug é o padrão do template do Flutter, e
// falha só no upload para a Play Store — tarde demais. O aviso traz a
// descoberta para o momento do build.
tasks.matching { it.name.contains("Release") && it.name.startsWith("assemble") || it.name.startsWith("bundleRelease") }
    .configureEach {
        doFirst {
            if (!hasReleaseKeystore) {
                logger.warn(
                    "AVISO: android/key.properties não encontrado — este artefato " +
                        "foi assinado com a chave de DEBUG e a Play Store vai recusá-lo. " +
                        "Ver android/key.properties.example.",
                )
            }
        }
    }

flutter {
    source = "../.."
}
