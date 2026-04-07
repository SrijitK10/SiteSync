import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

const _kCachedProjectsKey = 'cached_projects';

class ProjectsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    // STEP 1: Try cache first — return instantly so the UI can render.
    final cached = await _loadCache();
    if (cached != null) {
      // STEP 2: Refresh in background without blocking the current response.
      Future.microtask(_refreshInBackground);
      return cached;
    }

    // No cache — fetch fresh. The server may be cold (slow first hit).
    return await _fetchAndCache();
  }

  Future<List<Map<String, dynamic>>?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCachedProjectsKey);
      if (raw == null) return null;
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCachedProjectsKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _fetchAndCache() async {
    try {
      final response = await apiClient.get('/projects');
      final List<dynamic> data = response.data;
      final list = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      await _saveCache(list);
      return list;
    } catch (e) {
      throw Exception('Failed to load active projects. Are you connected to the Backend?');
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final fresh = await _fetchAndCache();
      // Only update state if widget is still mounted / provider alive.
      state = AsyncValue.data(fresh);
    } catch (_) {
      // Keep cached data on background refresh failure.
    }
  }

  /// Manual refresh (e.g., pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final fresh = await _fetchAndCache();
      state = AsyncValue.data(fresh);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<Map<String, dynamic>>>(
  ProjectsNotifier.new,
);
