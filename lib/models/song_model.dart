import 'dart:typed_data';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String audioUrl;
  final String coverUrl;
  final Uint8List? audioBytes;
  bool isLiked;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.audioUrl,
    required this.coverUrl,
    this.audioBytes,
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
    Uint8List? audioBytes,
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
      audioBytes: audioBytes ?? this.audioBytes,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration.inMilliseconds,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'isLiked': isLiked,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map, String docId) {
    return Song(
      id: docId,
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      album: map['album'] ?? '',
      duration: Duration(milliseconds: map['durationMs'] ?? 0),
      audioUrl: map['audioUrl'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      isLiked: map['isLiked'] ?? false,
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
