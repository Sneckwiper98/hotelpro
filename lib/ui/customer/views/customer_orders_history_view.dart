import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../dialogs/customer_invoice_dialog.dart';
import 'customer_order_tracking_view.dart';

class CustomerOrdersHistoryView extends StatelessWidget {
  const CustomerOrdersHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final orders = repo.customerOrders;
    final activeOrders = orders.where((o) => o.orderStatus != CustomerOrderStatus.delivered && o.orderStatus != CustomerOrderStatus.cancelled).toList();
    final pastOrders = orders.where((o) => o.orderStatus == CustomerOrderStatus.delivered || o.orderStatus == CustomerOrderStatus.cancelled).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('My Orders & Bills', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
          bottom: const TabBar(
            labelColor: Color(0xFFE23744),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFE23744),
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Active Orders'),
              Tab(text: 'Past Orders & Invoices'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrdersList(context, repo, activeOrders, isActive: true),
            _buildOrdersList(context, repo, pastOrders, isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, HotelRepository repo, List<CustomerFoodOrderModel> list, {required bool isActive}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? Icons.delivery_dining_outlined : Icons.history_rounded, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              isActive ? 'No active delivery in progress' : 'No past orders found',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              isActive ? 'Your freshly ordered meals will appear here!' : 'Order from our 5-star kitchen today.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final order = list[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Top Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B4F72))),
                        Text(dateFormat.format(order.createdAt), style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                      ],
                    ),
                    _statusChip(order.orderStatus),
                  ],
                ),
              ),

              // Items Summary
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: item.isVeg ? Colors.green : Colors.red),
                            const SizedBox(width: 6),
                            Expanded(child: Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: 12))),
                            Text('₹${item.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paid via ${_paymentLabel(order.paymentMethod)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text('₹${order.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B4F72))),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    // View GST Tax Invoice Button
                    OutlinedButton.icon(
                      onPressed: () => CustomerInvoiceDialog.show(context, order, repo.activeBranch),
                      icon: const Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF1B4F72)),
                      label: const Text('View GST Invoice', style: TextStyle(fontSize: 11, color: Color(0xFF1B4F72), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: const BorderSide(color: Color(0xFF1B4F72)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const Spacer(),
                    if (isActive)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => CustomerOrderTrackingView(initialOrder: order)),
                          );
                        },
                        icon: const Icon(Icons.location_searching_rounded, size: 14),
                        label: const Text('Track Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE23744),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () {
                          // Re-order items
                          for (final it in order.items) {
                            final match = repo.activeBranchMenuItems.firstWhere((m) => m.id == it.menuItemId, orElse: () => repo.activeBranchMenuItems.first);
                            repo.addToCustomerCart(match);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Items added to basket!'), backgroundColor: Colors.green),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text('Re-Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4F72),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(CustomerOrderStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case CustomerOrderStatus.placed:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'PLACED';
        break;
      case CustomerOrderStatus.kitchenPreparing:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'PREPARING';
        break;
      case CustomerOrderStatus.outForDelivery:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        label = 'ON THE WAY';
        break;
      case CustomerOrderStatus.delivered:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'DELIVERED';
        break;
      case CustomerOrderStatus.cancelled:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  static String _paymentLabel(OnlinePaymentMethod method) {
    switch (method) {
      case OnlinePaymentMethod.razorpay:
        return 'Razorpay';
      case OnlinePaymentMethod.upiGpay:
        return 'GPay UPI';
      case OnlinePaymentMethod.upiPhonepe:
        return 'PhonePe UPI';
      case OnlinePaymentMethod.upiPaytm:
        return 'Paytm UPI';
      case OnlinePaymentMethod.upiQrCode:
        return 'UPI QR';
      case OnlinePaymentMethod.creditDebitCard:
        return 'Card';
      case OnlinePaymentMethod.netBanking:
        return 'Net Banking';
      case OnlinePaymentMethod.cashOnDelivery:
        return 'COD';
    }
  }
}
