import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/audio_player_provider.dart';
import 'screens/spotify_shell.dart';

void main() {
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
      home: const SpotifyShell(),
    );
  }
}
