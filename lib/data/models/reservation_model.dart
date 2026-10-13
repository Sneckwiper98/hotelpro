import '../../config/app_constants.dart';

class ReservationModel {
  final String id;
  final String bookingReference; // e.g. "RES-MUM-4029"
  final String branchId;
  final String guestId;
  final String? roomId;
  final String roomTypeId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final DateTime? actualCheckIn;
  final DateTime? actualCheckOut;
  final ReservationStatus bookingStatus;
  final String bookingSource; // Walk-in, Direct Web, Booking.com, Corporate
  final double ratePerNight;
  final double advancePaid;
  final String specialNotes;

  // Enriched display fields
  final String guestName;
  final String guestPhone;
  final VipTier guestVipTier;
  final String roomNumber;
  final String roomTypeName;

  const ReservationModel({
    required this.id,
    required this.bookingReference,
    required this.branchId,
    required this.guestId,
    this.roomId,
    required this.roomTypeId,
    required this.checkInDate,
    required this.checkOutDate,
    this.actualCheckIn,
    this.actualCheckOut,
    this.bookingStatus = ReservationStatus.confirmed,
    this.bookingSource = 'Direct Walk-In',
    required this.ratePerNight,
    this.advancePaid = 0.0,
    this.specialNotes = '',
    required this.guestName,
    required this.guestPhone,
    this.guestVipTier = VipTier.regular,
    required this.roomNumber,
    required this.roomTypeName,
  });

  int get numberOfNights {
    final diff = checkOutDate.difference(checkInDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get totalRoomTariff => ratePerNight * numberOfNights;

  ReservationModel copyWith({
    ReservationStatus? bookingStatus,
    DateTime? actualCheckIn,
    DateTime? actualCheckOut,
    String? roomId,
    String? roomNumber,
  }) {
    return ReservationModel(
      id: id,
      bookingReference: bookingReference,
      branchId: branchId,
      guestId: guestId,
      roomId: roomId ?? this.roomId,
      roomTypeId: roomTypeId,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      actualCheckIn: actualCheckIn ?? this.actualCheckIn,
      actualCheckOut: actualCheckOut ?? this.actualCheckOut,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      bookingSource: bookingSource,
      ratePerNight: ratePerNight,
      advancePaid: advancePaid,
      specialNotes: specialNotes,
      guestName: guestName,
      guestPhone: guestPhone,
      guestVipTier: guestVipTier,
      roomNumber: roomNumber ?? this.roomNumber,
      roomTypeName: roomTypeName,
    );
  }

  factory ReservationModel.fromJson(Map<String, dynamic> json) => ReservationModel(
    id: json['id'] as String,
    bookingReference: json['booking_reference'] as String? ?? 'RES-001',
    branchId: json['branch_id'] as String? ?? '',
    guestId: json['guest_id'] as String? ?? '',
    roomId: json['room_id'] as String?,
    roomTypeId: json['room_type_id'] as String? ?? '',
    checkInDate: json['check_in_date'] != null
        ? DateTime.tryParse(json['check_in_date'].toString()) ?? DateTime.now()
        : DateTime.now(),
    checkOutDate: json['check_out_date'] != null
        ? DateTime.tryParse(json['check_out_date'].toString()) ?? DateTime.now().add(const Duration(days: 1))
        : DateTime.now().add(const Duration(days: 1)),
    bookingStatus: ReservationStatus.fromCode(json['booking_status'] as String? ?? 'confirmed'),
    bookingSource: json['booking_source'] as String? ?? 'Direct Walk-In',
    ratePerNight: (json['rate_per_night'] as num?)?.toDouble() ?? 5000.0,
    advancePaid: (json['advance_paid'] as num?)?.toDouble() ?? 0.0,
    specialNotes: json['special_notes'] as String? ?? '',
    guestName: json['guest_name'] as String? ?? 'Guest',
    guestPhone: json['guest_phone'] as String? ?? '',
    guestVipTier: VipTier.regular,
    roomNumber: json['room_number'] as String? ?? '',
    roomTypeName: json['room_type_name'] as String? ?? 'Deluxe Room',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'booking_reference': bookingReference,
    'branch_id': branchId,
    'guest_id': guestId,
    'room_id': roomId,
    'room_type_id': roomTypeId,
    'check_in_date': checkInDate.toIso8601String(),
    'check_out_date': checkOutDate.toIso8601String(),
    'actual_check_in': actualCheckIn?.toIso8601String(),
    'actual_check_out': actualCheckOut?.toIso8601String(),
    'booking_status': bookingStatus.code,
    'booking_source': bookingSource,
    'rate_per_night': ratePerNight,
    'advance_paid': advancePaid,
    'special_notes': specialNotes,
    'guest_name': guestName,
    'guest_phone': guestPhone,
    'room_number': roomNumber,
    'room_type_name': roomTypeName,
  };
}

