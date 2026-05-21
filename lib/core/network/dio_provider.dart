/// Riverpod Provider exposing the application's Dio instance.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/hive_service_provider.dart';
import 'auth_interceptor.dart';
import 'dio_client.dart';

/// Exposes the singleton [Dio] instance used by all remote data sources.
///
/// Reads [hiveServiceProvider] so the [AuthInterceptor] can read/write the JWT.
final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  final authInterceptor = AuthInterceptor(hiveService);
  return DioClient.build(authInterceptor: authInterceptor);
});
