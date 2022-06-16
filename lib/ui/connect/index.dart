import 'package:fluent_ui/fluent_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tremote/bean/Server.dart';
import 'package:tremote/common/Event.dart';
import 'package:tremote/enum/ServerType.dart';
import 'package:tremote/manager/DBManager.dart';
import 'package:provider/provider.dart';
import 'package:tremote/provider/AppProvider.dart';
import 'package:tremote/ui/connect/EditForm.dart';
import 'package:tremote/ui/connect/NewForm.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({Key? key}) : super(key: key);

  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _controller = ScrollController();
  //服务器列表
  List<Server> items = [];

  List<TreeViewItem> itemList = [];

  final values = ['Linux', 'Windows'];
  String? comboBoxValue;

  TreeViewItem? currentSelected;

  @override
  void initState() {
    super.initState();
    eventBus.on<EventRefreshServers>().listen((event) {
      initData();
    });
    initData();
  }

  //初始化数据
  initData() async {
    var box = DBManager.serverBox;
    setState(() {
      items.clear();
      items.addAll(box.toMap().values);
    });
    print("服务器数量：" + items.length.toString());
    buildListItem();
  }

  //构造列表
  void buildListItem() {
    List<TreeViewItem> list = <TreeViewItem>[];
    for (var element in items) {
      list.add(
          TreeViewItem(content: _buildServerItem(element), value: element));
    }
    setState(() {
      itemList = list;
    });
  }

  _buildServerItem(Server server) {
    return Container(
      transform: Matrix4.translationValues(-18.0, 0.0, 0.0),
      child: Row(children: [
        const Expanded(
          flex: 0,
          child: const Icon(FluentIcons.system),
        ),
        const SizedBox(
          width: 5,
        ),
        Expanded(flex: 2, child: Text(server.name)),
        Expanded(flex: 1, child: Text(getServerTypeName(server.type))),
        Expanded(flex: 1, child: Text(server.ip)),
        Expanded(flex: 1, child: Text(server.port.toString())),
        Expanded(flex: 1, child: Text(server.username)),
      ]),
    );
  }

  Future<void> onSelectionChanged(selectedItems) async {
    currentSelected = selectedItems[0];
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 1200,
        height: 1000,
        child: Column(
          children: [
            CommandBar(
              mainAxisAlignment: MainAxisAlignment.center,
              overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
              compactBreakpointWidth: 768,
              primaryItems: [
                CommandBarButton(
                  icon: const Icon(FluentIcons.open_in_new_tab),
                  label: const Text('打开'),
                  onPressed: () {
                    if (currentSelected != null) {
                      var app = context.read<AppProvider>();
                      app.setTabIndex(0);
                      eventBus
                          .fire(EventAddTerminalTab(currentSelected?.value));
                    }
                  },
                ),
                CommandBarButton(
                  icon: const Icon(FluentIcons.add),
                  label: const Text('新建'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return NewFormPage();
                      },
                    );
                  },
                ),
                CommandBarButton(
                  icon: const Icon(FluentIcons.edit),
                  label: const Text('编辑'),
                  onPressed: () {
                    if (currentSelected != null) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return EditFormPage(
                            server: currentSelected!.value,
                          );
                        },
                      );
                    }
                  },
                ),
                CommandBarButton(
                  icon: const Icon(FluentIcons.delete),
                  label: const Text('删除'),
                  onPressed: () {
                    if (currentSelected != null) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return ContentDialog(
                            title: const Text("提示"),
                            content: const Text("确认要删除该服务器? 该操作无法撤销!"),
                            actions: [
                              Button(
                                child: const Text('删除'),
                                onPressed: () async {
                                  var box = DBManager.serverBox;
                                  await box.delete(
                                      (currentSelected!.value as Server).id);
                                  //触发事件
                                  eventBus.fire(EventRefreshServers());
                                  Navigator.pop(context);
                                },
                              ),
                              FilledButton(
                                child: const Text('取消'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
            TreeView(items: [
              TreeViewItem(
                  content: Container(
                      transform: Matrix4.translationValues(-18.0, 0.0, 0.0),
                      child: Row(children: const [
                        SizedBox(
                          width: 18,
                        ),
                        Expanded(flex: 2, child: Text("名称")),
                        Expanded(flex: 1, child: Text("类型")),
                        Expanded(flex: 1, child: Text("IP")),
                        Expanded(flex: 1, child: Text("端口")),
                        Expanded(flex: 1, child: Text("用户名")),
                      ])))
            ]),
            itemList.isNotEmpty
                ? TreeView(
                    items: itemList,
                    selectionMode: TreeViewSelectionMode.single,
                    onSelectionChanged: onSelectionChanged)
                : Container(),
          ],
        ),
      ),
    );
  }
}
