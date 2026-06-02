import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/audio_player_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<AudioPlayerProvider>(context);

    // Sync input field value if query is changed from provider
    if (_searchController.text != playerProvider.searchQuery) {
      _searchController.text = playerProvider.searchQuery;
    }

    final categories = [
      {'title': 'Podcasts', 'color': const Color(0xFF27856A)},
      {'title': 'Made For You', 'color': const Color(0xFF1E3264)},
      {'title': 'New Releases', 'color': const Color(0xFFE8115B)},
      {'title': 'Pop', 'color': const Color(0xFF148A08)},
      {'title': 'Hip-Hop', 'color': const Color(0xFFBC5900)},
      {'title': 'Rock', 'color': const Color(0xFFE91429)},
      {'title': 'Lofi Beats', 'color': const Color(0xFF7D4B32)},
      {'title': 'Electronic', 'color': const Color(0xFFD840FF)},
      {'title': 'Jazz', 'color': const Color(0xFF777777)},
      {'title': 'Decades', 'color': const Color(0xFF537AA1)},
      {'title': 'Gaming', 'color': const Color(0xFFE8115B)},
      {'title': 'Focus', 'color': const Color(0xFF503750)},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  onChanged: (val) {
                    playerProvider.setSearchQuery(val);
                  },
                  decoration: const InputDecoration(
                    hintText: 'What do you want to listen to?',
                    hintStyle: TextStyle(color: Colors.black54),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic view based on queries
              Expanded(
                child: playerProvider.searchQuery.trim().isEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Browse all',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.6,
                              ),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: category['color'] as Color,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: 16,
                                        left: 16,
                                        right: 16,
                                        child: Text(
                                          category['title'] as String,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                        ),
                                      ),
                                      // Mock album art rotated on the bottom right
                                      Positioned(
                                        bottom: -15,
                                        right: -15,
                                        child: Transform.rotate(
                                          angle: 0.4,
                                          child: Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(4),
                                              color: Colors.black26,
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 10,
                                                )
                                              ],
                                              image: const DecorationImage(
                                                image: NetworkImage('https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=150'),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Songs',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: playerProvider.searchResults.isEmpty
                                ? Center(
                                    child: Text(
                                      'No results found for "${playerProvider.searchQuery}"',
                                      style: const TextStyle(color: Colors.white60, fontSize: 16),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: playerProvider.searchResults.length,
                                    itemBuilder: (context, index) {
                                      final song = playerProvider.searchResults[index];
                                      final isCurrentPlaying = playerProvider.currentSong?.id == song.id;

                                      return ListTile(
                                        onTap: () {
                                          playerProvider.play(song);
                                        },
                                        leading: Container(
                                          height: 48,
                                          width: 48,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(4),
                                            image: DecorationImage(
                                              image: NetworkImage(song.coverUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          song.title,
                                          style: GoogleFonts.outfit(
                                            color: isCurrentPlaying ? const Color(0xFF1DB954) : Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${song.artist} • ${song.album}',
                                          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            song.isLiked ? Icons.favorite : Icons.favorite_border,
                                            color: song.isLiked ? const Color(0xFF1DB954) : Colors.white60,
                                          ),
                                          onPressed: () {
                                            playerProvider.toggleLike(song);
                                          },
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
        ),
      ),
    );
  }
}
