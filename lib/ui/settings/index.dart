import 'package:fluent_ui/fluent_ui.dart';

class Settings extends StatelessWidget {
  const Settings({Key? key, this.controller}) : super(key: key);

  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('设置')),
      scrollController: controller,
      children: [
        Text('默认下载地址', style: FluentTheme.of(context).typography.subtitle),
        const SizedBox(height: 10,),
        TextButton(child: Text("H:\\flutter\\tremote",textAlign: TextAlign.left,), style: ButtonStyle(padding: ButtonState.all(const EdgeInsets.all(0))),onPressed: () {}),
      ],
    );
  }
}
