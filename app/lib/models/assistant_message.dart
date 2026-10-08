class AssistantMessage {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String rawInput;
  final String intent;
  final Map<String, dynamic> parsedData;
  final String executionStatus;
  final String? createdRecordId;
  final String assistantReply;
  final DateTime createdAt;

  AssistantMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.rawInput,
    required this.intent,
    required this.parsedData,
    required this.executionStatus,
    this.createdRecordId,
    required this.assistantReply,
    required this.createdAt,
  });

  bool get isExecuted => executionStatus == 'executed';
  bool get isPending => executionStatus == 'pending';
  bool get isCancelled => executionStatus == 'cancelled';
  bool get isTask => intent == 'task';
  bool get isAttendance => intent == 'attendance';

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    return AssistantMessage(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'Site Worker',
      userRole: json['user_role'] ?? 'site_manager',
      rawInput: json['raw_input'] ?? '',
      intent: json['intent'] ?? 'unknown',
      parsedData: (json['parsed_data'] is Map<String, dynamic>)
          ? json['parsed_data'] as Map<String, dynamic>
          : {},
      executionStatus: json['execution_status'] ?? 'pending',
      createdRecordId: json['created_record_id'],
      assistantReply: json['assistant_reply'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
