import 'package:fluent_ui/fluent_ui.dart';
import 'package:tremote/bean/Server.dart';
import 'package:tremote/common/Event.dart';
import 'package:tremote/enum/ServerType.dart';
import 'package:tremote/manager/DBManager.dart';

class EditFormPage extends StatefulWidget {
  Server server;
  EditFormPage({Key? key, required this.server}) : super(key: key);
  @override
  _EditFormPageState createState() => _EditFormPageState();
}

class _EditFormPageState extends State<EditFormPage> {
  final _formKey = GlobalKey<FormState>();
  final values = ['Linux', 'Windows'];
  String? comboBoxValue = "Linux";
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    var server = widget.server.copyWith();
    return ContentDialog(
      title: const Text('编辑服务器'),
      content: SizedBox(
        height: 500,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(children: [
            TextFormBox(
              header: '名称',
              placeholder: '输入服务器名称',
              maxLines: 1,
              onChanged: (text) => server.name = text,
              initialValue: server.name,
              autovalidateMode: AutovalidateMode.always,
              textInputAction: TextInputAction.next,
              validator: (text) {
                if (text == null || text.isEmpty) return '请输入服务器名称';
                return null;
              },
            ),
            InfoLabel(
                label: '类型',
                child: Combobox<String>(
                  placeholder: const Text('选择服务器类型'),
                  isExpanded: true,
                  items: values
                      .map((e) => ComboboxItem<String>(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  value: comboBoxValue,
                  onChanged: (value) {
                    setState(() {
                      server.type = getServerTypeByName(value!);
                      comboBoxValue = value;
                    });
                  },
                )),
            TextFormBox(
              header: 'IP',
              placeholder: '输入服务器IP',
              maxLines: 1,
              onChanged: (text) => server.ip = text,
              initialValue: server.ip,
              autovalidateMode: AutovalidateMode.always,
              textInputAction: TextInputAction.next,
              validator: (text) {
                if (text == null || text.isEmpty) return '请输入服务器IP';
                return null;
              },
            ),
            TextFormBox(
              header: '端口',
              placeholder: '输入服务器端口',
              maxLines: 1,
              onChanged: (text) => server.port = text as int,
              initialValue: server.port.toString(),
              autovalidateMode: AutovalidateMode.always,
              textInputAction: TextInputAction.next,
              validator: (text) {
                if (text == null || text.isEmpty) return '请输入服务器端口';
                return null;
              },
            ),
            TextFormBox(
              header: '用户名',
              placeholder: '输入服务器用户名',
              maxLines: 1,
              onChanged: (text) => server.username = text,
              initialValue: server.username,
              autovalidateMode: AutovalidateMode.always,
              textInputAction: TextInputAction.next,
              validator: (text) {
                if (text == null || text.isEmpty) return '请输入服务器用户名';
                return null;
              },
            ),
            TextFormBox(
              header: '密码',
              placeholder: '输入服务器密码',
              obscureText: !_showPassword,
              maxLines: 1,
              onChanged: (text) => server.password = text,
              initialValue: server.password,
              autovalidateMode: AutovalidateMode.always,
              textInputAction: TextInputAction.next,
              validator: (text) {
                if (text == null || text.isEmpty) return '请输入服务器密码';
                return null;
              },
              suffix: IconButton(
                icon: Icon(
                  !_showPassword ? FluentIcons.lock : FluentIcons.unlock,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ]),
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 500),
      actions: [
        Button(
            child: const Text('取消'),
            onPressed: () {
              Navigator.pop(context);
            }),
        Button(
            child: const Text('保存'),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                //保存到数据库
                var box = DBManager.serverBox;
                await box.put(server.id, server);
                //触发事件
                eventBus.fire(EventRefreshServers());
                Navigator.pop(context);
              }
            })
      ],
    );
  }
}
