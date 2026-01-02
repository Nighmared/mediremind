import 'package:mediremind/data/types.dart';
import 'package:mediremind/meds.dart';
import 'package:flutter/material.dart';

class _DailyReminderView extends StatelessWidget {
  final int hour;
  final int minute;
  final String remId;
  final _MediConfigState mcs;
  final Function() rebuildParent;

  const _DailyReminderView(
    this.hour,
    this.minute,
    this.remId,
    this.mcs,
    this.rebuildParent,
  );

  void _doSave(TimeOfDay time) {
    mcs.dailyReminders.remove((hour, minute, remId));
    mcs.dailyReminders.add((time.hour, time.minute, remId));
    rebuildParent();
  }

  void _doDelete() {
    mcs.dailyReminders.remove((hour, minute, remId));
    rebuildParent();
  }

  Future<void> _showReminderConfig(
    BuildContext context, [
    bool isCreation = false,
  ]) async {
    var titleText = "Change daily reminder";
    if (isCreation) {
      titleText = "Add daily reminder";
    }

    TimeOfDay? newTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return TimePickerDialog(
          helpText: titleText,
          initialTime: TimeOfDay(hour: hour, minute: minute),
        );
      },
    );
    if (newTime == null) {
      return;
    }
    _doSave(newTime);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        "Daily at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
      ),
      subtitle: Text("Reminder ID:$remId"),
      onTap: () => _showReminderConfig(context),
      trailing: IconButton(
        onPressed: _doDelete,
        icon: Icon(Icons.delete_forever),
      ),
    );
  }
}

class _RefillReminderView extends StatelessWidget {
  final int rem;
  final _MediConfigState mcs;
  final Function() rebuildParent;
  final TextEditingController remControl = TextEditingController();
  final bool isCreate;
  _RefillReminderView(
    this.mcs,
    this.rem,
    this.rebuildParent, [
    this.isCreate = false,
  ]);
  void _doSave(BuildContext context) {
    if (!isCreate) {
      mcs.refillReminders.remove(rem);
    }
    mcs.refillReminders.add(int.parse(remControl.text));
    rebuildParent();
    Navigator.pop(context);
  }

  void _deleteReminder(BuildContext context) {
    mcs.refillReminders.remove(rem);
    rebuildParent();
  }

  Future<void> _showRefillReminderConfig(
    BuildContext context, {
    bool isCreate = false,
  }) {
    var titleText = "Change refill reminder";
    if (isCreate) {
      titleText = "Set new refill reminder";
    }
    remControl.text = rem.toString();
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titleText),
          content: TextField(
            decoration: InputDecoration(
              label: Text("Remind me when _ meds left:"),
            ),
            autofocus: true,
            keyboardType: TextInputType.number,
            controller: remControl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(onPressed: () => _doSave(context), child: Text("Save")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("Remind when $rem meds left"),
      onTap: () => _showRefillReminderConfig(context),
      trailing: IconButton(
        onPressed: () => _deleteReminder(context),
        icon: Icon(Icons.delete_forever),
      ),
    );
  }
}

class _MediConfigState extends State<MediConfig> {
  Med _getMedInstance() {
    return widget.man.getMedFromId(widget.mediID);
  }

  bool initialized = false;
  final nameControl = TextEditingController();
  final doseControl = TextEditingController();
  final amountControl = TextEditingController();
  final Set<(int, int, String)> dailyReminders = {};
  final Set<int> refillReminders = {};
  num amountPerTakeInput = 0;

  void _doSave() {
    if (widget.isCreation) {
      widget.man.addMed(
        Med.create(
          name: nameControl.text,
          numLeft: num.parse(amountControl.text),
          dosage: doseControl.text,
          amountPerTake: amountPerTakeInput,
          refillReminders: refillReminders.map(RefillReminder.new).toList(),
          dailyRemindersRaw: dailyReminders,
        ),
      );
    } else {
      widget.man.applyChanges(
        id: widget.mediID,
        dosage: doseControl.text,
        name: nameControl.text,
        numLeft: double.parse(amountControl.text),
        amountPerTake: amountPerTakeInput,
        dailyRemindersRaw: dailyReminders,
        refillReminders: refillReminders.map(RefillReminder.new).toList(),
      );
    }
    widget.onSaveDone();
  }

