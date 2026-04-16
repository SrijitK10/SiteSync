import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFlatSnapshotsKey = 'flat_unread_snapshots_v1';
const _kProgressSnapshotsKey = 'progress_unread_snapshots_v1';

class UnreadTrackerState {
  final bool isReady;
  final Map<String, Map<String, String>> flatSnapshots;
  final Map<String, Map<String, String>> progressSnapshots;

  const UnreadTrackerState({
    this.isReady = false,
    this.flatSnapshots = const {},
    this.progressSnapshots = const {},
  });

  UnreadTrackerState copyWith({
    bool? isReady,
    Map<String, Map<String, String>>? flatSnapshots,
    Map<String, Map<String, String>>? progressSnapshots,
  }) {
    return UnreadTrackerState(
      isReady: isReady ?? this.isReady,
      flatSnapshots: flatSnapshots ?? this.flatSnapshots,
      progressSnapshots: progressSnapshots ?? this.progressSnapshots,
    );
  }
}

class UnreadTrackerNotifier extends Notifier<UnreadTrackerState> {
  bool _isLoading = false;

  @override
  UnreadTrackerState build() {
    Future.microtask(_ensureLoaded);
    return const UnreadTrackerState();
  }

  Future<void> _ensureLoaded() async {
    if (state.isReady || _isLoading) return;

    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        isReady: true,
        flatSnapshots: _decodeSnapshots(prefs.getString(_kFlatSnapshotsKey)),
        progressSnapshots: _decodeSnapshots(
          prefs.getString(_kProgressSnapshotsKey),
        ),
      );
    } catch (_) {
      state = state.copyWith(isReady: true);
    } finally {
      _isLoading = false;
    }
  }

  int unseenFlatItemCount({
    required String userId,
    required String projectId,
    required String flatId,
    required Iterable<dynamic> tasks,
  }) {
    if (!state.isReady) return 0;

    final previous = state.flatSnapshots[_flatKey(userId, projectId, flatId)];
    final current = _buildTaskSnapshot(tasks);
    return _countSnapshotChanges(previous, current);
  }

  int unseenProgressItemCount({
    required String userId,
    required String projectId,
    required Iterable<dynamic> images,
  }) {
    if (!state.isReady) return 0;

    final previous = state.progressSnapshots[_projectKey(userId, projectId)];
    final current = _buildImageSnapshot(images);
    return _countSnapshotChanges(previous, current);
  }

  Future<void> markFlatVisited({
    required String userId,
    required String projectId,
    required String flatId,
    required Iterable<dynamic> tasks,
  }) async {
    await _ensureLoaded();

    final snapshots = _cloneSnapshots(state.flatSnapshots);
    snapshots[_flatKey(userId, projectId, flatId)] = _buildTaskSnapshot(tasks);

    state = state.copyWith(flatSnapshots: snapshots, isReady: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFlatSnapshotsKey, jsonEncode(snapshots));
  }

  Future<void> markProgressVisited({
    required String userId,
    required String projectId,
    required Iterable<dynamic> images,
  }) async {
    await _ensureLoaded();

    final snapshots = _cloneSnapshots(state.progressSnapshots);
    snapshots[_projectKey(userId, projectId)] = _buildImageSnapshot(images);

    state = state.copyWith(progressSnapshots: snapshots, isReady: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProgressSnapshotsKey, jsonEncode(snapshots));
  }

  Map<String, Map<String, String>> _decodeSnapshots(String? raw) {
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return {};

    return decoded.map((key, value) {
      final entry = value is Map ? value : const <String, dynamic>{};
      return MapEntry(
        key,
        entry.map(
          (snapshotKey, snapshotValue) =>
              MapEntry(snapshotKey.toString(), snapshotValue.toString()),
        ),
      );
    });
  }

  Map<String, Map<String, String>> _cloneSnapshots(
    Map<String, Map<String, String>> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key, Map<String, String>.from(value)),
    );
  }

  Map<String, String> _buildTaskSnapshot(Iterable<dynamic> tasks) {
    final snapshot = <String, String>{};

    for (final rawTask in tasks) {
      if (rawTask is! Map) continue;
      final task = Map<String, dynamic>.from(rawTask);
      final id = task['id']?.toString();
      if (id == null || id.isEmpty) continue;

      snapshot[id] = [
        task['updated_at']?.toString() ?? '',
        task['created_at']?.toString() ?? '',
        task['status']?.toString() ?? '',
        task['title']?.toString() ?? '',
        task['description']?.toString() ?? '',
      ].join('|');
    }

    return snapshot;
  }

  Map<String, String> _buildImageSnapshot(Iterable<dynamic> images) {
    final snapshot = <String, String>{};

    for (final rawImage in images) {
      if (rawImage is! Map) continue;
      final image = Map<String, dynamic>.from(rawImage);
      final id = image['id']?.toString();
      if (id == null || id.isEmpty) continue;

      snapshot[id] = [
        image['date']?.toString() ?? '',
        image['caption']?.toString() ?? '',
        image['url']?.toString() ?? '',
      ].join('|');
    }

    return snapshot;
  }

  int _countSnapshotChanges(
    Map<String, String>? previous,
    Map<String, String> current,
  ) {
    if (previous == null) return current.length;

    var changes = 0;
    final keys = {...previous.keys, ...current.keys};
    for (final key in keys) {
      if (previous[key] != current[key]) {
        changes++;
      }
    }
    return changes;
  }

  String _flatKey(String userId, String projectId, String flatId) {
    return '$userId::$projectId::$flatId';
  }

  String _projectKey(String userId, String projectId) {
    return '$userId::$projectId';
  }
}

final unreadTrackerProvider =
    NotifierProvider<UnreadTrackerNotifier, UnreadTrackerState>(
      UnreadTrackerNotifier.new,
    );
