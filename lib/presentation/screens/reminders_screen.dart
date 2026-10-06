import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/reminder_model.dart';
import '../../data/providers/reminder_provider.dart';
import '../widgets/pagination_bar.dart';
import 'create_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _pendingPage = 1;
  int _completedPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReminderProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_outlined),
        label: const Text('New Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateReminderScreen()),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(text: 'Pending (${provider.pendingReminders.length})'),
                    Tab(text: 'Done (${provider.completedReminders.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReminderList(
                        context,
                        provider.pendingReminders,
                        provider,
                        isCompleted: false,
                        currentPage: _pendingPage,
                        onPageChanged: (p) => setState(() => _pendingPage = p),
                      ),
                      _buildReminderList(
                        context,
                        provider.completedReminders,
                        provider,
                        isCompleted: true,
                        currentPage: _completedPage,
                        onPageChanged: (p) => setState(() => _completedPage = p),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReminderList(
    BuildContext context,
    List<Reminder> reminders,
    ReminderProvider provider, {
    required bool isCompleted,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
  }) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_outline : Icons.alarm_off_outlined,
                size: 34,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isCompleted ? 'No completed reminders' : 'No pending reminders',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 6),
              const Text(
                'Tap + to create a reminder',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      );
    }

    final totalItems = reminders.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 999999);
    final clampedPage = currentPage > totalPages ? 1 : currentPage;
    final startIndex = (clampedPage - 1) * _itemsPerPage;
    final pageReminders = reminders.skip(startIndex).take(_itemsPerPage).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        ...pageReminders.map((reminder) => _buildReminderCard(context, reminder, provider)),
        PaginationBar(
          currentPage: clampedPage,
          totalItems: totalItems,
          itemsPerPage: _itemsPerPage,
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider,
  ) {
    final now = DateTime.now();
    final isOverdue = !reminder.isCompleted && reminder.reminderDate.isBefore(now);
    final isToday = reminder.reminderDate.year == now.year &&
        reminder.reminderDate.month == now.month &&
        reminder.reminderDate.day == now.day;

    Color cardBorderColor = AppColors.border;
    Color badgeColor = AppColors.primary;
    String badgeText = '';

    if (reminder.isCompleted) {
      cardBorderColor = AppColors.statusPaid;
      badgeColor = AppColors.statusPaid;
      badgeText = '✓ Done';
    } else if (isOverdue) {
      cardBorderColor = AppColors.statusOverdue;
      badgeColor = AppColors.statusOverdue;
      badgeText = '⚠ Overdue';
    } else if (isToday) {
      cardBorderColor = AppColors.statusPending;
      badgeColor = AppColors.statusPending;
      badgeText = '🔔 Today';
    }

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Reminder'),
            content: Text('Delete "${reminder.title}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => provider.deleteReminder(reminder.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: reminder.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                        decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (badgeText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Date & Time
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(reminder.reminderDate),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isOverdue && !reminder.isCompleted ? AppColors.statusOverdue : AppColors.textSecondary,
                      fontWeight: isOverdue && !reminder.isCompleted ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),

              if (reminder.clientName.isNotEmpty || reminder.itemDescription.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (reminder.clientName.isNotEmpty) ...[
                      const Icon(Icons.person_outline, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(reminder.clientName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    if (reminder.clientName.isNotEmpty && reminder.itemDescription.isNotEmpty)
                      const Text('  •  ', style: TextStyle(color: AppColors.textMuted)),
                    if (reminder.itemDescription.isNotEmpty) ...[
                      const Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reminder.itemDescription,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              if (reminder.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  reminder.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              if (reminder.amount > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${reminder.currency} ${reminder.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],

              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (reminder.notificationEnabled && !reminder.isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.primary.withValues(alpha: 0.6)),
                    ),
                  // Mark complete toggle
                  TextButton.icon(
                    onPressed: () => provider.markCompleted(reminder.id, !reminder.isCompleted),
                    icon: Icon(
                      reminder.isCompleted ? Icons.undo_outlined : Icons.check_circle_outline,
                      size: 16,
                    ),
                    label: Text(
                      reminder.isCompleted ? 'Undo' : 'Mark Done',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: reminder.isCompleted ? AppColors.textSecondary : AppColors.statusPaid,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Edit
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateReminderScreen(existingReminder: reminder),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
