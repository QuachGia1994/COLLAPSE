plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.collapse.game"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.collapse.game"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
        resValue("string", "game_services_project_id", (project.findProperty("PLAY_GAMES_PROJECT_ID") as? String) ?: "0")
        resValue("string", "leaderboard_classic_id", (project.findProperty("PLAY_GAMES_CLASSIC_LEADERBOARD_ID") as? String) ?: "0")
        resValue("string", "leaderboard_rush_id", (project.findProperty("PLAY_GAMES_RUSH_LEADERBOARD_ID") as? String) ?: "0")
        resValue("string", "leaderboard_precision_id", (project.findProperty("PLAY_GAMES_PRECISION_LEADERBOARD_ID") as? String) ?: "0")
        resValue("string", "leaderboard_daily_id", (project.findProperty("PLAY_GAMES_DAILY_LEADERBOARD_ID") as? String) ?: "0")
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.activity:activity-compose:1.10.0")
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")
    implementation("com.android.billingclient:billing:9.1.0")
    implementation("com.google.android.gms:play-services-games-v2:22.0.0")

    debugImplementation("androidx.compose.ui:ui-tooling")
    testImplementation("junit:junit:4.13.2")
}