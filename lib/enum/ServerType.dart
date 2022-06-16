import 'package:hive_flutter/hive_flutter.dart';

part 'ServerType.g.dart';

@HiveType(typeId: 2)
enum ServerType {
  @HiveField(0)
  Linux,
  @HiveField(1)
  Windows
}

String getServerTypeName(ServerType type) {
  switch (type) {
    case ServerType.Linux:
      return "Linux";
    case ServerType.Windows:
      return "Windows";
  }
}

ServerType getServerTypeByName(String type) {
  switch (type) {
    case "Linux":
      return ServerType.Linux;
    case "Windows":
      return ServerType.Windows;
  }
  return ServerType.Linux;
}
