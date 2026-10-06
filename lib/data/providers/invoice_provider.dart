import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_model.dart';
import '../services/storage_service.dart';

class InvoiceProvider extends ChangeNotifier {
  List<Invoice> _invoices = [];
  List<Client> _savedClients = [];
  List<InvoiceItem> _savedItems = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedStatus = 'all'; // 'all', 'paid', 'pending', 'overdue'
  DateTime? _startDate;
  DateTime? _endDate;

  List<Invoice> get invoices => _invoices;
  List<Client> get savedClients => _savedClients;
  List<InvoiceItem> get savedItems => _savedItems;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedStatus => _selectedStatus;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get hasDateFilter => _startDate != null || _endDate != null;

  // Public notify for external mutations (e.g., ManageContactsScreen)
  @override
  void notifyListeners() => super.notifyListeners();

  InvoiceProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _invoices = await StorageService.loadInvoices();
    _savedClients = await StorageService.loadClients();
    _savedItems = await StorageService.loadItems();

    // Populate clients and items from existing invoices if saved pools are empty
    _extractSuggestionsFromInvoices();

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  List<Invoice> get dateFilteredInvoices {
    if (!hasDateFilter) return _invoices;
    return _invoices.where((inv) {
      if (_startDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final invDate = DateTime(inv.date.year, inv.date.month, inv.date.day);
        if (invDate.isBefore(start)) return false;
      }
      if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (inv.date.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  List<Invoice> get activeInvoicesForStats => hasDateFilter ? dateFilteredInvoices : _invoices;

  List<Invoice> get filteredInvoices {
    final base = activeInvoicesForStats;
    return base.where((inv) {
      final matchesSearch = _searchQuery.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inv.client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inv.client.phone.contains(_searchQuery);

      final matchesStatus = _selectedStatus == 'all' || inv.status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // --- Suggestion Helpers ---
  List<Client> suggestClients(String pattern) {
    if (pattern.trim().isEmpty) return _savedClients.take(5).toList();
    final lower = pattern.trim().toLowerCase();
    return _savedClients.where((c) {
      return c.name.toLowerCase().contains(lower) ||
          c.phone.contains(pattern) ||
          c.email.toLowerCase().contains(lower);
    }).toList();
  }

  List<InvoiceItem> suggestItems(String pattern) {
    if (pattern.trim().isEmpty) return _savedItems.take(5).toList();
    final lower = pattern.trim().toLowerCase();
    return _savedItems.where((i) {
      return i.description.toLowerCase().contains(lower);
    }).toList();
  }

  // --- CRUD Operations ---
  Future<void> saveInvoice(Invoice invoice) async {
    final index = _invoices.indexWhere((inv) => inv.id == invoice.id);
    if (index >= 0) {
      _invoices[index] = invoice;
    } else {
      _invoices.insert(0, invoice);
    }

    // Auto-save Client to suggestion pool
    _addOrUpdateClientSuggestion(invoice.client);

    // Auto-save Items to suggestion pool
    for (final item in invoice.items) {
      _addOrUpdateItemSuggestion(item);
    }

    notifyListeners();
    await StorageService.saveInvoices(_invoices);
    await StorageService.saveClients(_savedClients);
    await StorageService.saveItems(_savedItems);
  }

  Future<void> deleteInvoice(String id) async {
    _invoices.removeWhere((inv) => inv.id == id);
    notifyListeners();
    await StorageService.saveInvoices(_invoices);
  }

  Future<void> updateStatus(String id, String newStatus) async {
    final index = _invoices.indexWhere((inv) => inv.id == id);
    if (index >= 0) {
      _invoices[index] = _invoices[index].copyWith(status: newStatus);
      notifyListeners();
      await StorageService.saveInvoices(_invoices);
    }
  }

  void _addOrUpdateClientSuggestion(Client client) {
    if (client.name.trim().isEmpty) return;
    final index = _savedClients.indexWhere(
      (c) => c.name.trim().toLowerCase() == client.name.trim().toLowerCase(),
    );
    if (index >= 0) {
      _savedClients[index] = client;
    } else {
      _savedClients.insert(0, client);
    }
  }

  void _addOrUpdateItemSuggestion(InvoiceItem item) {
    if (item.description.trim().isEmpty) return;
    final index = _savedItems.indexWhere(
      (i) => i.description.trim().toLowerCase() == item.description.trim().toLowerCase(),
    );
    if (index >= 0) {
      _savedItems[index] = item;
    } else {
      _savedItems.insert(0, item);
    }
  }

  void _extractSuggestionsFromInvoices() {
    bool hasNew = false;
    for (final inv in _invoices) {
      if (inv.client.name.isNotEmpty &&
          !_savedClients.any((c) => c.name.toLowerCase() == inv.client.name.toLowerCase())) {
        _savedClients.add(inv.client);
        hasNew = true;
      }
      for (final item in inv.items) {
        if (item.description.isNotEmpty &&
            !_savedItems.any((i) => i.description.toLowerCase() == item.description.toLowerCase())) {
          _savedItems.add(item);
          hasNew = true;
        }
      }
    }
    if (hasNew) {
      StorageService.saveClients(_savedClients);
      StorageService.saveItems(_savedItems);
    }
  }

  // --- Statistics & Counts (Dynamically reflect date filter if active) ---
  int get countAll => activeInvoicesForStats.length;
  int get countPaid => activeInvoicesForStats
      .where((inv) => inv.status.toLowerCase() == 'paid')
      .length;
  int get countPending => activeInvoicesForStats
      .where((inv) => inv.status.toLowerCase() == 'pending')
      .length;

  double get totalInvoiced => activeInvoicesForStats.fold(0.0, (sum, inv) => sum + inv.grandTotal);
  double get totalPaid => activeInvoicesForStats
      .where((inv) => inv.status.toLowerCase() == 'paid')
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);
  double get totalPending => activeInvoicesForStats
      .where((inv) => inv.status.toLowerCase() == 'pending')
      .fold(0.0, (sum, inv) => sum + inv.grandTotal);
}
