# Architecture Documentation

This document describes the architecture of the Grate Genyen Flutter mobile app.

## Table of Contents

1. [Overview](#overview)
2. [Architecture Pattern](#architecture-pattern)
3. [Project Structure](#project-structure)
4. [Data Flow](#data-flow)
5. [Key Components](#key-components)
6. [Design Decisions](#design-decisions)

## Overview

The Grate Genyen mobile app is built using Flutter and follows a clean, scalable architecture pattern. The app enables users to purchase raffle tickets, make payments, and manage their accounts.

### Technology Stack

- **Framework**: Flutter 3.16.0
- **Language**: Dart 3.0+
- **State Management**: Provider pattern
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences & Flutter Secure Storage
- **Navigation**: Named routes with Navigator 2.0
- **UI**: Material Design 3

## Architecture Pattern

The app follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Screens, Widgets, UI Components)  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        State Management Layer       │
│     (Providers, ChangeNotifiers)    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Business Logic Layer        │
│       (Services, Utilities)         │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│           Data Layer                │
│    (Models, API, Local Storage)     │
└─────────────────────────────────────┘
```

### Layer Responsibilities

1. **Presentation Layer**: 
   - Displays UI
   - Handles user interactions
   - Consumes state from providers

2. **State Management Layer**:
   - Manages app state
   - Notifies UI of changes
   - Coordinates between services

3. **Business Logic Layer**:
   - Implements business rules
   - Handles API calls
   - Manages data transformations

4. **Data Layer**:
   - Defines data models
   - Handles data persistence
   - Manages API communication

## Project Structure

```
flutter_app/
├── lib/
│   ├── config/              # App configuration
│   │   ├── api_config.dart  # API endpoints & timeouts
│   │   └── app_theme.dart   # Material theme configuration
│   │
│   ├── models/              # Data models
│   │   ├── user.dart
│   │   ├── ticket.dart
│   │   ├── payment.dart
│   │   ├── raffle.dart
│   │   └── app_error.dart   # Error model
│   │
│   ├── providers/           # State management
│   │   ├── auth_provider.dart
│   │   ├── ticket_provider.dart
│   │   ├── payment_provider.dart
│   │   └── cart_provider.dart
│   │
│   ├── services/            # Business logic
│   │   ├── api_service.dart          # HTTP client wrapper
│   │   ├── auth_service.dart         # Authentication
│   │   ├── ticket_service.dart       # Ticket operations
│   │   ├── payment_service.dart      # Payment processing
│   │   ├── storage_service.dart      # Local storage
│   │   └── error_logging_service.dart # Error tracking
│   │
│   ├── screens/             # UI screens
│   │   ├── auth/            # Authentication screens
│   │   ├── buyer/           # Buyer portal screens
│   │   ├── seller/          # Seller screens
│   │   ├── admin/           # Admin screens
│   │   ├── payment/         # Payment screens
│   │   └── shared/          # Shared screens
│   │
│   ├── widgets/             # Reusable widgets
│   │   ├── error_widgets/   # Error display components
│   │   ├── loading_widgets/ # Loading states
│   │   ├── buyer/           # Buyer-specific widgets
│   │   └── *.dart           # Common widgets
│   │
│   ├── utils/               # Utility functions
│   │   ├── error_handler.dart
│   │   ├── animation_utils.dart
│   │   ├── performance_monitor.dart
│   │   └── image_cache_manager.dart
│   │
│   └── main.dart            # App entry point
│
├── test/                    # Tests
│   ├── unit/               # Unit tests
│   ├── widget/             # Widget tests
│   ├── integration/        # Integration tests
│   ├── mocks/              # Mock objects
│   └── fixtures/           # Test data
│
├── assets/                  # Static assets
│   ├── images/
│   ├── icons/
│   └── animations/
│
└── pubspec.yaml            # Dependencies
```

## Data Flow

### Authentication Flow

```
LoginScreen → AuthProvider → AuthService → ApiService → Backend
                ↓
          StorageService (save token)
                ↓
          Navigate to Dashboard
```

### Ticket Purchase Flow

```
TicketSelectionScreen → CartProvider → add ticket
                            ↓
                    CheckoutScreen
                            ↓
                    PaymentProvider → PaymentService → Backend
                            ↓
                    StorageService (save transaction)
                            ↓
                    TicketProvider → refresh tickets
                            ↓
                    ConfirmationScreen
```

### Error Handling Flow

```
Any Error → ErrorHandler → AppError (categorized)
                ↓
        ErrorLoggingService (log with context)
                ↓
        UI (ErrorScreen/Dialog/Snackbar)
```

## Key Components

### 1. State Management (Provider Pattern)

The app uses the Provider pattern for state management:

```dart
// Define provider
class TicketProvider extends ChangeNotifier {
  List<Ticket> _tickets = [];
  bool _isLoading = false;

  List<Ticket> get tickets => _tickets;
  bool get isLoading => _isLoading;

  Future<void> fetchTickets() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _tickets = await _ticketService.getTickets();
    } catch (e) {
      // Handle error
    }
    
    _isLoading = false;
    notifyListeners();
  }
}

// Provide in main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => TicketProvider()),
  ],
  child: MyApp(),
)

// Consume in widget
class TicketList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    
    if (provider.isLoading) {
      return CircularProgressIndicator();
    }
    
    return ListView.builder(
      itemCount: provider.tickets.length,
      itemBuilder: (context, index) {
        return TicketCard(ticket: provider.tickets[index]);
      },
    );
  }
}
```

### 2. API Communication

HTTP requests are handled through a centralized ApiService:

```dart
class ApiService {
  final Dio _dio;
  
