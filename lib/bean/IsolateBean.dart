// ignore_for_file: public_member_api_docs, sort_constructors_first
class IsolateBean {
  IsolateType type;
  dynamic data;
  IsolateBean({
    required this.type,
    this.data,
  });
}




enum IsolateType{
  /// 开始下载
  startTransfer,
  /// 下载进度
  transferProgress,
  /// 下载完成
  endTransfer,
  
}