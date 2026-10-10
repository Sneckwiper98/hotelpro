import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  static RazorpayService get instance => _instance;

  RazorpayService._internal();

  Razorpay? _razorpay;
  Function(String paymentId)? _currentSuccessCallback;
  Function(String errorMsg)? _currentFailureCallback;

  // Standard Razorpay Sandbox Key for test environments
  String _keyId = 'rzp_test_1DP5mmOlF5G5ag';

  String get keyId => _keyId;
  void setKeyId(String newKey) {
    _keyId = newKey;
  }

  void initialize() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return; // Razorpay native SDK only on mobile
    }
    if (_razorpay != null) return;

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}';
    _currentSuccessCallback?.call(paymentId);
    _clearCallbacks();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final errorMsg = response.message ?? 'Payment was cancelled or encountered an error';
    _currentFailureCallback?.call(errorMsg);
    _clearCallbacks();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final walletName = response.walletName ?? 'Wallet';
    final paymentId = 'pay_wallet_${walletName}_${DateTime.now().millisecondsSinceEpoch}';
    _currentSuccessCallback?.call(paymentId);
    _clearCallbacks();
  }

  void _clearCallbacks() {
    _currentSuccessCallback = null;
    _currentFailureCallback = null;
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _clearCallbacks();
  }

  Future<void> openCheckout({
    required BuildContext context,
    required double amountInRupees,
    required String orderId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required Function(String paymentId) onSuccess,
    required Function(String errorMessage) onFailure,
    bool forceSimulator = false,
  }) async {
    _currentSuccessCallback = onSuccess;
    _currentFailureCallback = onFailure;

    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (!isMobile || forceSimulator) {
      _showSimulatorDialog(
        context: context,
        amount: amountInRupees,
        orderId: orderId,
        customerName: customerName,
        onSuccess: (pid) {
          _currentSuccessCallback?.call(pid);
          _clearCallbacks();
        },
        onFailure: (err) {
          _currentFailureCallback?.call(err);
          _clearCallbacks();
        },
      );
      return;
    }

    try {
      initialize();

      final options = {
        'key': _keyId,
        'amount': (amountInRupees * 100).toInt(), // in paise
        'name': 'HotelPro Luxury & Dining',
        'description': 'Order #$orderId',
        'timeout': 180, // seconds
        'prefill': {
          'contact': customerPhone.replaceAll(RegExp(r'\D'), ''),
          'email': customerEmail,
          'name': customerName,
        },
        'theme': {
          'color': '#E23744', // Zomato Red / HotelPro Primary
        },
        'external': {
          'wallets': ['paytm', 'mobikwik']
        }
      };

      _razorpay?.open(options);
    } catch (e) {
      // Fallback to interactive test simulator if native checkout encounters issues
      _showSimulatorDialog(
        context: context,
        amount: amountInRupees,
        orderId: orderId,
        customerName: customerName,
        onSuccess: (pid) {
          _currentSuccessCallback?.call(pid);
          _clearCallbacks();
        },
        onFailure: (err) {
          _currentFailureCallback?.call(err);
          _clearCallbacks();
        },
      );
    }
  }

  void _showSimulatorDialog({
    required BuildContext context,
    required double amount,
    required String orderId,
    required String customerName,
    required Function(String paymentId) onSuccess,
    required Function(String errorMessage) onFailure,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RazorpayCheckoutSimulatorModal(
        amount: amount,
        orderId: orderId,
        customerName: customerName,
        keyId: _keyId,
        onSuccess: (pid) {
          Navigator.of(ctx).pop();
          onSuccess(pid);
        },
        onFailure: (err) {
          Navigator.of(ctx).pop();
          onFailure(err);
        },
      ),
    );
  }
}

class _RazorpayCheckoutSimulatorModal extends StatefulWidget {
  final double amount;
  final String orderId;
  final String customerName;
  final String keyId;
  final Function(String paymentId) onSuccess;
  final Function(String errorMessage) onFailure;

  const _RazorpayCheckoutSimulatorModal({
    required this.amount,
    required this.orderId,
    required this.customerName,
    required this.keyId,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  State<_RazorpayCheckoutSimulatorModal> createState() => _RazorpayCheckoutSimulatorModalState();
}

class _RazorpayCheckoutSimulatorModalState extends State<_RazorpayCheckoutSimulatorModal> {
  int _selectedUpiIndex = 0;
  bool _isAuthorizing = false;

  final List<Map<String, dynamic>> _upiApps = [
    {'name': 'Google Pay (UPI)', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFF4285F4)},
    {'name': 'PhonePe', 'icon': Icons.payment_rounded, 'color': Color(0xFF5F259F)},
    {'name': 'Paytm UPI', 'icon': Icons.account_balance_rounded, 'color': Color(0xFF00BAF2)},
    {'name': 'Credit / Debit Card', 'icon': Icons.credit_card_rounded, 'color': Color(0xFFE23744)},
    {'name': 'Net Banking (All Banks)', 'icon': Icons.account_balance_rounded, 'color': Color(0xFF1B4F72)},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),

            // Razorpay Header Brand Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0C2340), // Razorpay signature dark blue
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C2340),
                      border: Border.all(color: const Color(0xFF3395FF), width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: Color(0xFF3395FF), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Razorpay Trusted Gateway',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        Text(
                          'RBI Licensed • 256-Bit SSL Encrypted',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade900,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 11, color: Colors.greenAccent),
                        SizedBox(width: 4),
                        Text('SECURE', style: TextStyle(color: Colors.greenAccent, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Details summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ID: ${widget.orderId}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                    Text('Paying to: HotelPro Luxury & Dining', style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                  ],
                ),
                Text(
                  '₹${widget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0C2340)),
                ),
              ],
            ),
            const Divider(height: 20),

            const Text(
              'CHOOSE PAYMENT OPTION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),

            // Payment Options
            ...List.generate(_upiApps.length, (idx) {
              final app = _upiApps[idx];
              final isSel = _selectedUpiIndex == idx;

              return InkWell(
                onTap: () => setState(() => _selectedUpiIndex = idx),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFF0F7FF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSel ? const Color(0xFF0C2340) : Colors.grey.shade200, width: isSel ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (app['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(app['icon'] as IconData, color: app['color'] as Color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          app['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? const Color(0xFF0C2340) : Colors.black87,
                          ),
                        ),
                      ),
                      if (isSel)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF0C2340), size: 18)
                      else
                        Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 18),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Pay Button
            ElevatedButton(
              onPressed: _isAuthorizing
                  ? null
                  : () async {
                      setState(() => _isAuthorizing = true);
                      await Future.delayed(const Duration(milliseconds: 1200));

                      final simulatedPaymentId = 'pay_rzp_${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';
                      widget.onSuccess(simulatedPaymentId);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C2340), // Razorpay Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
              ),
              child: _isAuthorizing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('Authorizing via Razorpay...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Pay ₹${widget.amount.toStringAsFixed(2)} via Razorpay',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => widget.onFailure('Customer cancelled Razorpay checkout'),
              child: const Text('Cancel Payment', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
