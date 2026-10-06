import 'package:flutter/material.dart';

class InvoiceTemplateOption {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color accentColor;
  final IconData icon;

  const InvoiceTemplateOption({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
    required this.icon,
  });

  static const List<InvoiceTemplateOption> allTemplates = [
    InvoiceTemplateOption(
      id: 'modern_blue',
      name: 'Modern Blue',
      description: 'Clean indigo header with modern contrast',
      primaryColor: Color(0xFF1E3A8A),
      accentColor: Color(0xFF3B82F6),
      icon: Icons.dashboard_customize_outlined,
    ),
    InvoiceTemplateOption(
      id: 'corporate_slate',
      name: 'Corporate Slate',
      description: 'Professional dark slate design for formal businesses',
      primaryColor: Color(0xFF1E293B),
      accentColor: Color(0xFF475569),
      icon: Icons.business_outlined,
    ),
    InvoiceTemplateOption(
      id: 'emerald_teal',
      name: 'Emerald Teal',
      description: 'Fresh teal accent with modern rounded badges',
      primaryColor: Color(0xFF0F766E),
      accentColor: Color(0xFF14B8A6),
      icon: Icons.eco_outlined,
    ),
    InvoiceTemplateOption(
      id: 'minimalist_clean',
      name: 'Minimalist Clean',
      description: 'Monochrome, lightweight and paper-efficient',
      primaryColor: Color(0xFF000000),
      accentColor: Color(0xFF64748B),
      icon: Icons.article_outlined,
    ),
    InvoiceTemplateOption(
      id: 'compact_receipt',
      name: 'Compact Receipt',
      description: 'Slip / thermal receipt style for quick billing',
      primaryColor: Color(0xFF262626),
      accentColor: Color(0xFF525252),
      icon: Icons.receipt_long_outlined,
    ),
  ];

  static InvoiceTemplateOption getById(String id) {
    return allTemplates.firstWhere(
      (t) => t.id == id,
      orElse: () => allTemplates.first,
    );
  }
}
