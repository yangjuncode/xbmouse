import 'dart:async';

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

  test(
    'refresh resets connection and inputs when the device disappears',
    () async {
      var gamepads = [
        const GamepadDeviceSnapshot(
          id: 'test-gamepad',
          name: 'Xbox Controller',
        ),
      ];
      final service = GamepadService(
        listGamepads: () async => gamepads,
        normalizedEvents: () => const Stream<NormalizedGamepadEvent>.empty(),
      );

      expect(await service.refreshConnectedGamepads(), isTrue);
      service.handleNormalizedEvent(axisEvent(GamepadAxis.rightStickX, 0.75));
      service.handleNormalizedEvent(buttonEvent(GamepadButton.a, 1.0));

      gamepads = [];
      expect(await service.refreshConnectedGamepads(), isTrue);

      expect(service.isConnected, isFalse);
      expect(service.state.gamepadInfo, isNull);
      expect(service.state.rightStickX, 0.0);
      expect(service.state.buttonA, isFalse);
    },
  );

  test('refresh treats only virtual devices as disconnected', () async {
    var gamepads = [
      const GamepadDeviceSnapshot(id: 'test-gamepad', name: 'Xbox Controller'),
    ];
    final service = GamepadService(
      listGamepads: () async => gamepads,
      normalizedEvents: () => const Stream<NormalizedGamepadEvent>.empty(),
    );

    expect(await service.refreshConnectedGamepads(), isTrue);

    gamepads = [
      const GamepadDeviceSnapshot(
        id: '1234:5678',
        name: 'XBMouse Virtual Mouse',
      ),
    ];
    expect(await service.refreshConnectedGamepads(), isTrue);

    expect(service.isConnected, isFalse);
    expect(service.state.gamepadInfo, isNull);
  });

  test(
    'startListening keeps refreshing after a gamepad is connected',
    () async {
      var refreshCount = 0;
      final disconnected = Completer<void>();
      late final GamepadService service;
      service = GamepadService(
        listGamepads: () async {
          refreshCount++;
          if (refreshCount == 1) {
            return [
              const GamepadDeviceSnapshot(
                id: 'test-gamepad',
                name: 'Xbox Controller',
              ),
            ];
          }
          return [];
        },
        normalizedEvents: () => const Stream<NormalizedGamepadEvent>.empty(),
        connectedRefreshInterval: const Duration(milliseconds: 1),
      );
      addTearDown(service.dispose);
      service.addListener(() {
        if (refreshCount > 1 &&
            !service.isConnected &&
            !disconnected.isCompleted) {
          disconnected.complete();
        }
      });

      await service.startListening();
      expect(service.isConnected, isTrue);

      await disconnected.future.timeout(const Duration(seconds: 1));
      expect(service.isConnected, isFalse);
    },
  );

  test(
    'startListening uses separate disconnected and connected refresh intervals',
    () async {
      var refreshCount = 0;
      final connected = Completer<void>();
      var gamepads = <GamepadDeviceSnapshot>[];
      late final GamepadService service;
      service = GamepadService(
        listGamepads: () async {
          refreshCount++;
          if (refreshCount == 2) {
            gamepads = [
              const GamepadDeviceSnapshot(
                id: 'test-gamepad',
                name: 'Xbox Controller',
              ),
            ];
          }
          return gamepads;
        },
        normalizedEvents: () => const Stream<NormalizedGamepadEvent>.empty(),
        disconnectedRefreshInterval: const Duration(milliseconds: 1),
        connectedRefreshInterval: const Duration(seconds: 1),
      );
      addTearDown(service.dispose);
      service.addListener(() {
        if (service.isConnected && !connected.isCompleted) {
          connected.complete();
        }
      });

      await service.startListening();
      expect(service.isConnected, isFalse);

      await connected.future.timeout(const Duration(seconds: 1));
      final countAfterConnected = refreshCount;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(service.isConnected, isTrue);
      expect(refreshCount, countAfterConnected);
    },
  );
}
