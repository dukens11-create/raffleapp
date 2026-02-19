# Contributing to Grate Genyen Mobile App

Thank you for your interest in contributing to the Grate Genyen mobile app! This document provides guidelines and instructions for contributing.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing Requirements](#testing-requirements)
6. [Submitting Changes](#submitting-changes)
7. [Review Process](#review-process)

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please:

- Be respectful and considerate
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Respect differing viewpoints and experiences

## Getting Started

### Prerequisites

- Flutter SDK 3.16.0 or higher
- Dart SDK 3.0 or higher
- Android Studio or VS Code with Flutter extensions
- Git
- Basic knowledge of Flutter and Dart

### Setup Development Environment

1. **Clone the repository**
   ```bash
   git clone https://github.com/dukens11-create/raffleapp.git
   cd raffleapp/flutter_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Patch QR code scanner**
   ```bash
   chmod +x scripts/patch_qr_code_scanner.sh
   ./scripts/patch_qr_code_scanner.sh
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

5. **Run tests**
   ```bash
   flutter test
   ```

## Development Workflow

### Branch Naming

Use descriptive branch names:
- `feature/ticket-purchase-flow` - New features
- `fix/login-validation-bug` - Bug fixes
- `refactor/api-service` - Code refactoring
- `docs/update-readme` - Documentation updates

### Commit Messages

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Example:**
```
feat(tickets): Add ticket filtering by category

- Implemented category filter dropdown
- Added filter logic to TicketProvider
- Updated UI to show filtered results

Closes #123
```

### Making Changes

1. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write clean, readable code
   - Follow coding standards
   - Add tests for new features
   - Update documentation

3. **Test your changes**
   ```bash
   flutter test
   flutter analyze
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: your feature description"
   ```

5. **Push to GitHub**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request**

## Coding Standards

### Dart Style Guide

Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style):

```dart
// Good
class TicketCard extends StatelessWidget {
  final Ticket ticket;
  
  const TicketCard({
    super.key,
    required this.ticket,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(ticket.ticketNumber),
        subtitle: Text('${ticket.price} HTG'),
      ),
    );
  }
}

// Bad
class ticketcard extends StatelessWidget {
  Ticket ticket;
  
  ticketcard({this.ticket});
  
  Widget build(context) {
    return Card(child: ListTile(title: Text(ticket.ticketNumber), subtitle: Text('${ticket.price} HTG')));
  }
}
```

### Code Organization

1. **Imports**: Group and order imports
   ```dart
   // Dart imports
   import 'dart:async';
   
   // Flutter imports
   import 'package:flutter/material.dart';
   
   // Package imports
   import 'package:provider/provider.dart';
   
   // Project imports
   import '../models/ticket.dart';
   import '../services/ticket_service.dart';
   ```

2. **Class structure**
   ```dart
   class MyClass {
     // Constants
     static const int maxRetries = 3;
     
     // Static fields
     static final instance = MyClass._();
     
     // Instance fields
     final String id;
     int _counter = 0;
     
     // Constructor
     MyClass(this.id);
     
     // Getters/Setters
     int get counter => _counter;
     
     // Public methods
     void increment() {
       _counter++;
     }
     
     // Private methods
     void _validate() {
       // ...
     }
   }
   ```

### Widget Guidelines

1. **Extract reusable widgets**
   ```dart
   // Good
   class TicketPrice extends StatelessWidget {
     final double price;
     
     const TicketPrice({super.key, required this.price});
     
     @override
     Widget build(BuildContext context) {
       return Text(
         '${price.toStringAsFixed(2)} HTG',
         style: Theme.of(context).textTheme.headlineMedium,
       );
     }
   }
   ```

2. **Use const constructors**
   ```dart
   // Good
   const Text('Hello')
   const SizedBox(height: 16)
   
   // Bad
   Text('Hello')
   SizedBox(height: 16)
   ```

3. **Prefer composition over inheritance**

### State Management

Use Provider pattern consistently:

```dart
// Provider
class TicketProvider extends ChangeNotifier {
  List<Ticket> _tickets = [];
  
  List<Ticket> get tickets => _tickets;
  
  Future<void> fetchTickets() async {
    _tickets = await _service.getTickets();
    notifyListeners();
  }
}

// Consumer
Consumer<TicketProvider>(
  builder: (context, provider, child) {
    return ListView.builder(
      itemCount: provider.tickets.length,
      itemBuilder: (context, index) {
        return TicketCard(ticket: provider.tickets[index]);
      },
    );
  },
)
```

### Error Handling

Always handle errors appropriately:

```dart
try {
  await ticketService.purchaseTicket(ticketId);
} catch (error, stackTrace) {
  final appError = ErrorHandler().handleError(
    error,
    stackTrace: stackTrace,
    userId: currentUser.id,
  );
  
  if (mounted) {
    ErrorSnackbar.show(context, appError);
  }
}
```

### Documentation

Add documentation for public APIs:

```dart
/// Fetches all available tickets for the current raffle.
///
/// Returns a list of [Ticket] objects. Throws [AppError] if the request fails.
///
/// Example:
/// ```dart
/// final tickets = await ticketService.fetchAvailableTickets();
/// ```
Future<List<Ticket>> fetchAvailableTickets() async {
  // Implementation
}
```

## Testing Requirements

### Test Coverage

- **Unit tests**: 70%+ coverage for services and providers
- **Widget tests**: All major screens
- **Integration tests**: Critical user flows

### Writing Tests

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketService', () {
    late TicketService ticketService;
    
    setUp(() {
      ticketService = TicketService();
    });
    
    test('should fetch available tickets', () async {
      final tickets = await ticketService.fetchAvailableTickets();
      
      expect(tickets, isNotEmpty);
      expect(tickets.every((t) => t.status == 'available'), isTrue);
    });
  });
}
```

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/unit/services/ticket_service_test.dart

# With coverage
flutter test --coverage
```

## Submitting Changes

### Pull Request Process

1. **Update documentation**
   - Update README if needed
   - Update CHANGELOG.md
   - Add inline documentation

2. **Ensure tests pass**
   ```bash
   flutter test
   flutter analyze
   ```

3. **Create Pull Request**
   - Use descriptive title
   - Provide detailed description
   - Reference related issues
   - Add screenshots for UI changes

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots here

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests pass locally
- [ ] No new warnings
```

## Review Process

### What Reviewers Look For

1. **Code Quality**
   - Follows style guide
   - Proper error handling
   - Efficient algorithms
   - No code duplication

2. **Testing**
   - Adequate test coverage
   - Edge cases handled
   - Tests are meaningful

3. **Documentation**
   - Code is well-documented
   - README updated if needed
   - Comments explain "why", not "what"

4. **User Experience**
   - Intuitive UI/UX
   - Proper loading states
   - Good error messages
   - Accessibility considered

### Addressing Review Feedback

- Respond to all comments
- Make requested changes
- Push new commits (don't force push)
- Re-request review when ready

### Merging

Once approved:
- Maintainers will merge your PR
- Delete your branch after merge
- Pull latest changes to stay updated

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Create a GitHub Issue
- **Chat**: Join our Discord (if available)
- **Email**: dev@grategenyen.com

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart)
- [Provider Package](https://pub.dev/packages/provider)
- [Testing in Flutter](https://docs.flutter.dev/testing)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

Thank you for contributing to Grate Genyen! 🎉
