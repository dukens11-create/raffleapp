import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:raffle_app/services/api_service.dart';

class MockApiService extends Mock implements ApiService {
  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return super.noSuchMethod(
      Invocation.method(#get, [path], {#queryParameters: queryParameters}),
      returnValue: Future.value(Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {},
      )),
      returnValueForMissingStub: Future.value(Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {},
      )),
    );
  }

  @override
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return super.noSuchMethod(
      Invocation.method(#post, [path], {#data: data, #queryParameters: queryParameters}),
      returnValue: Future.value(Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {},
      )),
      returnValueForMissingStub: Future.value(Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {},
      )),
    );
  }

  @override
  Future<Response> put(String path, {dynamic data}) async {
    return super.noSuchMethod(
      Invocation.method(#put, [path], {#data: data}),
      returnValue: Future.value(Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {},
      )),
      returnValueForMissingStub: Future.value(Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {},
      )),
    );
  }

  @override
  Future<Response> delete(String path) async {
    return super.noSuchMethod(
      Invocation.method(#delete, [path]),
      returnValue: Future.value(Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {},
      )),
      returnValueForMissingStub: Future.value(Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {},
      )),
    );
  }

  @override
  Future<Response> postFormData(String path, FormData formData) async {
    return super.noSuchMethod(
      Invocation.method(#postFormData, [path, formData]),
      returnValue: Future.value(Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {},
      )),
      returnValueForMissingStub: Future.value(Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {},
      )),
    );
  }
}
