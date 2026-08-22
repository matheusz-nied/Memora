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
    namespace = "app.theusz.dev.memora"
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
        applicationId = "app.theusz.dev.memora"
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
// falha só no upload para a Play Store — tarde demais.
//
// A trava fica no `bundleRelease`, que é o que gera o .aab de publicação:
// sem keystore ele para aqui, com a instrução do que fazer. O `assembleRelease`
// continua passando com a chave de debug, porque é o que `flutter run --release`
// e o APK de teste em aparelho usam — e esses não vão para loja nenhuma.
//
// Um `logger.warn` não serve: o `flutter build` filtra a saída do Gradle e
// engole o aviso. Só a falha atravessa.
tasks.matching { it.name.startsWith("bundleRelease") }.configureEach {
    doFirst {
        if (!hasReleaseKeystore) {
            throw GradleException(
                "android/key.properties não encontrado: este .aab seria assinado " +
                    "com a chave de DEBUG e a Play Store vai recusá-lo.\n" +
                    "Gere o keystore e copie android/key.properties.example para " +
                    "android/key.properties.\n" +
                    "Para um APK de teste em aparelho, use `flutter build apk --release`, " +
                    "que segue funcionando com a chave de debug.",
            )
        }
    }
}

flutter {
    source = "../.."
}
