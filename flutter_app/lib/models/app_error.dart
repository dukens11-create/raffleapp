/// Structured error model for consistent error handling across the app
class AppError {
  final ErrorType type;
  final String message;
  final String? userMessage;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  AppError({
    required this.type,
    required this.message,
    this.userMessage,
    this.code,
    this.originalError,
    this.stackTrace,
    this.context,
  });

  /// User-friendly message to display
  String get displayMessage => userMessage ?? _getDefaultUserMessage();

  /// Whether this error can be retried
  bool get isRetryable {
    switch (type) {
      case ErrorType.network:
      case ErrorType.timeout:
      case ErrorType.serverError:
        return true;
      case ErrorType.authentication:
      case ErrorType.authorization:
      case ErrorType.validation:
      case ErrorType.businessLogic:
      case ErrorType.notFound:
      case ErrorType.system:
      case ErrorType.unknown:
        return false;
    }
  }

  /// Get recovery actions available for this error
  List<ErrorRecoveryAction> get recoveryActions {
    final actions = <ErrorRecoveryAction>[];
    
    if (isRetryable) {
      actions.add(ErrorRecoveryAction.retry);
    }
    
    switch (type) {
      case ErrorType.network:
      case ErrorType.timeout:
        actions.addAll([
          ErrorRecoveryAction.checkConnection,
        ]);
        break;
      case ErrorType.authentication:
        actions.addAll([
          ErrorRecoveryAction.login,
        ]);
        break;
      case ErrorType.authorization:
        actions.addAll([
          ErrorRecoveryAction.contactSupport,
        ]);
        break;
      case ErrorType.businessLogic:
      case ErrorType.notFound:
        actions.addAll([
          ErrorRecoveryAction.goBack,
        ]);
        break;
      default:
        actions.addAll([
          ErrorRecoveryAction.goBack,
          ErrorRecoveryAction.contactSupport,
        ]);
    }
    
    return actions;
  }

  String _getDefaultUserMessage() {
    switch (type) {
      case ErrorType.network:
        return 'Pwoblèm koneksyon entènèt. Tanpri verifye koneksyon ou epi eseye ankò.';
      case ErrorType.timeout:
        return 'Demann lan pran twòp tan. Tanpri eseye ankò.';
      case ErrorType.serverError:
        return 'Sèvè a gen yon pwoblèm. Tanpri eseye ankò nan kèk minit.';
      case ErrorType.authentication:
        return 'Sesyon ou ekspire. Tanpri konekte ankò.';
      case ErrorType.authorization:
        return 'Ou pa gen pèmisyon pou fè aksyon sa a.';
      case ErrorType.validation:
        return 'Enfòmasyon ou antre pa valid. Tanpri verifye epi eseye ankò.';
      case ErrorType.businessLogic:
        return 'Nou pa kapab konplete aksyon sa a kounye a.';
      case ErrorType.notFound:
        return 'Enfòmasyon ou ap chache a pa jwenn.';
      case ErrorType.system:
        return 'Yon erè sistèm fèt. Tanpri eseye ankò.';
      case ErrorType.unknown:
        return 'Yon erè ki pa atandi fèt. Tanpri eseye ankò.';
    }
  }

  /// Factory constructors for common error scenarios
  factory AppError.network(String message, {dynamic error, StackTrace? stackTrace}) {
    return AppError(
      type: ErrorType.network,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  factory AppError.timeout(String message) {
    return AppError(
      type: ErrorType.timeout,
      message: message,
    );
  }

  factory AppError.serverError(String message, {String? code, dynamic error}) {
    return AppError(
      type: ErrorType.serverError,
      message: message,
      code: code,
      originalError: error,
    );
  }

  factory AppError.authentication(String message, {String? code}) {
    return AppError(
      type: ErrorType.authentication,
      message: message,
      code: code,
    );
  }

  factory AppError.authorization(String message) {
    return AppError(
      type: ErrorType.authorization,
      message: message,
    );
  }

  factory AppError.validation(String message, {Map<String, dynamic>? context}) {
    return AppError(
      type: ErrorType.validation,
      message: message,
      context: context,
    );
  }

  factory AppError.businessLogic(String message, {String? userMessage}) {
    return AppError(
      type: ErrorType.businessLogic,
      message: message,
      userMessage: userMessage,
    );
  }

  factory AppError.notFound(String message) {
    return AppError(
      type: ErrorType.notFound,
      message: message,
    );
  }

  factory AppError.system(String message, {dynamic error, StackTrace? stackTrace}) {
    return AppError(
      type: ErrorType.system,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  factory AppError.unknown(String message, {dynamic error, StackTrace? stackTrace}) {
    return AppError(
      type: ErrorType.unknown,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Parse HTTP status code to appropriate error type
  factory AppError.fromHttpStatus(int statusCode, String message, {dynamic error}) {
    if (statusCode >= 500) {
      return AppError.serverError(message, code: statusCode.toString(), error: error);
    } else if (statusCode == 401) {
      return AppError.authentication(message, code: statusCode.toString());
    } else if (statusCode == 403) {
      return AppError.authorization(message);
    } else if (statusCode == 404) {
      return AppError.notFound(message);
    } else if (statusCode >= 400) {
      return AppError.validation(message);
    } else {
      return AppError.unknown(message, error: error);
    }
  }

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, code: $code)';
  }
}

/// Error type categories
enum ErrorType {
  network,        // No internet, connection failed
  timeout,        // Request timeout
  serverError,    // 5xx errors
  authentication, // 401, token expired
  authorization,  // 403, insufficient permissions
  validation,     // 400, invalid input
  businessLogic,  // Insufficient funds, sold out, etc.
  notFound,       // 404, resource not found
  system,         // Database, file system, etc.
  unknown,        // Unclassified errors
}

/// Available recovery actions for errors
enum ErrorRecoveryAction {
  retry,
  goBack,
  login,
  contactSupport,
  checkConnection,
  clearCache,
  refresh,
}
