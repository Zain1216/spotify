import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/audio_player_provider.dart';

class LyricsPanel extends StatelessWidget {
  const LyricsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final song = playerProvider.currentSong;

    if (song == null) {
      return Container(
        color: const Color(0xFF121212),
        child: const Center(
          child: Text(
            'No song playing',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ),
      );
    }

    // Custom lyrics generated based on the song name
    final List<String> lyrics = _getMockLyrics(song.title, song.artist);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred backdrop matching song cover
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(song.coverUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
            child: Container(
              color: Colors.black.withOpacity(0.75),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            style: GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => playerProvider.toggleLyrics(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white12,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white10, height: 1),

                // Lyrics list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24.0),
                    itemCount: lyrics.length,
                    itemBuilder: (context, index) {
                      final isMiddle = index == lyrics.length ~/ 2 - 1 || index == lyrics.length ~/ 2;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          lyrics[index],
                          style: GoogleFonts.outfit(
                            color: isMiddle ? const Color(0xFF1DB954) : Colors.white70,
                            fontSize: isMiddle ? 32 : 26,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getMockLyrics(String title, String artist) {
    return [
      "[Intro]",
      "Yeah, this is a special journey...",
      "Feeling the rhythm, chasing the lights,",
      "Lost in the sound of these endless nights.",
      "",
      "[Verse 1]",
      "We started simple, just a melody in the dark,",
      "A single matchbox waiting for a spark.",
      "Now the bass is bumping, echoing in my head,",
      "Every word remembered, every story said.",
      "Watching the sunset turning into neon gold,",
      "It is the greatest tale that was ever told.",
      "",
      "[Chorus]",
      "Oh, can you hear the waves crashing down?",
      "We are the rulers of this techno town.",
      "Just play it louder, let the speakers blow,",
      "We have nowhere to rush, nowhere else to go.",
      "Yeah, we are riding on the sonic waves,",
      "Dancing through the night, outlasting all the days.",
      "",
      "[Verse 2]",
      "Midnight city vibes, streets are shiny wet,",
      "Moments in the music we will never forget.",
      "Turn the volume higher, feel it in your chest,",
      "This is our release, this is where we rest.",
      "",
      "[Outro]",
      "Let the melody fade, let the drums go low,",
      "Just the heartbeat left, moving soft and slow...",
      "Yeah, that is how it goes.",
    ];
  }
}
