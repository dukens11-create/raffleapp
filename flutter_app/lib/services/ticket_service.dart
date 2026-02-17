import '../models/ticket.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class TicketService {
  final ApiService _api = ApiService();

  /// Get available tickets with pagination
  /// 
  /// Parameters:
  /// - [page]: Page number (default: 1)
  /// - [limit]: Results per page (default: 50, max: 100)
  /// - [category]: Filter by category (optional)
  Future<TicketListResponse> getAvailableTickets({
    int page = 1,
    int limit = 50,
    String? category,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category,
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _api.get(
        '${ApiConfig.publicAvailableTicketsEndpoint}?$queryString'
      );

      if (response.statusCode == 200) {
        return TicketListResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch tickets: $e');
    }
  }

  /// Get tickets by buyer phone number
  Future<List<Ticket>> getTicketsByPhone(String phone) async {
    try {
      final response = await _api.get(
        '${ApiConfig.apiVersion}/public/my-tickets?phone=${Uri.encodeComponent(phone)}'
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['tickets'] ?? response.data;
        return data.map((json) => Ticket.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch tickets by phone: $e');
    }
  }

  /// Verify ticket by ticket number
  Future<TicketVerificationResult> verifyTicket(String ticketNumber) async {
    try {
      final response = await _api.get(
        '${ApiConfig.apiVersion}/public/verify-ticket/${Uri.encodeComponent(ticketNumber)}'
      );

      if (response.statusCode == 200) {
        return TicketVerificationResult.fromJson(response.data);
      } else {
        throw Exception('Failed to verify ticket: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to verify ticket: $e');
    }
  }

  /// Get ticket availability stats
  Future<TicketAvailability> getTicketAvailability() async {
    try {
      final response = await _api.get(
        '${ApiConfig.apiVersion}/public/ticket-availability'
      );

      if (response.statusCode == 200) {
        return TicketAvailability.fromJson(response.data);
      } else {
        throw Exception('Failed to load availability: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch ticket availability: $e');
    }
  }

  /// Get last 100K available tickets per category (for buyers)
  Future<Map<String, List<Ticket>>> getBuyerAvailableTickets() async {
    try {
      final response = await _api.get(
        '${ApiConfig.apiVersion}/buyer/available-tickets'
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final Map<String, List<Ticket>> ticketsByCategory = {};

        if (data['categories'] != null) {
          for (var category in data['categories']) {
            final categoryCode = category['category'] as String;
            final tickets = (category['tickets'] as List)
                .map((json) => Ticket.fromJson(json))
                .toList();
            ticketsByCategory[categoryCode] = tickets;
          }
        }

        return ticketsByCategory;
      } else {
        throw Exception('Failed to load buyer tickets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch buyer available tickets: $e');
    }
  }
}

class TicketListResponse {
  final List<Ticket> tickets;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  TicketListResponse({
    required this.tickets,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory TicketListResponse.fromJson(Map<String, dynamic> json) {
    return TicketListResponse(
      tickets: (json['tickets'] as List)
          .map((ticket) => Ticket.fromJson(ticket))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] ?? json['total_pages'] ?? 0,
    );
  }
}

class TicketVerificationResult {
  final bool valid;
  final Ticket? ticket;
  final String? error;

  TicketVerificationResult({
    required this.valid,
    this.ticket,
    this.error,
  });

  factory TicketVerificationResult.fromJson(Map<String, dynamic> json) {
    return TicketVerificationResult(
      valid: json['valid'] as bool,
      ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
      error: json['error'] as String?,
    );
  }
}

class TicketAvailability {
  final bool success;
  final List<CategoryAvailability> categories;
  final int totalAvailable;

  TicketAvailability({
    required this.success,
    required this.categories,
    required this.totalAvailable,
  });

  factory TicketAvailability.fromJson(Map<String, dynamic> json) {
    return TicketAvailability(
      success: json['success'] as bool,
      categories: (json['categories'] as List)
          .map((cat) => CategoryAvailability.fromJson(cat))
          .toList(),
      totalAvailable: json['total_available'] as int,
    );
  }
}

class CategoryAvailability {
  final String category;
  final int available;
  final int totalOnline;
  final double price;

  CategoryAvailability({
    required this.category,
    required this.available,
    required this.totalOnline,
    required this.price,
  });

  factory CategoryAvailability.fromJson(Map<String, dynamic> json) {
    return CategoryAvailability(
      category: json['category'] as String,
      available: json['available'] as int,
      totalOnline: json['total_online'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }

  bool get isAvailable => available > 0;
}
