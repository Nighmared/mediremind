import 'package:mediremind/data/types.dart';
import 'package:mediremind/meds.dart';
import 'package:flutter/material.dart';

class _MediConfigState extends State<MediConfig> {
  Med _getMedInstance() {
    return widget.man.getMedFromId(widget.mediID);
  }

  final nameControl = TextEditingController();
  final doseControl = TextEditingController();
  final amountControl = TextEditingController();
  final List<(int, int, String)> dailyreminders = [];
  num amountPerTakeInput = 0;

  void _doSave() {
    if (widget.isCreation) {
      widget.man.addMed(
        Med.create(
          name: nameControl.text,
          numLeft: num.parse(amountControl.text),
          dosage: doseControl.text,
          amountPerTake: amountPerTakeInput,
          refillReminders: [],
          dailyRemindersRaw: dailyreminders,
        ),
      );
    } else {
      widget.man.applyChanges(
        id: widget.mediID,
        dosage: doseControl.text,
        name: nameControl.text,
        numLeft: double.parse(amountControl.text),
        amountPerTake: amountPerTakeInput,
        dailyRemindersRaw: dailyreminders,
      );
    }
    widget.onSaveDone();
  }

  @override
  Widget build(BuildContext context) {
    var lastTaken = "never";
    var headText = "";
    if (widget.isCreation) {
      headText = "Creating new Med";
      nameControl.text = "";
      doseControl.text = "";
      amountControl.text = "";
      amountPerTakeInput = 1.0;
    } else {
      var inst = _getMedInstance();
      headText = "Settings for ${inst.name} ${inst.dosage}";
      nameControl.text = inst.name;
      doseControl.text = inst.dosage;
      amountControl.text = inst.numLeft.toString();
      amountPerTakeInput = inst.amountPerTake;
      dailyreminders.clear();
      dailyreminders.addAll(
        inst.dailyReminders.map((r) => (r.hour, r.minute, r.id)),
      );
      if (inst.takes.isNotEmpty) {
        lastTaken = inst.takes.last.date.toString();
      }
    }

    List<DropdownMenuEntry<num>> numPerTakeOptions = [];
    for (num i = 0.25; i <= 5; i += 0.25) {
      numPerTakeOptions.add(DropdownMenuEntry(value: i, label: i.toString()));
    }

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
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
          Text("Reminders"),
          Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "Last Taken: $lastTaken",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),

          Divider(),
          FloatingActionButton(
            onPressed: () {
              _doSave();
              Navigator.pop(context);
            },
            child: Icon(Icons.save),
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
