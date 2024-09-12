import 'package:uuid/uuid.dart';

class Uid {
  static final Uid _instance = Uid._internal();

  factory Uid() => _instance;
  static Uid get instance => _instance;

  Uuid uuid = const Uuid();

  Uid._internal();

  String get v1 => uuid.v1();

  String get v4 => uuid.v4();
}