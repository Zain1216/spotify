class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String audioUrl;
  final String coverUrl;
  bool isLiked;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.audioUrl,
    required this.coverUrl,
    this.isLiked = false,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? audioUrl,
    String? coverUrl,
    bool? isLiked,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final String coverUrl;
  final List<Song> songs;
  final String creator;
  final String type; // e.g. 'Playlist', 'Album', 'Podcast'

  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.coverUrl,
    required this.songs,
    this.creator = 'Spotify',
    this.type = 'Playlist',
  });
}
