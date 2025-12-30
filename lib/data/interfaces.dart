import 'package:mediremind/data/types.dart';

abstract class MedRepo {
  List<Med> getMeds();
  Med getMed(String key);
  void updateMed(String key, Med med);
  void addMed(Med med);
  void delMed(Med med);
}

abstract class StorageBackend {
  void writeMeds(Iterable<Med> meds);
  Future<List<Med>> readMeds();
}
