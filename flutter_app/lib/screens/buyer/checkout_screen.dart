import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/department_selector_widget.dart';
import '../payment/payment_method_screen.dart';

/// Checkout screen - Review cart and enter buyer information
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    // Pre-fill if info exists
    if (cart.buyerName != null) {
      _nameController.text = cart.buyerName!;
    }
    if (cart.buyerPhone != null) {
      _phoneController.text = cart.buyerPhone!;
    }
    if (cart.buyerEmail != null) {
      _emailController.text = cart.buyerEmail!;
    }
    _selectedDepartment = cart.department;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _proceedToPayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
        ),
      );
      return;
    }

    // Save buyer information
    cart.setBuyerInfo(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty 
          ? _emailController.text.trim() 
          : null,
      department: _selectedDepartment,
    );

    // Navigate to payment method selection
    // For simplicity, if cart has only one category, use that
    // Otherwise, we would need to handle multiple items
    final firstItem = cart.cartItems.first;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodScreen(
          amount: cart.totalAmount,
          ticketCategory: firstItem.categoryCode,
          ticketQuantity: firstItem.quantity,
          buyerName: _nameController.text.trim(),
          buyerPhone: _phoneController.text.trim(),
          buyerEmail: _emailController.text.trim().isNotEmpty 
              ? _emailController.text.trim() 
              : null,
          department: _selectedDepartment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Browse Tickets'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cart summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...cart.cartItems.map((item) {
                          final category = item.category;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      iconSize: 20,
                                      onPressed: () {
                                        cart.decreaseQuantity(item.categoryCode);
                                      },
                                    ),
                                    Text(
                                      '${item.quantity}x',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${category?.code} - ${category?.name}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${item.totalPrice.toStringAsFixed(0)} HTG',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${cart.totalAmount.toStringAsFixed(0)} HTG',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Buyer information form
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Name field
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name *',
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone field
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              hintText: '509-XXXX-XXXX',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email field (optional)
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email (Optional)',
                              hintText: 'your@email.com',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // Department selector
                          DepartmentSelectorWidget(
                            selectedDepartment: _selectedDepartment,
                            onChanged: (value) {
                              setState(() => _selectedDepartment = value);
                            },
                            labelText: 'Department (Optional)',
                            hintText: 'Select your department',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: cart.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Proceed to Payment',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
