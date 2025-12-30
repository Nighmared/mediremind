import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mediremind/data/local_file_backend.dart';
import 'package:mediremind/data/types.dart';
import 'package:mediremind/meds.dart';
import 'package:mediremind/notify.dart';

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
          Text("Debugging", style: Theme.of(context).textTheme.headlineSmall),

          TextButton(
            onPressed: () {
              Med m = man.getMeds()[0];
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
            onPressed: () => LocalFileBackend().writeMeds(man.getMeds()),
            child: Text("write meds to local file"),
          ),
        ],
      ),
    );
  }
}
