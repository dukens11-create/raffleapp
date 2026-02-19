# Testing Guide

This guide explains how to write and run tests for the Grate Genyen Flutter mobile app.

## Table of Contents

1. [Test Structure](#test-structure)
2. [Running Tests](#running-tests)
3. [Writing Tests](#writing-tests)
4. [Test Coverage](#test-coverage)
5. [Best Practices](#best-practices)

## Test Structure

The test directory is organized as follows:

```
flutter_app/test/
├── unit/               # Unit tests
│   ├── services/      # Service layer tests
│   ├── providers/     # Provider/state management tests
│   └── models/        # Model tests
├── widget/            # Widget tests
│   └── screens/       # Screen widget tests
├── integration/       # Integration tests
├── mocks/             # Mock implementations
└── fixtures/          # Test data fixtures
```

## Running Tests

### Run All Tests

```bash
cd flutter_app
flutter test
```

### Run Specific Test File

```bash
flutter test test/unit/services/api_service_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

To view coverage report:

```bash
# Install lcov (if not already installed)
# Ubuntu/Debian: sudo apt-get install lcov
# macOS: brew install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

### Run Tests in Watch Mode

```bash
flutter test --watch
```

### Run Widget Tests Only

```bash
flutter test test/widget/
```

### Run Unit Tests Only

```bash
flutter test test/unit/
```

## Writing Tests

### Unit Tests

Unit tests verify individual functions, methods, or classes in isolation.

**Example: Testing a Service**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raffle_app/services/auth_service.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('should login with valid credentials', () async {
      final result = await authService.login('+50912345678', 'password123');
      
      expect(result['success'], isTrue);
      expect(result['user'], isNotNull);
    });
  });
}
```

### Widget Tests

Widget tests verify UI components and user interactions.

**Example: Testing a Screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raffle_app/screens/auth/login_screen.dart';

void main() {
  testWidgets('Login screen displays form fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen()),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
```

### Integration Tests

Integration tests verify multiple components working together.

**Example: Testing a User Flow**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:raffle_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete ticket purchase flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Login
    await tester.enterText(find.byKey(Key('phone_field')), '+50912345678');
    await tester.enterText(find.byKey(Key('password_field')), 'password123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Browse tickets
    await tester.tap(find.text('Browse Tickets'));
    await tester.pumpAndSettle();

    // Select ticket
    await tester.tap(find.byType(TicketCard).first);
    await tester.pumpAndSettle();

    // Verify purchase screen
    expect(find.text('Checkout'), findsOneWidget);
  });
}
```

### Using Mocks

Use mocks to isolate components from dependencies.

```dart
import 'package:mockito/mockito.dart';
import 'package:raffle_app/services/api_service.dart';
import '../../mocks/mock_api_service.dart';

void main() {
  test('should handle API error gracefully', () async {
    final mockApi = SimpleApiService();
    mockApi.setNextError(Exception('Network error'));

    try {
      await mockApi.get('/tickets');
      fail('Should have thrown exception');
    } catch (e) {
      expect(e, isA<Exception>());
    }
  });
}
```

### Using Test Fixtures

Use fixtures for consistent test data:

```dart
import '../../fixtures/test_data.dart';

void main() {
  test('should process valid ticket', () {
    final ticket = TestData.basicTicket;
    
    expect(ticket.status, equals('available'));
    expect(ticket.price, greaterThan(0));
  });
}
```

## Test Coverage

### Coverage Targets

- **Unit Tests**: 70%+ coverage for all services and providers
- **Widget Tests**: All major screens should have widget tests
- **Integration Tests**: Cover critical user flows
- **Overall**: Aim for 70%+ total coverage

### Checking Coverage

```bash
flutter test --coverage
lcov --list coverage/lcov.info
```

### Excluding Files from Coverage

Edit `flutter_app/test/.test_config`:

```dart
// Files to exclude from coverage
const excludeFromCoverage = [
  '**/*.g.dart',        // Generated files
  '**/*.freezed.dart',  // Freezed files
  '**/main.dart',       // Entry points
];
```

## Best Practices

### 1. Test Organization

- Group related tests using `group()`
- Use descriptive test names
- Follow the Arrange-Act-Assert pattern

```dart
test('should return user when login is successful', () {
  // Arrange
  final phone = '+50912345678';
  final password = 'test123';
  
  // Act
  final result = await authService.login(phone, password);
  
  // Assert
  expect(result['success'], isTrue);
});
```

### 2. Setup and Teardown

Use `setUp()` and `tearDown()` for common initialization:

```dart
group('TicketProvider', () {
  late TicketProvider provider;
  
  setUp(() {
    provider = TicketProvider();
  });
  
  tearDown(() {
    provider.dispose();
  });
  
  test('should initialize with empty list', () {
    expect(provider.tickets, isEmpty);
  });
});
```

### 3. Async Testing

Use `async`/`await` for asynchronous tests:

```dart
test('should fetch tickets from API', () async {
  final tickets = await ticketService.fetchTickets();
  expect(tickets, isNotEmpty);
});
```

### 4. Widget Testing Tips

- Use `pumpAndSettle()` for async UI updates
- Use `find.byKey()` for reliable widget location
- Test user interactions (tap, scroll, input)

```dart
testWidgets('should submit form on button tap', (tester) async {
  await tester.pumpWidget(MyApp());
  
  await tester.enterText(find.byKey(Key('input')), 'test');
  await tester.tap(find.byKey(Key('submit')));
  await tester.pumpAndSettle();
  
  expect(find.text('Success'), findsOneWidget);
});
```

### 5. Mock External Dependencies

Always mock:
- API calls
- Database access
- File system operations
- Platform-specific code

### 6. Test Edge Cases

Test:
- Empty states
- Error states
- Boundary conditions
- Null values
- Invalid input

```dart
test('should handle empty ticket list', () {
  provider.setTickets([]);
  expect(provider.tickets, isEmpty);
});

test('should handle null user', () {
  expect(() => User.fromJson(null), throwsException);
});
```

## Continuous Integration

Tests run automatically on:
- Every push to `main` and `develop` branches
- Every pull request
- Manual workflow dispatch

See `.github/workflows/test.yml` for CI configuration.

## Troubleshooting

### Tests Fail Locally But Pass in CI

- Ensure Flutter version matches CI (3.16.0)
- Check for environment-specific dependencies
- Clear build cache: `flutter clean && flutter pub get`

### Flaky Tests

- Avoid hardcoded delays
- Use `pumpAndSettle()` instead of `pump()`
- Check for race conditions
- Use proper mocking

### Coverage Not Generated

```bash
# Install lcov
brew install lcov  # macOS
sudo apt-get install lcov  # Ubuntu

# Generate coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Integration Test Package](https://pub.dev/packages/integration_test)
- [Flutter Test Best Practices](https://docs.flutter.dev/testing/best-practices)
