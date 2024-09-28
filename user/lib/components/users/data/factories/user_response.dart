import 'package:dragonfly_annotations/dragonfly_annotations.dart';
import 'package:user/components/users/contracts/user.dart';
import 'package:user/components/users/contracts/user_device.dart';

mixin _UserFactory implements Users {
  @override
  bool get active => throw UnimplementedError();

  @override
  int get age => throw UnimplementedError();

  @override
  DateTime get creation => throw UnimplementedError();

  @override
  List<UserDevice> get devices => throw UnimplementedError();

  @override
  String get lastname => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();

  @override
  int get userId => throw UnimplementedError();
}

@FactoryModel()
class UserResponse with _UserFactory implements Users {
  const UserResponse(
      {@Field(value: 0, field: "user_id") required int userId,
      @Field(value: "julian") required String name,
      @Field(value: "never seen") required String lastname,
      @Field(value: 30) required int age,
      @Field(value: false) required bool active,
      @Field(value: DateTime.new) required DateTime creation,
      @Field(value: []) required List<UserDevice> devices});
}
