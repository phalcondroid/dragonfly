import 'package:user/components/users/contracts/user_device.dart';

abstract interface class Users {
  int get userId;
  String get name;
  String get lastname;
  int get age;
  bool get active;
  DateTime get creation;
  List<UserDevice> get devices;
}
