import 'package:flutter_test/flutter_test.dart';
import 'package:hotelpro/config/app_constants.dart';
import 'package:hotelpro/data/repositories/hotel_repository.dart';

void main() {
  group('HotelPro Enterprise PMS & ERP Core Engine Tests', () {
    late HotelRepository repo;

    setUp(() {
      repo = HotelRepository();
    });

    test('1. Multi-Branch Initialization & Branch Switching', () {
      expect(repo.branches.length, greaterThanOrEqualTo(3));
      expect(repo.activeBranch.starRating, equals(5));
      expect(repo.activeBranch.city, equals('Mumbai'));

      // Switch to Goa Branch
      final goaBranch = repo.branches.firstWhere((b) => b.city == 'Candolim');
      repo.switchBranch(goaBranch.id);
      expect(repo.activeBranch.code, equals('ABR-GOA'));

      // Switch back to Mumbai
      final mumBranch = repo.branches.firstWhere((b) => b.code == 'GIP-MUM');
      repo.switchBranch(mumBranch.id);
      expect(repo.activeBranch.code, equals('GIP-MUM'));
    });

    test('2. Express Check-In Workflow & Master Folio Generation', () {
      // Find an available clean room in Mumbai
      final availableRoom = repo.activeBranchRooms.firstWhere(
        (r) => r.status == RoomStatus.availableClean || r.status == RoomStatus.cleanInspected,
      );

      final initialFolioCount = repo.activeBranchFolios.length;

      // Execute check-in
      repo.checkInGuest(
        roomId: availableRoom.id,
        guestName: 'Anil Ambani',
        guestPhone: '+91 98200 99881',
        vipTier: VipTier.platinum,
        roomTypeName: availableRoom.roomTypeName,
        ratePerNight: availableRoom.basePrice,
        numberOfNights: 2,
        advancePayment: 10000.0,
        advanceMethod: PaymentMethod.creditCard,
      );

      // Verify room is now occupied
      final updatedRoom = repo.activeBranchRooms.firstWhere((r) => r.id == availableRoom.id);
      expect(updatedRoom.status, equals(RoomStatus.occupied));
      expect(updatedRoom.currentGuestName, equals('Anil Ambani'));
      expect(updatedRoom.currentGuestVip, equals(VipTier.platinum));

      // Verify master folio was created
      expect(repo.activeBranchFolios.length, equals(initialFolioCount + 1));
      final newFolio = repo.activeBranchFolios.firstWhere((f) => f.roomNumber == availableRoom.roomNumber);
      expect(newFolio.guestName, equals('Anil Ambani'));
      expect(newFolio.status, equals('open'));
      expect(newFolio.totalPaid, equals(10000.0));
      expect(newFolio.balanceDue, greaterThan(0.0));
    });

    test('3. Restaurant POS Charge-To-Room Folio Posting', () {
      // Post a restaurant dining charge to Room 101
      final success = repo.postChargeToRoomFolio(
        roomNumber: '101',
        category: FolioCategory.restaurant,
        description: 'The Royal Bistro - Dinner (Table 12)',
        amount: 3200.0,
        taxAmount: 160.0, // 5% GST
        referenceId: 'KOT-TEST-01',
      );

      expect(success, isTrue);

      final folio101 = repo.activeBranchFolios.firstWhere((f) => f.roomNumber == '101');
      final txn = folio101.transactions.last;
      expect(txn.category, equals(FolioCategory.restaurant));
      expect(txn.amount, equals(3200.0));
      expect(txn.taxAmount, equals(160.0));
    });

    test('4. Express Check-Out Workflow & Turnover Task Assignment', () {
      // Settle and checkout Room 101
      repo.checkOutGuest(
        roomId: 'rm-101',
        settlementMethod: PaymentMethod.creditCard,
      );

      final room101 = repo.activeBranchRooms.firstWhere((r) => r.id == 'rm-101');
      expect(room101.status, equals(RoomStatus.dirtyVacant));
      expect(room101.currentGuestName, isNull);

      // Verify a deep cleaning task was created in housekeeping
      final latestTask = repo.activeBranchHousekeeping.first;
      expect(latestTask.roomNumber, equals('101'));
      expect(latestTask.status, equals('pending'));
      expect(latestTask.priority, equals(HousekeepingPriority.urgentRush));
    });

    test('5. Housekeeping Lifecycle Progression', () {
      final initialPending = repo.activeBranchHousekeeping.firstWhere((t) => t.status == 'pending');

      // Start cleaning
      repo.progressHousekeepingTask(initialPending.id, 'in_progress');
      final inProgressTask = repo.activeBranchHousekeeping.firstWhere((t) => t.id == initialPending.id);
      expect(inProgressTask.status, equals('in_progress'));

      // Mark cleaned
      repo.progressHousekeepingTask(initialPending.id, 'cleaned');
      final cleanedTask = repo.activeBranchHousekeeping.firstWhere((t) => t.id == initialPending.id);
      expect(cleanedTask.status, equals('cleaned'));

      // 5-Star Supervisor Approval
      repo.progressHousekeepingTask(initialPending.id, 'inspected_approved', notes: 'VIP Inspected');
      final approvedTask = repo.activeBranchHousekeeping.firstWhere((t) => t.id == initialPending.id);
      expect(approvedTask.status, equals('inspected_approved'));
    });

    test('6. Executive Metrics: Occupancy, ADR & RevPAR Calculations', () {
      expect(repo.occupancyRate, greaterThan(0.0));
      expect(repo.averageDailyRate, greaterThan(0.0));
      expect(repo.revenuePerAvailableRoom, greaterThan(0.0));
    });
  });
}
