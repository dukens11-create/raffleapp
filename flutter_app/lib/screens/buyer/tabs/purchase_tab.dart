import 'package:flutter/material.dart';
import '../../../services/buyer_api_service.dart';
import '../../../models/buyer/payment_method.dart';
import '../../../models/buyer/purchase_data.dart';
import '../../../widgets/buyer/loading_spinner.dart';
import '../../../widgets/buyer/custom_button.dart';

class PurchaseTab extends StatefulWidget {
  const PurchaseTab({super.key});

  @override
  State<PurchaseTab> createState() => _PurchaseTabState();
}

class _PurchaseTabState extends State<PurchaseTab> {
  final BuyerApiService _apiService = BuyerApiService();
  int _currentStep = 0;

  // Step 1: Buyer Information
  final _step1FormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedCategory;
  int _quantity = 1;
  List<String> _departments = [];
  bool _loadingDepartments = false;

  // Step 2: Payment Method
  List<PaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedPaymentMethod;
  bool _loadingPaymentMethods = false;

  // Step 3: Payment Details
  ManualInstructions? _manualInstructions;
  bool _loadingInstructions = false;
  final _transactionRefController = TextEditingController();
  String? _buyerCode;
  bool _submittingPurchase = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _transactionRefController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadingDepartments = true);
    try {
      final departments = await _apiService.getDepartments();
      setState(() {
        _departments = departments;
        _loadingDepartments = false;
      });
    } catch (e) {
      setState(() => _loadingDepartments = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading departments: $e')),
        );
      }
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _loadingPaymentMethods = true);
    try {
      final methods = await _apiService.getPaymentMethods();
      setState(() {
        _paymentMethods = methods.where((m) => m.isActive).toList();
        _loadingPaymentMethods = false;
      });
    } catch (e) {
      setState(() => _loadingPaymentMethods = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payment methods: $e')),
        );
      }
    }
  }

  Future<void> _loadManualInstructions(String method) async {
    setState(() => _loadingInstructions = true);
    try {
      final instructions = await _apiService.getManualInstructions(method);
      setState(() {
        _manualInstructions = instructions;
        _loadingInstructions = false;
      });
    } catch (e) {
      setState(() => _loadingInstructions = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading instructions: $e')),
        );
      }
    }
  }

  int _calculateTotal() {
    final prices = {
      'XYZ': 50,
      'EFG': 100,
      'ABC': 500,
    };
    return (prices[_selectedCategory] ?? 0) * _quantity;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_step1FormKey.currentState!.validate()) {
        _loadPaymentMethods();
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      if (_selectedPaymentMethod != null) {
        if (!_selectedPaymentMethod!.isAutomated) {
          _loadManualInstructions(_selectedPaymentMethod!.method);
        }
        setState(() => _currentStep = 2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a payment method')),
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitPurchase() async {
    setState(() => _submittingPurchase = true);
    try {
      final request = PurchaseRequest(
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        department: _selectedDepartment!,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        category: _selectedCategory!,
        quantity: _quantity,
        paymentMethod: _selectedPaymentMethod!.method,
      );

      final response = await _apiService.initiatePurchase(request);
      
      if (response.success) {
        setState(() {
          _buyerCode = response.buyerCode;
          _submittingPurchase = false;
        });

        if (_selectedPaymentMethod!.isAutomated && response.redirectUrl != null) {
          // Handle automated payment redirect
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Redirect to Payment'),
                content: Text('You will be redirected to ${_selectedPaymentMethod!.displayName}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          // Show success for manual payment
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Purchase initiated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _submittingPurchase = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitManualPayment() async {
    if (_transactionRefController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter transaction reference')),
      );
      return;
    }

    setState(() => _submittingPurchase = true);
    try {
      final request = ManualPaymentRequest(
        buyerCode: _buyerCode!,
        transactionReference: _transactionRefController.text,
        paymentMethod: _selectedPaymentMethod!.method,
      );

      final response = await _apiService.submitManualPayment(request);
      
      setState(() => _submittingPurchase = false);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Submitted'),
            content: Text(response.message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetForm();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _submittingPurchase = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _fullNameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _selectedDepartment = null;
      _selectedCategory = null;
      _quantity = 1;
      _selectedPaymentMethod = null;
      _manualInstructions = null;
      _transactionRefController.clear();
      _buyerCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 24),
              if (_currentStep == 0) _buildStep1(),
              if (_currentStep == 1) _buildStep2(),
              if (_currentStep == 2) _buildStep3(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, _currentStep >= 0),
        Expanded(child: _buildStepLine(_currentStep >= 1)),
        _buildStepCircle(2, _currentStep >= 1),
        Expanded(child: _buildStepLine(_currentStep >= 2)),
        _buildStepCircle(3, _currentStep >= 2),
      ],
    );
  }

  Widget _buildStepCircle(int step, bool isActive) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF667eea) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      height: 2,
      color: isActive ? const Color(0xFF667eea) : Colors.grey[300],
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 Step 1: Your Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1e293b),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedDepartment,
            decoration: const InputDecoration(
              labelText: 'Department *',
              prefixIcon: Icon(Icons.location_city),
              border: OutlineInputBorder(),
            ),
            items: _departments
                .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                .toList(),
            onChanged: (value) => setState(() => _selectedDepartment = value),
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address (Optional)',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Ticket Category *',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'XYZ', child: Text('XYZ (50 HTG)')),
              DropdownMenuItem(value: 'EFG', child: Text('EFG (100 HTG)')),
              DropdownMenuItem(value: 'ABC', child: Text('ABC (500 HTG)')),
            ],
            onChanged: (value) => setState(() => _selectedCategory = value),
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Quantity: ', style: TextStyle(fontSize: 16)),
              IconButton(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _quantity < 10
                    ? () => setState(() => _quantity++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_calculateTotal()} HTG',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Continue to Payment',
            onPressed: _nextStep,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    if (_loadingPaymentMethods) {
      return const LoadingSpinner(message: 'Loading payment methods...');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💳 Step 2: Choose Payment Method',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 20),
        ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Back',
          onPressed: _previousStep,
          isPrimary: false,
          icon: Icons.arrow_back,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod?.method == method.method;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = method);
        _nextStep();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF667eea) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? const Color(0xFF667eea).withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              method.isAutomated ? Icons.flash_on : Icons.edit,
              color: const Color(0xFF667eea),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: method.isAutomated
                          ? const Color(0xFF10b981).withOpacity(0.15)
                          : const Color(0xFFf59e0b).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      method.isAutomated ? 'Instant' : 'Requires Approval',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: method.isAutomated
                            ? const Color(0xFF059669)
                            : const Color(0xFFd97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    if (_selectedPaymentMethod == null) {
      return const Text('Error: No payment method selected');
    }

    if (_selectedPaymentMethod!.isAutomated) {
      return _buildAutomatedPayment();
    } else {
      return _buildManualPayment();
    }
  }

  Widget _buildAutomatedPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💳 Step 3: Complete Payment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10b981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Purchase Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Name', _fullNameController.text),
              _buildSummaryRow('Category', _selectedCategory ?? ''),
              _buildSummaryRow('Quantity', '$_quantity'),
              _buildSummaryRow('Total', '${_calculateTotal()} HTG'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Proceed to ${_selectedPaymentMethod!.displayName}',
          onPressed: _submittingPurchase ? null : _submitPurchase,
          isLoading: _submittingPurchase,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Back',
          onPressed: _previousStep,
          isPrimary: false,
          icon: Icons.arrow_back,
        ),
      ],
    );
  }

  Widget _buildManualPayment() {
    if (_loadingInstructions) {
      return const LoadingSpinner(message: 'Loading instructions...');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💳 Step 3: Manual Payment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 20),
        if (_buyerCode == null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Purchase Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Name', _fullNameController.text),
                _buildSummaryRow('Category', _selectedCategory ?? ''),
                _buildSummaryRow('Quantity', '$_quantity'),
                _buildSummaryRow('Total', '${_calculateTotal()} HTG'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Generate Buyer Code',
            onPressed: _submittingPurchase ? null : _submitPurchase,
            isLoading: _submittingPurchase,
          ),
        ] else ...[
          if (_manualInstructions != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFfef3c7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Instructions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400e),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Wallet Number: ${_manualInstructions!.walletNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400e),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._manualInstructions!.instructions
                      .asMap()
                      .entries
                      .map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key + 1}. ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400e),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(color: Color(0xFF92400e)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Buyer Code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _buyerCode!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667eea),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _transactionRefController,
              decoration: const InputDecoration(
                labelText: 'Transaction Reference *',
                hintText: 'Enter transaction reference',
                prefixIcon: Icon(Icons.receipt),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Submit Payment',
              onPressed: _submittingPurchase ? null : _submitManualPayment,
              isLoading: _submittingPurchase,
            ),
          ],
        ],
        const SizedBox(height: 12),
        CustomButton(
          text: 'Back',
          onPressed: _previousStep,
          isPrimary: false,
          icon: Icons.arrow_back,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748b))),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
        ],
      ),
    );
  }
}
