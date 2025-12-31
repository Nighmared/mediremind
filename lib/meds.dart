import 'package:flutter/material.dart';
import 'package:mediremind/data/interfaces.dart';
import 'package:mediremind/data/types.dart';
import 'package:mediremind/notify.dart';

// logic here
class MedsManager {
  MedRepo _repo;

  MedsManager(this._repo);

  void addMed(Med m) {
    _repo.addMed(m);
  }

  void deleteMed(Med m) {
    _repo.delMed(m);
  }

  List<Med> getMeds() {
    return _repo.getMeds();
  }

  void deleteMedFromId(String id) {
    deleteMed(getMedFromId(id));
  }

  void refillMed(Med medi, int amount) {
    final newRefills = medi.refills;
    newRefills.add(Refill.now(amount));
    _repo.updateMed(
      medi.id,
      Med.of(old: medi, refills: newRefills, numLeft: medi.numLeft + amount),
    );
  }

  void checkRefillReminders() {
    List<Med> meds = _repo.getMeds();
    for (var m in meds) {
      for (var r in m.refillReminders) {
        if (m.numLeft <= r.remindAtLeft) {
          NotificationService().showNotification(
            title: "Refill Reminder",
            body: "Get a Refill for ${m.name} ${m.dosage}",
          );
        }
      }
    }
  }

  void takeMed(Reminder rem) {
    Med medi = _repo.getMed(rem.medID);
    final newTakes = medi.takes;
    newTakes.add(Take.now(medi.amountPerTake, rem.id));
    _repo.updateMed(
      medi.id,
      Med.of(
        old: medi,
        takes: newTakes,
        numLeft: medi.numLeft - medi.amountPerTake,
      ),
    );
    checkRefillReminders();
  }

  void _cleanupTakes(Med medi) {
    //delete takes older than 1 month from storage
    var todayOneMonthAgo = DateTime.now().subtract(Duration(days: 31));
    var newTakes = medi.takes.where((t) => t.date.isAfter(todayOneMonthAgo));
    _repo.updateMed(medi.id, Med.of(old: medi, takes: newTakes.toList()));
  }

  Med getMedFromId(String id) {
    return _repo.getMed(id);
  }

  void cleanupTakes() {
    for (var m in _repo.getMeds()) {
      _cleanupTakes(m);
    }
  }

  void applyChanges({
    required String id,
    String? name,
    String? dosage,
    double? numLeft,
    num? amountPerTake,
    Iterable<(int hour, int minute, String remId)> dailyRemindersRaw = const [],
    List<Refill>? refills,
    List<RefillReminder>? refillReminders,
    List<Take>? takes,
  }) {
    final old = getMedFromId(id);
    final newMed = Med.of(
      old: old,
      name: name,
      dosage: dosage,
      numLeft: numLeft,
      amountPerTake: amountPerTake,
      dailyReminders: dailyRemindersRaw
          .map((raw) => DailyReminder.withID(id, raw.$1, raw.$2, raw.$3))
          .toList(),
      refills: refills,
      refillReminders: refillReminders,
      takes: takes,
    );
    _repo.updateMed(id, newMed);
  }

  void scheduleNotifications() {
    NotificationService().resetAll();
    List<Med> meds = _repo.getMeds();
    for (var m in meds) {
      for (var r in m.dailyReminders) {
        r.scheduleNotif(m);
      }
    }
  }

  List<Reminder> getTodayMedReminders() {
    //returns ordered list of all reminders happening today
    List<Med> meds = _repo.getMeds();
    List<Reminder> out = [];
    for (var m in meds) {
      out.addAll(m.dailyReminders.where((rem) => rem.happensToday()));
    }
    return out;
  }
}
