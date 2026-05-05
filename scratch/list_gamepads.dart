import 'package:gamepads/gamepads.dart';

void main() async {
  print('Listing gamepads...');
  try {
    final gamepads = await Gamepads.list();
    print('Found ${gamepads.length} gamepads:');
    for (var g in gamepads) {
      print(' - ${g.id}: ${g.name}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
