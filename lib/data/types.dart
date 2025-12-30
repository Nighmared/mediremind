import 'package:mediremind/notify.dart';
import 'package:uuid/uuid.dart';

abstract class Serializer<T> {
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T o);
}

// types of reminders:
// - daily
// - certain weekdays
// - every n days
// - repeating cycle [lets ignore for now aaa]

var uuid = Uuid();

abstract class Reminder<T> implements Comparable {
  bool happensToday();
  (int hour, int minute) nextTimeOfDay();
  abstract final String medID;
  abstract final String id;
}

class DailyReminderSerializer implements Serializer<DailyReminder> {
  @override
  DailyReminder fromJson(Map<String, dynamic> json) {
    return DailyReminder._internal(
      json["id"],
      json["medID"],
      json["numTimes"],
      json["timesTaken"],
      json["hour"],
      json["minute"],
    );
  }

  @override
  Map<String, dynamic> toJson(DailyReminder o) => {
    "id": o.id,
    "medID": o._medID,
    "hour": o.hour,
    "minute": o.minute,
    "timesTaken": o.timesTaken,
    "numTimes": o.numTimes,
  };
}

class DailyReminder implements Reminder<DailyReminder> {
  @override
  final String id;
  int numTimes = -1;
  int timesTaken = 0;
  int hour;
  int minute;
  final String _medID;
  DailyReminder._internal(
    this.id,
    this._medID,
    this.numTimes,
    this.timesTaken,
    this.hour,
    this.minute,
  );
  DailyReminder(this._medID, this.hour, this.minute) : id = uuid.v4();
  DailyReminder.withID(this._medID, this.hour, this.minute, this.id);

  DateTime? getNext() {
    if (numTimes > 0 && numTimes < timesTaken) {
      return null;
    }
    return DateTime.now();
  }

  @override
  bool happensToday() {
    if (numTimes > 0) {
      //if limited number of times, do check, else daily reminder happens on all days
      return numTimes > timesTaken;
    }
    return true; //is daily!
  }

  void scheduleNotif(Med med) {
    NotificationService().scheduleDailyNotification(
      title: med._getNotifTitle(),
      body: med._getNotifBody(),
      hour: hour,
      minute: minute,
    );
  }

  @override
  String get medID => _medID;

  @override
  int compareTo(other) {
    var a = getNext();
    var b = other.getNext();
    return a!.compareTo(b);
  }

  @override
  (int, int) nextTimeOfDay() {
    return (hour, minute);
  }
}

class RefillReminderSerializer implements Serializer<RefillReminder> {
  @override
  RefillReminder fromJson(Map<String, dynamic> json) =>
      RefillReminder(json["remindAtLeft"]);

  @override
  Map<String, dynamic> toJson(RefillReminder o) => {
    "remindAtLeft": o.remindAtLeft,
  };
}

class RefillReminder {
  int remindAtLeft;
  RefillReminder(this.remindAtLeft);
}

class TakeSerializer implements Serializer<Take> {
  @override
  Take fromJson(Map<String, dynamic> json) {
    return Take(
      DateTime.fromMillisecondsSinceEpoch(json["date"]),
      json["amount"] as num,
      json["reminderID"],
    );
  }

  @override
  Map<String, dynamic> toJson(Take o) => {
    "date": o.date.millisecondsSinceEpoch,
    "amount": o.amount,
    "reminderID": o.reminderID,
  };
}

class Take {
  DateTime date;
  num amount;
  String reminderID;
  Take(this.date, this.amount, this.reminderID);
  Take.now(this.amount, this.reminderID) : date = DateTime.now();
}

class RefillSerializer implements Serializer<Refill> {
  @override
  Refill fromJson(Map<String, dynamic> json) =>
      Refill(DateTime.fromMillisecondsSinceEpoch(json["date"]), json["amount"]);

  @override
  Map<String, dynamic> toJson(Refill o) => {
    "date": o.date.millisecondsSinceEpoch,
    "amount": o.amount,
  };
}

class Refill {
  final DateTime date;
  final int amount;
  Refill(this.date, this.amount);

