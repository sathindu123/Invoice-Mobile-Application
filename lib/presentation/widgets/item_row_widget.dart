import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/models/invoice_item_model.dart';

class ItemRowWidget extends StatefulWidget {
  final int index;
  final InvoiceItem item;
  final String currency;
  final List<InvoiceItem> Function(String pattern) itemSuggester;
  final ValueChanged<InvoiceItem> onChanged;
  final VoidCallback onDelete;

  const ItemRowWidget({
    super.key,
    required this.index,
    required this.item,
    required this.currency,
    required this.itemSuggester,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<ItemRowWidget> createState() => _ItemRowWidgetState();
}

class _ItemRowWidgetState extends State<ItemRowWidget> {
  late TextEditingController _descController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.item.description);
    _qtyController = TextEditingController(
      text: widget.item.quantity.toStringAsFixed(
        widget.item.quantity.truncateToDouble() == widget.item.quantity ? 0 : 2,
      ),
    );
    _priceController = TextEditingController(
      text: widget.item.unitPrice > 0 ? widget.item.unitPrice.toStringAsFixed(2) : '',
    );
    _discountController = TextEditingController(
      text: widget.item.discountPercent > 0 ? widget.item.discountPercent.toString() : '',
    );
  }

  @override
  void didUpdateWidget(covariant ItemRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      if (_descController.text != widget.item.description) {
        _descController.text = widget.item.description;
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;

    widget.onChanged(
      widget.item.copyWith(
        description: _descController.text,
        quantity: qty,
        unitPrice: price,
        discountPercent: discount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Item number and delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item #${widget.index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.statusOverdue, size: 20),
                onPressed: widget.onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description with Autocomplete
          LayoutBuilder(
            builder: (context, constraints) {
              return Autocomplete<InvoiceItem>(
                displayStringForOption: (item) => item.description,
                optionsBuilder: (textVal) {
                  return widget.itemSuggester(textVal.text);
                },
                onSelected: (selected) {
                  _descController.text = selected.description;
                  if (selected.unitPrice > 0) {
                    _priceController.text = selected.unitPrice.toStringAsFixed(2);
                  }
                  _notifyChange();
                },
                fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
                  fieldController.text = _descController.text;
                  return TextField(
                    controller: fieldController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Item Name / Description',
                      hintText: 'e.g. Graphic Design, Laptop repair...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) {
                      _descController.text = val;
                      _notifyChange();
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: constraints.maxWidth,
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                          itemBuilder: (context, idx) {
                            final item = options.elementAt(idx);
                            return ListTile(
                              dense: true,
                              title: Text(item.description, style: const TextStyle(fontSize: 13)),
                              trailing: Text(
                                CurrencyHelper.formatAmount(item.unitPrice, widget.currency),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onTap: () => onSelected(item),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),

          // Qty, Price, Discount Row
          Row(
            children: [
              // Quantity
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (_) => _notifyChange(),
                ),
              ),
              const SizedBox(width: 8),
              // Price
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price (${CurrencyHelper.getSymbol(widget.currency)})',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (_) => _notifyChange(),
                ),
              ),
              const SizedBox(width: 8),
              // Discount %
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Disc %',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (_) => _notifyChange(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Item Total calculation bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Line Total:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  CurrencyHelper.formatAmount(widget.item.total, widget.currency),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
