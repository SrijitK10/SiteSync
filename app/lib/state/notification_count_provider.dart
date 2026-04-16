import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import 'projects_provider.dart';

/// Fetches total task (notification) counts for all projects in a single API call.
/// Returns a map of projectId → count.
final projectNotificationCountsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final projects = await ref.watch(projectsProvider.future);

  if (projects.isEmpty) return {};

  final ids = projects
      .map((p) => p['id']?.toString())
      .where((id) => id != null && id.isNotEmpty)
      .join(',');

  if (ids.isEmpty) return {};

  try {
    final response = await apiClient.get('/tasks/counts?projectIds=$ids');
    final data = Map<String, dynamic>.from(response.data as Map);
    return data.map((key, value) => MapEntry(key, (value as num).toInt()));
  } catch (_) {
    return {};
  }
});
