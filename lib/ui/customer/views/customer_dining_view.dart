import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/hotel_repository.dart';

class CustomerDiningView extends StatefulWidget {
  const CustomerDiningView({super.key});

  @override
  State<CustomerDiningView> createState() => _CustomerDiningViewState();
}

class _CustomerDiningViewState extends State<CustomerDiningView> {
  int _selectedGuests = 2;
  String _selectedSlot = '08:00 PM';
  String _serviceType = 'Table Booking'; // 'Table Booking' or 'Banquet Hall'
  String _selectedHallPackage = 'Royal Grand Buffet (Veg + Non-Veg) - ₹1,450/Plate';

  final List<String> _timeSlots = [
    '01:00 PM', '01:30 PM', '02:00 PM',
    '07:30 PM', '08:00 PM', '08:30 PM', '09:00 PM', '09:30 PM'
  ];

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final branch = repo.activeBranch;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Dine-in & Banquets • ${branch.city}',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Switch between Table Booking & Hall Booking
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _serviceType = 'Table Booking'),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _serviceType == 'Table Booking' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _serviceType == 'Table Booking'
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                              : null,
                        ),
                        child: Text(
                          '🍽️ Restaurant Table',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: _serviceType == 'Table Booking' ? const Color(0xFFE23744) : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _serviceType = 'Banquet Hall'),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _serviceType == 'Banquet Hall' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _serviceType == 'Banquet Hall'
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                              : null,
                        ),
                        child: Text(
                          '🏛️ Banquet & Hall Booking',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: _serviceType == 'Banquet Hall' ? const Color(0xFFE23744) : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_serviceType == 'Table Booking') ...[
              // Restaurant Ambience Card
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4F72), Color(0xFF2C3E50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                      child: const Text('5-STAR FINE DINING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black87)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The Royal Bistro & Terrace Grill',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      'Live music, candle light ambiance, rooftop view at ${branch.name}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Guests Selector
              const Text('Select Number of Guests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [1, 2, 4, 6, 8, 10].map((count) {
                  final isSelected = _selectedGuests == count;
                  return ChoiceChip(
                    label: Text('$count ${count == 1 ? "Guest" : "Guests"}'),
                    selected: isSelected,
                    onSelected: (s) => setState(() => _selectedGuests = count),
                    selectedColor: const Color(0xFFE23744),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Time Slot Selector
              const Text('Select Time Slot (Tonight)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((slot) {
                  final isSelected = _selectedSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: (s) => setState(() => _selectedSlot = slot),
                    selectedColor: const Color(0xFF1B4F72),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Table for $_selectedGuests guests reserved at $_selectedSlot! SMS confirmation sent.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Confirm Table Reservation (Free)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE23744),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ] else ...[
              // Banquet & Hall Booking Mode
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C3483), Color(0xFF1B4F72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                      child: const Text('WEDDINGS • CONFERENCES • PARTIES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black87)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kohinoor Grand Banquet Hall',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Text(
                      'Capacity: 50 to 500 Guests • Central AC • Stage & Audio Visuals',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Select Food & Catering Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedHallPackage,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                    items: [
                      'Silver Veg Buffet (3 Starters + 4 Mains + Desserts) - ₹850/Plate',
                      'Gold Deluxe Buffet (Veg + Chicken + Fish) - ₹1,150/Plate',
                      'Royal Grand Buffet (Veg + Non-Veg) - ₹1,450/Plate',
                      'High Tea & Corporate Snack Buffet - ₹550/Plate',
                    ].map((pkg) => DropdownMenuItem(value: pkg, child: Text(pkg, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _selectedHallPackage = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Estimated Guest Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [50, 100, 200, 300, 500].map((count) {
                  final isSelected = _selectedGuests == count;
                  return ChoiceChip(
                    label: Text('$count People'),
                    selected: isSelected,
                    onSelected: (s) => setState(() => _selectedGuests = count),
                    selectedColor: const Color(0xFF6C3483),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Banquet enquiry for $_selectedGuests guests booked! Our events manager will call you within 15 mins.'),
                      backgroundColor: Colors.purple.shade800,
                    ),
                  );
                },
                icon: const Icon(Icons.celebration_rounded),
                label: const Text('Request Banquet & Catering Quote'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C3483),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
