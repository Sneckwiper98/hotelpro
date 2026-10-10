import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/hotel_repository.dart';

class CustomerRoomsView extends StatelessWidget {
  const CustomerRoomsView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final branch = repo.activeBranch;
    final roomTypes = repo.activeBranchRoomTypes;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Luxury Rooms • ${branch.name}',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: roomTypes.length,
        itemBuilder: (ctx, i) {
          final rt = roomTypes[i];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Room Header Gradient Banner
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    gradient: LinearGradient(
                      colors: [const Color(0xFF1B4F72), const Color(0xFF2C3E50).withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                        child: Text('${rt.code} • 5-STAR COMFORT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9.5, color: Colors.black87)),
                      ),
                      const SizedBox(height: 4),
                      Text(rt.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Max ${rt.maxAdults} Adults, ${rt.maxChildren} Child • ${rt.bedType} • Air Conditioned', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rt.description ?? '5-star luxury room with premier amenities and round-the-clock room service.', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: rt.amenities.map((a) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                            child: Text('✓ $a', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade800)),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Starting from', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                              Text('₹${rt.basePrice.toStringAsFixed(0)} / Night', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B4F72))),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Reservation initialized for ${rt.name} at ${branch.name}!'), backgroundColor: Colors.green),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4F72),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Book Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
