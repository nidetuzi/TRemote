import 'dart:async';

import 'package:dartssh2/dartssh2.dart';
import 'package:tremote/bean/Server.dart';
import 'package:tremote/common/Log.dart';

class ConnectManager {
  ConnectManager._privateConstructor();

  static final ConnectManager _instance = ConnectManager._privateConstructor();

  factory ConnectManager() {
    return _instance;
  }

  Map<String, SSHClient> list = <String, SSHClient>{};

  /// 初始化心跳
  initTimer() async {
    // loggerNoStack.i("初始化定时器");
    // const timeout = Duration(seconds: 60);
    // Timer.periodic(timeout, (timer) {
    //   loggerNoStack.d("发送心跳信息 服务器数量:" + list.length.toString());
    //   list.forEach((key, value) {
    //     if (!value.isClosed) {
    //       //未关闭 则发送
    //       value.run("");
    //     }
    //   });
    // });
  }

  /// 获取ssh客户端
  Future<SSHClient?> getSSHClient(Server server) async {
    var ssh = SSHClient(
      await SSHSocket.connect(server.ip, server.port),
      username: server.username,
      onPasswordRequest: () => server.password,
    );
    await ssh.authenticated;
    return ssh;
  }

  /// 移除ssh客户端
  removeSSHClient(Server server) {
    //如果已存在就直接返回
    list.remove(server.ip);
  }
}
