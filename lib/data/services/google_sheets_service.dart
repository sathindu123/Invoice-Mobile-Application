import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/invoice_model.dart';
import '../models/business_profile.dart';

class GoogleSheetsService {
  /// Syncs the given list of invoices to Google Apps Script Web App
  static Future<Map<String, dynamic>> syncToGoogleSheets({
    required String webAppUrl,
    required List<Invoice> invoices,
    required BusinessProfile profile,
  }) async {
    if (webAppUrl.trim().isEmpty) {
      return {'success': false, 'message': 'Google Apps Script URL is empty'};
    }

    try {
      final payload = {
        'action': 'sync_invoices',
        'business': {
          'name': profile.name,
          'phone': profile.phone,
          'email': profile.email,
        },
        'invoices': invoices.map((inv) {
          return {
            'id': inv.id,
            'invoiceNumber': inv.invoiceNumber,
            'date': inv.date.toIso8601String(),
            'dueDate': inv.dueDate?.toIso8601String() ?? '',
            'clientName': inv.client.name,
            'clientPhone': inv.client.phone,
            'clientEmail': inv.client.email,
            'clientAddress': inv.client.address,
            'currency': inv.currency,
            'status': inv.status,
            'subtotal': inv.subtotal,
            'discount': inv.discountAmount,
            'tax': inv.taxAmount,
            'total': inv.grandTotal,
            'itemsSummary': inv.items.map((i) => '${i.description} (x${i.quantity.toInt()})').join(', '),
            'notes': inv.notes,
          };
        }).toList(),
      };

      final response = await http.post(
        Uri.parse(webAppUrl.trim()),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        try {
          final data = jsonDecode(response.body);
          return {'success': true, 'data': data};
        } catch (_) {
          return {'success': true, 'message': 'Synced successfully'};
        }
      } else {
        return {
          'success': false,
          'message': 'Server responded with status code ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('Google Sheet sync error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Ready-to-copy Google Apps Script code for the user
  static const String sampleAppsScriptCode = '''
/**
 * GOOGLE APPS SCRIPT FOR INVOICE APP
 * 
 * Instructions:
 * 1. Open Google Sheets (create a new sheet).
 * 2. Click Extensions > Apps Script.
 * 3. Replace all code with this script.
 * 4. Click Deploy > New deployment.
 * 5. Select type: "Web app".
 * 6. Set "Execute as": "Me".
 * 7. Set "Who has access": "Anyone".
 * 8. Click Deploy and copy the Web App URL into the Invoice App Settings!
 */

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheet = ss.getSheetByName("Invoices");
    
    if (!sheet) {
      sheet = ss.insertSheet("Invoices");
      sheet.appendRow([
        "Invoice #",
        "Date",
        "Due Date",
        "Client Name",
        "Client Phone",
        "Client Email",
        "Currency",
        "Subtotal",
        "Discount",
        "Tax",
        "Total",
        "Status",
        "Items Summary",
        "Notes",
        "Last Updated"
      ]);
      sheet.getRange(1, 1, 1, 15).setFontWeight("bold").setBackground("#1E3A8A").setFontColor("#FFFFFF");
    }
    
    if (data.action === "sync_invoices" && data.invoices) {
      // Clear existing rows (keep header)
      if (sheet.getLastRow() > 1) {
        sheet.deleteRows(2, sheet.getLastRow() - 1);
      }
      
      var rows = [];
      for (var i = 0; i < data.invoices.length; i++) {
        var inv = data.invoices[i];
        rows.push([
          inv.invoiceNumber || "",
          inv.date ? inv.date.substring(0, 10) : "",
          inv.dueDate ? inv.dueDate.substring(0, 10) : "",
          inv.clientName || "",
          inv.clientPhone || "",
          inv.clientEmail || "",
          inv.currency || "",
          inv.subtotal || 0,
          inv.discount || 0,
          inv.tax || 0,
          inv.total || 0,
          inv.status || "",
          inv.itemsSummary || "",
          inv.notes || "",
          new Date()
        ]);
      }
      
      if (rows.length > 0) {
        sheet.getRange(2, 1, rows.length, 15).setValues(rows);
      }
      
      return ContentService.createTextOutput(JSON.stringify({
        status: "success",
        syncedCount: rows.length
      })).setMimeType(ContentService.MimeType.JSON);
    }
    
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: "Invalid action"
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: err.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}
''';
}
