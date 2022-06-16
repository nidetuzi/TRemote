// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:hive/hive.dart';

import 'package:tremote/enum/ServerType.dart';

part 'Server.g.dart';

@HiveType(typeId: 1)
class Server {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late ServerType type;

  @HiveField(3)
  late String ip;

  @HiveField(4)
  late int port;

  @HiveField(5)
  late String username;

  @HiveField(6)
  late String password;

  Server(this.id, this.name, this.type, this.ip, this.port, this.username,
      this.password);


  Server copyWith({
    String? id,
    String? name,
    ServerType? type,
    String? ip,
    int? port,
    String? username,
    String? password,
  }) {
    return Server(
      id ?? this.id,
      name ?? this.name,
      type ?? this.type,
      ip ?? this.ip,
      port ?? this.port,
      username ?? this.username,
      password ?? this.password,
    );
  }
}
