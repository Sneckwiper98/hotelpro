import 'dart:math' as math;

class HotelCoordinates {
  final double latitude;
  final double longitude;
  final String branchCode;
  final String branchName;

  const HotelCoordinates({
    required this.latitude,
    required this.longitude,
    required this.branchCode,
    required this.branchName,
  });
}

class GeofenceService {
  static const double maxDeliveryRadiusKm = 10.0;

  // Known Hotel Branch GPS Locations
  static const Map<String, HotelCoordinates> branchLocations = {
    'MUM-MAIN': HotelCoordinates(
      latitude: 19.0896,
      longitude: 72.8656,
      branchCode: 'MUM-MAIN',
      branchName: 'HotelPro Mumbai International Airport & Suites',
    ),
    'DEL-AERO': HotelCoordinates(
      latitude: 28.5562,
      longitude: 77.1000,
      branchCode: 'DEL-AERO',
      branchName: 'HotelPro Delhi Aerocity Worldmark',
    ),
    'BLR-TECH': HotelCoordinates(
      latitude: 12.9352,
      longitude: 77.6946,
      branchCode: 'BLR-TECH',
      branchName: 'HotelPro Bengaluru TechPark Resort',
    ),
    'GOA-BEACH': HotelCoordinates(
      latitude: 15.2993,
      longitude: 74.1240,
      branchCode: 'GOA-BEACH',
      branchName: 'HotelPro Goa Candolim Luxury Beach Villa',
    ),
  };

  /// Calculates the Great-Circle distance in kilometers between two GPS coordinates using Haversine formula
  static double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degToRad(endLat - startLat);
    final double dLng = _degToRad(endLng - startLng);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(startLat)) *
            math.cos(_degToRad(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadiusKm * c;

    // Return rounded to 1 decimal place
    return (distance * 10).round() / 10.0;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Checks if a customer's location is within the strict 10km delivery radius
  static bool isEligibleForDelivery({
    required String branchCode,
    required double customerLat,
    required double customerLng,
  }) {
    final hotel = branchLocations[branchCode] ?? branchLocations['MUM-MAIN']!;
    final distance = calculateDistanceKm(
      startLat: hotel.latitude,
      startLng: hotel.longitude,
      endLat: customerLat,
      endLng: customerLng,
    );
    return distance <= maxDeliveryRadiusKm;
  }

  /// Calculates delivery distance from a branch
  static double getDistanceForBranch({
    required String branchCode,
    required double customerLat,
    required double customerLng,
  }) {
    final hotel = branchLocations[branchCode] ?? branchLocations['MUM-MAIN']!;
    return calculateDistanceKm(
      startLat: hotel.latitude,
      startLng: hotel.longitude,
      endLat: customerLat,
      endLng: customerLng,
    );
  }

  /// Calculates delivery charge based on distance and order subtotal
  static double calculateDeliveryFee({
    required double distanceKm,
    required double subtotal,
  }) {
    if (subtotal >= 499.0) {
      return 0.0; // Free delivery for orders above Rs 499!
    }
    if (distanceKm <= 3.0) {
      return 30.0;
    } else if (distanceKm <= 6.0) {
      return 45.0;
    } else {
      return 60.0;
    }
  }

  /// Calculates estimated delivery duration in minutes (20 min prep + travel time)
  static int calculateEstimatedMinutes(double distanceKm) {
    const int prepTime = 20; // 20 mins in hotel kitchen
    final int travelTime = (distanceKm * 3.5).round(); // ~3.5 min per km in city
    return prepTime + travelTime;
  }

  /// Preset sample locations for user demo (addresses within & beyond 10km)
  static List<Map<String, dynamic>> getDemoDeliveryLocations(String branchCode) {
    if (branchCode == 'DEL-AERO') {
      return [
        {
          'label': 'Mahipalpur (Near Aerocity)',
          'address': 'Flat 402, Royal Enclave, Mahipalpur, New Delhi',
          'landmark': 'Opposite Metro Pillar 114',
          'lat': 28.5480,
          'lng': 77.1200,
          'expectedKm': 2.3,
        },
        {
          'label': 'Vasant Kunj (Pocket B)',
          'address': 'B-7/22, DDA Flats, Vasant Kunj, New Delhi',
          'landmark': 'Near Ambience Mall',
          'lat': 28.5310,
          'lng': 77.1420,
          'expectedKm': 5.1,
        },
        {
          'label': 'Noida Sector 62 (Beyond 10km)',
          'address': 'Tower 4, Green View Apartments, Sector 62, Noida',
          'landmark': 'Near Fortis Hospital',
          'lat': 28.6280,
          'lng': 77.3680,
          'expectedKm': 28.4,
        },
      ];
    }

    // Default Mumbai Locations
    return [
      {
        'label': 'Andheri East (Near Chakala Metro)',
        'address': 'Flat 604, Orchid Heights, Chakala, Andheri East, Mumbai',
        'landmark': 'Near JB Nagar Metro Station',
        'lat': 19.1136,
        'lng': 72.8697,
        'expectedKm': 2.8,
      },
      {
        'label': 'Vile Parle East (Near Airport Road)',
        'address': 'Plot 12, Navkar Niwas, Dixit Road, Vile Parle East, Mumbai',
        'landmark': 'Opposite Parle Tilak Vidyalaya',
        'lat': 19.0988,
        'lng': 72.8520,
        'expectedKm': 1.9,
      },
      {
        'label': 'Bandra Kurla Complex (BKC)',
        'address': 'Office 8B, Godrej BKC, G Block, BKC, Bandra East, Mumbai',
        'landmark': 'Near Asian Heart Institute',
        'lat': 19.0657,
        'lng': 72.8683,
        'expectedKm': 4.2,
      },
      {
        'label': 'Goregaon East (Oberoi Garden City)',
        'address': 'Flat 1401, Oberoi Exquisite, Off Western Express Highway, Goregaon East',
        'landmark': 'Behind Oberoi Mall',
        'lat': 19.1680,
        'lng': 72.8630,
        'expectedKm': 8.7,
      },
      {
        'label': 'Thane West (Outside 10km Limit)',
        'address': 'Tower A, Hiranandani Estate, Ghodbunder Road, Thane West',
        'landmark': 'Near The Walk High Street',
        'lat': 19.2550,
        'lng': 72.9800,
        'expectedKm': 23.5,
      },
      {
        'label': 'Colaba South Mumbai (Outside 10km Limit)',
        'address': 'Sea View Villa, Arthur Bunder Road, Colaba, Mumbai',
        'landmark': 'Near Taj Mahal Palace',
        'lat': 18.9220,
        'lng': 72.8340,
        'expectedKm': 21.0,
      },
    ];
  }
}
