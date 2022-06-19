import 'dart:io';

import 'package:contextual_menu/contextual_menu.dart' as CMenu;
import 'package:file_picker/file_picker.dart' as FilePicker;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tremote/bean/FileItem.dart';
import 'package:tremote/bean/Server.dart';
import 'package:tremote/common/SFTP.dart';
import 'package:tremote/common/Utils.dart';

getFileMenu(
    {required BuildContext context,
    required FileItem? fileItem,
    required String currentDir,
    required Server server,
    required List<CMenu.MenuItem> commonMenu}) {
  return CMenu.Menu(
    items: [
      CMenu.MenuItem(
        label: '下载',
        onClick: (_) async {
          if (fileItem != null &&
              fileItem.filetype != FileType.directory &&
              fileItem.filetype != FileType.linkDirectory) {
            Directory? dir = await getDownloadsDirectory();
            //本地保存目录
            var savePath = dir!.path + "\\" + fileItem.filename;
            //远程目录
            var remotePath = currentDir + "/" + fileItem.filename;
            print(remotePath);
            //调用传输方法
            transferFile(
                context: context,
                filename: fileItem.filename,
                filesize: fileItem.sftp.attr.size!,
                remotePath: remotePath,
                savePath: savePath,
                server: server,
                isUpload: false);
          }
        },
      ),
      CMenu.MenuItem(
        label: '下载到指定文件夹',
        onClick: (_) async {
          if (fileItem != null &&
              fileItem.filetype != FileType.directory &&
              fileItem.filetype != FileType.linkDirectory) {
            String? selectedDirectory =
                await FilePicker.FilePicker.platform.getDirectoryPath();
            if (selectedDirectory != null) {
              //本地保存目录
              var savePath =
                  selectedDirectory + Separator() + fileItem.filename;
              //远程目录
              var remotePath = currentDir + "/" + fileItem.filename;
              //调用传输方法
              transferFile(
                  context: context,
                  filename: fileItem.filename,
                  filesize: fileItem.sftp.attr.size!,
                  remotePath: remotePath,
                  savePath: savePath,
                  server: server,
                  isUpload: false);
            }
          }
        },
      ),
      CMenu.MenuItem.separator(),
      CMenu.MenuItem(
        label: '上传',
        onClick: (_) async {
          FilePicker.FilePickerResult? result =
              await FilePicker.FilePicker.platform.pickFiles();
          if (result != null) {
            File file = File(result.files.single.path!);
            //远程目录
            var remotePath = currentDir + "/" + result.files.single.name;
            //调用传输方法
            transferFile(
                context: context,
                filename: fileItem!.filename,
                filesize: await file.length(),
                remotePath: remotePath,
                savePath: file.path,
                server: server,
                isUpload: true);
          }
        },
      ),
      CMenu.MenuItem.separator(),
      ...commonMenu
    ],
  );
}
