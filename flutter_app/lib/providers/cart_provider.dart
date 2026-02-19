import 'package:flutter/foundation.dart';
import '../utils/ticket_categories.dart';

/// Shopping cart item for ticket purchase
class CartItem {
  final String categoryCode;
  int quantity;

  CartItem({
    required this.categoryCode,
    this.quantity = 1,
  });

  TicketCategory? get category => TicketCategories.getByCode(categoryCode);
  
  double get totalPrice {
    final cat = category;
    if (cat == null) return 0.0;
    return cat.priceHTG * quantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryCode': categoryCode,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      categoryCode: json['categoryCode'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }
}

/// Shopping cart state management for ticket purchases
class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  
  // Buyer information
  String? _buyerName;
  String? _buyerPhone;
  String? _buyerEmail;
  String? _department;

  Map<String, CartItem> get items => Map.unmodifiable(_items);
  
  List<CartItem> get cartItems => _items.values.toList();
  
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  bool get isEmpty => _items.isEmpty;
  
  bool get isNotEmpty => _items.isNotEmpty;

  // Buyer information getters
  String? get buyerName => _buyerName;
  String? get buyerPhone => _buyerPhone;
  String? get buyerEmail => _buyerEmail;
  String? get department => _department;

  /// Add item to cart or increase quantity
  void addItem(String categoryCode, {int quantity = 1}) {
    if (!TicketCategories.isValid(categoryCode)) {
      throw ArgumentError('Invalid category code: $categoryCode');
    }

    if (quantity < 1 || quantity > 10) {
      throw ArgumentError('Quantity must be between 1 and 10');
    }

    if (_items.containsKey(categoryCode)) {
      final newQuantity = _items[categoryCode]!.quantity + quantity;
      if (newQuantity > 10) {
        throw ArgumentError('Maximum 10 tickets per category');
      }
      _items[categoryCode]!.quantity = newQuantity;
    } else {
      _items[categoryCode] = CartItem(
        categoryCode: categoryCode,
        quantity: quantity,
      );
    }
    notifyListeners();
  }

  /// Set exact quantity for an item
  void updateQuantity(String categoryCode, int quantity) {
    if (!_items.containsKey(categoryCode)) {
      throw ArgumentError('Item not in cart: $categoryCode');
    }

    if (quantity < 1 || quantity > 10) {
      throw ArgumentError('Quantity must be between 1 and 10');
    }

    _items[categoryCode]!.quantity = quantity;
    notifyListeners();
  }

  /// Remove item from cart
  void removeItem(String categoryCode) {
    _items.remove(categoryCode);
    notifyListeners();
  }

  /// Decrease quantity by 1, remove if quantity becomes 0
  void decreaseQuantity(String categoryCode) {
    if (!_items.containsKey(categoryCode)) return;

    if (_items[categoryCode]!.quantity > 1) {
      _items[categoryCode]!.quantity--;
    } else {
      _items.remove(categoryCode);
    }
    notifyListeners();
  }

  /// Clear all items from cart
  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Set buyer information
  void setBuyerInfo({
    String? name,
    String? phone,
    String? email,
    String? department,
  }) {
    _buyerName = name;
    _buyerPhone = phone;
    _buyerEmail = email;
    _department = department;
    notifyListeners();
  }

  /// Check if buyer information is complete
  bool get hasBuyerInfo {
    return _buyerName != null &&
        _buyerName!.isNotEmpty &&
        _buyerPhone != null &&
        _buyerPhone!.isNotEmpty;
  }

  /// Validate buyer information
  String? validateBuyerInfo() {
    if (_buyerName == null || _buyerName!.isEmpty) {
      return 'Buyer name is required';
    }
    if (_buyerPhone == null || _buyerPhone!.isEmpty) {
      return 'Buyer phone is required';
    }
    // Validate phone format (Haiti format: 509-XXXX-XXXX or similar)
    if (!_isValidPhone(_buyerPhone!)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  bool _isValidPhone(String phone) {
    // Remove spaces, dashes, parentheses
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Should be 8-11 digits (Haiti numbers)
    return RegExp(r'^\d{8,11}$').hasMatch(cleaned);
  }

  /// Get cart summary for checkout
  Map<String, dynamic> getCheckoutData() {
    return {
      'buyer_name': _buyerName,
      'buyer_phone': _buyerPhone,
      'buyer_email': _buyerEmail,
      'department': _department,
      'items': _items.values.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'item_count': itemCount,
    };
  }

  /// Check if a category is in cart
  bool hasCategory(String categoryCode) {
    return _items.containsKey(categoryCode);
  }

  /// Get quantity for a category
  int getQuantity(String categoryCode) {
    return _items[categoryCode]?.quantity ?? 0;
  }

  /// Reset cart and buyer info after successful purchase
  void resetAfterPurchase() {
    _items.clear();
    _buyerName = null;
    _buyerPhone = null;
    _buyerEmail = null;
    _department = null;
    notifyListeners();
  }
}
