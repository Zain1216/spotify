import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song_model.dart';
import '../data/mock_data.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Playback state
  Song? _currentSong;
  Playlist? _currentPlaylist;
  int _currentTrackIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 0.5;
  bool _isShuffle = false;
  bool _isRepeat = false;

  // App Navigation & Library States
  String _currentScreen = 'home'; // 'home', 'search', 'library', 'playlist_detail'
  Playlist? _selectedPlaylist;
  String _searchQuery = '';
  List<Song> _searchResults = [];
  bool _showLyrics = false;

  // Custom User Playlists & Likes
  final List<Song> _likedSongs = [];
  final List<Playlist> _playlists = [];

  // Streams subscriptions
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  AudioPlayerProvider() {
    _playlists.addAll(mockPlaylists);
    _initAudioPlayer();
  }

  // Getters
  Song? get currentSong => _currentSong;
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;

  String get currentScreen => _currentScreen;
  Playlist? get selectedPlaylist => _selectedPlaylist;
  String get searchQuery => _searchQuery;
  List<Song> get searchResults => _searchResults;
  bool get showLyrics => _showLyrics;

  List<Song> get likedSongs => _likedSongs;
  List<Playlist> get playlists => _playlists;

  void _initAudioPlayer() {
    // Set initial volume
    _audioPlayer.setVolume(_volume);

    // Listeners
    _positionSub = _audioPlayer.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _completeSub = _audioPlayer.onPlayerComplete.listen((event) {
      _handlePlaybackComplete();
    });
  }

  void _handlePlaybackComplete() {
    if (_isRepeat) {
      // Re-play current song
      if (_currentSong != null) {
        play(_currentSong!);
      }
    } else {
      next();
    }
  }

  // Playback actions
  Future<void> play(Song song, {Playlist? fromPlaylist}) async {
    _currentSong = song;
    if (fromPlaylist != null) {
      _currentPlaylist = fromPlaylist;
      _currentTrackIndex = fromPlaylist.songs.indexWhere((s) => s.id == song.id);
    } else {
      // If played outside a playlist, clear current playlist context or set it to mock songs
      _currentPlaylist = null;
      _currentTrackIndex = mockSongs.indexWhere((s) => s.id == song.id);
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(song.audioUrl));
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_currentSong != null) {
      await _audioPlayer.resume();
      _isPlaying = true;
      notifyListeners();
    } else if (mockSongs.isNotEmpty) {
      play(mockSongs[0]);
    }
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration pos) async {
    await _audioPlayer.seek(pos);
  }

  void setVolume(double val) {
    _volume = val;
    _audioPlayer.setVolume(val);
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  void next() {
    List<Song> songList = _currentPlaylist?.songs ?? mockSongs;
    if (songList.isEmpty) return;

    if (_isShuffle) {
      final random = Random();
      _currentTrackIndex = random.nextInt(songList.length);
    } else {
      _currentTrackIndex = (_currentTrackIndex + 1) % songList.length;
    }

    if (_currentTrackIndex >= 0 && _currentTrackIndex < songList.length) {
      play(songList[_currentTrackIndex], fromPlaylist: _currentPlaylist);
    }
  }

  void previous() {
    List<Song> songList = _currentPlaylist?.songs ?? mockSongs;
    if (songList.isEmpty) return;

    if (_isShuffle) {
      final random = Random();
      _currentTrackIndex = random.nextInt(songList.length);
    } else {
      _currentTrackIndex = _currentTrackIndex - 1;
      if (_currentTrackIndex < 0) {
        _currentTrackIndex = songList.length - 1;
      }
    }

    if (_currentTrackIndex >= 0 && _currentTrackIndex < songList.length) {
      play(songList[_currentTrackIndex], fromPlaylist: _currentPlaylist);
    }
  }

  // Navigation actions
  void navigateTo(String screen, {Playlist? playlist}) {
    _currentScreen = screen;
    if (playlist != null) {
      _selectedPlaylist = playlist;
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
    } else {
      final lowercaseQuery = query.toLowerCase();
      _searchResults = mockSongs.where((song) {
        return song.title.toLowerCase().contains(lowercaseQuery) ||
               song.artist.toLowerCase().contains(lowercaseQuery) ||
               song.album.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
    notifyListeners();
  }

  void toggleLyrics() {
    _showLyrics = !_showLyrics;
    notifyListeners();
  }

  // Library / Liked actions
  void toggleLike(Song song) {
    final songIndex = mockSongs.indexWhere((s) => s.id == song.id);
    if (songIndex != -1) {
      mockSongs[songIndex].isLiked = !mockSongs[songIndex].isLiked;
      song.isLiked = mockSongs[songIndex].isLiked;
    }

    // Update in playlist song lists if present
    for (var playlist in _playlists) {
      final playlistSongIdx = playlist.songs.indexWhere((s) => s.id == song.id);
      if (playlistSongIdx != -1) {
        playlist.songs[playlistSongIdx].isLiked = song.isLiked;
      }
    }

    if (song.isLiked) {
      if (!_likedSongs.any((s) => s.id == song.id)) {
        _likedSongs.add(song);
      }
    } else {
      _likedSongs.removeWhere((s) => s.id == song.id);
    }
    notifyListeners();
  }

  void createPlaylist(String name) {
    final newPlaylist = Playlist(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: 'A custom playlist created by you.',
      coverUrl: 'https://images.unsplash.com/photo-1494232410401-ad00d5433cfa?w=400',
      songs: [],
      creator: 'You',
    );
    _playlists.add(newPlaylist);
    notifyListeners();
  }

  void addSongToPlaylist(Song song, Playlist playlist) {
    if (!playlist.songs.any((s) => s.id == song.id)) {
      playlist.songs.add(song);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
