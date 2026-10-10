import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/hotel_sync_bridge_service.dart';
import '../../../data/services/razorpay_service.dart';

class CustomerPaymentView extends StatefulWidget {
  final Function(CustomerFoodOrderModel order) onPaymentSuccess;

  const CustomerPaymentView({
    super.key,
    required this.onPaymentSuccess,
  });

  @override
  State<CustomerPaymentView> createState() => _CustomerPaymentViewState();
}

class _CustomerPaymentViewState extends State<CustomerPaymentView> {
  OnlinePaymentMethod _selectedMethod = OnlinePaymentMethod.razorpay;
  bool _isProcessing = false;
  String _statusMessage = 'Connecting to Razorpay Gateway...';

  @override
  void dispose() {
    RazorpayService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final grandTotal = repo.customerCartGrandTotal;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Payment Method',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
            tooltip: 'Razorpay Info',
            onPressed: () => _showRazorpayInfoDialog(context),
          ),
        ],
      ),
      body: _isProcessing
          ? _buildProcessingState(grandTotal)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total Payable Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Amount to Pay', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              '₹${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0C2340)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified_user_rounded, size: 14, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text('Razorpay Secured', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── RAZORPAY PRIMARY HERO TILE ────────────────────────────
                  const Text(
                    'RECOMMENDED (ALL-IN-ONE GATEWAY)',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: () => setState(() => _selectedMethod = OnlinePaymentMethod.razorpay),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _selectedMethod == OnlinePaymentMethod.razorpay
                              ? [const Color(0xFF0C2340), const Color(0xFF1E3A8A)]
                              : [Colors.white, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedMethod == OnlinePaymentMethod.razorpay
                              ? const Color(0xFF3395FF)
                              : Colors.grey.shade300,
                          width: _selectedMethod == OnlinePaymentMethod.razorpay ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _selectedMethod == OnlinePaymentMethod.razorpay
                                ? const Color(0xFF0C2340).withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _selectedMethod == OnlinePaymentMethod.razorpay
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : const Color(0xFF0C2340).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.flash_on_rounded,
                                  color: _selectedMethod == OnlinePaymentMethod.razorpay
                                      ? const Color(0xFF3395FF)
                                      : const Color(0xFF0C2340),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Razorpay Secure Checkout',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.5,
                                            color: _selectedMethod == OnlinePaymentMethod.razorpay ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3395FF),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('OFFICIAL', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'UPI (GPay, PhonePe, Paytm), Cards, NetBanking & Wallets',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _selectedMethod == OnlinePaymentMethod.razorpay ? Colors.white70 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<OnlinePaymentMethod>(
                                value: OnlinePaymentMethod.razorpay,
                                groupValue: _selectedMethod,
                                onChanged: (v) => setState(() => _selectedMethod = v!),
                                activeColor: const Color(0xFF3395FF),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _paymentBadge('GPay / PhonePe / Paytm', _selectedMethod == OnlinePaymentMethod.razorpay),
                              const SizedBox(width: 6),
                              _paymentBadge('Visa / RuPay / MC', _selectedMethod == OnlinePaymentMethod.razorpay),
                              const SizedBox(width: 6),
                              _paymentBadge('50+ Banks', _selectedMethod == OnlinePaymentMethod.razorpay),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── OTHER PAYMENT METHODS ─────────────────────────────────
                  const Text(
                    'DIRECT PAYMENT MODES',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),

                  _paymentTile(
                    method: OnlinePaymentMethod.upiGpay,
                    title: 'Google Pay UPI',
                    subtitle: 'Instant UPI transfer',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF4285F4),
                  ),
                  _paymentTile(
                    method: OnlinePaymentMethod.upiPhonepe,
                    title: 'PhonePe UPI',
                    subtitle: 'Direct UPI transfer',
                    icon: Icons.payment_rounded,
                    iconColor: const Color(0xFF5F259F),
                  ),
                  _paymentTile(
                    method: OnlinePaymentMethod.upiPaytm,
                    title: 'Paytm UPI',
                    subtitle: 'Direct Paytm wallet & UPI',
                    icon: Icons.account_balance_rounded,
                    iconColor: const Color(0xFF00BAF2),
                  ),
                  _paymentTile(
                    method: OnlinePaymentMethod.creditDebitCard,
                    title: 'Credit / Debit Card',
                    subtitle: 'Visa, Mastercard, RuPay, Amex',
                    icon: Icons.credit_card_rounded,
                    iconColor: const Color(0xFFE23744),
                  ),
                  _paymentTile(
                    method: OnlinePaymentMethod.cashOnDelivery,
                    title: 'Cash on Delivery (COD)',
                    subtitle: 'Pay cash or UPI to delivery rider at door',
                    icon: Icons.local_shipping_rounded,
                    iconColor: Colors.teal,
                  ),

                  const SizedBox(height: 24),

                  // Pay Button
                  ElevatedButton(
                    onPressed: () => _handlePayButton(repo, grandTotal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMethod == OnlinePaymentMethod.razorpay
                          ? const Color(0xFF0C2340) // Razorpay Blue
                          : const Color(0xFFE23744), // Zomato Red
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedMethod == OnlinePaymentMethod.razorpay ? Icons.flash_on_rounded : Icons.lock_outline_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedMethod == OnlinePaymentMethod.razorpay
                              ? 'Pay ₹${grandTotal.toStringAsFixed(2)} via Razorpay'
                              : 'Pay ₹${grandTotal.toStringAsFixed(2)} Securely',
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      '🔒 End-to-End 256-Bit SSL Encrypted Transaction',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _paymentBadge(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white70 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _paymentTile({
    required OnlinePaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedMethod == method;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? const Color(0xFFE23744) : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
      ),
      child: RadioListTile<OnlinePaymentMethod>(
        value: method,
        groupValue: _selectedMethod,
        onChanged: (v) => setState(() => _selectedMethod = v!),
        activeColor: const Color(0xFFE23744),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildProcessingState(double total) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF0C2340), strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0C2340)),
            ),
            const SizedBox(height: 6),
            Text('Processing authorization for ₹${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_clock_rounded, size: 14, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('Please do not close the app or tap back', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePayButton(HotelRepository repo, double grandTotal) async {
    final customer = repo.currentCustomer;
    final customerName = customer?.name ?? 'Guest User';
    final customerPhone = customer?.phone ?? '+91 99999 88888';
    final customerEmail = customer?.email ?? 'guest@hotelpro.com';
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    if (_selectedMethod == OnlinePaymentMethod.razorpay) {
      // Trigger Razorpay SDK / Simulator Checkout
      await RazorpayService.instance.openCheckout(
        context: context,
        amountInRupees: grandTotal,
        orderId: orderId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        onSuccess: (paymentId) {
          _completeOrderPlacement(repo, paymentId, OnlinePaymentMethod.razorpay);
        },
        onFailure: (errorMessage) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Razorpay Error: $errorMessage'), backgroundColor: Colors.red),
          );
        },
      );
    } else {
      // Direct / COD payment
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Confirming your order with kitchen...';
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      final txnId = _selectedMethod == OnlinePaymentMethod.cashOnDelivery
          ? 'COD-PAY-ON-DELIVERY'
          : 'TXN-DIR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      _completeOrderPlacement(repo, txnId, _selectedMethod);
    }
  }

  void _completeOrderPlacement(HotelRepository repo, String transactionId, OnlinePaymentMethod method) {
    final order = repo.placeCustomerFoodOrder(
      paymentMethod: method,
      transactionId: transactionId,
    );

    if (order != null) {
      // Push order to Windows Desktop ERP over Hotel LAN / Wi-Fi
      HotelSyncBridgeService.instance.sendCustomerOrderToWindowsErp(order);
      widget.onPaymentSuccess(order);
      Navigator.of(context).pop(); // Close payment view
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Payment Successful! Transaction ID: $transactionId'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Please check cart items.'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRazorpayInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.flash_on_rounded, color: Color(0xFF3395FF)),
            SizedBox(width: 8),
            Text('Razorpay Integration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HotelPro is configured with Razorpay Payment Gateway.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Key:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(RazorpayService.instance.keyId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Mode: Sandbox / Live Hybrid with Simulator Fallback', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
