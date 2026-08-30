package com.collapse.game.ui

import androidx.compose.ui.graphics.Color

sealed interface SkinAccess {
    data object Free : SkinAccess
    data class Gems(val cost: Int) : SkinAccess
    data object Plus : SkinAccess
}

data class SkinPalette(
    val backgroundTop: Color,
    val backgroundBottom: Color,
    val primary: Color,
    val secondary: Color,
    val safe: Color,
    val danger: Color
)

enum class GameSkin(
    val title: String,
    val subtitle: String,
    val access: SkinAccess,
    val pulseFrequency: Double,
    val pulseDepth: Double,
    val palette: SkinPalette
) {
    Classic(
        "Classic", "Kính nguyên bản", SkinAccess.Free, 2.0, 0.08,
        SkinPalette(Color(0xFF080F21), Color.Black, Color.Cyan, Color(0xFFB74DFF), Color.Green, Color.Red)
    ),
    Nebula(
        "Nebula", "Tím vũ trụ", SkinAccess.Plus, 3.1, 0.14,
        SkinPalette(Color(0xFF1A0830), Color(0xFF050214), Color(0xFF4DCCFF), Color(0xFFE05AFF), Color(0xFF4DFF9E), Color(0xFFFF4D6B))
    ),
    Aurora(
        "Aurora", "Lục lam cực quang", SkinAccess.Gems(25), 2.4, 0.10,
        SkinPalette(Color(0xFF001F24), Color(0xFF030A12), Color(0xFF33F2FF), Color(0xFF38FFA6), Color(0xFF47FF87), Color(0xFFFF4D4D))
    ),
    Solar(
        "Solar", "Vàng cam mặt trời", SkinAccess.Gems(60), 2.8, 0.10,
        SkinPalette(Color(0xFF291202), Color(0xFF0A0502), Color(0xFFFFBF42), Color(0xFFFF6129), Color(0xFF73FF73), Color(0xFFFF472E))
    ),
    Obsidian(
        "Obsidian", "Đen chrome", SkinAccess.Plus, 1.6, 0.14,
        SkinPalette(Color(0xFF0D0D12), Color.Black, Color.White, Color(0xFF858FAE), Color(0xFF40FF91), Color(0xFFFF403D))
    ),
    FrozenQuartz(
        "Frozen Quartz", "Lam băng", SkinAccess.Plus, 2.2, 0.14,
        SkinPalette(Color(0xFF051A33), Color(0xFF030817), Color(0xFF6BE0FF), Color(0xFF9EB3FF), Color(0xFF57FFB8), Color(0xFFFF575F))
    )
}