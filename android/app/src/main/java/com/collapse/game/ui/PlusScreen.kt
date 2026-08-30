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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.collapse.game.R
import com.collapse.game.services.BillingStatus
import com.collapse.game.services.BillingStore
import com.collapse.game.services.PlaySubscriptionPlan

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
                stringResource(R.string.plus_description),
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
                Text(stringResource(R.string.plus_restore))
            }
            Text(
                billingStatusText(billing.status),
                modifier = Modifier.padding(top = 4.dp),
                color = if (billing.isPlusUnlocked) Color(0xFF65F59A) else CollapseYellow.copy(alpha = 0.82f),
                fontSize = 12.sp,
                textAlign = TextAlign.Center
            )
            Text(
                stringResource(R.string.plus_fairness),
                modifier = Modifier.padding(top = 18.dp),
                color = Color.White.copy(alpha = 0.48f),
                fontSize = 12.sp,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(28.dp))
        }
        OutlinedButton(onClick = onClose, modifier = Modifier.align(Alignment.TopEnd).padding(top = 24.dp, end = 14.dp)) {
            Text(stringResource(R.string.plus_close))
        }
    }
}

@Composable
private fun billingStatusText(status: BillingStatus): String = when (status) {
    BillingStatus.Connecting -> stringResource(R.string.plus_connecting)
    BillingStatus.Loading -> stringResource(R.string.plus_status_loading)
    BillingStatus.Ready -> stringResource(R.string.plus_status_ready)
    BillingStatus.Active -> stringResource(R.string.plus_status_active)
    BillingStatus.Pending -> stringResource(R.string.plus_status_pending)
    BillingStatus.None -> stringResource(R.string.plus_status_none)
    BillingStatus.Unavailable -> stringResource(R.string.plus_unavailable)
    BillingStatus.Error -> stringResource(R.string.plus_status_error)
    BillingStatus.Cancelled -> stringResource(R.string.plus_status_cancelled)
    BillingStatus.Restoring -> stringResource(R.string.plus_status_restoring)
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
        Text(stringResource(R.string.plus_connecting), color = Color.White.copy(alpha = 0.58f), fontSize = 12.sp)
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
            Text(planTitle(plan), fontWeight = FontWeight.SemiBold)
            Text(
                when {
                    isPlusUnlocked -> stringResource(R.string.plus_active)
                    plan == null -> stringResource(R.string.plus_unavailable)
                    else -> "${plan.formattedPrice} / ${periodLabel(plan.billingPeriod)}"
                }
            )
        }
    }
}

@Composable
private fun planTitle(plan: PlaySubscriptionPlan?): String = when (plan?.productId) {
    "collapse.plus.weekly" -> stringResource(R.string.plus_plan_weekly)
    "collapse.plus.monthly" -> stringResource(R.string.plus_plan_monthly)
    else -> stringResource(R.string.plus_plan)
}

@Composable
private fun periodLabel(period: String): String = when (period) {
    "P1W" -> stringResource(R.string.period_week)
    "P1M" -> stringResource(R.string.period_month)
    "P1Y" -> stringResource(R.string.period_year)
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
    val plusBenefits = listOf(
        "▱" to stringResource(R.string.plus_no_ads),
        "✦" to stringResource(R.string.plus_themes),
        "◉" to stringResource(R.string.plus_early),
        "▥" to stringResource(R.string.plus_sound),
        "⬢" to stringResource(R.string.plus_fair)
    )
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
