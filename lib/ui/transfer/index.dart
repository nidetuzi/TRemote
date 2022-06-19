import 'package:date_format/date_format.dart';
import 'package:file_icon/file_icon.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:tremote/bean/FileItem.dart';
import 'package:tremote/bean/Server.dart';
import 'package:tremote/bean/TransferItem.dart';
import 'package:provider/provider.dart';
import 'package:tremote/common/Event.dart';
import 'package:tremote/provider/AppProvider.dart';
import 'package:filesize/filesize.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({Key? key}) : super(key: key);

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _controller = ScrollController();
  //服务器列表
  List<Server> items = [];

  List<TreeViewItem> itemList = [];

  Map<int, ValueNotifier<double>> progressList = {};
  Map<int, ValueNotifier<String>> speedList = {};

  TreeViewItem? currentSelected;

  @override
  void initState() {
    super.initState();
    eventBus.on<EventAddTransferItem>().listen((event) {
      print(context.read<AppProvider>().getTransferList().length);
      buildListItem(context.read<AppProvider>().getTransferList());
    });
    eventBus.on<EventRefreshTransferItem>().listen((event) {
      setState(() {
        progressList[event.key]!.value = event.progress;
        speedList[event.key]!.value = event.speed;
      });
    });
    buildListItem(context.read<AppProvider>().getTransferList());
  }

  //构造列表
  buildListItem(Map<int, TransferItem> list) {
    List<TreeViewItem> result = [];
    speedList.clear();
    progressList.clear();
    itemList.clear();
    list.forEach((key, value) {
      progressList[key] = ValueNotifier<double>(value.progress);
      speedList[key] = ValueNotifier<String>("");
      result.add(
          TreeViewItem(content: _buildTransferItem(value, key), value: value));
    });
    setState(() {
      itemList = result;
      print(itemList.length);
    });
  }

  _buildTransferItem(TransferItem transfer, int key) {
    return Container(
      transform: Matrix4.translationValues(-18.0, 0.0, 0.0),
      child: Row(children: [
        FileIcon(transfer.filename),
        const SizedBox(
          width: 5,
        ),
        Expanded(flex: 2, child: Text(transfer.filename)), //名称
        Expanded(
            flex: 1,
            child: ValueListenableBuilder<double>(
              builder: (context, value, child) {
                return Text(value >= 100 ? "完成" : "传输中");
              },
              valueListenable: progressList[key]!,
            )),
        Expanded(
            flex: 1,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.8, //宽度因子
              child: ValueListenableBuilder<double>(
                builder: (context, value, child) {
                  return ProgressBar(
                    value: value,
                  );
                },
                valueListenable: progressList[key]!,
              ),
            )),
        Expanded(flex: 1, child: Text(filesize(transfer.size))),
        Expanded(
            flex: 2,
            child: Text(
              transfer.localpath,
              overflow: TextOverflow.ellipsis,
            )),
        Expanded(
            flex: 2,
            child: Text(transfer.remotepath, overflow: TextOverflow.ellipsis)),
        Expanded(
            flex: 1,
            child: Row(
              children: [
                transfer.isUpload
                    ? const Icon(FluentIcons.upload)
                    : const Icon(
                        FluentIcons.download,
                        size: 14,
                      ),
                ValueListenableBuilder<String>(
                  builder: (context, value, child) {
                    return Text(value);
                  },
                  valueListenable: speedList[key]!,
                )
              ],
            )),
        Expanded(
            flex: 1,
            child: Text(formatDate(
                DateTime.fromMillisecondsSinceEpoch(transfer.createTime!),
                [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]))),
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
        height: 1000,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Row(children: const [
                SizedBox(
                  width: 18,
                ),
                SizedBox(
                  width: 5,
                ),
                Expanded(flex: 2, child: Text("名称")),
                Expanded(flex: 1, child: Text("状态")),
                Expanded(
                  flex: 1,
                  child: Text("进度"),
                ),
                Expanded(flex: 1, child: Text("大小")),
                Expanded(flex: 2, child: Text("本地路径")),
                Expanded(flex: 2, child: Text("远程路径")),
                Expanded(flex: 1, child: Text("速度")),
                Expanded(flex: 1, child: Text("创建时间")),
              ]),
            ),
            itemList.isNotEmpty
                ? TreeView(
                    items: itemList,
                    selectionMode: TreeViewSelectionMode.single,
                    onSelectionChanged: onSelectionChanged)
                : Container()
          ],
        ),
      ),
    );
  }
}
