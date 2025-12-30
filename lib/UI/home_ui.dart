import 'package:flutter/material.dart';
import 'package:mediremind/data/types.dart' show Reminder, Med;
import 'package:mediremind/meds.dart';

class HomeUi extends StatelessWidget {
  final MedsManager man;
  const HomeUi(this.man, {super.key});

  bool _sameDay(DateTime now, DateTime take) {
    return (now.year == take.year &&
        now.month == take.month &&
        now.day == take.day);
  }

  ListTile _ReminderToListTile(
    BuildContext ctxt,
    MedsManager man,
    Reminder rem,
  ) {
    var now = DateTime.now();
    Med med = man.getMedFromId(rem.medID);

    var matchTakes = med.takes.where(
      (t) => _sameDay(now, t.date) && t.reminderID == rem.id,
    );
    assert(matchTakes.length <= 1);
    bool taken = matchTakes.isNotEmpty;
    // done with logic
    Widget trailing = TextButton(
      onPressed: () {
        man.takeMed(rem);
        //rebuild home ui
        (ctxt as Element).markNeedsBuild();
      },
      child: Text("Take", style: TextStyle(color: Colors.blue)),
    );
    if (taken) {
      trailing = Text("Already Taken", style: TextStyle(color: Colors.grey));
    }

    var nextTime = rem.nextTimeOfDay();

    return ListTile(
      title: Text("${nextTime.$1}:${nextTime.$2}\n${med.name} "),
      subtitle: Text("Take ${med.amountPerTake} of ${med.name} ${med.dosage}"),
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    var rn = DateTime.now();
    var headline = "${rn.day}.${rn.month}.${rn.year}";

    List<ListTile> reminderTiles = man
        .getTodayMedReminders()
        .map((r) => _ReminderToListTile(context, man, r))
        .toList();

    return Padding(
      padding: EdgeInsets.all(10),
      child: Center(
        child: Column(
          children: [
            Text(headline, style: Theme.of(context).textTheme.headlineLarge),
            Text(
              "Meds scheduled for today:",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Expanded(
              child: ListView(
                children: reminderTiles,
                /* man.getTodayMedTiles(
                  () => {(context as Element).markNeedsBuild()},*/
              ),
            ),
          ],
        ),
      ),
    );
  }
}
