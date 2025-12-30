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
  Future<List<Med>> readMeds() async {
    var fileContent = await _readFile();
    if (fileContent.isEmpty) {
      return [];
    }
    final ms = MedSerializer();
    final List<Map<String, dynamic>> parsed = List<Map<String, dynamic>>.from(
      jsonDecode(fileContent),
    );
    List<Med> meds = parsed.map(ms.fromJson).toList();
    return meds;
  }

  @override
  void writeMeds(Iterable<Med> meds) {
    var ms = MedSerializer();
    var fileString = jsonEncode(
      meds.map(ms.toJson).toList(),
      toEncodable: (v) => v,
    );
    _writeFile(fileString);
  }
}
