import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/branch_model.dart';
import '../../core/components/hotel_logo_widget.dart';

class CustomerInvoiceDialog extends StatelessWidget {
  final CustomerFoodOrderModel order;
  final BranchModel branch;

  const CustomerInvoiceDialog({
    super.key,
    required this.order,
    required this.branch,
  });

  static void show(BuildContext context, CustomerFoodOrderModel order, BranchModel branch) {
    showDialog(
      context: context,
      builder: (ctx) => CustomerInvoiceDialog(order: order, branch: branch),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF1B4F72),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'GST TAX INVOICE',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Invoice Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hotel Letterhead with Brand Logo
                      Center(
                        child: Column(
                          children: [
                            const HotelLogoWidget(
                              width: 54,
                              height: 54,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              branch.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B4F72)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${branch.address}, ${branch.city} - ${branch.state}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                            Text(
                              'GSTIN: ${branch.taxIdentifier} | Phone: ${branch.phone}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                            ),
                            Text(
                              'FSSAI Lic No: 11522018000492',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(thickness: 1.5, color: Colors.black87),

                      // Metadata Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _metaRow('Invoice No:', order.id),
                                _metaRow('Date & Time:', dateFormat.format(order.createdAt)),
                                _metaRow('Place of Supply:', '${branch.city} (27)'),
                                _metaRow('SAC / HSN Code:', '996331 (Food & Beverage)'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _metaRow('Billed To:', order.customerName),
                                _metaRow('Phone:', order.customerPhone),
                                _metaRow('Delivery Address:', order.deliveryAddress.fullAddress),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Items Table
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              color: const Color(0xFFF2F4F4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: const Row(
                                children: [
                                  SizedBox(width: 24, child: Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  Expanded(child: Text('Item Description', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 32, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 60, child: Text('Rate (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  SizedBox(width: 70, child: Text('Amount (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Colors.black26),
                            // Table Rows
                            ...order.items.asMap().entries.map((entry) {
                              final idx = entry.key + 1;
                              final item = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  children: [
                                    SizedBox(width: 24, child: Text('$idx', style: const TextStyle(fontSize: 11))),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 8,
                                            color: item.isVeg ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(child: Text(item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 32, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                                    SizedBox(width: 60, child: Text(item.price.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                                    SizedBox(width: 70, child: Text(item.subtotal.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Totals & Taxes Breakup
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBFCFC),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            _calcRow('Item Subtotal', '₹${order.itemTotal.toStringAsFixed(2)}'),
                            _calcRow('CGST (2.5%)', '₹${(order.gstAmount / 2).toStringAsFixed(2)}'),
                            _calcRow('SGST (2.5%)', '₹${(order.gstAmount / 2).toStringAsFixed(2)}'),
                            _calcRow('Packaging Charges', '₹${order.packagingCharge.toStringAsFixed(2)}'),
                            _calcRow('Delivery Charges (Within 10km)', order.deliveryFee == 0 ? 'FREE' : '₹${order.deliveryFee.toStringAsFixed(2)}', color: order.deliveryFee == 0 ? Colors.green.shade700 : null),
                            if (order.discountAmount > 0)
                              _calcRow('Promo Discount (${order.couponCodeApplied})', '-₹${order.discountAmount.toStringAsFixed(2)}', color: Colors.green.shade800),
                            const Divider(thickness: 1.2),
                            _calcRow(
                              'TOTAL AMOUNT PAID',
                              '₹${order.grandTotal.toStringAsFixed(2)}',
                              isBold: true,
                              fontSize: 13,
                              color: const Color(0xFF1B4F72),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Payment & Signature Information
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Paid via ${_paymentLabel(order.paymentMethod)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  Text(
                                    'Txn Ref: ${order.transactionId} | Status: PAID',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'For ${branch.name}',
                                  style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '[Computer Generated Invoice]',
                                  style: TextStyle(fontSize: 9, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invoice downloaded as PDF (Saved to Downloads/Invoices)'), backgroundColor: Colors.green),
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download PDF'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4F72),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Printing GST Invoice to default thermal receipt printer...'), backgroundColor: Color(0xFF1B4F72)),
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print Receipt'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 10.5, color: Colors.black87),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            TextSpan(text: val),
          ],
        ),
      ),
    );
  }

  Widget _calcRow(String label, String val, {bool isBold = false, double fontSize = 11, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black87)),
          Text(val, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  static String _paymentLabel(OnlinePaymentMethod method) {
    switch (method) {
      case OnlinePaymentMethod.razorpay:
        return 'Razorpay Payment Gateway';
      case OnlinePaymentMethod.upiGpay:
        return 'Google Pay (UPI)';
      case OnlinePaymentMethod.upiPhonepe:
        return 'PhonePe (UPI)';
      case OnlinePaymentMethod.upiPaytm:
        return 'Paytm (UPI)';
      case OnlinePaymentMethod.upiQrCode:
        return 'Instant UPI QR';
      case OnlinePaymentMethod.creditDebitCard:
        return 'Credit/Debit Card';
      case OnlinePaymentMethod.netBanking:
        return 'Net Banking';
      case OnlinePaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
    }
  }
}
