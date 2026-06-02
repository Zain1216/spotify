import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/audio_player_provider.dart';
import '../models/song_model.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);
    final songs = playerProvider.likedSongs;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // Banner App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => playerProvider.navigateTo('home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF512DA8).withOpacity(0.8),
                      const Color(0xFF121212),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Liked Songs Heart Art
                    Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF450E71), Color(0xFFC08DF4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Metadata
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PLAYLIST',
                            style: GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Liked Songs',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'You',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.circle, size: 4, color: Colors.white70),
                              const SizedBox(width: 8),
                              Text(
                                '${songs.length} songs',
                                style: GoogleFonts.outfit(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Control Button Section
          if (songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    // Play button
                    GestureDetector(
                      onTap: () {
                        playerProvider.play(
                          songs[0],
                          fromPlaylist: Playlist(
                            id: 'liked',
                            name: 'Liked Songs',
                            description: '',
                            coverUrl: '',
                            songs: songs,
                          ),
                        );
                      },
                      child: Container(
                        height: 56,
                        width: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1DB954),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white70, size: 28),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white70, size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

          // Header row for song list
          if (songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                child: DefaultTextStyle(
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold),
                  child: const Row(
                    children: [
                      SizedBox(width: 30, child: Text('#')),
                      Expanded(flex: 3, child: Text('TITLE')),
                      Expanded(flex: 2, child: Text('ALBUM')),
                      SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: Text('DURATION'))),
                    ],
                  ),
                ),
              ),
            ),
          if (songs.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Divider(color: Colors.white10),
              ),
            ),

          // Songs list
          songs.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.music_note, color: Colors.white24, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Songs you like will appear here',
                          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => playerProvider.navigateTo('home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Find Songs'),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      final isCurrentPlaying = playerProvider.currentSong?.id == song.id;

                      return InkWell(
                        onTap: () {
                          playerProvider.play(
                            song,
                            fromPlaylist: Playlist(
                              id: 'liked',
                              name: 'Liked Songs',
                              description: '',
                              coverUrl: '',
                              songs: songs,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                          child: Row(
                            children: [
                              // Track index / Play icon
                              SizedBox(
                                width: 30,
                                child: isCurrentPlaying
                                    ? const Icon(Icons.volume_up, color: Color(0xFF1DB954), size: 18)
                                    : Text(
                                        '${index + 1}',
                                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
                                      ),
                              ),
                              // Title / Artist / Image
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        image: DecorationImage(
                                          image: NetworkImage(song.coverUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.title,
                                            style: GoogleFonts.outfit(
                                              color: isCurrentPlaying ? const Color(0xFF1DB954) : Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            song.artist,
                                            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Album
                              Expanded(
                                flex: 2,
                                child: Text(
                                  song.album,
                                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Like Button & Duration
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      song.isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: song.isLiked ? const Color(0xFF1DB954) : Colors.white60,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      playerProvider.toggleLike(song);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 60,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _formatDuration(song.duration),
                                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          )
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString();
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
