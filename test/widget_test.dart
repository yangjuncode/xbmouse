import 'package:flutter_test/flutter_test.dart';

import 'package:xbmouse/models/config_model.dart';

void main() {
  test('defaults rb mapping to Ctrl+W', () {
    expect(ButtonMappings().rb, 'Control_L+w');
  });

  test('uses Ctrl+W fallback when rb is absent from config', () {
    final mappings = ButtonMappings.fromMaps(buttons: {});
    expect(mappings.rb, 'Control_L+w');
  });
}
