import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../data/models/reminder_model.dart';
import '../../data/providers/invoice_provider.dart';
import '../../data/providers/reminder_provider.dart';

class CreateReminderScreen extends StatefulWidget {
  final Reminder? existingReminder;
  const CreateReminderScreen({super.key, this.existingReminder});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _notificationEnabled = true;
  String _selectedCurrency = 'LKR';
  bool _showClientSuggestions = false;
  bool _showItemSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      final r = widget.existingReminder!;
      _titleCtrl.text = r.title;
      _descCtrl.text = r.description;
      _clientCtrl.text = r.clientName;
      _itemCtrl.text = r.itemDescription;
      _amountCtrl.text = r.amount > 0 ? r.amount.toString() : '';
      _selectedDate = r.reminderDate;
      _selectedTime = TimeOfDay.fromDateTime(r.reminderDate);
      _notificationEnabled = r.notificationEnabled;
      _selectedCurrency = r.currency;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _clientCtrl.dispose();
    _itemCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(DateTime.now()) ? _selectedDate : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ReminderProvider>(context, listen: false);
    final reminder = Reminder(
      id: widget.existingReminder?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      reminderDate: _combinedDateTime,
      clientName: _clientCtrl.text.trim(),
      itemDescription: _itemCtrl.text.trim(),
      amount: double.tryParse(_amountCtrl.text) ?? 0.0,
      currency: _selectedCurrency,
      notificationEnabled: _notificationEnabled,
      isCompleted: widget.existingReminder?.isCompleted ?? false,
    );

    await provider.saveReminder(reminder);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingReminder == null ? 'Reminder saved! 🔔' : 'Reminder updated! ✅',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final clientSuggestions = invoiceProvider.suggestClients(_clientCtrl.text);
    final itemSuggestions = invoiceProvider.suggestItems(_itemCtrl.text);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.existingReminder == null ? 'Create Reminder' : 'Edit Reminder',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            _buildSectionLabel('📝 Reminder Title'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('e.g. Payment due from Kamal', Icons.title_outlined),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
            ),

            const SizedBox(height: 20),

            // Date & Time Row
            _buildSectionLabel('📅 Date & Time'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTapCard(
                    icon: Icons.calendar_today_outlined,
                    label: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    subtitle: 'Date',
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTapCard(
                    icon: Icons.access_time_outlined,
                    label: _selectedTime.format(context),
                    subtitle: 'Time',
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Client
            _buildSectionLabel('👤 Client (Optional)'),
            const SizedBox(height: 6),
            Column(
              children: [
                TextFormField(
                  controller: _clientCtrl,
                  decoration: _inputDecoration('Select or type client name', Icons.person_outline),
                  onChanged: (v) => setState(() => _showClientSuggestions = v.isNotEmpty),
                  onTap: () => setState(() => _showClientSuggestions = true),
                ),
                if (_showClientSuggestions && clientSuggestions.isNotEmpty)
                  _buildSuggestionList(
                    suggestions: clientSuggestions.map((c) => c.name).toList(),
                    subtitles: clientSuggestions.map((c) => c.phone).toList(),
                    onSelect: (name) {
                      _clientCtrl.text = name;
                      setState(() => _showClientSuggestions = false);
                    },
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Item
            _buildSectionLabel('📦 Item / Service (Optional)'),
            const SizedBox(height: 6),
            Column(
              children: [
                TextFormField(
                  controller: _itemCtrl,
                  decoration: _inputDecoration('Select or type item name', Icons.inventory_2_outlined),
                  onChanged: (v) => setState(() => _showItemSuggestions = v.isNotEmpty),
                  onTap: () => setState(() => _showItemSuggestions = true),
                ),
                if (_showItemSuggestions && itemSuggestions.isNotEmpty)
                  _buildSuggestionList(
                    suggestions: itemSuggestions.map((i) => i.description).toList(),
                    subtitles: itemSuggestions.map((i) => 'Rs. ${i.unitPrice.toStringAsFixed(2)}').toList(),
                    onSelect: (name) {
                      _itemCtrl.text = name;
                      setState(() => _showItemSuggestions = false);
                    },
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Amount & Currency
            _buildSectionLabel('💰 Amount (Optional)'),
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: _inputDecoration('', Icons.currency_exchange),
                    items: ['LKR', 'USD', 'EUR', 'GBP', 'INR']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Amount', Icons.monetization_on_outlined),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            _buildSectionLabel('📋 Notes (Optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('Additional notes...', Icons.notes_outlined),
            ),

            const SizedBox(height: 20),

            // Notification Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _notificationEnabled ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _notificationEnabled
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _notificationEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                      color: _notificationEnabled ? AppColors.primary : AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Push Notification',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        Text(
                          _notificationEnabled
                              ? 'You will be notified at ${_selectedTime.format(context)}'
                              : 'Notification is disabled',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _notificationEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _notificationEnabled = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save_outlined),
        label: Text(
          widget.existingReminder == null ? 'Save Reminder' : 'Update Reminder',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTapCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionList({
    required List<String> suggestions,
    required List<String> subtitles,
    required void Function(String) onSelect,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: suggestions.asMap().entries.map((entry) {
          final i = entry.key;
          final name = entry.value;
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: subtitles[i].isNotEmpty ? Text(subtitles[i], style: const TextStyle(fontSize: 11)) : null,
            onTap: () => onSelect(name),
          );
        }).toList(),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}
