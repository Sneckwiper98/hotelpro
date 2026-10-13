import '../../config/app_constants.dart';

class PosOutletModel {
  final String id;
  final String branchId;
  final String name; // e.g. "The Royal Bistro", "Skyline Rooftop Bar", "In-Room Dining"
  final String type;

  const PosOutletModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.type,
  });

  factory PosOutletModel.fromJson(Map<String, dynamic> json) => PosOutletModel(
    id: json['id'] as String,
    branchId: json['branch_id'] as String? ?? '',
    name: json['name'] as String? ?? 'Outlet',
    type: json['type'] as String? ?? 'fine_dining',
  );
}

class PosMenuItemModel {
  final String id;
  final String outletId;
  final String name;
  final String category;
  final double price;
  final double taxRate; // e.g. 5.0 %
  final bool isAvailable;
  final bool isVeg;
  final String emoji;
  final String? description;
  final String? imageUrl;

  const PosMenuItemModel({
    required this.id,
    required this.outletId,
    required this.name,
    required this.category,
    required this.price,
    this.taxRate = 5.0,
    this.isAvailable = true,
    this.isVeg = true,
    this.emoji = '🍽️',
    this.description,
    this.imageUrl,
  });

  PosMenuItemModel copyWith({
    String? name,
    String? category,
    double? price,
    double? taxRate,
    bool? isAvailable,
    bool? isVeg,
    String? emoji,
    String? description,
    String? imageUrl,
  }) {
    return PosMenuItemModel(
      id: id,
      outletId: outletId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      taxRate: taxRate ?? this.taxRate,
      isAvailable: isAvailable ?? this.isAvailable,
      isVeg: isVeg ?? this.isVeg,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  double get taxAmount => (price * taxRate) / 100.0;
  double get totalPriceWithTax => price + taxAmount;
  double get cgstAmount => taxAmount / 2.0;
  double get sgstAmount => taxAmount / 2.0;
  String get taxLabel => taxRate > 0 ? '${taxRate.toStringAsFixed(0)}% GST' : 'Exempt (0%)';

  factory PosMenuItemModel.fromJson(Map<String, dynamic> json) => PosMenuItemModel(
    id: json['id'] as String,
    outletId: json['outlet_id'] as String? ?? '',
    name: json['name'] as String,
    category: json['category'] as String? ?? 'Main Course',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 5.0,
    isAvailable: json['is_available'] as bool? ?? true,
    isVeg: json['is_veg'] as bool? ?? true,
    emoji: json['emoji'] as String? ?? '🍽️',
    description: json['description'] as String?,
    imageUrl: json['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'outlet_id': outletId,
    'name': name,
    'category': category,
    'price': price,
    'tax_rate': taxRate,
    'is_available': isAvailable,
    'is_veg': isVeg,
    'emoji': emoji,
    'description': description,
    'image_url': imageUrl,
  };
}


class PosOrderItem {
  final String menuItemId;
  final String name;
  int quantity;
  final double price;
  final double taxRate;
  final String? notes;

  PosOrderItem({
    required this.menuItemId,
    required this.name,
    this.quantity = 1,
    required this.price,
    this.taxRate = 5.0,
    this.notes,
  });

  double get subtotal => price * quantity;
  double get tax => subtotal * (taxRate / 100);
  double get total => subtotal + tax;

  factory PosOrderItem.fromJson(Map<String, dynamic> json) => PosOrderItem(
    menuItemId: json['menuItemId']?.toString() ?? json['menu_item_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    taxRate: (json['taxRate'] ?? json['tax_rate'] as num?)?.toDouble() ?? 5.0,
    notes: json['notes'] as String?,
  );
}

class PosOrderModel {
  final String id;
  final String outletId;
  final String orderNumber; // e.g. "KOT-1092"
  final String? tableNumber;
  final String? roomNumber;
  final String? guestName;
  final PosOrderStatus status;
  final List<PosOrderItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String? chargedToFolioId;
  final DateTime createdAt;

  const PosOrderModel({
    required this.id,
    required this.outletId,
    required this.orderNumber,
    this.tableNumber,
    this.roomNumber,
    this.guestName,
    this.status = PosOrderStatus.kotPrinted,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.chargedToFolioId,
    required this.createdAt,
  });

  PosOrderModel copyWith({
    PosOrderStatus? status,
    String? chargedToFolioId,
  }) {
    return PosOrderModel(
      id: id,
      outletId: outletId,
      orderNumber: orderNumber,
      tableNumber: tableNumber,
      roomNumber: roomNumber,
      guestName: guestName,
      status: status ?? this.status,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      chargedToFolioId: chargedToFolioId ?? this.chargedToFolioId,
      createdAt: createdAt,
    );
  }

  factory PosOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<PosOrderItem> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems.map((i) => PosOrderItem.fromJson(i as Map<String, dynamic>)).toList();
    }
    final statusStr = json['status'] as String? ?? 'kot_printed';
    PosOrderStatus status = PosOrderStatus.kotPrinted;
    for (final s in PosOrderStatus.values) {
      if (s.name == statusStr || s.code == statusStr) {
        status = s;
        break;
      }
    }
    return PosOrderModel(
      id: json['id'] as String,
      outletId: json['outlet_id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      tableNumber: json['table_number'] as String?,
      roomNumber: json['room_number'] as String?,
      guestName: json['guest_name'] as String?,
      status: status,
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      chargedToFolioId: json['charged_to_folio_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// ── POS Billing Stream Types ────────────────────────────────────────────────
enum PosBillingType {
  tableDining('Table Dining', 'table_dining', '🍽️'),
  roomFolio('Room Folio', 'room_folio', '🛎️'),
  hallBooking('Hall & Banquet Booking', 'hall_booking', '🏛️');

  final String label;
  final String code;
  final String iconEmoji;

  const PosBillingType(this.label, this.code, this.iconEmoji);
}

/// ── Complete POS Bill Record (Settled & Stored Invoices) ────────────────────
class PosBillRecord {
  final String id;
  final String billNumber;
  final PosBillingType billingType;
  final String branchId;
  final String outletId;
  final String outletName;

  // Table Dining specific
  final String? tableNumber;
  final int? covers;
  final String? waiterName;

  // Room Folio specific
  final String? roomNumber;
  final String? guestName;
  final String? folioId;
  final String? deliverySteward;

  // Hall Booking specific
  final String? hallName;
  final String? eventName;
  final String? hostName;
  final String? hostPhone;
  final String? eventSlot; // 'Morning (09:00 - 15:00)', 'Evening (18:00 - 23:30)', 'Full Day'
  final int? paxCount;
  final double? hallRentAmount;
  final double? cateringAmount;
  final double? advancePaid;
  final double? balanceDue;

  // Common items & financials
  final List<PosOrderItem> items;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;

  // Payment details
  final String paymentMethod;
  final String paymentStatus; // 'paid', 'posted_to_folio', 'partial_advance', 'pending'
  final DateTime createdAt;

  const PosBillRecord({
    required this.id,
    required this.billNumber,
    required this.billingType,
    required this.branchId,
    required this.outletId,
    required this.outletName,
    this.tableNumber,
    this.covers,
    this.waiterName,
    this.roomNumber,
    this.guestName,
    this.folioId,
    this.deliverySteward,
    this.hallName,
    this.eventName,
    this.hostName,
    this.hostPhone,
    this.eventSlot,
    this.paxCount,
    this.hallRentAmount,
    this.cateringAmount,
    this.advancePaid,
    this.balanceDue,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory PosBillRecord.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<PosOrderItem> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems.map((i) => PosOrderItem.fromJson(i as Map<String, dynamic>)).toList();
    }
    final bTypeStr = json['billing_type'] as String? ?? 'tableDining';
    PosBillingType bType = PosBillingType.tableDining;
    for (final t in PosBillingType.values) {
      if (t.name == bTypeStr || t.code == bTypeStr) {
        bType = t;
        break;
      }
    }
    return PosBillRecord(
      id: json['id'] as String,
      billNumber: json['bill_number'] as String? ?? '',
      billingType: bType,
      branchId: json['branch_id'] as String? ?? '',
      outletId: json['outlet_id'] as String? ?? '',
      outletName: json['outlet_name'] as String? ?? 'Restaurant',
      tableNumber: json['table_number'] as String?,
      covers: (json['covers'] as num?)?.toInt(),
      waiterName: json['waiter_name'] as String?,
      roomNumber: json['room_number'] as String?,
      guestName: json['guest_name'] as String?,
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      paymentStatus: json['payment_status'] as String? ?? 'paid',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// ── Banquet & Event Hall Facility Model ────────────────────────────────────
class BanquetHallModel {
  final String id;
  final String branchId;
  final String name;
  final int capacity;
  final double baseRental;
  final String features;

  const BanquetHallModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.capacity,
    required this.baseRental,
    required this.features,
  });

  factory BanquetHallModel.fromJson(Map<String, dynamic> json) => BanquetHallModel(
    id: json['id'] as String,
    branchId: json['branch_id'] as String? ?? '',
    name: json['name'] as String? ?? 'Banquet Hall',
    capacity: (json['capacity'] as num?)?.toInt() ?? 100,
    baseRental: (json['base_rental'] as num?)?.toDouble() ?? 50000.0,
    features: json['features'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_id': branchId,
    'name': name,
    'capacity': capacity,
    'base_rental': baseRental,
    'features': features,
  };

  BanquetHallModel copyWith({
    String? name,
    int? capacity,
    double? baseRental,
    String? features,
  }) => BanquetHallModel(
    id: id,
    branchId: branchId,
    name: name ?? this.name,
    capacity: capacity ?? this.capacity,
    baseRental: baseRental ?? this.baseRental,
    features: features ?? this.features,
  );
}
