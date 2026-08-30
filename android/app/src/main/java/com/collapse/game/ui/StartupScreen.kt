package com.collapse.game.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun StartupScreen() {
    Box(
        Modifier
            .fillMaxSize()
            .background(
                Brush.radialGradient(
                    listOf(Color(0xFF071526), Color.Black)
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Box(
                Modifier
                    .size(152.dp)
                    .background(Color.White.copy(alpha = 0.07f), CircleShape)
                    .border(1.dp, CollapseCyan.copy(alpha = 0.28f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                CollapseLogoSymbol(CollapseCyan, Modifier.size(104.dp))
            }
            Text(
                "COLLAPSE",
                color = Color.White,
                fontSize = 30.sp,
                fontWeight = FontWeight.Light,
                letterSpacing = 7.sp
            )
            Text(
                "CHỌN TƯƠNG LAI",
                modifier = Modifier.padding(top = 2.dp),
                color = Color.White.copy(alpha = 0.50f),
                fontSize = 11.sp,
                fontWeight = FontWeight.Medium,
                letterSpacing = 2.6.sp
            )
        }
    }
}
