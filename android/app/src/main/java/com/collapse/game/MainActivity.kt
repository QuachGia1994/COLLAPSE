package com.collapse.game

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.collapse.game.services.BillingStore
import com.collapse.game.services.PlayerProfile
import com.collapse.game.services.PlayGamesStore
import com.collapse.game.services.SensoryEngine
import com.collapse.game.ui.CollapseTheme
import com.collapse.game.ui.GameScreen
import com.collapse.game.ui.HomeScreen
import com.collapse.game.ui.PlusScreen
import com.collapse.game.ui.SkinScreen
import com.collapse.game.ui.StartupScreen
import com.collapse.game.ui.TutorialScreen
import kotlinx.coroutines.delay

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.dark(Color.TRANSPARENT)
        )
        setContent {
            CollapseTheme {
                CollapseApp(activity = this@MainActivity)
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
private fun CollapseApp(activity: Activity) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val profile = remember { PlayerProfile(context.applicationContext) }
    val sensory = remember { SensoryEngine(context.applicationContext) }
    val billing = remember { BillingStore(context.applicationContext) }
    val playGames = remember { PlayGamesStore(activity) }
    var route by remember { mutableStateOf(if (profile.didCompleteTutorial) AppRoute.Home else AppRoute.Tutorial) }
    var tutorialReplay by remember { mutableStateOf(false) }
    var showsStartup by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        playGames.retryPending()
        playGames.refresh(profile.selectedMode)
        delay(720)
        showsStartup = false
    }

    DisposableEffect(sensory, billing, lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) billing.refresh()
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
            sensory.close()
            billing.close()
        }
    }

    if (showsStartup) {
        StartupScreen()
        return
    }

    BackHandler(enabled = route != AppRoute.Home && route != AppRoute.Game) {
        if (route == AppRoute.Tutorial && !profile.didCompleteTutorial) profile.completeTutorial()
        tutorialReplay = false
        route = AppRoute.Home
    }

    when (route) {
        AppRoute.Home -> HomeScreen(
            profile = profile,
            playGames = playGames,
            isPlusUnlocked = billing.isPlusUnlocked,
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
            playGames = playGames,
            mode = profile.selectedMode,
            isPlusUnlocked = billing.isPlusUnlocked,
            onHome = { route = AppRoute.Home }
        )
        AppRoute.Skins -> SkinScreen(
            profile = profile,
            isPlusUnlocked = billing.isPlusUnlocked,
            onBack = { route = AppRoute.Home },
            onPlus = { route = AppRoute.Plus }
        )
        AppRoute.Plus -> PlusScreen(
            billing = billing,
            onPurchase = { productId -> billing.purchase(activity, productId) },
            onClose = { route = AppRoute.Home }
        )
    }
}
