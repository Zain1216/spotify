import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/audio_player_provider.dart';
import '../models/song_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);

    // Get time-based greeting
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 18) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E3C72).withOpacity(0.5),
                const Color(0xFF121212),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              // Top navigation header bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        greeting,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: Colors.white),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.history, color: Colors.white),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'logout') {
                              playerProvider.logout();
                            }
                          },
                          color: const Color(0xFF282828),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white12,
                            child: Text(
                              (playerProvider.currentUser?.email ?? 'G')[0].toUpperCase(),
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'email',
                              enabled: false,
                              child: Text(
                                playerProvider.currentUser?.email ?? 'Guest User',
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Log Out', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Grid of 6 quick playlist options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3.2,
                  ),
                  itemCount: playerProvider.playlists.length > 6 ? 6 : playerProvider.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playerProvider.playlists[index];
                    return _buildQuickCard(context, playlist, playerProvider);
                  },
                ),
              ),
              const SizedBox(height: 36),

              // Recently Played horizontal list
              _buildCategorySection(
                context,
                title: 'Recently Played',
                playlists: playerProvider.playlists,
                playerProvider: playerProvider,
              ),
              const SizedBox(height: 36),

              // Recommended for You section
              _buildCategorySection(
                context,
                title: 'Recommended for You',
                playlists: playerProvider.playlists.reversed.toList(),
                playerProvider: playerProvider,
              ),
              const SizedBox(height: 100), // Player buffer
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCard(BuildContext context, Playlist playlist, AudioPlayerProvider provider) {
    return InkWell(
      onTap: () {
        provider.navigateTo('playlist_detail', playlist: playlist);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Cover Art
            AspectRatio(
              aspectRatio: 1.0,
              child: Image.network(
                playlist.coverUrl,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                playlist.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Play Button
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: provider.currentPlaylist?.id == playlist.id && provider.isPlaying
                  ? _buildPlayButton(provider, playlist, isPlaying: true)
                  : _buildPlayButton(provider, playlist, isPlaying: false),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(AudioPlayerProvider provider, Playlist playlist, {required bool isPlaying}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (playlist.songs.isNotEmpty) {
            if (isPlaying) {
              provider.pause();
            } else {
              provider.play(playlist.songs[0], fromPlaylist: playlist);
            }
          }
        },
        child: Container(
          height: 40,
          width: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1DB954),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.black,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required String title,
    required List<Playlist> playlists,
    required AudioPlayerProvider playerProvider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Show all',
                style: GoogleFonts.outfit(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return _buildPlaylistCard(context, playlist, playerProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist, AudioPlayerProvider provider) {
    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () {
          provider.navigateTo('playlist_detail', playlist: playlist);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover art with relative stack for play button
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                        image: DecorationImage(
                          image: NetworkImage(playlist.coverUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _buildPlayButton(provider, playlist,
                        isPlaying: provider.currentPlaylist?.id == playlist.id && provider.isPlaying),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                playlist.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Description
              Text(
                playlist.description,
                style: GoogleFonts.outfit(
                  color: Colors.white60,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
