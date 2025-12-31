import 'package:flutter/material.dart';
import 'package:mediremind/UI/home_ui.dart';
import 'package:mediremind/UI/med_ui.dart';
import 'package:mediremind/data/generic_repo.dart';
import 'package:mediremind/data/local_file_backend.dart';
import 'package:mediremind/meds.dart';
import 'package:mediremind/notify.dart';
import 'package:mediremind/UI/settings_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //init notifications
  NotificationService().initNotify();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medi Remind',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.lightGreenAccent),
      ),
      home: const HomePage(title: 'MediRemind'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentDestination = 0;
  MedsManager? man;

  _HomePageState() : _currentDestination = 0;

  @override
  Widget build(BuildContext context) {
    man ??= MedsManager(GenericRepo(LocalFileBackend(), () => setState(() {})));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: "Add Medication",
        onPressed: () => {
          MedUI.showConfig(context, "", man!, () => {setState(() => {})}, true),
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: [
        HomeUi(man!),
        MedUI(man: man!),
        SettingsUi(man!),
      ][_currentDestination],

      bottomNavigationBar: NavigationBar(
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: "Overview",
          ),
          const NavigationDestination(
            icon: Icon(Icons.medication),
            label: "Meds",
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
        selectedIndex: _currentDestination,
        onDestinationSelected: (int value) => {
          setState(() {
            _currentDestination = value;
          }),
        },
      ),
    );
  }
}
