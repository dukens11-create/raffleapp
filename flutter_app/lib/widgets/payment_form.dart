import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/department.dart';
import '../models/ticket_category.dart';
import 'department_selector.dart';

class PaymentForm extends StatefulWidget {
  final List<TicketCategory> categories;
  final Function(PaymentFormData) onSubmit;
  final bool useKreyol;
  final String? initialCategory;

  const PaymentForm({
    super.key,
    required this.categories,
    required this.onSubmit,
    this.useKreyol = false,
    this.initialCategory,
  });

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _selectedCategory;
  Department? _selectedDepartment;
  int _quantity = 1;
  String _paymentMethod = 'moncash';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buyer Information Section
          Text(
            widget.useKreyol ? 'Enfòmasyon Ou' : 'Vos Informations',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: widget.useKreyol ? 'Non Konplè' : 'Nom Complet',
              hintText: widget.useKreyol ? 'Antre non w' : 'Entrez votre nom',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return widget.useKreyol ? 'Non obligatwa' : 'Nom requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Phone field
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: widget.useKreyol ? 'Nimewo Telefòn' : 'Numéro de Téléphone',
              hintText: '509-XXXX-XXXX',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\-\+\s]')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return widget.useKreyol ? 'Telefòn obligatwa' : 'Téléphone requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Email field (optional)
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: widget.useKreyol ? 'Imel (Opsyonèl)' : 'Email (Optionnel)',
              hintText: 'exemple@email.com',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          
          // Department selector
          DepartmentSelector(
            selectedDepartment: _selectedDepartment?.code,
            onDepartmentChanged: (department) {
              setState(() {
                _selectedDepartment = department;
              });
            },
            useKreyol: widget.useKreyol,
            required: true,
          ),
          const SizedBox(height: 24),
          
          // Ticket Selection Section
          Text(
            widget.useKreyol ? 'Chwazi Tikè' : 'Sélection des Tickets',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Category dropdown
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: widget.useKreyol ? 'Kategori' : 'Catégorie',
              prefixIcon: const Icon(Icons.category),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: widget.categories.map((category) {
              final available = category.isAvailable;
              return DropdownMenuItem<String>(
                value: category.categoryCode,
                enabled: available,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${category.categoryCode} - ${category.categoryName}',
                      style: TextStyle(
                        color: available ? Colors.black : Colors.grey,
                      ),
                    ),
                    Text(
                      '${category.price.toStringAsFixed(0)} HTG',
                      style: TextStyle(
                        color: available ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return widget.useKreyol ? 'Chwazi kategori' : 'Sélectionnez une catégorie';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Quantity selector
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.useKreyol ? 'Kantite' : 'Quantité',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _quantity.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _quantity < 10
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Payment Method Section
          Text(
            widget.useKreyol ? 'Mètod Peman' : 'Méthode de Paiement',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Payment method selection
          _buildPaymentMethodOption(
            'moncash',
            'MonCash',
            Icons.payment,
          ),
          _buildPaymentMethodOption(
            'natcash',
            'NatCash',
            Icons.account_balance_wallet,
          ),
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.useKreyol ? 'Kontinye ak Peman' : 'Continuer au Paiement',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.blue[50] : Colors.white,
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _paymentMethod,
        onChanged: (newValue) {
          setState(() {
            _paymentMethod = newValue!;
          });
        },
        title: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final data = PaymentFormData(
        buyerName: _nameController.text,
        buyerPhone: _phoneController.text,
        buyerEmail: _emailController.text.isEmpty ? null : _emailController.text,
        department: _selectedDepartment?.code,
        category: _selectedCategory!,
        quantity: _quantity,
        paymentMethod: _paymentMethod,
      );
      
      widget.onSubmit(data);
    }
  }
}

class PaymentFormData {
  final String buyerName;
  final String buyerPhone;
  final String? buyerEmail;
  final String? department;
  final String category;
  final int quantity;
  final String paymentMethod;

  PaymentFormData({
    required this.buyerName,
    required this.buyerPhone,
    this.buyerEmail,
    this.department,
    required this.category,
    required this.quantity,
    required this.paymentMethod,
  });
}
