import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../data/models/client_model.dart';
import '../../data/models/invoice_item_model.dart';
import '../../data/providers/invoice_provider.dart';
import '../../data/services/storage_service.dart';
import '../widgets/pagination_bar.dart';

class ManageContactsScreen extends StatefulWidget {
  const ManageContactsScreen({super.key});

  @override
  State<ManageContactsScreen> createState() => _ManageContactsScreenState();
}

class _ManageContactsScreenState extends State<ManageContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _customerSearch = '';
  String _itemSearch = '';
  int _customerPage = 1;
  int _itemPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ========== CUSTOMER METHODS ==========
  void _addEditCustomer(BuildContext context, InvoiceProvider provider, {Client? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  existing == null ? '➕ Add Customer' : '✏️ Edit Customer',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDeco('Customer Full Name *', Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDeco('Phone Number', Icons.phone_outlined),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDeco('Email Address', Icons.email_outlined),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addrCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDeco('Billing Address', Icons.location_on_outlined),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final client = Client(
                        id: existing?.id ?? const Uuid().v4(),
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        address: addrCtrl.text.trim(),
                      );
                      final idx = provider.savedClients.indexWhere((c) => c.id == client.id);
                      if (idx >= 0) {
                        provider.savedClients[idx] = client;
                      } else {
                        provider.savedClients.insert(0, client);
                      }
                      await StorageService.saveClients(provider.savedClients);
                      provider.notifyListeners();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      existing == null ? 'Add Customer' : 'Update Customer',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteCustomer(BuildContext context, InvoiceProvider provider, Client client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete "${client.name}" from customers?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      provider.savedClients.removeWhere((c) => c.id == client.id);
      await StorageService.saveClients(provider.savedClients);
      provider.notifyListeners();
    }
  }

  // ========== ITEM METHODS ==========
  void _addEditItem(BuildContext context, InvoiceProvider provider, {InvoiceItem? existing}) {
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.unitPrice.toStringAsFixed(2) : '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  existing == null ? '➕ Add Item / Service' : '✏️ Edit Item / Service',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDeco('Item / Service Description *', Icons.inventory_2_outlined),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Description required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDeco('Unit Price (optional)', Icons.monetization_on_outlined),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final item = InvoiceItem(
                        id: existing?.id ?? const Uuid().v4(),
                        description: descCtrl.text.trim(),
                        quantity: existing?.quantity ?? 1,
                        unitPrice: double.tryParse(priceCtrl.text) ?? 0.0,
                      );
                      final idx = provider.savedItems.indexWhere((i) => i.id == item.id);
                      if (idx >= 0) {
                        provider.savedItems[idx] = item;
                      } else {
                        provider.savedItems.insert(0, item);
                      }
                      await StorageService.saveItems(provider.savedItems);
                      provider.notifyListeners();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      existing == null ? 'Add Item' : 'Update Item',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteItem(BuildContext context, InvoiceProvider provider, InvoiceItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${item.description}" from items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      provider.savedItems.removeWhere((i) => i.id == item.id);
      await StorageService.saveItems(provider.savedItems);
      provider.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InvoiceProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0 ? 'Add Customer' : 'Add Item',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            _addEditCustomer(context, provider);
          } else {
            _addEditItem(context, provider);
          }
        },
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: '${lang.tr('customers')} (${provider.savedClients.length})'),
              Tab(text: '${lang.tr('items')} (${provider.savedItems.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // CUSTOMERS TAB
                _buildCustomerList(context, provider, lang),
                // ITEMS TAB
                _buildItemList(context, provider, lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(BuildContext context, InvoiceProvider provider, LanguageProvider lang) {
    final allClients = provider.savedClients;

    // Filter customers by search
    final filteredClients = allClients.where((c) {
      if (_customerSearch.trim().isEmpty) return true;
      final q = _customerSearch.trim().toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q);
    }).toList();

    final totalItems = filteredClients.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 999999);
    if (_customerPage > totalPages) {
      _customerPage = 1;
    }
    final startIndex = (_customerPage - 1) * _itemsPerPage;
    final pageClients = filteredClients.skip(startIndex).take(_itemsPerPage).toList();

    return Column(
      children: [
        // Search Bar for Customers
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            decoration: InputDecoration(
              hintText: lang.tr('search_customers'),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              suffixIcon: _customerSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() {
                        _customerSearch = '';
                        _customerPage = 1;
                      }),
                    )
                  : null,
            ),
            onChanged: (val) => setState(() {
              _customerSearch = val;
              _customerPage = 1;
            }),
          ),
        ),

        // List & Pagination
        Expanded(
          child: totalItems == 0
              ? _buildEmptyState(
                  _customerSearch.isEmpty ? 'No customers saved yet' : 'No customers match your search',
                  _customerSearch.isEmpty
                      ? 'Customers added during invoice creation appear here'
                      : 'Try searching with a different name or phone number',
                  Icons.people_outline,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    ...pageClients.map((client) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                              child: Text(
                                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              client.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (client.phone.isNotEmpty)
                                  Text(client.phone, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                                if (client.email.isNotEmpty)
                                  Text(client.email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                if (client.address.isNotEmpty)
                                  Text(client.address, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                            isThreeLine: client.email.isNotEmpty || client.address.isNotEmpty,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                  onPressed: () => _addEditCustomer(context, provider, existing: client),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => _deleteCustomer(context, provider, client),
                                ),
                              ],
                            ),
                          ),
                        )),

                    // Pagination
                    PaginationBar(
                      currentPage: _customerPage,
                      totalItems: totalItems,
                      itemsPerPage: _itemsPerPage,
                      onPageChanged: (newPage) {
                        setState(() => _customerPage = newPage);
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildItemList(BuildContext context, InvoiceProvider provider, LanguageProvider lang) {
    final allItems = provider.savedItems;

    // Filter items by search
    final filteredItems = allItems.where((i) {
      if (_itemSearch.trim().isEmpty) return true;
      final q = _itemSearch.trim().toLowerCase();
      return i.description.toLowerCase().contains(q) ||
          i.unitPrice.toString().contains(q);
    }).toList();

    final totalItems = filteredItems.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 999999);
    if (_itemPage > totalPages) {
      _itemPage = 1;
    }
    final startIndex = (_itemPage - 1) * _itemsPerPage;
    final pageItems = filteredItems.skip(startIndex).take(_itemsPerPage).toList();

    return Column(
      children: [
        // Search Bar for Items
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            decoration: InputDecoration(
              hintText: lang.tr('search_items'),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              suffixIcon: _itemSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() {
                        _itemSearch = '';
                        _itemPage = 1;
                      }),
                    )
                  : null,
            ),
            onChanged: (val) => setState(() {
              _itemSearch = val;
              _itemPage = 1;
            }),
          ),
        ),

        // List & Pagination
        Expanded(
          child: totalItems == 0
              ? _buildEmptyState(
                  _itemSearch.isEmpty ? 'No items saved yet' : 'No items match your search',
                  _itemSearch.isEmpty
                      ? 'Items added during invoice creation appear here'
                      : 'Try searching with a different description',
                  Icons.inventory_2_outlined,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    ...pageItems.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, size: 22, color: AppColors.accent),
                            ),
                            title: Text(
                              item.description,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            subtitle: item.unitPrice > 0
                                ? Text('Unit Price: Rs. ${item.unitPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))
                                : const Text('No price set', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                  onPressed: () => _addEditItem(context, provider, existing: item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => _deleteItem(context, provider, item),
                                ),
                              ],
                            ),
                          ),
                        )),

                    // Pagination
                    PaginationBar(
                      currentPage: _itemPage,
                      totalItems: totalItems,
                      itemsPerPage: _itemsPerPage,
                      onPageChanged: (newPage) {
                        setState(() => _itemPage = newPage);
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
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
            child: Icon(icon, size: 34, color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      fillColor: AppColors.background,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}
