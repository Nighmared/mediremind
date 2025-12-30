import 'package:mediremind/data/interfaces.dart';
import 'package:mediremind/data/types.dart';

class GenericRepo implements MedRepo {
  final Map<String, Med> _medsCache;
  final StorageBackend _backend;

  GenericRepo._internal(this._medsCache, this._backend);

  factory GenericRepo(StorageBackend backend) {
    Map<String, Med> newCache = {};
    Future<List<Med>> futureMeds = backend.readMeds();
    futureMeds.then((meds) {
      for (var m in meds) {
        newCache[m.id] = m;
      }
    });
    return GenericRepo._internal(newCache, backend);
  }

  @override
  List<Med> getMeds() {
    return _medsCache.values.toList();
  }

  @override
  Med getMed(String key) {
    assert(_medsCache.containsKey(key));
    return _medsCache[key] as Med;
  }

  @override
  void addMed(Med med) {
    assert(!_medsCache.containsKey(med.id));
    _medsCache[med.id] = med;
    _backend.writeMeds(_medsCache.values);
  }

  @override
  void delMed(Med med) {
    _medsCache.remove(med.id);
    _backend.writeMeds(_medsCache.values);
  }

  @override
  void updateMed(String key, Med med) {
    assert(_medsCache.containsKey(med.id));
    _medsCache[key] = med;
    _backend.writeMeds(_medsCache.values);
  }
}
