import 'package:fluent_ui/fluent_ui.dart';
import 'package:tremote/bean/Server.dart';
import 'package:tremote/bean/TransferItem.dart';

class AppProvider extends ChangeNotifier {
  //主页tab
  int? tabIndex = 0;
  //传输列表
  Map<int, TransferItem> transferList = <int, TransferItem>{};

  List<TreeViewItem> itemList = [];

  int? getTabIndex() {
    return tabIndex;
  }

  void setTabIndex(int? tabIndex) {
    this.tabIndex = tabIndex;
    notifyListeners();
  }

  Map<int, TransferItem> getTransferList() {
    return transferList;
  }

  void setTransferList(Map<int, TransferItem> transferList) {
    this.transferList = transferList;
    notifyListeners();
  }
  
  /// 获取当前传输数量
  int getTransferCount() {
    int i = 0;
    transferList.forEach((key, value) {
      if (!value.isFinish) {
        i++;
      }
    });
    return i;
  }
}
