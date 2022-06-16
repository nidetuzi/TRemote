import 'dart:core';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:tremote/bean/Server.dart';
import 'package:tremote/common/Event.dart';
import 'package:tremote/provider/AppProvider.dart';
import 'package:tremote/ui/linux/index.dart';
import 'package:provider/provider.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  int currentIndex = 0;

  List<Server> servers = <Server>[];
  List<LinuxPage> pages = <LinuxPage>[];

  @override
  void initState() {
    super.initState();

    eventBus.on<EventAddTerminalTab>().listen((event) {
      setState(() {
        servers.add(event.server);
        pages.add(LinuxPage(
          key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
          server: event.server,
        ));
        if (currentIndex < servers.length - 1) currentIndex++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: TabView(
            currentIndex: currentIndex,
            onChanged: (index) => setState(() => currentIndex = index),
            onNewPressed: () {
              var app = context.read<AppProvider>();
              app.setTabIndex(1);
            },
            tabs: List.generate(servers.length, (index) {
              return Tab(
                  text: Text(servers[index].name),
                  closeIcon: FluentIcons.chrome_close,
                  onClosed: () {
                    //关闭tab
                    setState(() {
                      servers.removeAt(index);
                      pages.removeAt(index);
                      if (currentIndex > servers.length - 1) currentIndex--;
                    });
                  });
            }),
            bodies: List.generate(servers.length, (index) {
              return Container();
            }),
          ),
        ),
        Expanded(
            child: IndexedStack(
          index: currentIndex,
          children: pages,
        ))
      ],
    );
  }
}
