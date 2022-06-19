import 'dart:ffi';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tremote/bean/Server.dart';
import 'package:tremote/common/Utils.dart';
import 'package:tremote/enum/ServerType.dart';

class DBManager {
  static late Box<Server> serverBox;

  /// 初始化数据库
  static Future<void> init() async {
    var appDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(
        appDir.path + Separator() + "TRemote" + Separator() + "db");
    Hive.registerAdapter(ServerAdapter());
    Hive.registerAdapter(ServerTypeAdapter());
    serverBox = await Hive.openBox<Server>('server');
  }
}
