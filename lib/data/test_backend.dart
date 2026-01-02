import 'package:mediremind/data/interfaces.dart';
import 'package:uuid/uuid.dart';
import 'types.dart';

class TestBackend implements StorageBackend {
  AppState _as;
  TestBackend._internal(this._as);
  static final Uuid uuid = Uuid();

  factory TestBackend() {
    var meds = [
      Med.create(
        name: "Concerta",
        dosage: "27mg",
        numLeft: 10,
        refillReminders: [RefillReminder(20), RefillReminder(10)],
        dailyRemindersRaw: [(8, 0, uuid.v4())],
      ),
      Med.create(
        name: "Paracetamol",
        dosage: "1kg",
        numLeft: 50,
        refillReminders: [RefillReminder(10)],
        dailyRemindersRaw: [],
      ),
    ];
    return TestBackend._internal(AppState(AppVersion.v1, meds));
  }

  @override
  void writeAppState(AppState as) {
    _as = AppState(as.version, List.from(as.meds));
  }

  @override
  Future<AppState> readAppState() {
    return Future<AppState>.value(_as);
  }
}
