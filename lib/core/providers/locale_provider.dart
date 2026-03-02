import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider that holds the current app locale.
/// Watching this provider causes the full [MaterialApp] to rebuild when the
/// language is changed from the Settings screen, so individual screens no
/// longer need the `final _ = context.locale;` workaround.
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));
