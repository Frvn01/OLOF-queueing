// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

@JS('olofChime.play')
external void _callJsPlay();

@JS('olofChime.unlock')
external void _callJsUnlock();

/// Web implementation using Web Audio API
void callJsPlay() {
  _callJsPlay();
}

void callJsUnlock() {
  _callJsUnlock();
}
