# Testing Guide

## Overview

This guide covers testing strategies and practices for the Grate Genyen Flutter app.

## Test Types

### 1. Unit Tests
Test individual functions and classes in isolation.

**Location**: `test/unit/`

**Example**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raffle_app/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('should login successfully with valid credentials', () async {
      final authService = AuthService();
      final result = await authService.login('1234567890', 'password');
      expect(result['success'], true);
    });
  });
}
```

### 2. Widget Tests
Test UI components and user interactions.

**Location**: `test/widget/`

**Example**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raffle_app/widgets/custom_button.dart';

void main() {
  testWidgets('Custom button displays text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomButton(
          text: 'Click Me',
          onPressed: () {},
        ),
      ),
    );

    expect(find.text('Click Me'), findsOneWidget);
  });
}
```

### 3. Integration Tests
Test complete user flows end-to-end.

**Location**: `test/integration/`

**Example**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete ticket purchase flow', (WidgetTester tester) async {
    // Test implementation
  });
}
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/unit/services/auth_service_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### View Coverage Report
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Mocking

We use `mockito` for creating mocks:

```dart
import 'package:mockito/mockito.dart';
import 'package:raffle_app/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  test('should handle API errors', () async {
    final mockApi = MockApiService();
    when(mockApi.get('/test'))
        .thenThrow(Exception('Network error'));
    
    // Test error handling
  });
}
```

## Test Helpers

Use test helpers for common operations:

```dart
import 'package:raffle_app/test/helpers/test_helpers.dart';

testWidgets('Test with helper', (WidgetTester tester) async {
  await TestHelpers.pumpWidget(tester, MyWidget());
  await TestHelpers.tapAndSettle(tester, find.byType(ElevatedButton));
});
```

## Best Practices

1. **Test Naming**: Use descriptive test names
2. **AAA Pattern**: Arrange, Act, Assert
3. **One Assertion**: Each test should verify one thing
4. **Mock External Dependencies**: Don't call real APIs
5. **Clean Up**: Dispose resources properly
6. **Fast Tests**: Tests should run quickly
7. **Isolated Tests**: Tests shouldn't depend on each other
8. **Coverage Goal**: Aim for 80%+ code coverage

## CI Integration

Tests automatically run on every push via GitHub Actions:

```yaml
- name: Run tests
  working-directory: flutter_app
  run: flutter test --coverage
```

## Golden Tests

For UI consistency:

```dart
testWidgets('Golden test for login screen', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(home: LoginScreen()));
  await expectLater(
    find.byType(LoginScreen),
    matchesGoldenFile('goldens/login_screen.png'),
  );
});
```

## Performance Tests

```dart
test('Large list performance', () {
  final stopwatch = Stopwatch()..start();
  // Perform operation
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(100));
});
```
