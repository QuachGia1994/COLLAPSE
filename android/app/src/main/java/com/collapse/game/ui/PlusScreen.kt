package com.collapse.game.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.collapse.game.services.BillingStore
import com.collapse.game.services.PlaySubscriptionPlan

private val plusBenefits = listOf(
    "▱" to "Tắt quảng cáo",
    "✦" to "Theme và pulse Plus riêng",
    "◉" to "Vào sớm level và mode mới",
    "▥" to "Soundscape và haptic Plus",
    "⬢" to "Không tăng điểm hay lợi thế sống sót"
)

@Composable
fun PlusScreen(
    billing: BillingStore,
    onPurchase: (String) -> Unit,
    onClose: () -> Unit
) {
    Box(
        Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(Color.Black, Color(0xFF080719))))
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 22.dp, vertical = 34.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            PlusOrb()
            Spacer(Modifier.height(18.dp))
            Text("COLLAPSE PLUS", color = Color.White, fontSize = 28.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 4.sp)
            Text(
                "Đăng ký tuần hoặc tháng. Hủy bất kỳ lúc nào trong Google Play.",
                modifier = Modifier.padding(top = 8.dp),
                color = Color.White.copy(alpha = 0.50f),
                fontSize = 15.sp,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(18.dp))
            BenefitsCard()
            Spacer(Modifier.height(18.dp))
            BillingState(billing)
            PlanButton(billing.weeklyPlan, billing.isPlusUnlocked, onPurchase)
            Spacer(Modifier.height(10.dp))
            PlanButton(billing.monthlyPlan, billing.isPlusUnlocked, onPurchase)
            TextButton(onClick = billing::restore) {
                Text("KHÔI PHỤC / KIỂM TRA GIAO DỊCH")
            }
            Text(
                billing.statusMessage,
                modifier = Modifier.padding(top = 4.dp),
                color = if (billing.isPlusUnlocked) Color(0xFF65F59A) else CollapseYellow.copy(alpha = 0.82f),
                fontSize = 12.sp,
                textAlign = TextAlign.Center
            )
            Text(
                "Plus chỉ thay đổi quảng cáo, theme/pulse và quyền truy cập sớm. Hazard, thời gian quyết định, điểm và khả năng sống sót giống hệt Free.",
                modifier = Modifier.padding(top = 18.dp),
                color = Color.White.copy(alpha = 0.48f),
                fontSize = 12.sp,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(28.dp))
        }
        OutlinedButton(onClick = onClose, modifier = Modifier.align(Alignment.TopEnd).padding(top = 24.dp, end = 14.dp)) {
            Text("Đóng")
        }
    }
}

@Composable
private fun BillingState(billing: BillingStore) {
    if (!billing.isConnecting) return
    Row(
        Modifier.fillMaxWidth().padding(bottom = 12.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp)
        Spacer(Modifier.size(8.dp))
        Text("Đang kết nối Google Play…", color = Color.White.copy(alpha = 0.58f), fontSize = 12.sp)
    }
}

@Composable
private fun PlanButton(
    plan: PlaySubscriptionPlan?,
    isPlusUnlocked: Boolean,
    onPurchase: (String) -> Unit
) {
    Button(
        onClick = { plan?.let { onPurchase(it.productId) } },
        enabled = plan != null && !isPlusUnlocked,
        modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.buttonColors(
            containerColor = CollapseYellow,
            contentColor = Color.Black,
            disabledContainerColor = Color.White.copy(alpha = 0.07f),
            disabledContentColor = Color.White.copy(alpha = 0.55f)
        )
    ) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(plan?.title ?: "GÓI PLUS", fontWeight = FontWeight.SemiBold)
            Text(
                when {
                    isPlusUnlocked -> "ĐANG HOẠT ĐỘNG"
                    plan == null -> "KHÔNG KHẢ DỤNG"
                    else -> "${plan.formattedPrice} / ${periodLabel(plan.billingPeriod)}"
                }
            )
        }
    }
}

private fun periodLabel(period: String): String = when (period) {
    "P1W" -> "tuần"
    "P1M" -> "tháng"
    "P1Y" -> "năm"
    else -> period
}

@Composable
private fun PlusOrb() {
    Box(
        Modifier
            .size(196.dp)
            .background(Color.White.copy(alpha = 0.09f), CircleShape),
        contentAlignment = Alignment.Center
    ) {
        Box(
            Modifier
                .size(184.dp)
                .background(
                    Brush.radialGradient(listOf(Color(0xFF36C8EE).copy(alpha = 0.35f), Color(0xFF9B42B9).copy(alpha = 0.25f), Color.Transparent)),
                    CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            CollapseLogoSymbol(CollapseYellow, Modifier.size(92.dp))
            Text("+", modifier = Modifier.align(Alignment.BottomEnd).padding(20.dp), color = CollapseYellow, fontSize = 32.sp)
        }
    }
}

@Composable
private fun BenefitsCard() {
    GlassSurface(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(13.dp)) {
            plusBenefits.forEach { (icon, label) ->
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(icon, color = CollapseYellow, fontSize = 20.sp, modifier = Modifier.size(32.dp))
                    Text(label, color = Color.White, fontSize = 16.sp)
                }
            }
        }
    }
}
