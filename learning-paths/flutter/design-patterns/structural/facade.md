# Definition

Abstract away a large number of subsystems, each with its own simple or complicated interfaces by unifying them under one common, usually simpler interface.

# Example code

```dart
class SecuritySystem {
  void enable() => print("SecuritySystem enabled");
  void disable() => print("SecuritySystem disabled");
}

class Intercom {
  void on()  => print("Intercom ready");
  void off() => print("Intercom standing by");
}

class WindowShades {
  void open() => print("WindowShades open");
  void close() => print("WindowShades closed");
}

class Lights {
  void on() => print("Lights on");
  void off() => print("Lights off");
}

// This is façade class that facilitates access to the subsystem features
class SmartHome {
  SecuritySystem _securitySystem = SecuritySystem();
  Intercom _intercom = Intercom();
  WindowShades _windowShades = WindowShades();
  Lights _lights = Lights();

  void home() {
    _securitySystem.disable();
    _intercom.on();
    _windowShades.open();
    _lights.on();
  }

  void out() {
    _securitySystem.enable();
    _intercom.off();
    _windowShades.close();
    _lights.off();
  }
}
```
