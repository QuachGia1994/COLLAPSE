package com.collapse.game.domain

import java.time.LocalDate

enum class GameMode(
    val title: String,
    val subtitle: String,
    val choiceBase: Double,
    val choiceFloor: Double,
    val choiceDecay: Double,
    val travelBase: Double,
    val travelFloor: Double,
    val travelDecay: Double,
    val hazardRadiusMultiplier: Double,
    val maxSwitchesPerRound: Int?,
    val collisionEndsRun: Boolean,
    val isCompetitive: Boolean
) {
    Classic(
        "CLASSIC", "Nhịp cân bằng nguyên bản.",
        1.45, 0.72, 0.045, 0.90, 0.62, 0.012, 1.0, null, true, true
    ),
    Rush(
        "RUSH", "Quyết định nhanh, chuyển động nhanh.",
        1.05, 0.52, 0.032, 0.68, 0.46, 0.010, 1.0, null, true, true
    ),
    Precision(
        "PRECISION", "Chỉ một lần đổi nhánh mỗi round.",
        1.24, 0.58, 0.038, 0.82, 0.56, 0.010, 1.28, 1, true, true
    ),
    Daily(
        "DAILY", "Một timeline cố định cho mỗi ngày.",
        1.28, 0.62, 0.040, 0.84, 0.56, 0.011, 1.10, null, true, true
    ),
    Zen(
        "ZEN", "Practice chậm, va chạm không kết thúc run.",
        2.00, 1.20, 0.025, 1.08, 0.82, 0.006, 0.90, null, false, false
    );

    fun seed(date: LocalDate = LocalDate.now()): ULong {
        if (this != Daily) return 0xC011A953uL
        val dayNumber = (date.year * 10_000 + date.monthValue * 100 + date.dayOfMonth).toULong()
        return dayNumber xor 0xD41C0A53uL
    }
}
