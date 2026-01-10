import 'package:sensors_plus/sensors_plus.dart';

class SensorsUtil {
  static void registerAccelerometerEvent([Function(AccelerometerEvent event)? fn]) {
    // [AccelerometerEvent (x: 0.0, y: 9.8, z: 0.0)]
    accelerometerEvents.listen(fn);
  }

  static void registerUserAccelerometerEvent(
      [Function(UserAccelerometerEvent event)? fn]) {
    // [UserAccelerometerEvent (x: 0.0, y: 0.0, z: 0.0)]
    userAccelerometerEvents.listen(fn);
  }

  static void registerGyroscopeEvent([Function(GyroscopeEvent event)? fn]) {
    // [GyroscopeEvent (x: 0.0, y: 0.0, z: 0.0)]
    gyroscopeEvents.listen(fn);
  }
}
