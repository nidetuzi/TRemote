import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:date_format/date_format.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart' as FilePicker;
import 'package:filesize/filesize.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tremote/bean/Server.dart';
import 'package:tremote/common/Event.dart';
import 'package:tremote/common/Log.dart';
import 'package:tremote/common/SFTP.dart';
import 'package:tremote/common/Utils.dart';
import 'package:tremote/manager/ConnectManager.dart';
import 'package:xterm/flutter.dart';
import 'package:xterm/xterm.dart';
import 'package:contextual_menu/contextual_menu.dart' as CMenu;

import '../../bean/FileItem.dart';
import '../../common/TerminalBackend.dart';

class LinuxPage extends StatefulWidget {
  Server server;
  LinuxPage({Key? key, required this.server}) : super(key: key);

  @override
  _LinuxPageState createState() => _LinuxPageState();
}

class _LinuxPageState extends State<LinuxPage> {
  //当前选择的文件名
  String currentSelectedName = "";
  //当前所在目录
  String currentDir = "/";
  //当前输入框写的目录
  String currentInputDir = "/";
  //文件列表
  List<FileItem> items = [];
  FileItem? currentRightFile;

  List<TreeViewItem> fileList = [];
  late SSHClient client;
  late SftpClient sftp;
  //上次点击时间
  int lastClickTime = 0;
  TreeViewItem? lastClickItem;
  //终端
  late Terminal terminal;
  late List commonMenu = [];
  late CMenu.Menu termMenu;
  final _formKey = GlobalKey();
// 定时器
  Timer? timer; // 定义定时器

