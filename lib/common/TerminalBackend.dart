import 'dart:async';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:tremote/bean/Server.dart';
import 'package:tremote/common/Log.dart';
import 'package:tremote/manager/ConnectManager.dart';
import 'package:xterm/xterm.dart';
import 'dart:convert';
import 'dart:typed_data';

class MyTerminalBackend extends TerminalBackend {
  final _exitCodeCompleter = Completer<int>();
  // ignore: close_sinks
  final _outStream = StreamController<String>();

  Server server;

  late SSHClient ssh;
  late SSHSession shell;

  var isInit = false;

  var width = 0;
  var height = 0;

  Timer? timer;

  void onWrite(String data) {
    _outStream.sink.add(data);
  }

  MyTerminalBackend(this.server);

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  Future<void> init() async {
    // Use utf8.decoder to handle broken utf8 chunks
    final _sshOutput = StreamController<List<int>>();
    _sshOutput.stream.transform(utf8.decoder).listen(onWrite);

    final _errorOutput = StreamController<List<int>>();
    _errorOutput.stream.transform(utf8.decoder).listen(onWrite);

    onWrite('connecting ' + server.ip + "... \r\n");
    try {
      ssh = (await ConnectManager().getSSHClient(server))!;
      timer = Timer.periodic(const Duration(seconds: 60), (timer) {
        loggerNoStack.d("发送心跳信息");
        ssh.run("");
      });
      shell = await ssh.shell(pty: SSHPtyConfig(width: width, height: height));
      _sshOutput.addStream(shell.stdout); // listening for stdout
      //_errorOutput.addStream(shell.stderr); // listening for stdout
      isInit = true;
    } on SSHAuthError catch (ex) {
      onWrite(ex.message + "\r\n");
    }
  }

  @override
  Stream<String> get out => _outStream.stream;

  //尺寸发生变化
  @override
  void resize(int width, int height, int pixelWidth, int pixelHeight) {
    this.width = width;
    this.height = height;
    if (isInit) {
      Logger().d("终端尺寸发生变更");
      shell.resizeTerminal(this.width, this.height);
    }
  }

  //输入数据
  @override
  void write(String input) {
    if (isInit) {
      try {
        shell.write(Uint8List.fromList(utf8.encode(input)));
      } on SSHMessageError catch (ex) {
        isInit = false;
        onWrite(ex.message + "\r\n");
      }
    }
  }

  @override
  void terminate() {
    shell.close();
    ssh.close();
    timer!.cancel();
  }

  @override
  void ackProcessed() {
    //NOOP
  }
}
