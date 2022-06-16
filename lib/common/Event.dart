// ignore_for_file: public_member_api_docs, sort_constructors_first
// tabBar切换选中页面
import 'package:event_bus/event_bus.dart';

import 'package:tremote/bean/Server.dart';
import 'package:tremote/bean/TransferItem.dart';

EventBus eventBus = EventBus();

class EventAddTerminalTab{
// 参数为int 即需要改变的下标
  Server server;
  EventAddTerminalTab(this.server);
}

//刷新服务器列表
class EventRefreshServers{
  EventRefreshServers();
}


class EventAddTransferItem{
  EventAddTransferItem();
}
class EventRefreshTransferItem {
  int key;
  double progress;
  String speed;

  EventRefreshTransferItem(
    this.key,
    this.progress,
    this.speed
  );
}
