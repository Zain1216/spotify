import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/audio_player_provider.dart';
import '../models/song_model.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'liked_songs_screen.dart';
import 'playlist_detail_screen.dart';
import '../widgets/lyrics_panel.dart';

class SpotifyShell extends StatelessWidget {
  const SpotifyShell({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);

    // If lyrics panel is toggled on, overlay it fullscreen
    if (playerProvider.showLyrics) {
      return const LyricsPanel();
    }

    Widget bodyWidget;
    switch (playerProvider.currentScreen) {
      case 'search':
        bodyWidget = const SearchScreen();
        break;
      case 'library':
        bodyWidget = const LikedSongsScreen();
        break;
      case 'playlist_detail':
        bodyWidget = const PlaylistDetailScreen();
        break;
      case 'home':
      default:
        bodyWidget = const HomeScreen();
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Navigation Sidebar
                _buildSidebar(context, playerProvider),
                // Main Content View
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: bodyWidget,
                  ),
                ),
              ],
            ),
          ),
          // Bottom Player Bar
          _buildPlayerBar(context, playerProvider),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AudioPlayerProvider provider) {
    return Container(
      width: 240,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.radio, color: Color(0xFF1DB954), size: 36),
                const SizedBox(width: 10),
                Text(
                  'Spotify',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main Tabs Container
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildSidebarTile(
                  icon: Icons.home_filled,
                  title: 'Home',
                  isActive: provider.currentScreen == 'home',
                  onTap: () => provider.navigateTo('home'),
                ),
                _buildSidebarTile(
                  icon: Icons.search,
                  title: 'Search',
                  isActive: provider.currentScreen == 'search',
                  onTap: () => provider.navigateTo('search'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Library & Custom Playlists Container
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.library_music_outlined, color: Colors.white60, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              'Your Library',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white60, size: 20),
                          onPressed: () => _showCreatePlaylistDialog(context, provider),
                        ),
                      ],
                    ),
                  ),

                  // Shortcuts: Liked Songs
                  _buildSidebarTile(
                    icon: Icons.favorite,
                    title: 'Liked Songs',
                    isActive: provider.currentScreen == 'library',
                    iconColor: const Color(0xFF1DB954),
                    onTap: () => provider.navigateTo('library'),
                  ),

                  const Divider(color: Colors.white10, height: 16),

                  // Custom Playlists Scrollable List
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = provider.playlists[index];
                        final isSelected = provider.currentScreen == 'playlist_detail' &&
                            provider.selectedPlaylist?.id == playlist.id;

                        return ListTile(
                          onTap: () {
                            provider.navigateTo('playlist_detail', playlist: playlist);
                          },
                          dense: true,
                          leading: Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              image: DecorationImage(
                                image: NetworkImage(playlist.coverUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(
                            playlist.name,
                            style: GoogleFonts.outfit(
                              color: isSelected ? const Color(0xFF1DB954) : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            playlist.creator,
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? Colors.white : (iconColor ?? Colors.white60),
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: isActive ? Colors.white : Colors.white60,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildPlayerBar(BuildContext context, AudioPlayerProvider provider) {
    final song = provider.currentSong;

    return Container(
      height: 90,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Current Song Info
          Expanded(
            flex: 3,
            child: song == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(song.coverUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist,
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          song.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: song.isLiked ? const Color(0xFF1DB954) : Colors.white60,
                          size: 20,
                        ),
                        onPressed: () => provider.toggleLike(song),
                      ),
                    ],
                  ),
          ),

          // Center: Player Controls
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: provider.isShuffle ? const Color(0xFF1DB954) : Colors.white60,
                        size: 20,
                      ),
                      onPressed: () => provider.toggleShuffle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white60, size: 24),
                      onPressed: () => provider.previous(),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => provider.togglePlay(),
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          provider.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white60, size: 24),
                      onPressed: () => provider.next(),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.repeat,
                        color: provider.isRepeat ? const Color(0xFF1DB954) : Colors.white60,
                        size: 20,
                      ),
                      onPressed: () => provider.toggleRepeat(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Progress slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(provider.position),
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          ),
                          child: Slider(
                            min: 0,
                            max: provider.duration.inMilliseconds.toDouble(),
                            value: provider.position.inMilliseconds.toDouble().clamp(
                                  0.0,
                                  provider.duration.inMilliseconds.toDouble(),
                                ),
                            onChanged: (val) {
                              provider.seek(Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(provider.duration),
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Options & Volume
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.lyrics_outlined, color: Colors.white60, size: 20),
                  onPressed: () => provider.toggleLyrics(),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.white60, size: 20),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 100,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF1DB954),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    ),
                    child: Slider(
                      value: provider.volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) {
                        provider.setVolume(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, AudioPlayerProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: Text('Create Playlist', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'My Playlist #1',
              hintStyle: TextStyle(color: Colors.white30),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1DB954))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim().isEmpty ? 'My Playlist' : controller.text.trim();
                provider.createPlaylist(name);
                Navigator.pop(context);
              },
              child: const Text('Create', style: TextStyle(color: Color(0xFF1DB954))),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString();
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
