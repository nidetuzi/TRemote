// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartssh2/dartssh2.dart';

import 'package:tremote/bean/FileItem.dart';
import 'package:tremote/bean/Server.dart';

class TransferIsolateBean {
  String filename;
  String remotePath;
  String localPath;
  Server server;

  TransferIsolateBean({
    required this.filename,
    required this.remotePath,
    required this.localPath,
    required this.server,
  });
}
