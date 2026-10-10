import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  // Read .env file directly
  final envMap = <String, String>{};
  final envFile = File('.env');
  if (envFile.existsSync()) {
    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split('=');
      if (parts.length >= 2) {
        envMap[parts[0].trim()] = parts.sublist(1).join('=').trim();
      }
    }
  }

  print('Connecting to Supabase online using .env credentials...');
  final url = envMap['SUPABASE_URL'] ?? 'https://koujqdqdzklurxvbhygf.supabase.co';
  final anonKey = envMap['SUPABASE_ANON_KEY'] ?? envMap['SUPABASE_ANNON_KEY'] ?? '';

  final client = SupabaseClient(url, anonKey);

  try {
    // 1. Check existing branches
    final branches = await client.from('branches').select();
    print('SUCCESS: Connected to online Supabase!');
    print('Found ${branches.length} branches in online database.');

    // 2. Perform test data entry (insert into pos_orders)
    final testOrderNumber = 'TEST-CONN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    print('\nTesting live Data Entry with orderNumber: $testOrderNumber ...');

    final insertRes = await client.from('pos_orders').insert({
      'outlet_id': 'outlet-mum-01',
      'order_number': testOrderNumber,
      'table_number': 'T-99',
      'waiter_name': 'Live Test Waiter',
      'guest_name': 'Supabase Verification Guest',
      'status': 'kot_printed',
      'items': [
        {
          'menuItemId': 'mi-1',
          'name': 'Dum Pukht Biryani',
          'price': 650.0,
          'quantity': 2,
          'notes': 'Online Supabase Connection Test'
        }
      ],
      'subtotal': 1300.0,
      'tax': 65.0,
      'total': 1365.0,
      'notes': 'Verified live entry directly to Supabase cloud'
    }).select();

    print('SUCCESS: Data entry created in Supabase online:');
    print(insertRes);

    // 3. Verify reading the inserted data back
    final verify = await client.from('pos_orders').select().eq('order_number', testOrderNumber);
    print('\nVerified reading back from Supabase online: ${verify.length} record(s) found.');
    print('Record details: ${verify.first['guest_name']} | Total: ₹${verify.first['total']}');

    // 4. Clean up test record
    await client.from('pos_orders').delete().eq('order_number', testOrderNumber);
    print('\nTest record cleaned up successfully.');
    print('ALL SUPABASE CHECKS PASSED 100%!');
  } catch (e, st) {
    print('ERROR connecting to Supabase: $e');
    print(st);
  }
}
