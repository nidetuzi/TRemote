import 'package:dartssh2/dartssh2.dart';
import 'package:file_icon/file_icon.dart';
import 'package:fluent_ui/fluent_ui.dart';

class FileItem {
  //文件名
  String filename;
  //文件类型
  FileType filetype;
  //sftp信息
  SftpName sftp;

  FileItem(
      {required this.filename, required this.filetype, required this.sftp});
}

enum FileType { file, directory, linkFile, linkDirectory }

/// 是否是文件
bool isFile(FileType type) {
  return type == FileType.file || type == FileType.linkFile;
}

//获取文件类型对应的图标
getFileTypeIcon(FileType type, String filename) {
  switch (type) {
    case FileType.file:
      {
        return FileIcon(filename);
      }
    case FileType.directory:
      {
        return const Icon(FluentIcons.fabric_folder);
      }
    case FileType.linkFile:
      {
        return const Icon(FluentIcons.file_symlink);
      }
    case FileType.linkDirectory:
      {
        return const Icon(FluentIcons.fabric_folder_link);
      }
  }
}

//获取文件类型名称
getFileTypeName(FileType type) {
  switch (type) {
    case FileType.file:
      {
        return "文件";
      }
    case FileType.directory:
      {
        return "文件夹";
      }
    case FileType.linkFile:
      {
        return "文件";
      }
    case FileType.linkDirectory:
      {
        return "文件夹";
      }
  }
}
