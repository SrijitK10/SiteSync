import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assistant_message.dart';
import '../state/assistant_provider.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/drawn_app_icon.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _selectedTab = 0; // 0 = Chat, 1 = Supervision Feed (if admin)
  String _supervisionRange = 'all';
  String _supervisionStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assistantProvider.notifier).loadMyMessages();
      final user = ref.read(authProvider).currentUser;
      if (user != null && user.role.isAdmin) {
        ref.read(assistantProvider.notifier).loadSupervisionFeed();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    final res = await ref.read(assistantProvider.notifier).sendMessage(text);
    if (res != null) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider).currentUser;
    final isAdmin = user != null && user.role.isAdmin;
    final state = ref.watch(assistantProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: DrawnAppIcon(
                kind: DrawnAppIconKind.assistant,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Site Assistant',
                  style: AppTheme.heading.copyWith(fontSize: 18),
                ),
                Text(
                  'Banglish • Bengali • English',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: isAdmin
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'My Assistant',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTab == 0
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedTab = 1);
                              ref.read(assistantProvider.notifier).loadSupervisionFeed(
                                    range: _supervisionRange,
                                    status: _supervisionStatus,
                                  );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, size: 15, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Supervision Feed',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedTab == 1
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: _selectedTab == 0
          ? _buildChatView(context, state, isDark)
          : _buildSupervisionView(context, state, isDark),
    );
  }

  Widget _buildChatView(BuildContext context, AssistantState state, bool isDark) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (state.error != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: state.isLoading && state.myMessages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.myMessages.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: state.myMessages.length,
                      itemBuilder: (ctx, index) {
                        final msg = state.myMessages[index];
                        return _buildMessageTurn(ctx, msg, isDark);
                      },
                    ),
        ),
        if (state.isSending)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Understanding message...',
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        _buildInputBar(context, isDark),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: DrawnAppIcon(
              kind: DrawnAppIconKind.assistant,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Smart Site Assistant',
            style: AppTheme.heading.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Write or speak tasks and attendance in simple words. Bengali, Banglish, and English are all supported!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick Examples (Tap to try):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPromptChip(
            context,
            '👷 Attendance',
            'rupayan aster harkash 4 labour 5 mistri',
          ),
          const SizedBox(height: 8),
          _buildPromptChip(
            context,
            '📋 Task',
            'rupayan dahlia 403 cement pending',
          ),
          const SizedBox(height: 8),
          _buildPromptChip(
            context,
            'বাংলা ইনপুট',
            'রূপায়ণ অ্যাস্টার ২০১ পুট্টি কাজ শেষ',
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(BuildContext context, String tag, String prompt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        _textController.text = prompt;
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252538) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              prompt,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTurn(BuildContext context, AssistantMessage msg, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. User Message bubble (Right)
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(left: 48, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              msg.rawInput,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),

        // 2. Assistant Confirmation / Status Card (Left)
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(right: 32, bottom: 18),
            child: _buildActionCard(context, msg, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, AssistantMessage msg, bool isDark) {
    final data = msg.parsedData;
    final isTask = msg.isTask;
    final isAttendance = msg.isAttendance;

    final headerColor = isAttendance
        ? Colors.green.shade600
        : (isTask ? Colors.blue.shade600 : Colors.grey.shade600);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: msg.isExecuted
              ? Colors.green.withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : Colors.black12),
          width: msg.isExecuted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(
                  isAttendance
                      ? Icons.co_present_rounded
                      : (isTask ? Icons.assignment_rounded : Icons.help_outline),
                  size: 16,
                  color: headerColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isAttendance
                      ? 'Attendance Detected'
                      : (isTask ? 'Task Detected' : 'Site Entry'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
                const Spacer(),
                if (msg.isExecuted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'SAVED',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else if (msg.isCancelled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CANCELLED',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description of action
                Text(
                  msg.assistantReply,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Details Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (data['project_name'] != null)
                      _buildChip(
                        Icons.apartment,
                        data['project_name'].toString(),
                        Colors.indigo,
                        isDark,
                      ),
                    if (data['flat_number'] != null)
                      _buildChip(
                        Icons.meeting_room,
                        'Flat ${data['flat_number']}',
                        Colors.orange,
                        isDark,
                      ),
                    if (data['contractor_name'] != null)
                      _buildChip(
                        Icons.person_pin,
                        data['contractor_name'].toString(),
                        Colors.teal,
                        isDark,
                      ),
                    if (data['labourers_count'] != null && (data['labourers_count'] as num) > 0)
                      _buildChip(
                        Icons.groups,
                        '${data['labourers_count']} Labour',
                        Colors.blue,
                        isDark,
                      ),
                    if (data['mistris_count'] != null && (data['mistris_count'] as num) > 0)
                      _buildChip(
                        Icons.handyman,
                        '${data['mistris_count']} Mistri',
                        Colors.deepPurple,
                        isDark,
                      ),
                    if (data['santras_count'] != null && (data['santras_count'] as num) > 0)
                      _buildChip(
                        Icons.architecture,
                        '${data['santras_count']} Santras',
                        Colors.amber.shade800,
                        isDark,
                      ),
                  ],
                ),

                // Actions if still pending
                if (msg.isPending) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          ref.read(assistantProvider.notifier).cancelAction(msg.id);
                        },
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final success = await ref
                              .read(assistantProvider.notifier)
                              .executeAction(msg.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Successfully recorded to database!'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(
                          isAttendance ? 'Confirm Attendance' : 'Confirm & Create',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28283E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Type tasks or attendance...',
                  hintStyle: TextStyle(fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  // --- Supervision Feed View for Admins ---
  Widget _buildSupervisionView(BuildContext context, AssistantState state, bool isDark) {
    return Column(
      children: [
        // Filter row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Time', _supervisionRange == 'all', () {
                  setState(() => _supervisionRange = 'all');
                  _refreshSupervision();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Today', _supervisionRange == 'today', () {
                  setState(() => _supervisionRange = 'today');
                  _refreshSupervision();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('This Week', _supervisionRange == 'week', () {
                  setState(() => _supervisionRange = 'week');
                  _refreshSupervision();
                }),
                const SizedBox(width: 16),
                _buildFilterChip('All Status', _supervisionStatus == 'all', () {
                  setState(() => _supervisionStatus = 'all');
                  _refreshSupervision();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Executed', _supervisionStatus == 'executed', () {
                  setState(() => _supervisionStatus = 'executed');
                  _refreshSupervision();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', _supervisionStatus == 'pending', () {
                  setState(() => _supervisionStatus = 'pending');
                  _refreshSupervision();
                }),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // Supervision stream
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refreshSupervision(),
            child: state.isSupervisionLoading && state.supervisionMessages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.supervisionMessages.isEmpty
                    ? Center(
                        child: Text(
                          'No assistant logs found for this filter.',
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.supervisionMessages.length,
                        itemBuilder: (ctx, index) {
                          final msg = state.supervisionMessages[index];
                          return _buildSupervisionCard(ctx, msg, isDark);
                        },
                      ),
          ),
        ),
      ],
    );
  }

  void _refreshSupervision() {
    ref.read(assistantProvider.notifier).loadSupervisionFeed(
          range: _supervisionRange,
          status: _supervisionStatus,
        );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildSupervisionCard(BuildContext context, AssistantMessage msg, bool isDark) {
    final statusColor = msg.isExecuted
        ? Colors.green
        : (msg.isCancelled ? Colors.grey : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                child: Text(
                  msg.userName.isNotEmpty ? msg.userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      msg.userRole.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  msg.executionStatus.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'User Typed: "${msg.rawInput}"',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            msg.assistantReply,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
