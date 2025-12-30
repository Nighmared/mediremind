import 'package:mediremind/data/interfaces.dart';
import 'package:uuid/uuid.dart';
import 'types.dart';

class TestBackend implements StorageBackend {
  final List<Med> _meds;
  TestBackend._internal(this._meds);
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
    return TestBackend._internal(meds);
  }

  @override
  void writeMeds(Iterable<Med> meds) {
    _meds.clear();
    for (var m in meds) {
      _meds.add(m);
    }
  }

  @override
  Future<List<Med>> readMeds() {
    return Future<List<Med>>.value(_meds);
  }
}
