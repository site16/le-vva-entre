plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Adiciona o plugin de serviços do Google
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.levva_entregador"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.levva_entregador"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Outras dependências...

    // Importa o Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))

    // TODO: Adicione as dependências dos produtos Firebase que deseja usar
    // Ao usar o BoM, não especifique versões nas dependências do Firebase
    // https://firebase.google.com/docs/android/setup#available-libraries
}