  @override
  void initState() {
    super.initState();
    logger.i("初始化");

    terminal = Terminal(
      backend: MyTerminalBackend(widget.server),
      maxLines: 10000,
    );
    //初始化菜单
    termMenu = CMenu.Menu(
      items: [
        CMenu.MenuItem(
            label: '复制',
            onClick: (_) {
              Clipboard.setData(ClipboardData(text: terminal.selectedText));
            }),
        CMenu.MenuItem(
          label: '粘贴',
          onClick: (_) async {
            ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
            terminal.backend!.write("${data?.text}");
          },
        ),
      ],
    );
    //通用菜单
    commonMenu = [
      MenuFlyoutItem(
        text: const Text('上传'),
        onPressed: () async {
          FilePicker.FilePickerResult? result =
              await FilePicker.FilePicker.platform.pickFiles();
          if (result != null) {
            File file = File(result.files.single.path!);
            //远程目录
            var remotePath = currentDir + "/" + result.files.single.name;
            //调用传输方法
            transferFile(
                context: context,
                filename: result.files.single.name,
                filesize: await file.length(),
                remotePath: remotePath,
                savePath: file.path,
                server: widget.server,
                isUpload: true,
                pageKey: widget.key);
          }
          Navigator.of(context).pop();
        },
      ),
      const MenuFlyoutSeparator(),
      MenuFlyoutItem(
          text: const Text("删除"),
          onPressed: () async {
            if (currentRightFile != null) {
              showDialog(
                context: context,
                builder: (context) {
                  return ContentDialog(
                    title: const Text("提示"),
                    content: const Text("确认要删除该文件或者文件夹? 该操作无法撤销!"),
                    actions: [
                      Button(
                        child: const Text('删除'),
                        onPressed: () async {
                          var remotepath = currentInputDir +
                              "/" +
                              currentRightFile!.filename;
                          if (isFile(currentRightFile!.filetype)) {
                            await sftp.remove(remotepath);
                          } else {
                            await sftp.rmdir(remotepath);
                          }
                          getFileList(currentDir);
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
            Navigator.of(context).pop();
          }),
      MenuFlyoutItem(
          text: const Text("快速删除(rm -rf)"),
          onPressed: () async {
            if (currentRightFile != null) {
              showDialog(
                context: context,
                builder: (context) {
                  return ContentDialog(
                    title: const Text("提示"),
                    content: const Text("确认要删除该文件或者文件夹? 该操作无法撤销!"),
                    actions: [
                      Button(
                        child: const Text('删除'),
                        onPressed: () async {
                          var remotepath = currentInputDir +
                              "/" +
                              currentRightFile!.filename;
                          await client.run("rm -rf " + remotepath);
                          getFileList(currentDir);
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
            Navigator.of(context).pop();
          }),
      const MenuFlyoutSeparator(),
      MenuFlyoutItem(
          text: const Text("复制路径"),
          onPressed: () {
            if (currentRightFile != null) {
              var remotepath =
                  currentInputDir + "/" + currentRightFile!.filename;
              Clipboard.setData(ClipboardData(text: remotepath));
            }
            Navigator.of(context).pop();
          }),
      MenuFlyoutItem(
          text: const Text("刷新"),
          onPressed: () {
            if (currentRightFile != null) {
              getFileList(currentDir);
            }
            Navigator.of(context).pop();
          }),
    ];
    //刷新文件列表
    eventBus.on<EventRefreshSFTPFiles>().listen((event) {
      if (event.key == widget.key) {
        getFileList(currentDir);
      }
    });
    getData();
  }

  @override
  void dispose() {
    super.dispose();
    client.close();
    sftp.close();
    timer!.cancel();
    terminal.backend!.terminate();
  }

  getData() async {
    try {
      client = (await ConnectManager().getSSHClient(widget.server))!;

      timer = Timer.periodic(const Duration(seconds: 60), (timer) {
        loggerNoStack.d("发送心跳信息");
        client.run("");
      });

      sftp = await client.sftp();
      await getFileList(currentDir);
    } catch (ex) {}
  }

  /// 获取文件列表
  getFileList(String path) async {
    setState(() {
      items = [];
    });
    currentInputDir = path;

    List<SftpName> lists = await sftp.listdir(path);
    List<FileItem> files = [];
    List<FileItem> directorys = [];

    //转换为文件夹和文件
    for (SftpName file in lists) {
      if (file.filename == ".") {
        continue;
      }
      if (currentDir == "/" && file.filename == "..") {
        continue;
      }
      try {
        if (file.attr.isFile) {
          files.add(FileItem(
              filename: file.filename, filetype: FileType.file, sftp: file));
        } else if (file.attr.isDirectory) {
          directorys.add(FileItem(
              filename: file.filename,
              filetype: FileType.directory,
              sftp: file));
        } else if (file.attr.isSymbolicLink) {
          //软连接判断实际类型
          final stat = await sftp.stat(path + "/" + file.filename);
          if (stat.isDirectory) {
            directorys.add(FileItem(
                filename: file.filename,
                filetype: FileType.linkDirectory,
                sftp: file));
          } else if (stat.isFile) {
            files.add(FileItem(
                filename: file.filename,
                filetype: FileType.linkFile,
                sftp: file));
          }
        }
      } catch (ex) {
        loggerNoStack.e("文件：" + path + "/" + file.filename + " 找不到!");
        continue;
      }
    }
    directorys.sort(((a, b) => a.filename.compareTo(b.filename)));
    files.sort(((a, b) => a.filename.compareTo(b.filename)));
    setState(() {
      items.addAll(directorys);
      items.addAll(files);
      buildListItem();
    });
  }

  //构造列表
  void buildListItem() {
    List<TreeViewItem> list = <TreeViewItem>[];
    for (var element in items) {
      list.add(TreeViewItem(
          content: _buildFileItem(element),
          onInvoked: doubleTap,
          value: element));
    }

    setState(() {
      fileList = list;
    });
  }

  //检测双击事件
  Future<void> doubleTap(TreeViewItem item) async {
    if (lastClickItem != item) {
      lastClickItem = item;
      lastClickTime = DateTime.now().millisecondsSinceEpoch;
      return;
    }
    if (DateTime.now().millisecondsSinceEpoch - lastClickTime <= 300) {
      var file = item.value as FileItem;
      if (file.filetype == FileType.directory) {
        if (file.filename == "..") {
          var paths = currentDir.split("/");
          if (paths.length == 1) {
            return;
          }
          paths.removeAt(paths.length - 1);
          String path = paths.join("/");
          currentDir = paths.length == 1 ? "/" : path;
          getFileList(currentDir);
          return;
        }

        if (currentDir == "/") {
          currentDir += file.filename;
        } else {
          currentDir += "/" + file.filename;
        }

        getFileList(currentDir);
      } else {
        var tempDir = currentDir;
        if (tempDir == "/") {
          tempDir += file.filename;
        } else {
          tempDir += "/" + file.filename;
        }
        final stat = await sftp.stat(tempDir);
        if (stat.isDirectory) {
          currentDir = tempDir;
          getFileList(currentDir);
        }
      }
      return;
    }
    lastClickTime = DateTime.now().millisecondsSinceEpoch;
  }

  //构造文件夹item
  _buildFileItem(FileItem file) {
    return Container(
      transform: Matrix4.translationValues(-18.0, 0.0, 0.0),
      child: Row(children: [
        getFileTypeIcon(file.filetype, file.filename),
        const SizedBox(
          width: 5,
        ),
        Expanded(flex: 2, child: Text(file.filename)),
        Expanded(flex: 1, child: Text(getFileTypeName(file.filetype))),
        Expanded(
            flex: 1,
            child: isFile(file.filetype)
                ? Text(filesize(file.sftp.attr.size))
                : const Text("")),
        Expanded(
            flex: 1,
            child: Text(formatDate(
                DateTime.fromMillisecondsSinceEpoch(
                    file.sftp.attr.modifyTime! * 1000),
                [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]))),
      ]),
    );
  }

  Widget _buildFileMenu(context) {
    return MenuFlyout(
      items: [
        MenuFlyoutItem(
          text: const Text('下载'),
          onPressed: () async {
            if (currentRightFile != null &&
                currentRightFile!.filetype != FileType.directory &&
                currentRightFile!.filetype != FileType.linkDirectory) {
              Directory? dir = await getDownloadsDirectory();
              //本地保存目录
              var savePath = dir!.path + "\\" + currentRightFile!.filename;
              //远程目录
              var remotePath = currentDir + "/" + currentRightFile!.filename;
              print(remotePath);
              //调用传输方法
              transferFile(
                  context: context,
                  filename: currentRightFile!.filename,
                  filesize: currentRightFile!.sftp.attr.size!,
                  remotePath: remotePath,
                  savePath: savePath,
                  server: widget.server,
                  isUpload: false);
            }
            Navigator.of(context).pop();
          },
        ),
        MenuFlyoutItem(
          text: const Text('下载到指定文件夹'),
          onPressed: () async {
            print(currentRightFile);
            if (currentRightFile != null &&
                currentRightFile!.filetype != FileType.directory &&
                currentRightFile!.filetype != FileType.linkDirectory) {
              String? selectedDirectory =
                  await FilePicker.FilePicker.platform.getDirectoryPath(dialogTitle:"选择保存文件夹",lockParentWindow: true);
              if (selectedDirectory != null) {
                //本地保存目录
                var savePath = selectedDirectory +
                    Separator() +
                    currentRightFile!.filename;
                //远程目录
                var remotePath = currentDir + "/" + currentRightFile!.filename;
                //调用传输方法
                transferFile(
                    context: context,
                    filename: currentRightFile!.filename,
                    filesize: currentRightFile!.sftp.attr.size!,
                    remotePath: remotePath,
                    savePath: savePath,
                    server: widget.server,
                    isUpload: false);
              }
              Navigator.of(context).pop();
            }
          },
        ),
        const MenuFlyoutSeparator(),
        ...commonMenu
      ],
    );
  }

  Widget _buildDirMenu(context) {
    return MenuFlyout(
      items: [...commonMenu],
    );
  }

  //屏蔽tab造成的焦点切换
  var focus = FocusNode(onKey: (FocusNode node, RawKeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onSecondaryTap: () {
              CMenu.popUpContextualMenu(
                termMenu,
                placement: CMenu.Placement.bottomRight,
              );
            },
            child: RawKeyboardListener(
              focusNode: focus,
              child: TerminalView(
                terminal: terminal,
              ),
            ),
          ),
        ),
        TextBox(
          controller: TextEditingController(text: currentDir),
          placeholder: '请输入路径',
          onChanged: (text) {
            currentInputDir = text;
          },
          onSubmitted: (text) {
            currentInputDir = text;
            if (currentInputDir != "") {
              currentDir = currentInputDir;
              getFileList(currentInputDir);
              return;
            }
            getFileList(currentDir);
          },
          suffix: Row(
            children: [
              //前往按钮
              IconButton(
                icon: const Icon(
                  FluentIcons.navigate_back_mirrored,
                  size: 15,
                ),
                onPressed: () {
                  if (currentInputDir != "") {
                    currentDir = currentInputDir;
                    getFileList(currentInputDir);
                    return;
                  }
                  getFileList(currentDir);
                },
              ),
              //刷新按钮
              IconButton(
                icon: const Icon(
                  FluentIcons.refresh,
                  size: 15,
                ),
                onPressed: () {
                  getFileList(currentDir);
                },
              ),
              //打开下载列表对话框
              IconButton(
                icon: const Icon(
                  FluentIcons.cloud_download,
                  size: 15,
                ),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return SizedBox(
                            height: 300,
                            width: 500,
                            child: Container(
                              color: Colors.black,
                            ));
                      });
                },
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 3,
        ),
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
            Expanded(flex: 1, child: Text("类型")),
            Expanded(flex: 1, child: Text("大小")),
            Expanded(flex: 1, child: Text("修改时间")),
          ]),
        ),
        items.isNotEmpty
            ? Expanded(
                flex: 1,
                child: DropTarget(
                    onDragDone: (detail) {
                      print(detail);
                    },
                    child: GestureDetector(
                      onSecondaryTapDown: (detail) {
                        //空白处右键
                        //TODO: 暂时屏蔽 
                        // currentRightFile = null;
                        // showMenu(
                        //     context: context,
                        //     builder: _buildDirMenu,
                        //     offset: detail.globalPosition);
                      },
                      child: TreeView(
                        items: fileList,
                        selectionMode: TreeViewSelectionMode.single,
                        onSecondaryTap: (item, offset) async {
                          currentRightFile = item.value as FileItem;
                          if (isFile((item.value as FileItem).filetype)) {
                            showMenu(
                                context: context,
                                builder: _buildFileMenu,
                                offset: offset);
                          } else {
                            showMenu(
                                context: context,
                                builder: _buildDirMenu,
                                offset: offset);
                          }
                        },
                      ),
                    )))
            : const Expanded(
                child: Padding(
                padding: EdgeInsets.all(10),
                child: ProgressBar(),
              )),
        const SizedBox(
          height: 3,
        ),
      ],
    );
  }
}
