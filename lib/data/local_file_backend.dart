import 'dart:convert';
import 'dart:io';

import 'package:mediremind/data/interfaces.dart';
import 'package:mediremind/data/types.dart';
import 'package:path_provider/path_provider.dart';

final String localFilename = "meds.json";

class LocalFileBackend implements StorageBackend {
  final String filename;

  LocalFileBackend.withPath(this.filename);

  LocalFileBackend() : filename = localFilename;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  Future<String> _readFile() async {
    final file = await _localFile;
    if (await file.exists()) {
      final contents = await file.readAsString();
      return contents;
    } else {
      return "";
    }
  }

  Future<File> _writeFile(String content) async {
    final file = await _localFile;
    return file.writeAsString(content);
  }

  @override
  Future<AppState> readAppState() async {
    String fileContent = await _readFile();
    if (fileContent.isEmpty) {
      return AppState(AppState.currentVersion, []);
    }
    final parsed = jsonDecode(fileContent);
    final AppStateSerializer as = AppStateSerializer();

    return as.specialFromJson(parsed);
  }

  @override
  void writeAppState(AppState as) {
    var aSS = AppStateSerializer();
    var fileString = jsonEncode(aSS.toJson(as), toEncodable: (v) => v);
    _writeFile(fileString);
  }
}
