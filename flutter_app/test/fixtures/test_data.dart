import '../models/ticket.dart';
import '../models/raffle.dart';
import '../models/user.dart';
import '../models/payment.dart';
import '../models/ticket_category.dart';

/// Test data fixtures for consistent testing
class TestData {
  // Test Users
  static final adminUser = User(
    id: 'test-admin-1',
    username: 'admin',
    email: 'admin@test.com',
    role: 'admin',
    fullName: 'Test Admin',
  );

  static final sellerUser = User(
    id: 'test-seller-1',
    username: 'seller',
    email: 'seller@test.com',
    role: 'seller',
    fullName: 'Test Seller',
  );

  static final buyerUser = User(
    id: 'test-buyer-1',
    username: 'buyer',
    email: 'buyer@test.com',
    role: 'buyer',
    fullName: 'Test Buyer',
    phoneNumber: '+50912345678',
  );

  // Test Raffle
  static final activeRaffle = Raffle(
    id: 'test-raffle-1',
    name: 'Test Raffle 2024',
    description: 'Test raffle for automated testing',
    startDate: DateTime.now().subtract(const Duration(days: 7)),
    endDate: DateTime.now().add(const Duration(days: 7)),
    drawDate: DateTime.now().add(const Duration(days: 14)),
    status: 'active',
    totalTickets: 1000,
    availableTickets: 750,
  );

  // Test Ticket Categories
  static final basicCategory = TicketCategory(
    id: 'BAS',
    name: 'Basic',
    code: 'BAS',
    price: 50.0,
    description: 'Basic ticket tier',
  );

  static final premiumCategory = TicketCategory(
    id: 'PRM',
    name: 'Premium',
    code: 'PRM',
    price: 100.0,
    description: 'Premium ticket tier',
  );

  static final bronzeCategory = TicketCategory(
    id: 'BRZ',
    name: 'Bronze',
    code: 'BRZ',
    price: 250.0,
    description: 'Bronze ticket tier',
  );

  // Test Tickets
  static final basicTicket = Ticket(
    id: 'test-ticket-1',
    ticketNumber: 'BAS-001',
    raffleId: activeRaffle.id,
    categoryId: basicCategory.id,
    status: 'available',
    price: basicCategory.price,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  );

  static final soldTicket = Ticket(
    id: 'test-ticket-2',
    ticketNumber: 'PRM-001',
    raffleId: activeRaffle.id,
    categoryId: premiumCategory.id,
    status: 'sold',
    price: premiumCategory.price,
    buyerId: buyerUser.id,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    soldAt: DateTime.now().subtract(const Duration(days: 1)),
  );

  // Test Payments
  static final pendingPayment = Payment(
    id: 'test-payment-1',
    amount: 100.0,
    currency: 'HTG',
    method: PaymentMethod.monCashManual,
    status: PaymentStatus.pending,
    userId: buyerUser.id,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  static final completedPayment = Payment(
    id: 'test-payment-2',
    amount: 50.0,
    currency: 'HTG',
    method: PaymentMethod.monCashAutomated,
    status: PaymentStatus.completed,
    userId: buyerUser.id,
    transactionId: 'MON-12345',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    completedAt: DateTime.now().subtract(const Duration(days: 1, hours: -1)),
  );

  // API Response Mock Data
  static final Map<String, dynamic> mockRaffleResponse = {
    'id': activeRaffle.id,
    'name': activeRaffle.name,
    'description': activeRaffle.description,
    'start_date': activeRaffle.startDate.toIso8601String(),
    'end_date': activeRaffle.endDate.toIso8601String(),
    'draw_date': activeRaffle.drawDate.toIso8601String(),
    'status': activeRaffle.status,
    'total_tickets': activeRaffle.totalTickets,
    'available_tickets': activeRaffle.availableTickets,
  };

  static final Map<String, dynamic> mockTicketResponse = {
    'id': basicTicket.id,
    'ticket_number': basicTicket.ticketNumber,
    'raffle_id': basicTicket.raffleId,
    'category_id': basicTicket.categoryId,
    'status': basicTicket.status,
    'price': basicTicket.price,
    'created_at': basicTicket.createdAt.toIso8601String(),
  };

  static final Map<String, dynamic> mockLoginResponse = {
    'token': 'test-jwt-token-123',
    'user': {
      'id': buyerUser.id,
      'username': buyerUser.username,
      'email': buyerUser.email,
      'role': buyerUser.role,
      'full_name': buyerUser.fullName,
      'phone_number': buyerUser.phoneNumber,
    },
  };

  static final Map<String, dynamic> mockErrorResponse = {
    'error': 'Invalid request',
    'message': 'The requested resource was not found',
    'code': 404,
  };

  // Test Lists
  static List<Ticket> get availableTickets => [
        basicTicket,
        Ticket(
          id: 'test-ticket-3',
          ticketNumber: 'BAS-002',
          raffleId: activeRaffle.id,
          categoryId: basicCategory.id,
          status: 'available',
          price: basicCategory.price,
          createdAt: DateTime.now(),
        ),
        Ticket(
          id: 'test-ticket-4',
          ticketNumber: 'BRZ-001',
          raffleId: activeRaffle.id,
          categoryId: bronzeCategory.id,
          status: 'available',
          price: bronzeCategory.price,
          createdAt: DateTime.now(),
        ),
      ];

  static List<TicketCategory> get allCategories => [
        basicCategory,
        premiumCategory,
        bronzeCategory,
      ];

  // Error scenarios for testing
  static Exception get networkException =>
      Exception('SocketException: Failed host lookup');
  
  static Exception get timeoutException =>
      Exception('TimeoutException: Request timed out');
  
  static Exception get unauthorizedException =>
      Exception('HTTP 401: Unauthorized');
  
  static Exception get serverException =>
      Exception('HTTP 500: Internal Server Error');
}
