import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:moc_firebase/analytics/analytics_provider.dart';
import 'package:moc_firebase/analytics/firebase_analytics_handler.dart';
import 'package:moc_firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnalyticsProvider(
      handlers: [
        FirebaseAnalyticsHandler(),
      ],
      child: MaterialApp(
        title: 'MOC Firebase',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    // Callback pour appeler une fonction après le premier build du widget (après l'init)
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() async {
    await AnalyticsProvider.of(context).setUserProperty('user_name', 'Timo');
    if (mounted) {
      await AnalyticsProvider.of(context).setUserProperty('user_height', '181');
    }

  }

  void _incrementCounter() async {
    await AnalyticsProvider.of(context).logEvent('counter_incremented', {'counter': _counter});

    FirebaseAnalytics.instance.logEvent(
      name: 'counter_incremented',
      parameters: {'counter': _counter},
    );
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              try {
                await Future.delayed(const Duration(seconds: 1));
                throw Exception('coucou');
              } catch(error) {
                // Prévoir le crash dans le catch ET le logger sans faire crasher l'app !!
                FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
                // FirebaseCrashlytics.instance.setUserIdentifier(identifier);
              }

            },
            tooltip: 'Increment',
            child: const Icon(Icons.car_crash),
          ),
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
        ]
      ),
    );
  }
}
