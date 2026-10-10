import '../../config/app_constants.dart';

class RoomTypeModel {
  final String id;
  final String branchId;
  final String name; // e.g. Executive Deluxe, Royal Suite, Presidential Suite
  final String code; // DLX, STE, PRS
  final double basePrice;
  final int maxAdults;
  final int maxChildren;
  final String bedType; // King, Twin, Double
  final List<String> amenities;
  final String? description;

  const RoomTypeModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.code,
    required this.basePrice,
    required this.maxAdults,
    required this.maxChildren,
    required this.bedType,
    required this.amenities,
    this.description,
  });

  RoomTypeModel copyWith({
    String? name,
    double? basePrice,
    String? bedType,
    int? maxAdults,
    String? description,
  }) {
    return RoomTypeModel(
      id: id,
      branchId: branchId,
      name: name ?? this.name,
      code: code,
      basePrice: basePrice ?? this.basePrice,
      maxAdults: maxAdults ?? this.maxAdults,
      maxChildren: maxChildren,
      bedType: bedType ?? this.bedType,
      amenities: amenities,
      description: description ?? this.description,
    );
  }

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) => RoomTypeModel(
    id: json['id'] as String,
    branchId: json['branch_id'] as String? ?? '',
    name: json['name'] as String,
    code: json['code'] as String,
    basePrice: (json['base_price'] as num).toDouble(),
    maxAdults: (json['max_adults'] as num?)?.toInt() ?? 2,
    maxChildren: (json['max_children'] as num?)?.toInt() ?? 1,
    bedType: json['bed_type'] as String? ?? 'King Size Plush Bed',
    amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
    description: json['description'] as String?,
  );
}

class RoomModel {
  final String id;
  final String branchId;
  final String roomTypeId;
  final String roomNumber;
  final int floorNumber;
  final RoomStatus status;
  final String? keycardRfid;
  final String? notes;
  final String roomTypeName;
  final double basePrice;
  final String bedType;
  final int maxOccupancy;
  final List<String> amenities;
  final String? currentGuestName;
  final String? currentReservationId;
  final VipTier? currentGuestVip;

  const RoomModel({
    required this.id,
    required this.branchId,
    required this.roomTypeId,
    required this.roomNumber,
    required this.floorNumber,
    required this.status,
    this.keycardRfid,
    this.notes,
    required this.roomTypeName,
    required this.basePrice,
    this.bedType = 'King Size',
    this.maxOccupancy = 2,
    this.amenities = const [],
    this.currentGuestName,
    this.currentReservationId,
    this.currentGuestVip,
  });

  bool get isOccupied => status == RoomStatus.occupied;

  RoomModel copyWith({
    RoomStatus? status,
    String? roomNumber,
    double? basePrice,
    String? bedType,
    int? maxOccupancy,
    String? currentGuestName,
    String? currentReservationId,
    VipTier? currentGuestVip,
    String? notes,
    String? keycardRfid,
    bool clearGuest = false,
  }) {
    return RoomModel(
      id: id,
      branchId: branchId,
      roomTypeId: roomTypeId,
      roomNumber: roomNumber ?? this.roomNumber,
      floorNumber: floorNumber,
      status: status ?? this.status,
      keycardRfid: keycardRfid ?? this.keycardRfid,
      notes: notes ?? this.notes,
      roomTypeName: roomTypeName,
      basePrice: basePrice ?? this.basePrice,
      bedType: bedType ?? this.bedType,
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      amenities: amenities,
      currentGuestName: clearGuest ? null : (currentGuestName ?? this.currentGuestName),
      currentReservationId: clearGuest ? null : (currentReservationId ?? this.currentReservationId),
      currentGuestVip: clearGuest ? null : (currentGuestVip ?? this.currentGuestVip),
    );
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
    id: json['id'] as String,
    branchId: json['branch_id'] as String? ?? '',
    roomTypeId: json['room_type_id'] as String? ?? '',
    roomNumber: json['room_number'] as String,
    floorNumber: (json['floor_number'] as num?)?.toInt() ?? 1,
    status: RoomStatus.fromCode(json['status'] as String? ?? 'available_clean'),
    keycardRfid: json['keycard_rfid'] as String?,
    notes: json['notes'] as String?,
    roomTypeName: json['room_type_name'] as String? ?? 'Deluxe Room',
    basePrice: (json['base_price'] as num?)?.toDouble() ?? 4500.0,
    currentGuestName: json['current_guest_name'] as String?,
    currentReservationId: json['current_reservation_id'] as String?,
    currentGuestVip: json['current_guest_vip'] != null
        ? VipTier.fromCode(json['current_guest_vip'] as String)
        : null,
  );
}
