import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:camera/camera.dart';

import 'screens/screens.dart';
import 'services/services.dart';

List<CameraDescription> cameras = [];
CameraDescription firstCamera;

// Runs app
Future<void> main() async {
  try {
    // Ensures all plugins services are initialized before runApp()
    WidgetsFlutterBinding.ensureInitialized();

    // gets all available cameras
    cameras = await availableCameras();

    // selects the first camera, which is the rear one
    firstCamera = cameras.first;
  } on CameraException catch (e) {
    print(e.code + ' ' + e.description); // Prints error to console
  }

  // Finally runs app
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Wrap MaterialApp in a MultiProvider that provides the user that's logged in
    // this way the data of the user is always asynchronously refreshed and
    // served on demand to any screen.
    return MultiProvider(
      providers: [
        StreamProvider<FirebaseUser>.value(value: AuthService().user)
      ],
      
      child: MaterialApp(
        title: 'Inventory App',

        // Enable analytics
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics())
        ],

        // The default theme for the whole app
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'Nunito',
          primaryColor: activeColor
        ),

        // The routes to all screens
        routes: {
          '/': (context) => LoginScreen(),
          '/equipment': (context) => EquipmentScreen(),
          '/students': (context) => StudentsScreen(),
          '/borrowed': (context) => BorrowedScreen(),
        }
      )
    );
  }
}
