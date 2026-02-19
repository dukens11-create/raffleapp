import 'package:mockito/mockito.dart';
import 'package:raffle_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Future<Map<String, dynamic>> login(String phone, String password) async {
    return super.noSuchMethod(
      Invocation.method(#login, [phone, password]),
      returnValue: Future.value({
        'success': true,
        'message': 'Login successful',
        'user': null,
      }),
      returnValueForMissingStub: Future.value({
        'success': true,
        'message': 'Login successful',
        'user': null,
      }),
    );
  }

  @override
  Future<bool> logout() async {
    return super.noSuchMethod(
      Invocation.method(#logout, []),
      returnValue: Future.value(true),
      returnValueForMissingStub: Future.value(true),
    );
  }

  @override
  Future<bool> isAuthenticated() async {
    return super.noSuchMethod(
      Invocation.method(#isAuthenticated, []),
      returnValue: Future.value(false),
      returnValueForMissingStub: Future.value(false),
    );
  }

  @override
  Future<String?> getUserRole() async {
    return super.noSuchMethod(
      Invocation.method(#getUserRole, []),
      returnValue: Future.value(null),
      returnValueForMissingStub: Future.value(null),
    );
  }

  @override
  Future<Map<String, dynamic>> registerSeller({
    required String phone,
    required String password,
    required String name,
    required String email,
    required String department,
    String? idPicturePath,
  }) async {
    return super.noSuchMethod(
      Invocation.method(#registerSeller, [], {
        #phone: phone,
        #password: password,
        #name: name,
        #email: email,
        #department: department,
        #idPicturePath: idPicturePath,
      }),
      returnValue: Future.value({
        'success': true,
        'message': 'Registration submitted for approval',
      }),
      returnValueForMissingStub: Future.value({
        'success': true,
        'message': 'Registration submitted for approval',
      }),
    );
  }
}
