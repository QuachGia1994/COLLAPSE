package com.collapse.game.services

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams

private const val WEEKLY_PRODUCT_ID = "collapse.plus.weekly"
private const val MONTHLY_PRODUCT_ID = "collapse.plus.monthly"
private val PLUS_PRODUCT_IDS = setOf(WEEKLY_PRODUCT_ID, MONTHLY_PRODUCT_ID)

data class PlaySubscriptionPlan(
    val productId: String,
    val title: String,
    val formattedPrice: String,
    val billingPeriod: String
)

class BillingStore(context: Context) : PurchasesUpdatedListener, BillingClientStateListener {
    private val billingClient = BillingClient.newBuilder(context)
        .setListener(this)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder()
                .enableOneTimeProducts()
                .build()
        )
        .enableAutoServiceReconnection()
        .build()

    private val productDetails = mutableMapOf<String, ProductDetails>()

    var weeklyPlan by mutableStateOf<PlaySubscriptionPlan?>(null)
        private set
    var monthlyPlan by mutableStateOf<PlaySubscriptionPlan?>(null)
        private set
    var isPlusUnlocked by mutableStateOf(false)
        private set
    var isConnecting by mutableStateOf(false)
        private set
    var statusMessage by mutableStateOf("Đang kết nối Google Play…")
        private set

    init {
        connect()
    }

    override fun onBillingSetupFinished(result: BillingResult) {
        isConnecting = false
        if (result.responseCode != BillingClient.BillingResponseCode.OK) {
            statusMessage = "Không kết nối được Google Play. Hãy thử lại khi có Play Store."
            return
        }
        statusMessage = "Đang tải gói Plus…"
        refresh()
    }

    override fun onBillingServiceDisconnected() {
        isConnecting = false
        statusMessage = "Google Play tạm ngắt kết nối."
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: List<Purchase>?) {
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> reconcilePurchases(purchases.orEmpty())
            BillingClient.BillingResponseCode.USER_CANCELED -> statusMessage = "Đã hủy thanh toán."
            else -> statusMessage = result.debugMessage.ifBlank { "Không thể hoàn tất thanh toán." }
        }
    }

    fun refresh() {
        guardReady { return }
        queryPlans()
        queryPurchases()
    }

    fun purchase(activity: Activity, productId: String) {
        guardReady { return }
        val details = productDetails[productId]
        if (details == null) {
            statusMessage = "Gói này chưa khả dụng từ Google Play."
            queryPlans()
            return
        }
        launchPurchase(activity, details)
    }

    fun restore() {
        guardReady { return }
        statusMessage = "Đang kiểm tra giao dịch…"
        queryPurchases()
    }

    fun close() {
        billingClient.endConnection()
    }

    private fun queryPlans() {
        val products = PLUS_PRODUCT_IDS.map { productId ->
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productId)
                .setProductType(BillingClient.ProductType.SUBS)
                .build()
        }
        val params = QueryProductDetailsParams.newBuilder().setProductList(products).build()
        billingClient.queryProductDetailsAsync(params) { result, queryResult ->
            if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                statusMessage = "Không tải được giá từ Google Play."
                return@queryProductDetailsAsync
            }
            applyProductDetails(queryResult.productDetailsList)
        }
    }

    private fun applyProductDetails(details: List<ProductDetails>) {
        productDetails.clear()
        details.forEach { productDetails[it.productId] = it }
        weeklyPlan = details.firstOrNull { it.productId == WEEKLY_PRODUCT_ID }?.toPlan("HÀNG TUẦN")
        monthlyPlan = details.firstOrNull { it.productId == MONTHLY_PRODUCT_ID }?.toPlan("HÀNG THÁNG")
        statusMessage = when {
            isPlusUnlocked -> "COLLAPSE Plus đang hoạt động."
            weeklyPlan == null && monthlyPlan == null -> "Gói Plus chưa khả dụng trong bản cài này. Dùng Google Play Internal Testing để mua thử."
            else -> "Chọn gói để tiếp tục trên Google Play."
        }
    }

    private fun queryPurchases() {
        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.SUBS)
            .build()
        billingClient.queryPurchasesAsync(params) { result, purchases ->
            if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                statusMessage = "Không kiểm tra được giao dịch Google Play."
                return@queryPurchasesAsync
            }
            reconcilePurchases(purchases)
        }
    }

    private fun reconcilePurchases(purchases: List<Purchase>) {
        val plusPurchases = purchases.filter { purchase ->
            purchase.products.any(PLUS_PRODUCT_IDS::contains)
        }
        val active = plusPurchases.filter { it.purchaseState == Purchase.PurchaseState.PURCHASED }
        isPlusUnlocked = active.isNotEmpty()
        active.filterNot { it.isAcknowledged }.forEach(::acknowledge)
        statusMessage = when {
            isPlusUnlocked -> "COLLAPSE Plus đang hoạt động."
            plusPurchases.any { it.purchaseState == Purchase.PurchaseState.PENDING } -> "Thanh toán đang chờ Google Play xác nhận."
            else -> "Chưa có gói Plus đang hoạt động."
        }
    }

    private fun acknowledge(purchase: Purchase) {
        val params = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()
        billingClient.acknowledgePurchase(params) { result ->
            if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                statusMessage = "Plus đã mua nhưng chưa xác nhận được với Google Play."
            }
        }
    }

    private fun launchPurchase(activity: Activity, details: ProductDetails) {
        val offer = details.subscriptionOfferDetails?.firstOrNull()
        if (offer == null) {
            statusMessage = "Gói chưa có base plan/offer khả dụng."
            return
        }
        val product = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(details)
            .setOfferToken(offer.offerToken)
            .build()
        val params = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(product))
            .build()
        val result = billingClient.launchBillingFlow(activity, params)
        if (result.responseCode != BillingClient.BillingResponseCode.OK) {
            statusMessage = result.debugMessage.ifBlank { "Không mở được Google Play checkout." }
        }
    }

    private fun ProductDetails.toPlan(title: String): PlaySubscriptionPlan? {
        val offer = subscriptionOfferDetails?.firstOrNull() ?: return null
        val phase = offer.pricingPhases.pricingPhaseList.lastOrNull() ?: return null
        return PlaySubscriptionPlan(
            productId = productId,
            title = title,
            formattedPrice = phase.formattedPrice,
            billingPeriod = phase.billingPeriod
        )
    }

    private fun connect() {
        if (billingClient.isReady || isConnecting) return
        isConnecting = true
        statusMessage = "Đang kết nối Google Play…"
        billingClient.startConnection(this)
    }

    private inline fun guardReady(onFailure: () -> Unit) {
        if (billingClient.isReady) return
        connect()
        onFailure()
    }
}
