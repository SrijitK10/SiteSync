import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assistant_message.dart';
import '../services/api_client.dart';

class AssistantState {
  final List<AssistantMessage> myMessages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  // Supervision feed for Admins / Super Admins
  final List<AssistantMessage> supervisionMessages;
  final bool isSupervisionLoading;
  final String? supervisionError;

  const AssistantState({
    this.myMessages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.supervisionMessages = const [],
    this.isSupervisionLoading = false,
    this.supervisionError,
  });

  AssistantState copyWith({
    List<AssistantMessage>? myMessages,
    bool? isLoading,
    bool? isSending,
    String? error,
    List<AssistantMessage>? supervisionMessages,
    bool? isSupervisionLoading,
    String? supervisionError,
  }) {
    return AssistantState(
      myMessages: myMessages ?? this.myMessages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      supervisionMessages: supervisionMessages ?? this.supervisionMessages,
      isSupervisionLoading: isSupervisionLoading ?? this.isSupervisionLoading,
      supervisionError: supervisionError,
    );
  }
}

class AssistantNotifier extends Notifier<AssistantState> {
  @override
  AssistantState build() {
    Future.microtask(() => loadMyMessages());
    return const AssistantState();
  }

  Future<void> loadMyMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get('/assistant/messages/my');
      final List rawList = response.data is List ? response.data : [];
      final messages = rawList.map((m) => AssistantMessage.fromJson(m)).toList();
      state = state.copyWith(myMessages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<AssistantMessage?> sendMessage(String text) async {
    if (text.trim().isEmpty) return null;
    state = state.copyWith(isSending: true, error: null);
    try {
      final response = await apiClient.post('/assistant/message', data: {'text': text.trim()});
      final newMsg = AssistantMessage.fromJson(response.data);
      state = state.copyWith(
        myMessages: [...state.myMessages, newMsg],
        isSending: false,
      );
      return newMsg;
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
      return null;
    }
  }

  Future<bool> executeAction(String messageId) async {
    try {
      final response = await apiClient.post('/assistant/execute/$messageId');
      final updatedMsg = AssistantMessage.fromJson(response.data);

      final updatedList = state.myMessages.map((m) {
        return m.id == messageId ? updatedMsg : m;
      }).toList();

      final updatedSupList = state.supervisionMessages.map((m) {
        return m.id == messageId ? updatedMsg : m;
      }).toList();

      state = state.copyWith(
        myMessages: updatedList,
        supervisionMessages: updatedSupList,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> cancelAction(String messageId) async {
    try {
      final response = await apiClient.post('/assistant/cancel/$messageId');
      final updatedMsg = AssistantMessage.fromJson(response.data);

      final updatedList = state.myMessages.map((m) {
        return m.id == messageId ? updatedMsg : m;
      }).toList();

      final updatedSupList = state.supervisionMessages.map((m) {
        return m.id == messageId ? updatedMsg : m;
      }).toList();

      state = state.copyWith(
        myMessages: updatedList,
        supervisionMessages: updatedSupList,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> loadSupervisionFeed({
    String? range,
    String? status,
    String? intent,
    String? projectId,
    String? userId,
  }) async {
    state = state.copyWith(isSupervisionLoading: true, supervisionError: null);
    try {
      final queryParams = <String, dynamic>{};
      if (range != null && range != 'all') queryParams['range'] = range;
      if (status != null && status != 'all') queryParams['status'] = status;
      if (intent != null && intent != 'all') queryParams['intent'] = intent;
      if (projectId != null && projectId.isNotEmpty) queryParams['projectId'] = projectId;
      if (userId != null && userId.isNotEmpty) queryParams['userId'] = userId;

      final response = await apiClient.get(
        '/assistant/supervision/all',
        queryParameters: queryParams,
      );

      final List rawList = response.data is List ? response.data : [];
      final messages = rawList.map((m) => AssistantMessage.fromJson(m)).toList();
      state = state.copyWith(
        supervisionMessages: messages,
        isSupervisionLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSupervisionLoading: false,
        supervisionError: e.toString(),
      );
    }
  }
}

final assistantProvider =
    NotifierProvider<AssistantNotifier, AssistantState>(AssistantNotifier.new);
