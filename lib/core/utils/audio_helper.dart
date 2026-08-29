import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'audio_platform_stub.dart'
    if (dart.library.js_interop) 'audio_platform_web.dart' as platform;

/// Audio helper for queue chimes and announcements.
///
/// On Web (Chrome): uses the injected Web Audio API engine in index.html
///   (`window.olofChime.play()`) via conditional JS interop.
///
/// On Mobile / Desktop (Android, iOS, Windows): uses audioplayers to play chime.wav / chime.mp3.
class AudioHelper {
  static final AudioPlayer _player = AudioPlayer();
  static bool _mobileInitialized = false;
  static bool _audioUnlocked = false;

  static bool get isAudioUnlocked => _audioUnlocked;

  static void _initMobileIfNeeded() {
    if (!_mobileInitialized) {
      _player.setReleaseMode(ReleaseMode.stop);
      _player.setVolume(1.0);
      _mobileInitialized = true;
    }
  }

  /// Call this once from any user gesture (button tap, etc.) to unlock web audio.
  static void unlockWebAudio() {
    if (kIsWeb) {
      try {
        platform.callJsUnlock();
        _audioUnlocked = true;
      } catch (_) {}
    }
  }

  /// Play the notification chime when a patient is called.
  static Future<bool> playChime() async {
    _audioUnlocked = true;

    if (kIsWeb) {
      // Use the Web Audio API synthesised chime (no autoplay restriction)
      try {
        platform.callJsPlay();
        return true;
      } catch (e) {
        debugPrint('Web Audio chime error: $e');
        return false;
      }
    }

    // Mobile / Desktop — use audioplayers
    _initMobileIfNeeded();
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/chime.wav'));
      return true;
    } catch (e) {
      debugPrint('Audioplayers chime wav error: $e');
      try {
        await _player.play(AssetSource('sounds/chime.mp3'));
        return true;
      } catch (e2) {
        debugPrint('Audioplayers chime mp3 error: $e2');
        return false;
      }
    }
  }

  static void dispose() {
    _player.dispose();
  }
}
