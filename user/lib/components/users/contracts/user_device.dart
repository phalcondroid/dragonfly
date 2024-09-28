import 'package:user/components/users/contracts/enums/device_operative_system.dart';

abstract interface class UserDevice {
  String get deviceId;
  DeviceOperativeSystem get deviceOp;
  String get modelName;
  String get brand;
}
