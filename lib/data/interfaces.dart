import 'package:mediremind/data/types.dart';

abstract class MedRepo {
  List<Med> getMeds();
  Med getMed(String key);
  void updateMed(String key, Med med);
  void addMed(Med med);
  void delMed(Med med);
  AppState getState();
  void writeState(AppState newState);
}

abstract class StorageBackend {
  void writeAppState(AppState as);
  Future<AppState> readAppState();
}
