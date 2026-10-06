import 'package:flutter/material.dart';

void main() {
  runApp(const InvoiceApp());
}

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invoice Generator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const InvoiceScreen(),
    );
  }
}

// Invoice Screen Class eka methanin patan gannawa
class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  // Text Controllers for getting user input
  final _customerController = TextEditingController();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();

  String customerName = "";
  String itemName = "";
  String itemPrice = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Name Input
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Item Name Input
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Price Input
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (LRS / USD)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    customerName = _customerController.text;
                    itemName = _itemController.text;
                    itemPrice = _priceController.text;
                  });
                },
                child: const Text('Generate Invoice'),
              ),
            ),
            const SizedBox(height: 30),
            
            // Invoice Preview Section
            const Text(
              'Invoice Preview:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text('Customer: $customerName', style: const TextStyle(fontSize: 16)),
            Text('Item: $itemName', style: const TextStyle(fontSize: 16)),
            Text('Total Amount: \$$itemPrice', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}