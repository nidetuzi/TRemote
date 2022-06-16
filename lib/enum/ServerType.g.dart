// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ServerType.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServerTypeAdapter extends TypeAdapter<ServerType> {
  @override
  final int typeId = 2;

  @override
  ServerType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ServerType.Linux;
      case 1:
        return ServerType.Windows;
      default:
        return ServerType.Linux;
    }
  }

  @override
  void write(BinaryWriter writer, ServerType obj) {
    switch (obj) {
      case ServerType.Linux:
        writer.writeByte(0);
        break;
      case ServerType.Windows:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
