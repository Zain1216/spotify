import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/song_model.dart';

class AuthUser {
  final String uid;
  final String email;
  final bool isAdmin;

  AuthUser({
    required this.uid,
    required this.email,
    required this.isAdmin,
  });
}

class FirebaseService {
  static bool isInitialized = false;

  // Stream of AuthUser?
  static final StreamController<AuthUser?> _authController = StreamController<AuthUser?>.broadcast();
  Stream<AuthUser?> get authStateChanges => _authController.stream;

  AuthUser? _currentAuthUser;
  AuthUser? get currentAuthUser => _currentAuthUser;

  // Local mock database collections
  static final List<AuthUser> _mockUsers = [
    AuthUser(uid: 'mock_admin', email: 'admin@spotify.com', isAdmin: true),
  ];
  static final List<Song> _mockUploadedSongs = [];
  static final StreamController<List<Song>> _mockSongsStreamController = StreamController<List<Song>>.broadcast();
  static final Map<String, List<String>> _mockUserLikes = {};
  static final Map<String, StreamController<List<String>>> _mockLikesStreamControllers = {};

  FirebaseService() {
    if (isInitialized) {
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user == null) {
          _currentAuthUser = null;
          _authController.add(null);
        } else {
          final isAdmin = await isUserAdmin(user.uid);
          _currentAuthUser = AuthUser(
            uid: user.uid,
            email: user.email ?? '',
            isAdmin: isAdmin,
          );
          _authController.add(_currentAuthUser);
        }
      });
    } else {
      // Start in signed out state for mock mode initially
      Future.delayed(Duration.zero, () {
        _authController.add(_currentAuthUser);
      });
    }
  }

  // Sign In
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    if (isInitialized) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      final userIndex = _mockUsers.indexWhere((u) => u.email == email);
      if (userIndex != -1) {
        _currentAuthUser = _mockUsers[userIndex];
      } else {
        // Create user on the fly for ease of test/development
        _currentAuthUser = AuthUser(
          uid: 'mock_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          isAdmin: email.toLowerCase().contains('admin'),
        );
        _mockUsers.add(_currentAuthUser!);
      }
      _authController.add(_currentAuthUser);
    }
  }

  // Sign Up
  Future<void> signUpWithEmailAndPassword(
    String email,
    String password, {
    required bool isAdmin,
  }) async {
    if (isInitialized) {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'isAdmin': isAdmin,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      if (_mockUsers.any((u) => u.email == email)) {
        throw Exception("The email address is already in use by another account.");
      }
      final newUser = AuthUser(
        uid: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        isAdmin: isAdmin,
      );
      _mockUsers.add(newUser);
      _currentAuthUser = newUser;
      _authController.add(_currentAuthUser);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    if (isInitialized) {
      await FirebaseAuth.instance.signOut();
    } else {
      await Future.delayed(const Duration(milliseconds: 200));
      _currentAuthUser = null;
      _authController.add(null);
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String uid) async {
    if (isInitialized) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return doc.data()?['isAdmin'] == true;
        }
      } catch (e) {
        debugPrint("Error checking admin status: $e");
      }
      return false;
    } else {
      return _currentAuthUser?.isAdmin ?? false;
    }
  }

  // Upload Song File + Cover Art (Storage vs Local memory)
  Future<void> uploadSong({
    required String title,
    required String artist,
    required String album,
    required Duration duration,
    required Uint8List audioBytes,
    required String audioFileName,
    required Uint8List coverBytes,
    required String coverFileName,
    Function(double)? onProgress,
  }) async {
    if (isInitialized) {
      // 1. Upload audio file
      final audioRef = FirebaseStorage.instance.ref().child('songs/audio/${DateTime.now().millisecondsSinceEpoch}_$audioFileName');
      final audioUploadTask = audioRef.putData(
        audioBytes,
        SettableMetadata(contentType: 'audio/mpeg'),
      );

      audioUploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          double progress = (event.bytesTransferred / event.totalBytes) * 0.7;
          if (onProgress != null) onProgress(progress);
        }
      });

      final audioSnapshot = await audioUploadTask;
      final audioUrl = await audioSnapshot.ref.getDownloadURL();

      // 2. Upload cover image
      final coverRef = FirebaseStorage.instance.ref().child('songs/covers/${DateTime.now().millisecondsSinceEpoch}_$coverFileName');
      final coverUploadTask = coverRef.putData(
        coverBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      coverUploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          double progress = 0.7 + ((event.bytesTransferred / event.totalBytes) * 0.3);
          if (onProgress != null) onProgress(progress);
        }
      });

      final coverSnapshot = await coverUploadTask;
      final coverUrl = await coverSnapshot.ref.getDownloadURL();

      // 3. Write metadata to Firestore
      final docRef = FirebaseFirestore.instance.collection('songs').doc();
      final song = Song(
        id: docRef.id,
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        audioUrl: audioUrl,
        coverUrl: coverUrl,
      );

      await docRef.set(song.toMap()..addAll({
        'createdAt': FieldValue.serverTimestamp(),
      }));
    } else {
      // Local Memory mock upload simulation
      for (double i = 0.0; i <= 1.0; i += 0.1) {
        await Future.delayed(const Duration(milliseconds: 30));
        if (onProgress != null) onProgress(i);
      }

      final song = Song(
        id: 'mock_uploaded_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        audioUrl: '',
        coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300',
        audioBytes: audioBytes, // Save the picked bytes directly for local memory playback
      );

      _mockUploadedSongs.add(song);
      _mockSongsStreamController.add(_mockUploadedSongs);
    }
  }

  // Stream songs
  Stream<List<Song>> getSongsStream() {
    if (isInitialized) {
      return FirebaseFirestore.instance
          .collection('songs')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Song.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } else {
      Future.delayed(Duration.zero, () {
        _mockSongsStreamController.add(_mockUploadedSongs);
      });
      return _mockSongsStreamController.stream;
    }
  }

  // Update liked song
  Future<void> updateLikedSong(String userId, String songId, bool isLiked) async {
    if (isInitialized) {
      final userLikesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('liked_songs')
          .doc(songId);
      if (isLiked) {
        await userLikesRef.set({
          'likedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userLikesRef.delete();
      }
    } else {
      if (!_mockUserLikes.containsKey(userId)) {
        _mockUserLikes[userId] = [];
      }
      if (isLiked) {
        if (!_mockUserLikes[userId]!.contains(songId)) {
          _mockUserLikes[userId]!.add(songId);
        }
      } else {
        _mockUserLikes[userId]!.remove(songId);
      }
      if (_mockLikesStreamControllers.containsKey(userId)) {
        _mockLikesStreamControllers[userId]!.add(_mockUserLikes[userId]!);
      }
    }
  }

  // Stream liked song IDs
  Stream<List<String>> getLikedSongIdsStream(String userId) {
    if (isInitialized) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('liked_songs')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
    } else {
      if (!_mockLikesStreamControllers.containsKey(userId)) {
        _mockLikesStreamControllers[userId] = StreamController<List<String>>.broadcast();
      }
      final controller = _mockLikesStreamControllers[userId]!;
      Future.delayed(Duration.zero, () {
        controller.add(_mockUserLikes[userId] ?? []);
      });
      return controller.stream;
    }
  }
}
