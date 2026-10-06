import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/client_model.dart';

class ClientAutocompleteField extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final List<Client> Function(String pattern) clientSuggester;
  final String labelText;

  const ClientAutocompleteField({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    required this.clientSuggester,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Client>(
          displayStringForOption: (Client client) => client.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            return clientSuggester(textEditingValue.text);
          },
          onSelected: (Client selection) {
            nameController.text = selection.name;
            if (selection.phone.isNotEmpty) phoneController.text = selection.phone;
            if (selection.email.isNotEmpty) emailController.text = selection.email;
            if (selection.address.isNotEmpty) addressController.text = selection.address;
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // Keep nameController in sync
            fieldTextEditingController.text = nameController.text;
            fieldTextEditingController.selection = TextSelection.fromPosition(
              TextPosition(offset: fieldTextEditingController.text.length),
            );

            return TextField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              decoration: InputDecoration(
                labelText: labelText,
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryLight),
                suffixIcon: fieldTextEditingController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          fieldTextEditingController.clear();
                          nameController.clear();
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                nameController.text = val;
              },
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<Client> onSelected,
            Iterable<Client> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (BuildContext context, int index) {
                      final Client client = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primaryLight.withOpacity(0.12),
                          child: Text(
                            client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          client.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: client.phone.isNotEmpty || client.address.isNotEmpty
                            ? Text(
                                [client.phone, client.address].where((s) => s.isNotEmpty).join(' • '),
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: const Icon(Icons.north_west, size: 14, color: AppColors.textMuted),
                        onTap: () {
                          onSelected(client);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
