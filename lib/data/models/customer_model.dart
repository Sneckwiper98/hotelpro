enum CustomerOrderStatus {
  placed,
  kitchenPreparing,
  outForDelivery,
  delivered,
  cancelled,
}

enum OnlinePaymentMethod {
  razorpay,
  upiGpay,
  upiPhonepe,
  upiPaytm,
  upiQrCode,
  creditDebitCard,
  netBanking,
  cashOnDelivery,
}

enum OnlinePaymentStatus {
  pending,
  success,
  failed,
  refunded,
}

class CustomerAddressModel {
  final String id;
  final String label; // "Home", "Work", "Other"
  final String fullAddress;
  final String landmark;
  final String city;
  final String pincode;
  final double latitude;
  final double longitude;
  final double distanceKmFromHotel;
  final bool isWithin10Km;

  const CustomerAddressModel({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.landmark = '',
    this.city = 'Mumbai',
    this.pincode = '400069',
    this.latitude = 19.1136,
    this.longitude = 72.8697,
    this.distanceKmFromHotel = 3.2,
    this.isWithin10Km = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'full_address': fullAddress,
    'landmark': landmark,
    'city': city,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
    'distance_km': distanceKmFromHotel,
    'is_within_10km': isWithin10Km,
  };

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) => CustomerAddressModel(
    id: json['id'] as String,
    label: json['label'] as String? ?? 'Home',
    fullAddress: json['full_address'] as String? ?? '',
    landmark: json['landmark'] as String? ?? '',
    city: json['city'] as String? ?? 'Mumbai',
    pincode: json['pincode'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 19.0760,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 72.8777,
    distanceKmFromHotel: (json['distance_km'] as num?)?.toDouble() ?? 3.0,
    isWithin10Km: json['is_within_10km'] as bool? ?? true,
  );
}

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String password;
  final String city;
  final String? gstin;
  final String? companyName;
  final List<CustomerAddressModel> addresses;
  final double walletBalance;
  final int totalVisits;
  final DateTime joinedDate;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.password = '123456',
    this.city = 'Mumbai',
    this.gstin,
    this.companyName,
    required this.addresses,
    this.walletBalance = 150.0,
    this.totalVisits = 1,
    required this.joinedDate,
  });

  CustomerAddressModel? get primaryAddress => addresses.isNotEmpty ? addresses.first : null;
  String get displayAddress => primaryAddress?.fullAddress ?? (city.isNotEmpty ? city : 'India');

  CustomerModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? password,
    String? city,
    String? gstin,
    String? companyName,
    List<CustomerAddressModel>? addresses,
    double? walletBalance,
    int? totalVisits,
  }) {
    return CustomerModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      city: city ?? this.city,
      gstin: gstin ?? this.gstin,
      companyName: companyName ?? this.companyName,
      addresses: addresses ?? this.addresses,
      walletBalance: walletBalance ?? this.walletBalance,
      totalVisits: totalVisits ?? this.totalVisits,
      joinedDate: joinedDate,
    );
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    List<CustomerAddressModel> addrs = [];
    final rawAddrs = json['addresses'];
    if (rawAddrs is List) {
      addrs = rawAddrs
          .map((a) => CustomerAddressModel.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Customer',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '123456',
      city: json['city'] as String? ?? 'Mumbai',
      gstin: json['gstin'] as String?,
      companyName: json['company_name'] as String?,
      addresses: addrs,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      totalVisits: (json['total_visits'] as num?)?.toInt() ?? 1,
      joinedDate: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'addresses': addresses.map((a) => a.toJson()).toList(),
        'wallet_balance': walletBalance,
        'created_at': joinedDate.toIso8601String(),
      };
}


class CustomerCartItem {
  final String menuItemId;
  final String name;
  final double price;
  final bool isVeg;
  final String? imageUrl;
  final String category;
  int quantity;
  String cookingInstructions;

  CustomerCartItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.isVeg,
    this.imageUrl,
    this.category = 'Main Course',
    this.quantity = 1,
    this.cookingInstructions = '',
  });

  double get subtotal => price * quantity;

  factory CustomerCartItem.fromJson(Map<String, dynamic> json) => CustomerCartItem(
    menuItemId: json['menuItemId']?.toString() ?? json['menu_item_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    isVeg: json['isVeg'] ?? json['is_veg'] ?? true,
    imageUrl: json['imageUrl'] ?? json['image_url'],
    category: json['category']?.toString() ?? 'Main Course',
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    cookingInstructions: json['cookingInstructions']?.toString() ?? '',
  );
}

class DeliveryRiderModel {
  final String id;
  final String name;
  final String phone;
  final String vehicleNo;
  final double rating;
  final int deliveriesCompleted;
  final bool isAvailable;
  final String photoUrl;

  const DeliveryRiderModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleNo,
    this.rating = 4.9,
    this.deliveriesCompleted = 840,
    this.isAvailable = true,
    this.photoUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
  });

  factory DeliveryRiderModel.fromJson(Map<String, dynamic> json) => DeliveryRiderModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Rider',
    phone: json['phone'] as String? ?? '',
    vehicleNo: json['vehicle_no'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
    deliveriesCompleted: (json['deliveries_completed'] as num?)?.toInt() ?? 0,
    isAvailable: json['is_available'] as bool? ?? true,
    photoUrl: json['photo_url'] as String? ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'vehicle_no': vehicleNo,
    'rating': rating,
    'deliveries_completed': deliveriesCompleted,
    'is_available': isAvailable,
    'photo_url': photoUrl,
  };

  DeliveryRiderModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? vehicleNo,
    double? rating,
    int? deliveriesCompleted,
    bool? isAvailable,
    String? photoUrl,
  }) {
    return DeliveryRiderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      rating: rating ?? this.rating,
      deliveriesCompleted: deliveriesCompleted ?? this.deliveriesCompleted,
      isAvailable: isAvailable ?? this.isAvailable,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class CustomerFoodOrderModel {
  final String id; // e.g. "ORD-HP-9204"
  final String branchId;
  final String branchName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final CustomerAddressModel deliveryAddress;
  final List<CustomerCartItem> items;
  final double itemTotal;
  final double gstAmount; // 5% GST
  final double deliveryFee;
  final double packagingCharge;
  final double discountAmount;
  final String? couponCodeApplied;
  final double grandTotal;
  final OnlinePaymentMethod paymentMethod;
  final OnlinePaymentStatus paymentStatus;
  final String transactionId;
  final CustomerOrderStatus orderStatus;
  final String? riderName;
  final String? riderPhone;
  final String? riderVehicleNo;
  final double? riderRating;
  final String? riderPhotoUrl;
  final double? currentRiderLat;
  final double? currentRiderLng;
  final int estimatedDeliveryMinutes;
  final DateTime createdAt;

  final String channel; // e.g. 'Direct App', 'Zomato', 'Swiggy', 'Magicpin', 'ONDC', 'UrbanPiper'
  final String? aggregatorOrderId; // e.g. 'ZOM-882104'
  final double commissionAmount; // Platform commission deducted
  final String? otp; // Delivery / Handover OTP
  final String? specialInstructions; // Customer / aggregator cooking notes

  const CustomerFoodOrderModel({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.itemTotal,
    required this.gstAmount,
    required this.deliveryFee,
    required this.packagingCharge,
    this.discountAmount = 0.0,
    this.couponCodeApplied,
    required this.grandTotal,
    required this.paymentMethod,
    this.paymentStatus = OnlinePaymentStatus.success,
    required this.transactionId,
    this.orderStatus = CustomerOrderStatus.placed,
    this.riderName = 'Ramesh Patel',
    this.riderPhone = '+91 98201 54321',
    this.riderVehicleNo = 'MH 02 CZ 4421',
    this.riderRating = 4.9,
    this.riderPhotoUrl,
    this.currentRiderLat,
    this.currentRiderLng,
    this.estimatedDeliveryMinutes = 32,
    this.channel = 'Direct App',
    this.aggregatorOrderId,
    this.commissionAmount = 0.0,
    this.otp,
    this.specialInstructions,
    required this.createdAt,
  });

  /// Net amount receivable to the hotel after aggregator platform commission
  double get netPayout => (grandTotal - commissionAmount).clamp(0.0, double.infinity);

  CustomerFoodOrderModel copyWith({
    CustomerOrderStatus? orderStatus,
    OnlinePaymentStatus? paymentStatus,
    String? riderName,
    String? riderPhone,
    String? riderVehicleNo,
    double? riderRating,
    String? riderPhotoUrl,
    double? currentRiderLat,
    double? currentRiderLng,
    int? estimatedDeliveryMinutes,
    String? channel,
    String? aggregatorOrderId,
    double? commissionAmount,
    String? otp,
    String? specialInstructions,
  }) {
    return CustomerFoodOrderModel(
      id: id,
      branchId: branchId,
      branchName: branchName,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      items: items,
      itemTotal: itemTotal,
      gstAmount: gstAmount,
      deliveryFee: deliveryFee,
      packagingCharge: packagingCharge,
      discountAmount: discountAmount,
      couponCodeApplied: couponCodeApplied,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionId: transactionId,
      orderStatus: orderStatus ?? this.orderStatus,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      riderVehicleNo: riderVehicleNo ?? this.riderVehicleNo,
      riderRating: riderRating ?? this.riderRating,
      riderPhotoUrl: riderPhotoUrl ?? this.riderPhotoUrl,
      currentRiderLat: currentRiderLat ?? this.currentRiderLat,
      currentRiderLng: currentRiderLng ?? this.currentRiderLng,
      estimatedDeliveryMinutes: estimatedDeliveryMinutes ?? this.estimatedDeliveryMinutes,
      channel: channel ?? this.channel,
      aggregatorOrderId: aggregatorOrderId ?? this.aggregatorOrderId,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      otp: otp ?? this.otp,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt,
    );
  }

  factory CustomerFoodOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<CustomerCartItem> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems.map((i) => CustomerCartItem.fromJson(i as Map<String, dynamic>)).toList();
    }
    final rawAddress = json['delivery_address'];
    CustomerAddressModel addr = const CustomerAddressModel(
      id: 'addr-def',
      label: 'Home',
      fullAddress: 'Mumbai Hotel Vicinity',
    );
    if (rawAddress is Map<String, dynamic>) {
      addr = CustomerAddressModel.fromJson(rawAddress);
    }
    final statusStr = json['order_status'] as String? ?? 'placed';
    CustomerOrderStatus status = CustomerOrderStatus.placed;
    for (final s in CustomerOrderStatus.values) {
      if (s.name == statusStr) {
        status = s;
        break;
      }
    }
    return CustomerFoodOrderModel(
      id: json['id'] as String,
      branchId: json['branch_id'] as String? ?? '',
      branchName: json['branch_name'] as String? ?? 'HotelPro Grand',
      customerId: json['customer_id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? 'Customer',
      customerPhone: json['customer_phone'] as String? ?? '',
      deliveryAddress: addr,
      items: itemsList,
      itemTotal: (json['item_total'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (json['gst_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      packagingCharge: (json['packaging_charge'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      couponCodeApplied: json['coupon_code'] as String?,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: OnlinePaymentMethod.values.firstWhere(
        (m) => m.name == json['payment_method'],
        orElse: () => OnlinePaymentMethod.cashOnDelivery,
      ),
      paymentStatus: OnlinePaymentStatus.values.firstWhere(
        (s) => s.name == json['payment_status'],
        orElse: () => OnlinePaymentStatus.success,
      ),
      transactionId: json['transaction_id'] as String? ?? 'TXN-DIRECT',
      orderStatus: status,
      riderName: json['rider_name'] as String?,
      riderPhone: json['rider_phone'] as String?,
      riderVehicleNo: json['rider_vehicle_no'] as String?,
      channel: json['channel'] as String? ?? 'Direct App',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

