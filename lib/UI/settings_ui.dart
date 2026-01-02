import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mediremind/data/local_file_backend.dart';
import 'package:mediremind/data/types.dart';
import 'package:mediremind/meds.dart';
import 'package:mediremind/notify.dart';
import 'package:flutter/services.dart';

class SettingsUi extends StatelessWidget {
  final MedsManager man;

  const SettingsUi(this.man, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              "Settings",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          Divider(),
          Text(
            "Notifications",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          TextButton(
            onPressed: man.scheduleNotifications,
            child: Text("Reconfigure all Notifications"),
          ),
          TextButton(
            onPressed: () => {NotificationService().resetAll()},
            child: Text("Cancel all scheduled Notifications"),
          ),
          TextButton(
            onPressed: () => {
              NotificationService().showNotification(
                title: "Test Notification",
                body: "test",
              ),
            },
            child: Text("Send test Notification"),
          ),
          Divider(),
          Text("Backup", style: Theme.of(context).textTheme.headlineSmall),

          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: man.exportState()));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Copied!")));
            },
            child: Text("Copy Backup to Clipboard"),
          ),
          TextButton(
            onPressed: () => {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  final controller = TextEditingController();
                  return AlertDialog(
                    actions: [
                      TextButton(
                        onPressed: () {
                          try {
                            man.importState(controller.text);
                            Navigator.of(context).pop();
                          } on Exception {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Invalid backup, could not import",
                                ),
                              ),
                            );
                          }
                        },
                        child: Text("Save"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("Cancel"),
                      ),
                    ],
                    content: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        label: Text("Paste previously exported backup"),
                      ),
                      minLines: 5,
                      maxLines: 10,
                      maxLength: 15000,
                    ),
                  );
                },
              ),
            },
            child: Text("Import Backup"),
          ),
          Divider(),
          Text("Debugging", style: Theme.of(context).textTheme.headlineSmall),

          TextButton(
            onPressed: () {
              List<Med> meds = man.getMeds();
              if (meds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("No meds configured, nothing to serialize"),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Med m = meds[0];
              MedSerializer ms = MedSerializer();
              var jsonObject = jsonEncode(ms.toJson(m), toEncodable: (v) => v);
              Med n = ms.fromJson(jsonDecode(jsonObject));
              n; //aaaa
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Success!")));
            },
            child: Text("Test json serialize/deserialize pipeline"),
          ),
          TextButton(
            onPressed: () => LocalFileBackend().writeAppState(
              AppState(AppState.currentVersion, man.getMeds()),
            ),
            child: Text("write meds to local file"),
          ),
          Divider(),
        ],
      ),
    );
  }
}
