import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:xbmouse/services/gamepad_service.dart';

void main() {
  GamepadEvent rawEvent({
    KeyType type = KeyType.analog,
    String key = '0',
    double value = 0.0,
  }) {
    return GamepadEvent(
      gamepadId: 'test-gamepad',
      timestamp: 0,
      type: type,
      key: key,
      value: value,
    );
  }

  NormalizedGamepadEvent axisEvent(GamepadAxis axis, double value) {
    return NormalizedGamepadEvent(
      gamepadId: 'test-gamepad',
      timestamp: 0,
      value: value,
      rawEvent: rawEvent(value: value),
      axis: axis,
    );
  }

  NormalizedGamepadEvent buttonEvent(GamepadButton button, double value) {
    return NormalizedGamepadEvent(
      gamepadId: 'test-gamepad',
      timestamp: 0,
      value: value,
      rawEvent: rawEvent(type: KeyType.button, value: value),
      button: button,
    );
  }

  test('keeps centered stick axes at zero', () {
    final service = GamepadService();

    service.handleNormalizedEvent(axisEvent(GamepadAxis.leftStickX, 0.0));
    service.handleNormalizedEvent(axisEvent(GamepadAxis.leftStickY, 0.0));
    service.handleNormalizedEvent(axisEvent(GamepadAxis.rightStickX, 0.0));
    service.handleNormalizedEvent(axisEvent(GamepadAxis.rightStickY, 0.0));

    expect(service.state.leftStickX, 0.0);
    expect(service.state.leftStickY, 0.0);
    expect(service.state.rightStickX, 0.0);
    expect(service.state.rightStickY, 0.0);
  });

  test('converts normalized stick y axis to screen movement direction', () {
    final service = GamepadService();

    service.handleNormalizedEvent(axisEvent(GamepadAxis.leftStickY, 1.0));
    service.handleNormalizedEvent(axisEvent(GamepadAxis.rightStickY, -1.0));

    expect(service.state.leftStickY, -1.0);
    expect(service.state.rightStickY, 1.0);
  });

  test('updates normalized buttons', () {
    final service = GamepadService();

    service.handleNormalizedEvent(buttonEvent(GamepadButton.a, 1.0));
    service.handleNormalizedEvent(buttonEvent(GamepadButton.dpadLeft, 1.0));
    service.handleNormalizedEvent(buttonEvent(GamepadButton.a, 0.0));

    expect(service.state.buttonA, isFalse);
    expect(service.state.dpadLeft, isTrue);
  });
}
