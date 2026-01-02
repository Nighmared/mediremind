import 'package:mediremind/data/interfaces.dart';
import 'package:mediremind/data/types.dart';

class GenericRepo implements MedRepo {
  late AppState _appState;
  final Map<String, int> _medsIndexCache;
  final StorageBackend _backend;
  bool initialized = false;

  GenericRepo._internal(this._backend, this._medsIndexCache);

  void _setAppState(AppState as) {
    _appState = as;
    initialized = true;
  }

  factory GenericRepo(
    StorageBackend backend, [
    Function()? doneReadingCallback,
  ]) {
    Map<String, int> indexCache = {};
    Future<AppState> futureState = backend.readAppState();

    final newRepo = GenericRepo._internal(backend, indexCache);
    futureState.then((state) {
      newRepo._setAppState(state);
      int stateMedLen = state.meds.length;
      Med m;
      for (int i = 0; i < stateMedLen; i++) {
        m = state.meds[i];
        indexCache[m.id] = i;
      }
      doneReadingCallback?.call();
    });
    return newRepo;
  }

  @override
  List<Med> getMeds() {
    if (!initialized) {
      throw NotReadyError();
    }
    return _appState.meds;
  }

  @override
  Med getMed(String key) {
    if (!initialized) {
      throw NotReadyError();
    }
    assert(_medsIndexCache.containsKey(key));
    return _appState.meds[_medsIndexCache[key] as int];
  }

  @override
  void addMed(Med med) {
    if (!initialized) {
      throw NotReadyError();
    }
    assert(!_medsIndexCache.containsKey(med.id));
    _medsIndexCache[med.id] = _appState.meds.length;
    _appState.meds.add(med);

    _backend.writeAppState(_appState);
  }

  @override
  void delMed(Med med) {
    if (!initialized) {
      throw NotReadyError();
    }
    int? targetIndx = _medsIndexCache[med.id];
    _medsIndexCache.remove(med.id);
    _appState.meds.removeAt(targetIndx!);
    _backend.writeAppState(_appState);
  }

  @override
  void updateMed(String key, Med med) {
    if (!initialized) {
      throw NotReadyError();
    }
    _appState.meds[_medsIndexCache[key]!] = med;
    _backend.writeAppState(_appState);
  }

  @override
  AppState getState() {
    return _appState;
  }

  void _rebuild(AppState as) {
    _appState = as;
    _medsIndexCache.clear();
    final medsLen = as.meds.length;
    for (int i = 0; i < medsLen; i++) {
      _medsIndexCache[as.meds[i].id] = i;
    }
  }

  @override
  void writeState(AppState newState) {
    _backend.writeAppState(newState);
    _rebuild(newState);
  }
}
