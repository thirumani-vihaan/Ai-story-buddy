import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_feature.dart';

typedef FeatureInitTask = Future<void> Function();

class FeatureRegistry extends ChangeNotifier {
  FeatureRegistry._(
    this._enabled,
    this._initTasks,
  );

  static const _prefsKey = 'ai_story_buddy_feature_flags';

  final Map<AppFeature, bool> _enabled;
  final Map<AppFeature, FeatureInitTask> _initTasks;

  static Future<FeatureRegistry> load({
    required Map<AppFeature, bool> defaultEnabled,
    Map<AppFeature, FeatureInitTask>? initTasks,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    Map<String, dynamic> preferences = <String, dynamic>{};
    if (saved != null) {
      try {
        preferences = jsonDecode(saved) as Map<String, dynamic>;
      } catch (_) {
        preferences = <String, dynamic>{};
      }
    }

    final enabled = <AppFeature, bool>{};
    for (final feature in AppFeature.values) {
      final rawValue = preferences[feature.name];
      if (rawValue is bool) {
        enabled[feature] = rawValue;
      } else {
        enabled[feature] = defaultEnabled[feature] ?? false;
      }
    }

    return FeatureRegistry._(
      enabled,
      Map<AppFeature, FeatureInitTask>.from(initTasks ?? const {}),
    );
  }

  bool isEnabled(AppFeature feature) => _enabled[feature] ?? false;

  Future<void> setEnabled(AppFeature feature, bool enabled) async {
    if (_enabled[feature] == enabled) return;
    _enabled[feature] = enabled;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, bool>{};
    for (final entry in _enabled.entries) {
      map[entry.key.name] = entry.value;
    }
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  Future<void> initialize() async {
    for (final entry in _initTasks.entries) {
      if (!isEnabled(entry.key)) continue;
      try {
        await entry.value();
      } catch (_) {
        // Initialization is best-effort: the app should still start if a
        // warm-up task fails, local fallback paths remain available.
      }
    }
  }
}
