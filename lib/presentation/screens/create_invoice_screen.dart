import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_translations.dart';
import '../../core/localization/language_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/invoice_number_generator.dart';
import '../../data/models/client_model.dart';
import '../../data/models/invoice_item_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/invoice_template.dart';
import '../../data/providers/business_provider.dart';
import '../../data/providers/invoice_provider.dart';
import '../widgets/client_autocomplete_field.dart';
import '../widgets/item_row_widget.dart';
import '../widgets/template_picker_card.dart';
import 'invoice_details_screen.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoiceToEdit;

  const CreateInvoiceScreen({super.key, this.invoiceToEdit});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  late TextEditingController _invoiceNumberController;
  late TextEditingController _clientNameController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _clientEmailController;
  late TextEditingController _clientAddressController;
  late TextEditingController _taxPercentController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  DateTime? _selectedDueDate;
  late String _selectedCurrency;
  late String _selectedTemplateId;
  late String _selectedDocLanguage;
  late String _selectedStatus;

  List<InvoiceItem> _items = [];

  @override
  void initState() {
    super.initState();
    final edit = widget.invoiceToEdit;
    final businessProfile = Provider.of<BusinessProvider>(context, listen: false).profile;
    final defaultDocLang = Provider.of<LanguageProvider>(context, listen: false).invoiceLanguage;

    if (edit != null) {
      _invoiceNumberController = TextEditingController(text: edit.invoiceNumber);
      _clientNameController = TextEditingController(text: edit.client.name);
      _clientPhoneController = TextEditingController(text: edit.client.phone);
      _clientEmailController = TextEditingController(text: edit.client.email);
      _clientAddressController = TextEditingController(text: edit.client.address);
      _taxPercentController = TextEditingController(
        text: edit.taxPercent > 0 ? edit.taxPercent.toString() : '',
      );
      _notesController = TextEditingController(text: edit.notes);

      _selectedDate = edit.date;
      _selectedDueDate = edit.dueDate;
      _selectedCurrency = edit.currency;
      _selectedTemplateId = edit.templateId;
      _selectedDocLanguage = edit.languageCode;
      _selectedStatus = edit.status;
      _items = List.from(edit.items);
    } else {
      // Auto-generate random invoice number
      _invoiceNumberController = TextEditingController(
        text: InvoiceNumberGenerator.generateRandom(),
      );
      _clientNameController = TextEditingController();
      _clientPhoneController = TextEditingController();
      _clientEmailController = TextEditingController();
      _clientAddressController = TextEditingController();
      _taxPercentController = TextEditingController();
      _notesController = TextEditingController(
        text: businessProfile.paymentInfo.isNotEmpty ? businessProfile.paymentInfo : '',
      );

      _selectedDate = DateTime.now();
      _selectedDueDate = DateTime.now().add(const Duration(days: 7));
      _selectedCurrency = businessProfile.defaultCurrency.isNotEmpty
          ? businessProfile.defaultCurrency
          : 'LKR';
      _selectedTemplateId = 'modern_blue';
      _selectedDocLanguage = defaultDocLang;
      _selectedStatus = 'pending';

      // Start with 1 empty item
      _items = [
        InvoiceItem(
          id: const Uuid().v4(),
          description: '',
          quantity: 1,
          unitPrice: 0,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _clientAddressController.dispose();
    _taxPercentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _regenerateInvoiceNumber() {
    setState(() {
      _invoiceNumberController.text = InvoiceNumberGenerator.generateRandom();
    });
  }

  void _addItem() {
    setState(() {
      _items.add(
        InvoiceItem(
          id: const Uuid().v4(),
          description: '',
          quantity: 1,
          unitPrice: 0,
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one item is required')),
      );
      return;
    }
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.subtotal);
  double get _discountTotal => _items.fold(0.0, (sum, i) => sum + i.discountAmount);
  double get _itemsTotal => _items.fold(0.0, (sum, i) => sum + i.total);
  double get _taxAmount {
    final taxRate = double.tryParse(_taxPercentController.text) ?? 0.0;
    return _itemsTotal * (taxRate / 100);
  }
  double get _grandTotal => _itemsTotal + _taxAmount;

  Future<void> _pickDate(bool isDueDate) async {
    final initialDate = isDueDate ? (_selectedDueDate ?? DateTime.now()) : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _selectedDueDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  void _saveAndProceed() async {
    final invNumber = _invoiceNumberController.text.trim();
    if (invNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invoice number')),
      );
      return;
    }

    final clientName = _clientNameController.text.trim();
    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter client/customer name')),
      );
      return;
    }

    // Filter valid items
    final validItems = _items.where((i) => i.description.trim().isNotEmpty).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item with description')),
      );
      return;
    }

    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);

    final newInvoice = Invoice(
      id: widget.invoiceToEdit?.id ?? const Uuid().v4(),
      invoiceNumber: invNumber,
      date: _selectedDate,
      dueDate: _selectedDueDate,
      client: Client(
        id: const Uuid().v4(),
        name: clientName,
        phone: _clientPhoneController.text.trim(),
        email: _clientEmailController.text.trim(),
        address: _clientAddressController.text.trim(),
      ),
      items: validItems,
      currency: _selectedCurrency,
      templateId: _selectedTemplateId,
      languageCode: _selectedDocLanguage,
      status: _selectedStatus,
      taxPercent: double.tryParse(_taxPercentController.text) ?? 0.0,
      notes: _notesController.text.trim(),
      createdAt: widget.invoiceToEdit?.createdAt ?? DateTime.now(),
    );

    await invoiceProvider.saveInvoice(newInvoice);

    if (!mounted) return;

    // Navigate directly to Invoice Details / Preview screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailsScreen(invoiceId: newInvoice.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.invoiceToEdit != null ? lang.tr('edit_invoice') : lang.tr('create_invoice'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveAndProceed,
            icon: const Icon(Icons.check, color: AppColors.primaryLight),
            label: Text(
              lang.tr('save'),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryLight),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Invoice Number & Status Row
            _buildInvoiceNumberCard(lang),

            const SizedBox(height: 16),

            // 2. Dates & Currency Card
            _buildDatesAndCurrencyCard(lang),

            const SizedBox(height: 16),

            // 3. Client Information (With Autocomplete & Suggestions)
            _buildClientCard(lang, invoiceProvider),

            const SizedBox(height: 16),

            // 4. Items List (With Autocomplete & Dynamic rows)
            _buildItemsCard(lang, invoiceProvider),

            const SizedBox(height: 16),

            // 5. Template Selector (Visual Cards)
            _buildTemplateSelectorCard(lang),

            const SizedBox(height: 16),

            // 6. Invoice Document Language Selector
            _buildDocumentLanguageCard(lang),

            const SizedBox(height: 16),

            // 7. Taxes, Notes & Summary Card
            _buildTotalsCard(lang),

            const SizedBox(height: 24),

            // Save & Generate Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.visibility_outlined),
                label: Text(
                  '${lang.tr('save')} & ${lang.tr('view_details')}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceNumberCard(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.tr('invoice_number'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              // Random generator button
              TextButton.icon(
                onPressed: _regenerateInvoiceNumber,
                icon: const Icon(Icons.casino_outlined, size: 16, color: AppColors.primaryLight),
                label: const Text(
                  'Random',
                  style: TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _invoiceNumberController,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.tag, color: AppColors.primaryLight),
                    hintText: lang.tr('invoice_number_hint'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Status Toggle (Pending / Paid)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStatus = _selectedStatus == 'pending' ? 'paid' : 'pending';
                  });
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _selectedStatus == 'paid'
                        ? AppColors.statusPaid.withOpacity(0.12)
                        : AppColors.statusPending.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedStatus == 'paid' ? AppColors.statusPaid : AppColors.statusPending,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedStatus.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _selectedStatus == 'paid' ? AppColors.statusPaid : AppColors.statusPending,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatesAndCurrencyCard(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Invoice Date
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.tr('date'),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primaryLight),
                            const SizedBox(width: 6),
                            Text(
                              DateHelper.formatDisplay(_selectedDate),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Due Date
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.tr('due_date'),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.event_available_outlined, size: 14, color: AppColors.primaryLight),
                            const SizedBox(width: 6),
                            Text(
                              _selectedDueDate != null
                                  ? DateHelper.formatDisplay(_selectedDueDate!)
                                  : 'Optional',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Currency Selector
          DropdownButtonFormField<String>(
            value: _selectedCurrency,
            decoration: InputDecoration(
              labelText: lang.tr('currency'),
              prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.primaryLight),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: CurrencyHelper.currencies.map((c) {
              return DropdownMenuItem<String>(
                value: c['code'],
                child: Text('${c['code']} - ${c['name']} (${c['symbol']})'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedCurrency = val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(LanguageProvider lang, InvoiceProvider invoiceProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                lang.tr('client_details'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Client Name Autocomplete Field
          ClientAutocompleteField(
            nameController: _clientNameController,
            phoneController: _clientPhoneController,
            emailController: _clientEmailController,
            addressController: _clientAddressController,
            clientSuggester: invoiceProvider.suggestClients,
            labelText: lang.tr('client_name'),
          ),

          const SizedBox(height: 10),

          // Phone & Email Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _clientPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: lang.tr('client_phone'),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _clientEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: lang.tr('client_email'),
                    prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Address
          TextField(
            controller: _clientAddressController,
            decoration: InputDecoration(
              labelText: lang.tr('client_address'),
              prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(LanguageProvider lang, InvoiceProvider invoiceProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    lang.tr('items'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primaryLight),
                label: Text(
                  lang.tr('add_item'),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dynamic Items
          ...List.generate(_items.length, (index) {
            return ItemRowWidget(
              key: ValueKey(_items[index].id),
              index: index,
              item: _items[index],
              currency: _selectedCurrency,
              itemSuggester: invoiceProvider.suggestItems,
              onChanged: (updatedItem) {
                setState(() {
                  _items[index] = updatedItem;
                });
              },
              onDelete: () => _removeItem(index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTemplateSelectorCard(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.style_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                lang.tr('select_template'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: InvoiceTemplateOption.allTemplates.length,
              itemBuilder: (context, idx) {
                final template = InvoiceTemplateOption.allTemplates[idx];
                return TemplatePickerCard(
                  template: template,
                  isSelected: _selectedTemplateId == template.id,
                  onSelect: () {
                    setState(() {
                      _selectedTemplateId = template.id;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentLanguageCard(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                lang.tr('invoice_language'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lang.tr('invoice_language_desc'),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Chips for languages
          Row(
            children: AppTranslations.supportedLanguages.map((l) {
              final isSel = _selectedDocLanguage == l['code'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${l['name']} (${l['native']})'),
                  selected: isSel,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? AppColors.primary : AppColors.textPrimary,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedDocLanguage = l['code']!);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tax input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taxPercentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: lang.tr('tax'),
                    hintText: 'e.g. 15',
                    prefixIcon: const Icon(Icons.percent, size: 18, color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Notes & Payment terms
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: lang.tr('notes_terms'),
              hintText: lang.tr('notes_hint'),
              alignLabelWithHint: true,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 10),

          // Calculation breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang.tr('subtotal'), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(CurrencyHelper.formatAmount(_subtotal, _selectedCurrency),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          if (_discountTotal > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(lang.tr('discount'), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text('- ${CurrencyHelper.formatAmount(_discountTotal, _selectedCurrency)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.statusOverdue, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          if (_taxAmount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${lang.tr('tax')} (${_taxPercentController.text}%)',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(CurrencyHelper.formatAmount(_taxAmount, _selectedCurrency),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, thickness: 1.2),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.tr('grand_total'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              Text(
                CurrencyHelper.formatAmount(_grandTotal, _selectedCurrency),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
