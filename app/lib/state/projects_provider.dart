import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

final projectsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await apiClient.get('/projects');
    final List<dynamic> data = response.data;
    
    // Convert generic responses to strict Map types ensuring native Flutter UI safety
    return data.map((e) => e as Map<String, dynamic>).toList();
  } catch (e) {
    throw Exception('Failed to load active projects. Are you connected to the Backend?');
  }
});