  Future<Response> get(String path) async {
    final token = await _storage.getToken();
    
    return await _dio.get(
      path,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }
}
```

### 3. Error Handling

Errors are categorized and handled consistently:

```dart
try {
  await ticketService.purchaseTicket(ticketId);
} catch (error, stackTrace) {
  final appError = ErrorHandler().handleError(
    error,
    stackTrace: stackTrace,
    userId: currentUser.id,
    screen: 'TicketPurchaseScreen',
  );
  
  ErrorSnackbar.show(context, appError);
}
```

### 4. Navigation

The app uses named routes for navigation:

```dart
// Define routes in main.dart
routes: {
  '/login': (context) => LoginScreen(),
  '/buyer': (context) => BuyerPortal(),
  '/tickets': (context) => TicketSelectionScreen(),
}

// Navigate
Navigator.pushNamed(context, '/tickets');
```

## Design Decisions

### Why Provider?

- **Simple**: Easy to understand and implement
- **Performance**: Efficient widget rebuilds
- **Testing**: Easy to test and mock
- **Community**: Well-supported with extensive documentation

### Why Dio over http?

- **Interceptors**: Easy to add auth tokens
- **Request/Response transformation**: Built-in JSON handling
- **Error handling**: Better error messages
- **Timeout**: Configurable timeout handling

### Why Named Routes?

- **Maintainability**: Centralized route definitions
- **Deep linking**: Easier to implement
- **Navigation logic**: Cleaner navigation code

### Error Handling Strategy

Errors are categorized into types (network, auth, validation, etc.) to provide:
- Context-specific error messages
- Appropriate recovery actions
- Better error tracking
- User-friendly feedback

### State Management Scope

State is scoped appropriately:
- **App-level**: Auth, theme (top-level providers)
- **Feature-level**: Tickets, payments (feature providers)
- **Widget-level**: Form inputs, UI state (local state)

## Performance Considerations

1. **Lazy Loading**: Lists load data on-demand
2. **Image Caching**: Network images are cached
3. **Widget Reuse**: Common widgets extracted and reused
4. **Selective Rebuilds**: Providers notify only affected widgets
5. **Async Operations**: All network calls are async

## Security Measures

1. **Token Storage**: Secure storage for auth tokens
2. **API Security**: Bearer token authentication
3. **Input Validation**: Client-side validation
4. **Error Messages**: No sensitive info in error messages
5. **HTTPS**: All API calls use HTTPS

## Testing Strategy

- **Unit Tests**: Services, providers, models
- **Widget Tests**: Screens, components
- **Integration Tests**: User flows
- **Coverage Target**: 70%+

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for details.

## Future Improvements

1. **Offline Support**: Local database with sync
2. **Push Notifications**: Firebase Cloud Messaging
3. **Analytics**: User behavior tracking
4. **Feature Flags**: A/B testing capability
5. **GraphQL**: Consider for complex queries
6. **Riverpod**: Evaluate for state management upgrade

## References

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Flutter Best Practices](https://docs.flutter.dev/perf/best-practices)
