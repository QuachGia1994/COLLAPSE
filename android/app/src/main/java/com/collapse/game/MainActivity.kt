package com.collapse.game

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import com.collapse.game.services.PlayerProfile
import com.collapse.game.services.SensoryEngine
import com.collapse.game.ui.CollapseTheme
import com.collapse.game.ui.GameScreen
import com.collapse.game.ui.HomeScreen
import com.collapse.game.ui.PlusScreen
import com.collapse.game.ui.SkinScreen
import com.collapse.game.ui.TutorialScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            CollapseTheme {
                CollapseApp()
            }
        }
    }
}

private enum class AppRoute {
    Home,
    Tutorial,
    Game,
    Skins,
    Plus
}

@Composable
private fun CollapseApp() {
    val context = LocalContext.current
    val profile = remember { PlayerProfile(context.applicationContext) }
    val sensory = remember { SensoryEngine(context.applicationContext) }
    var route by remember { mutableStateOf(if (profile.didCompleteTutorial) AppRoute.Home else AppRoute.Tutorial) }
    var tutorialReplay by remember { mutableStateOf(false) }

    DisposableEffect(sensory) {
        onDispose { sensory.close() }
    }

    BackHandler(enabled = route != AppRoute.Home && route != AppRoute.Game) {
        if (route == AppRoute.Tutorial && !profile.didCompleteTutorial) {
            profile.completeTutorial()
        }
        tutorialReplay = false
        route = AppRoute.Home
    }

    when (route) {
        AppRoute.Home -> HomeScreen(
            profile = profile,
            isPlusUnlocked = false,
            onPlay = { route = AppRoute.Game },
            onSkins = { route = AppRoute.Skins },
            onPlus = { route = AppRoute.Plus },
            onTutorial = {
                tutorialReplay = true
                route = AppRoute.Tutorial
            }
        )
        AppRoute.Tutorial -> TutorialScreen(
            isReplay = tutorialReplay || profile.didCompleteTutorial,
            onClose = { route = AppRoute.Home },
            onFinished = {
                profile.completeTutorial()
                tutorialReplay = false
                route = AppRoute.Home
            }
        )
        AppRoute.Game -> GameScreen(
            profile = profile,
            sensory = sensory,
            isPlusUnlocked = false,
            onHome = { route = AppRoute.Home }
        )
        AppRoute.Skins -> SkinScreen(
            profile = profile,
            isPlusUnlocked = false,
            onBack = { route = AppRoute.Home },
            onPlus = { route = AppRoute.Plus }
        )
        AppRoute.Plus -> PlusScreen(onClose = { route = AppRoute.Home })
    }
}