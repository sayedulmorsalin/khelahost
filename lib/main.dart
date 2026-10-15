import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/firebase_options.dart';
import 'package:khelahost/screens/auth_screen.dart';
import 'package:khelahost/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mobile-only UI orientation and overlay styles
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.bgDeep,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // Initialize Firebase safely across all platforms
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const KhelaHostApp());
}

class KhelaHostApp extends StatelessWidget {
  const KhelaHostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KhelaHost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}

/// Listens to Firebase auth state and routes to the correct screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While waiting for the auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.bgDeep,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        // Signed in (email or anonymous guest)
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // Not signed in
        return const AuthScreen();
      },
    );
  }
}
