// Web implementation using browser navigator.onLine
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool isWebOffline() {
  try {
    return html.window.navigator.onLine == false;
  } catch (_) {
    return false;
  }
}


