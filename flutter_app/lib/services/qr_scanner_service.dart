import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

/// Service for QR code and barcode scanning
/// 
/// Supports:
/// - QR codes
/// - Barcodes (Code 128, Code 39)
/// - Ticket validation via API
class QRScannerService {
  final ApiService _api = ApiService();

  /// Validate a scanned ticket barcode/QR code
  /// 
  /// Makes API call to /api/validate-ticket
  /// Returns validation result with ticket details
  Future<TicketValidationResult> validateTicket(String ticketCode) async {
    try {
      final response = await _api.post(
        '${ApiConfig.apiVersion}/validate-ticket',
        data: {'ticket_code': ticketCode},
      );

      if (response.statusCode == 200) {
        return TicketValidationResult.fromJson(response.data);
      } else {
        return TicketValidationResult.error(
          'Validation failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return TicketValidationResult.error('Error validating ticket: $e');
    }
  }

  /// Check if a barcode format is supported
  static bool isSupportedFormat(BarcodeFormat format) {
    return format == BarcodeFormat.qrCode ||
        format == BarcodeFormat.code128 ||
        format == BarcodeFormat.code39;
  }

  /// Parse scanned barcode data
  static String? parseBarcode(Barcode barcode) {
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    return rawValue;
  }
}

/// Ticket validation result from API
class TicketValidationResult {
  final bool isValid;
  final String? ticketNumber;
  final String? category;
  final String? status;
  final String? buyerName;
  final String? buyerPhone;
  final String? message;
  final String? errorMessage;

  TicketValidationResult({
    required this.isValid,
    this.ticketNumber,
    this.category,
    this.status,
    this.buyerName,
    this.buyerPhone,
    this.message,
    this.errorMessage,
  });

  factory TicketValidationResult.fromJson(Map<String, dynamic> json) {
    return TicketValidationResult(
      isValid: json['valid'] ?? json['isValid'] ?? false,
      ticketNumber: json['ticket_number'] ?? json['ticketNumber'],
      category: json['category'],
      status: json['status'],
      buyerName: json['buyer_name'] ?? json['buyerName'],
      buyerPhone: json['buyer_phone'] ?? json['buyerPhone'],
      message: json['message'],
      errorMessage: json['error'] ?? json['errorMessage'],
    );
  }

  factory TicketValidationResult.error(String error) {
    return TicketValidationResult(
      isValid: false,
      errorMessage: error,
    );
  }

  String get displayMessage {
    if (isValid) {
      return message ?? 'Valid ticket';
    } else {
      return errorMessage ?? 'Invalid ticket';
    }
  }
}
