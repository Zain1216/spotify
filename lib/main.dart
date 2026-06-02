import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/audio_player_provider.dart';
import 'screens/spotify_shell.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseService.isInitialized = true;
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    debugPrint("Ensure you configure DefaultFirebaseOptions in lib/firebase_options.dart with your Firebase keys!");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioPlayerProvider(),
      child: const SpotifyCloneApp(),
    ),
  );
}

class SpotifyCloneApp extends StatelessWidget {
  const SpotifyCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotify - Web Player',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF1DB954),
        hintColor: const Color(0xFF1DB954),
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFF1DB954),
          inactiveTrackColor: Colors.white24,
          thumbColor: Colors.white,
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          surface: Color(0xFF121212),
          background: Color(0xFF121212),
          onPrimary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: StreamBuilder<AuthUser?>(
        stream: FirebaseService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1DB954),
                ),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const SpotifyShell();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