  @override
  Widget build(BuildContext context) {
    var lastTaken = "never";
    var headText = "";
    if (widget.isCreation) {
      if (!initialized) {
        headText = "Creating new Med";
        nameControl.text = "";
        doseControl.text = "";
        amountControl.text = "";
        amountPerTakeInput = 1.0;
        dailyReminders.clear();
        refillReminders.clear();
        initialized = true;
      }
    } else {
      if (!initialized) {
        var inst = _getMedInstance();
        headText = "Settings for ${inst.name} ${inst.dosage}";
        nameControl.text = inst.name;
        doseControl.text = inst.dosage;
        amountControl.text = inst.numLeft.toString();
        amountPerTakeInput = inst.amountPerTake;
        dailyReminders.clear();
        dailyReminders.addAll(
          inst.dailyReminders.map((r) => (r.hour, r.minute, r.id)),
        );
        refillReminders.clear();
        refillReminders.addAll(inst.refillReminders.map((r) => r.remindAtLeft));
        if (inst.takes.isNotEmpty) {
          lastTaken = inst.takes.last.date.toString();
        }
        initialized = true;
      }
    }

    List<DropdownMenuEntry<num>> numPerTakeOptions = [];
    for (num i = 0.25; i <= 5; i += 0.25) {
      numPerTakeOptions.add(DropdownMenuEntry(value: i, label: i.toString()));
    }

    return Padding(
      padding: EdgeInsets.all(20),
      child: ListView(
        children:
            [
              Text(headText, style: Theme.of(context).textTheme.headlineMedium),
              TextField(
                controller: nameControl,
                decoration: InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: doseControl,
                decoration: InputDecoration(labelText: "Dosage"),
              ),
              TextField(
                controller: amountControl,
                decoration: InputDecoration(labelText: "# Left"),
                keyboardType: TextInputType.numberWithOptions(
                  signed: false,
                  decimal: true,
                ),
              ),
              Divider(),
              Row(
                children: [
                  Text("Amount per Take: "),
                  Spacer(),
                  DropdownMenu<num>(
                    dropdownMenuEntries: numPerTakeOptions,
                    initialSelection: amountPerTakeInput,
                    onSelected: (value) {
                      amountPerTakeInput = value!;
                    },
                  ),
                ],
              ),
              Divider(),
              Text("Reminders", style: Theme.of(context).textTheme.titleLarge),
              Divider(),
              Text(
                "Medication Reminders",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ] +
            <Widget>[] +
            dailyReminders
                .map(
                  (dr) => _DailyReminderView(
                    dr.$1,
                    dr.$2,
                    dr.$3,
                    this,
                    () => setState(() {}),
                  ),
                )
                .toList() +
            [
              ListTile(
                tileColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(20),
                ),
                trailing: Icon(Icons.add),
                title: Text("Add a medication reminder"),
                onTap: () => _DailyReminderView(
                  10,
                  10,
                  uuid.v4(),
                  this,
                  () => setState(() {}),
                )._showReminderConfig(context, true),
              ),

              Divider(),
              Text(
                "Refill Reminders",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ] +
            <Widget>[] +
            refillReminders
                .map((r) => _RefillReminderView(this, r, () => setState(() {})))
                .toList() +
            [
              ListTile(
                tileColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(20),
                ),
                trailing: Icon(Icons.add),
                title: Text("Add a refill reminder"),
                onTap: () => _RefillReminderView(
                  this,
                  10,
                  () => setState(() {}),
                  true,
                )._showRefillReminderConfig(context, isCreate: true),
              ),

              Divider(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Last Taken: $lastTaken",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

              Divider(),
              IconButton(
                onPressed: () {
                  _doSave();
                  Navigator.pop(context);
                },
                icon: Icon(Icons.save),
              ),
            ],
      ),
    );
  }
}

class MediConfig extends StatefulWidget {
  final String mediID;
  final bool isCreation;
  final MedsManager man;
  final Function() onSaveDone;

  const MediConfig(
    this.mediID,
    this.man,
    this.onSaveDone,
    this.isCreation, {
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _MediConfigState();
  }
}

class _MediState extends State<MediWidget> {
  Med _getMedInstance() {
    return widget.mman.getMedFromId(widget.mediID);
  }

  void _refillMed(int amount) {
    setState(() {
      widget.mman.refillMed(_getMedInstance(), amount);
    });
  }

  void _delMed() {
    widget.mman.deleteMedFromId(widget.mediID);
    widget.rebuildParent();
  }

  final refillController = TextEditingController();

  Future<void> _showRefillDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Refill for ${_getMedInstance().name}"),
          content: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  controller: refillController,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _refillMed(int.parse(refillController.text));
                refillController.clear();
                Navigator.pop(context);
              },
              child: Text("Submit"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Medication"),
          actions: [
            TextButton(
              onPressed: () {
                _delMed();
                Navigator.pop(context);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Med instance = _getMedInstance();
    List<Widget> rowChildren = [Text("${instance.numLeft} left")];

    if (instance.needsRefill()) {
      rowChildren.add(
        Text("Needs Refill", style: TextStyle(color: Colors.red)),
      );
    }

    return ListTile(
      title: Text("${_getMedInstance().name} ${_getMedInstance().dosage}"),
      subtitle: Row(spacing: 50, children: rowChildren),
      trailing: PopupMenuButton(
        itemBuilder: (BuildContext ctx) => <PopupMenuEntry>[
          PopupMenuItem(
            child: Text("Refill"),
            onTap: () => _showRefillDialog(context),
          ),
          PopupMenuItem(
            child: Text("Delete", style: TextStyle(color: Colors.red)),
            onTap: () => _showDeleteDialog(context),
          ),
        ],
        icon: Icon(Icons.more_horiz),
      ),
      onTap: () => MedUI.showConfig(
        context,
        widget.mediID,
        widget.mman,
        () => {setState(() {})},
        false,
      ),
    );
  }
}

class MediWidget extends StatefulWidget {
  final String mediID;
  final MedsManager mman;
  final Function() rebuildParent;
  const MediWidget({
    super.key,
    required this.mediID,
    required this.mman,
    required this.rebuildParent,
  });

  @override
  State<MediWidget> createState() => _MediState();
}

class MedUI extends StatelessWidget {
  final MedsManager man;
  const MedUI({super.key, required this.man});

  @override
  Widget build(BuildContext context) {
    var meds = man.getMeds();
    List<Widget> ays = meds
        .map(
          (e) => MediWidget(
            mediID: e.id,
            mman: man,
            rebuildParent: () {
              (context as Element).markNeedsBuild();
            },
          ),
        )
        .toList();

    return ListView(children: ays);
  }

  static Future<void> showConfig(
    BuildContext ctxt,
    String mediID,
    MedsManager mman,
    Function() onClose,
    bool isCreation,
  ) {
    return showDialog<void>(
      context: ctxt,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: MediConfig(mediID, mman, onClose, isCreation),
        );
      },
    );
  }
}
