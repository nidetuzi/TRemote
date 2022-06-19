import 'dart:io';
import 'dart:isolate';

import 'package:dartssh2/dartssh2.dart';
import 'package:filesize/filesize.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:tremote/bean/IsolateBean.dart';
import 'package:tremote/bean/Server.dart';
import 'package:tremote/bean/TransferIsolateBean.dart';
import 'package:tremote/bean/TransferItem.dart';
import 'package:tremote/common/Event.dart';
import 'package:tremote/manager/ConnectManager.dart';
import 'package:tremote/provider/AppProvider.dart';
import 'package:provider/provider.dart';
import 'package:worker_manager/worker_manager.dart';

import 'Log.dart';

/// 传输文件
transferFile({
  required BuildContext context,
  required String filename,
  required int filesize,
  required String remotePath,
  required String savePath,
  required Server server,
  required bool isUpload,
  Key? pageKey,
}) async {
  var key = DateTime.now().millisecondsSinceEpoch;
  //添加到传输列表
  context.read<AppProvider>().getTransferList().putIfAbsent(
      key,
      () => TransferItem(
            key: key,
            filename: filename,
            size: filesize,
            remotepath: remotePath,
            localpath: savePath,
            isUpload: isUpload,
            isFinish: false,
            progress: 0,
            createTime: DateTime.now().millisecondsSinceEpoch,
          ));
  //发送增加传输列表事件
  eventBus.fire(EventAddTransferItem());

  loggerNoStack.d(savePath);
  loggerNoStack.d(remotePath);

  var beforeTime = DateTime.now().millisecondsSinceEpoch;
  int secondCount = 0; // 每秒的下载量
  String speedText = "0.00 MB/s";
  var lastSize = 0;
  // 创建一个消息接收器
  var receivePort = ReceivePort();
  // 主isolate接收持有主进程发送器的isolate发过来的消息
  receivePort.listen((message) {
    //发送传输信息
    if (message is SendPort) {
      message.send(IsolateBean(
          type: IsolateType.startTransfer,
          data: TransferIsolateBean(
              filename: filename,
              remotePath: remotePath,
              localPath: savePath,
              server: server)));
      return;
    }
    if (message is IsolateBean) {
      switch (message.type) {
        case IsolateType.transferProgress:
          {
            //计算传输速度
            var currentTime = DateTime.now().millisecondsSinceEpoch;
            if (currentTime - beforeTime > 1000) {
              beforeTime = currentTime;
              speedText = getSpeedText(secondCount);
              secondCount = 0;
            } else {
              secondCount += (message.data as int) - lastSize;
            }
            lastSize = message.data;
            //设置进度信息
            context.read<AppProvider>().getTransferList()[key]!.progress =
                (message.data / filesize!) * 100;
            //触发更新事件
            eventBus.fire(EventRefreshTransferItem(
                key, (message.data / filesize!) * 100, speedText));
            break;
          }
        case IsolateType.endTransfer:
          {
            context.read<AppProvider>().getTransferList()[key]!.isFinish = true;
            if (isUpload) {
              LocalNotification(
                title: "TRemote",
                body: "文件:" + filename + " 上传完成",
              ).show();
            } else {
              LocalNotification(
                title: "TRemote",
                body: "文件:" + filename + " 下载完成",
              ).show();
            }
            if (pageKey != null) {
              eventBus.fire(EventRefreshSFTPFiles(key: pageKey));
            }
            break;
          }
      }
    }
  });
  //开启任务
  loggerNoStack.i("开始传输：" + filename);
  var task = Executor().execute(
      arg1: receivePort.sendPort,
      fun1: isUpload ? uploadIsolate : downloadIsolate);
}

String getSpeedText(int speedCount) {
  return filesize(speedCount, 2) + "/s";
}

/// 下载
void downloadIsolate(SendPort sendPort) {
  // 创建一个消息接收器
  var receivePort = ReceivePort();
  receivePort.listen((message) async {
    if (message is IsolateBean) {
      switch (message.type) {
        case IsolateType.startTransfer:
          {
            //添加下载
            var bean = message.data as TransferIsolateBean;
            var ssh = await ConnectManager().getSSHClient(bean.server);
            var sftp = await ssh!.sftp();

            var file = await sftp.open(bean.remotePath);
            var data = file.read(onProgress: (bytesRead) {
              sendPort.send(IsolateBean(
                  type: IsolateType.transferProgress, data: bytesRead));
            });
            print("读取文件");
            var localFile = File(bean.localPath);
            var sink = localFile.openWrite();
            await sink.addStream(data);
            await sink.flush();
            await sink.close();
            print("文件下载完成");
            //完成下载
            sendPort.send(IsolateBean(type: IsolateType.endTransfer));
            break;
          }
      }
    }
  });
  sendPort.send(receivePort.sendPort);
}

/// 上传
void uploadIsolate(SendPort sendPort) {
  // 创建一个消息接收器
  var receivePort = ReceivePort();
  receivePort.listen((message) async {
    if (message is IsolateBean) {
      switch (message.type) {
        case IsolateType.startTransfer:
          {
            var bean = message.data as TransferIsolateBean;
            var ssh = await ConnectManager().getSSHClient(bean.server);
            var sftp = await ssh!.sftp();
            var file = await sftp.open(bean.remotePath,
                mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
            file.write(
              File(bean.localPath).openRead().cast(),
              onProgress: (total) {
                sendPort.send(IsolateBean(
                    type: IsolateType.transferProgress, data: total));
              },
            );
            print("文件传输完成");
            //完成下载
            sendPort.send(IsolateBean(type: IsolateType.endTransfer));
            break;
          }
      }
    }
  });
  sendPort.send(receivePort.sendPort);
}
