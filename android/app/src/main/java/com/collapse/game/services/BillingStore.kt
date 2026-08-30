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

enum class BillingStatus {
    Connecting,
    Loading,
    Ready,
    Active,
    Pending,
    None,
    Unavailable,
    Error,
    Cancelled,
    Restoring
}

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
    var status by mutableStateOf(BillingStatus.Connecting)
        private set

    init {
        connect()
    }

    override fun onBillingSetupFinished(result: BillingResult) {
        isConnecting = false
        if (result.responseCode != BillingClient.BillingResponseCode.OK) {
            status = BillingStatus.Unavailable
            return
        }
        status = BillingStatus.Loading
        refresh()
    }

    override fun onBillingServiceDisconnected() {
        isConnecting = false
        status = BillingStatus.Unavailable
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: List<Purchase>?) {
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> reconcilePurchases(purchases.orEmpty())
            BillingClient.BillingResponseCode.USER_CANCELED -> status = BillingStatus.Cancelled
            else -> status = BillingStatus.Error
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
            status = BillingStatus.Unavailable
            queryPlans()
            return
        }
        launchPurchase(activity, details)
    }

    fun restore() {
        guardReady { return }
        status = BillingStatus.Restoring
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
                status = BillingStatus.Error
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
        status = when {
            isPlusUnlocked -> BillingStatus.Active
            weeklyPlan == null && monthlyPlan == null -> BillingStatus.Unavailable
            else -> BillingStatus.Ready
        }
    }

    private fun queryPurchases() {
        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.SUBS)
            .build()
        billingClient.queryPurchasesAsync(params) { result, purchases ->
            if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                status = BillingStatus.Error
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
        status = when {
            isPlusUnlocked -> BillingStatus.Active
            plusPurchases.any { it.purchaseState == Purchase.PurchaseState.PENDING } -> BillingStatus.Pending
            else -> BillingStatus.None
        }
    }

    private fun acknowledge(purchase: Purchase) {
        val params = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()
        billingClient.acknowledgePurchase(params) { result ->
            if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                status = BillingStatus.Error
            }
        }
    }

    private fun launchPurchase(activity: Activity, details: ProductDetails) {
        val offer = details.subscriptionOfferDetails?.firstOrNull()
        if (offer == null) {
            status = BillingStatus.Unavailable
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
            status = BillingStatus.Error
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
        status = BillingStatus.Connecting
        billingClient.startConnection(this)
    }

    private inline fun guardReady(onFailure: () -> Unit) {
        if (billingClient.isReady) return
        connect()
        onFailure()
    }
}
