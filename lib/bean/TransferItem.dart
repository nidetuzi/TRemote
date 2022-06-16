// ignore_for_file: public_member_api_docs, sort_constructors_first
class TransferItem {
  /// key
  int key;

  /// 文件名称
  String filename;

  /// 文件大小
  int? size;

  /// 远程文件目录
  String remotepath;

  /// 本地文件目录
  String localpath;

  /// 是否为上传
  bool isUpload;

  /// 是否完成
  bool isFinish;

  /// 当前进度
  double progress = 0;



  TransferItem({
    required this.key,
    required this.filename,
    required this.size,
    required this.remotepath,
    required this.localpath,
    required this.isUpload,
    required this.isFinish,
    required this.progress,
  });
}
