// =====================================================================
// HOTELPRO ERP & PMS CONSTANTS & ENUMS
// =====================================================================

enum ChainTier {
  threeStar('3-Star Business', '3_star_chain'),
  fourStar('4-Star Premium', '4_star_chain'),
  fiveStarLuxury('5-Star Luxury Palace', '5_star_luxury');

  final String label;
  final String code;
  const ChainTier(this.label, this.code);
}

enum RoomStatus {
  availableClean('Available & Clean', 'available_clean'),
  cleanInspected('Inspected (VIP Ready)', 'clean_inspected'),
  occupied('Occupied', 'occupied'),
  dirtyVacant('Dirty (Vacated)', 'dirty_vacant'),
  cleaningInProgress('Cleaning in Progress', 'cleaning_in_progress'),
  outOfOrder('Out of Order (OOO)', 'out_of_order'),
  reserved('Reserved (Due In)', 'reserved');

  final String label;
  final String code;
  const RoomStatus(this.label, this.code);

  static RoomStatus fromCode(String code) {
    return RoomStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => RoomStatus.availableClean,
    );
  }
}

enum VipTier {
  regular('Regular Guest', 'regular'),
  silver('Silver Club', 'silver'),
  gold('Gold Privilege', 'gold'),
  platinum('Platinum Elite', 'platinum'),
  royalClub('Royal 5-Star Ambassador', 'royal_club');

  final String label;
  final String code;
  const VipTier(this.label, this.code);

  static VipTier fromCode(String code) {
    return VipTier.values.firstWhere(
      (e) => e.code == code,
      orElse: () => VipTier.regular,
    );
  }
}

enum ReservationStatus {
  confirmed('Confirmed', 'confirmed'),
  checkedIn('Checked In', 'checked_in'),
  checkedOut('Checked Out', 'checked_out'),
  cancelled('Cancelled', 'cancelled'),
  noShow('No Show', 'no_show');

  final String label;
  final String code;
  const ReservationStatus(this.label, this.code);

  static ReservationStatus fromCode(String code) {
    return ReservationStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ReservationStatus.confirmed,
    );
  }
}

enum FolioCategory {
  roomCharge('Room Tariff', 'room_charge'),
  tax('GST / VAT', 'tax'),
  restaurant('Restaurant F&B', 'restaurant'),
  bar('Bar & Lounge', 'bar'),
  spa('Spa & Wellness', 'spa'),
  laundry('Laundry Express', 'laundry'),
  minibar('Mini Bar', 'minibar'),
  roomService('In-Room Dining', 'room_service'),
  banquet('Banquet / Event', 'banquet'),
  payment('Payment Settled', 'payment'),
  discount('Management Discount', 'discount');

  final String label;
  final String code;
  const FolioCategory(this.label, this.code);

  static FolioCategory fromCode(String code) {
    return FolioCategory.values.firstWhere(
      (e) => e.code == code,
      orElse: () => FolioCategory.roomCharge,
    );
  }
}

enum PaymentMethod {
  cash('Cash', 'cash'),
  creditCard('Credit Card', 'credit_card'),
  upi('UPI / QR Code', 'upi'),
  bankTransfer('Bank Transfer', 'bank_transfer'),
  billToCompany('Bill to Corporate (BTC)', 'bill_to_company'),
  roomCredit('Charge to Room', 'room_credit');

  final String label;
  final String code;
  const PaymentMethod(this.label, this.code);
}

enum PosOrderStatus {
  kotPrinted('KOT Printed', 'kot_printed'),
  inKitchen('Cooking in Kitchen', 'in_kitchen'),
  served('Served to Table/Room', 'served'),
  settled('Billed & Settled', 'settled'),
  cancelled('Cancelled', 'cancelled');

  final String label;
  final String code;
  const PosOrderStatus(this.label, this.code);
}

enum HousekeepingPriority {
  urgentRush('Rush (Guest Waiting)', 'urgent_rush'),
  high('High Priority', 'high'),
  normal('Standard', 'normal'),
  low('Low', 'low');

  final String label;
  final String code;
  const HousekeepingPriority(this.label, this.code);

  static HousekeepingPriority fromCode(String code) {
    return HousekeepingPriority.values.firstWhere(
      (e) => e.code == code || e.name == code,
      orElse: () => HousekeepingPriority.normal,
    );
  }
}