  Refill.now(this.amount) : date = DateTime.now();
}

List<T> _parseListOfJsonObjects<T>(List<dynamic> ls, Serializer<T> s) {
  return List<Map<String, dynamic>>.from(ls).map(s.fromJson).toList();
}

class MedSerializer implements Serializer<Med> {
  @override
  Med fromJson(Map<String, dynamic> json) {
    return Med(
      id: json["id"],
      name: json["name"],
      dosage: json["dosage"],
      numLeft: json["numLeft"],
      amountPerTake: json["amountPerTake"],
      dailyReminders: _parseListOfJsonObjects(
        json["dailyReminders"],
        DailyReminderSerializer(),
      ),
      refills: _parseListOfJsonObjects(json["refills"], RefillSerializer()),
      refillReminders: _parseListOfJsonObjects(
        json["refillReminders"],
        RefillReminderSerializer(),
      ),
      takes: _parseListOfJsonObjects(json["takes"], TakeSerializer()),
    );
  }

  @override
  Map<String, dynamic> toJson(Med o) {
    final drs = DailyReminderSerializer();
    final rfs = RefillSerializer();
    final rrs = RefillReminderSerializer();
    final tas = TakeSerializer();

    return {
      "id": o.id,
      "name": o.name,
      "dosage": o.dosage,
      "amountPerTake": o.amountPerTake,
      "numLeft": o.numLeft,
      "dailyReminders": o.dailyReminders.map((r) => drs.toJson(r)).toList(),
      "refills": o.refills.map((r) => rfs.toJson(r)).toList(),
      "refillReminders": o.refillReminders.map((r) => rrs.toJson(r)).toList(),
      "takes": o.takes.map((t) => tas.toJson(t)).toList(),
    };
  }
}

class Med {
  final String id;
  final String name;
  final String dosage;
  final num amountPerTake;
  final num numLeft;
  final List<DailyReminder> dailyReminders;
  final List<RefillReminder> refillReminders;
  final List<Take> takes;
  final List<Refill> refills;

  Med({
    required this.id,
    required this.name,
    required this.dosage,
    required this.numLeft,
    required this.amountPerTake,
    required this.dailyReminders,
    required this.refills,
    required this.refillReminders,
    required this.takes,
  });

  String _getNotifTitle() {
    return "Time to take your meds!";
  }

  String _getNotifBody() {
    return "Take $amountPerTake of $name $dosage";
  }

  factory Med.of({
    required Med old,
    String? name,
    String? dosage,
    num? numLeft,
    num? amountPerTake,
    List<DailyReminder>? dailyReminders,
    List<Refill>? refills,
    List<RefillReminder>? refillReminders,
    List<Take>? takes,
  }) {
    return Med(
      id: old.id,
      name: name ?? old.name,
      dosage: dosage ?? old.dosage,
      numLeft: numLeft ?? old.numLeft,
      amountPerTake: amountPerTake ?? old.amountPerTake,
      dailyReminders: dailyReminders ?? old.dailyReminders,
      refills: refills ?? old.refills,
      refillReminders: refillReminders ?? old.refillReminders,
      takes: takes ?? old.takes,
    );
  }

  factory Med.create({
    required String name,
    required String dosage,
    required num numLeft,
    required List<RefillReminder> refillReminders,
    required Iterable<(int hour, int minute, String remId)> dailyRemindersRaw,
    num amountPerTake = 1.0,
  }) {
    String newMedId = uuid.v4();
    return Med(
      id: newMedId,
      name: name,
      dosage: dosage,
      numLeft: numLeft,
      amountPerTake: amountPerTake,
      dailyReminders: dailyRemindersRaw
          .map((dr) => DailyReminder.withID(newMedId, dr.$1, dr.$2, dr.$3))
          .toList(),

      refillReminders: refillReminders,
      takes: [],
      refills: [],
    );
  }

  bool needsRefill() {
    for (var r in refillReminders) {
      if (numLeft <= r.remindAtLeft) {
        return true;
      }
    }
    return false;
  }
}
