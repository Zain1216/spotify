import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../models/song_model.dart';
import '../data/mock_data.dart';
import '../services/firebase_service.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseService _firebaseService = FirebaseService();

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
  String _currentScreen = 'home'; // 'home', 'search', 'library', 'playlist_detail', 'admin_upload'
  Playlist? _selectedPlaylist;
  String _searchQuery = '';
  List<Song> _searchResults = [];
  bool _showLyrics = false;

  // Firebase auth & data states
  AuthUser? _currentUser;
  bool _isAdmin = false;
  List<Song> _firebaseSongs = [];

  // Custom User Playlists & Likes
  final List<Song> _likedSongs = [];
  final List<Playlist> _playlists = [];

  // Stream subscriptions
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;
  StreamSubscription<AuthUser?>? _authSub;
  StreamSubscription<List<Song>>? _songsSub;
  StreamSubscription<List<String>>? _likesSub;

  AudioPlayerProvider() {
    _playlists.addAll(mockPlaylists);
    _initAudioPlayer();
    _initAuthListener();
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

  // Auth & Admin Getters
  AuthUser? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  List<Song> get firebaseSongs => _firebaseSongs;
  List<Song> get allSongs => [..._firebaseSongs, ...mockSongs];

  void _initAudioPlayer() {
    _audioPlayer.setVolume(_volume);

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

  void _initAuthListener() {
    _authSub = _firebaseService.authStateChanges.listen((user) async {
      _currentUser = user;
      _songsSub?.cancel();
      _likesSub?.cancel();

      if (user != null) {
        // Fetch Admin status
        _isAdmin = await _firebaseService.isUserAdmin(user.uid);
        notifyListeners();

        // Subscribe to Firestore songs
        _songsSub = _firebaseService.getSongsStream().listen(
          (songs) {
            _firebaseSongs = songs;
            _updateFirebasePlaylist();
            notifyListeners();
          },
          onError: (error) {
            debugPrint("Error streaming songs (check Firestore rules): $error");
          },
        );

        // Subscribe to Firestore liked songs
        _likesSub = _firebaseService.getLikedSongIdsStream(user.uid).listen(
          (likedIds) {
            _likedSongs.clear();
            // Update liked status on all songs
            for (var song in mockSongs) {
              song.isLiked = likedIds.contains(song.id);
              if (song.isLiked) _likedSongs.add(song);
            }
            for (var song in _firebaseSongs) {
              song.isLiked = likedIds.contains(song.id);
              if (song.isLiked) _likedSongs.add(song);
            }
            notifyListeners();
          },
          onError: (error) {
            debugPrint("Error streaming liked songs (check Firestore rules): $error");
          },
        );
      } else {
        _isAdmin = false;
        _firebaseSongs.clear();
        _likedSongs.clear();
        for (var song in mockSongs) {
          song.isLiked = false;
        }
        _playlists.removeWhere((p) => p.id == 'firebase_uploads');
        notifyListeners();
      }
    });
  }

  void _updateFirebasePlaylist() {
    final index = _playlists.indexWhere((p) => p.id == 'firebase_uploads');
    final firebasePlaylist = Playlist(
      id: 'firebase_uploads',
      name: 'Cloud Tracks',
      description: 'Songs uploaded by Admins to Firebase Storage.',
      coverUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400',
      songs: _firebaseSongs,
      creator: 'Admin Uploads',
    );

    if (index != -1) {
      _playlists[index] = firebasePlaylist;
    } else {
      // Insert it near the top of playlists
      _playlists.insert(0, firebasePlaylist);
    }
  }

  void _handlePlaybackComplete() {
    if (_isRepeat) {
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
      _currentPlaylist = null;
      _currentTrackIndex = allSongs.indexWhere((s) => s.id == song.id);
    }

    try {
      await _audioPlayer.stop();
      if (song.audioBytes != null) {
        await _audioPlayer.play(BytesSource(song.audioBytes!));
      } else {
        await _audioPlayer.play(UrlSource(song.audioUrl));
      }
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
    } else if (allSongs.isNotEmpty) {
      play(allSongs[0]);
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
    List<Song> songList = _currentPlaylist?.songs ?? allSongs;
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
    List<Song> songList = _currentPlaylist?.songs ?? allSongs;
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
      _searchResults = allSongs.where((song) {
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
    final allSongsIndex = allSongs.indexWhere((s) => s.id == song.id);
    if (allSongsIndex != -1) {
      final targetSong = allSongs[allSongsIndex];
      final newLikedState = !targetSong.isLiked;

      // Update in local instance
      targetSong.isLiked = newLikedState;
      song.isLiked = newLikedState;

      // Update in playlists
      for (var playlist in _playlists) {
        final playlistSongIdx = playlist.songs.indexWhere((s) => s.id == song.id);
        if (playlistSongIdx != -1) {
          playlist.songs[playlistSongIdx].isLiked = newLikedState;
        }
      }

      // Sync to cloud if user is logged in
      if (_currentUser != null) {
        _firebaseService.updateLikedSong(_currentUser!.uid, song.id, newLikedState);
      } else {
        // Fallback local-only state updates for guest
        if (newLikedState) {
          if (!_likedSongs.any((s) => s.id == song.id)) {
            _likedSongs.add(song);
          }
        } else {
          _likedSongs.removeWhere((s) => s.id == song.id);
        }
        notifyListeners();
      }
    }
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

  Future<void> importLocalSongs() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final localPlaylist = _playlists.firstWhere((p) => p.id == 'local_imports');

        for (var file in result.files) {
          Uint8List? bytes = file.bytes;
          if (bytes == null && file.path != null && !kIsWeb) {
            final ioFile = File(file.path!);
            bytes = await ioFile.readAsBytes();
          }

          if (bytes != null) {
            final title = file.name.replaceAll(RegExp(r'\.(mp3|wav|m4a|aac)$', caseSensitive: false), '');
            final song = Song(
              id: 'local_${DateTime.now().millisecondsSinceEpoch}_${file.name}',
              title: title,
              artist: 'Local Artist',
              album: 'Device Files',
              duration: const Duration(minutes: 3),
              audioUrl: '',
              coverUrl: 'https://images.unsplash.com/photo-1507838153414-b4b713384a76?w=300',
              audioBytes: bytes,
            );

            mockSongs.add(song);
            localPlaylist.songs.add(song);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking files: $e");
    }
  }

  // Logout method helper
  Future<void> logout() async {
    await _firebaseService.signOut();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _authSub?.cancel();
    _songsSub?.cancel();
    _likesSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
