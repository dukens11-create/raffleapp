class ApiConfig {
  // Backend API configuration
  // NOTE: For production, always use HTTPS
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://enejipamticket.com',
  );
  
  static const String apiVersion = '/api';
  
  // API Endpoints
  static const String loginEndpoint = '$apiVersion/login';
  static const String logoutEndpoint = '/logout';
  static const String sellerRegistrationEndpoint = '$apiVersion/seller-registration';
  
  // Tickets
  static const String ticketsEndpoint = '$apiVersion/tickets';
  static const String ticketsScanEndpoint = '$apiVersion/tickets/scan';
  static const String availableTicketsEndpoint = '$apiVersion/available-tickets';
  
  // Public endpoints
  static const String publicRaffleInfoEndpoint = '$apiVersion/public/raffle-info';
  static const String publicAvailableTicketsEndpoint = '$apiVersion/public/available-tickets';
  static const String publicPurchaseEndpoint = '$apiVersion/public/purchase/initiate';
  
  // Sellers
  static const String sellersEndpoint = '$apiVersion/sellers';
  static const String sellerRequestsEndpoint = '$apiVersion/seller-requests';
  
  // Draws
  static const String drawsEndpoint = '$apiVersion/draws';
  static const String drawPhotoUploadEndpoint = '$apiVersion/seller/draw-photo/upload';
  
  // Payments
  static const String paymentsEndpoint = '$apiVersion/payments';
  static const String moncashPaymentEndpoint = '$apiVersion/payments/moncash/initiate';
  static const String natcashPaymentEndpoint = '$apiVersion/payments/natcash/initiate';
  static const String manualPaymentEndpoint = '$apiVersion/payments/manual/submit';
  
  // Stats & Analytics
  static const String statsEndpoint = '$apiVersion/stats';
  static const String departmentStatsEndpoint = '$apiVersion/seller/department-stats';
  
  // Health
  static const String healthEndpoint = '/health';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
