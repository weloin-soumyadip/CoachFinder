/// Concrete AuthRepository composing remote and local data sources.
library;

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../models/register_request_model.dart';
import 'auth_local_datasource.dart';
import 'auth_remote_datasource.dart';
import 'auth_repository.dart';

/// Coordinates [AuthRemoteDataSource] (network) and [AuthLocalDataSource]
/// (Hive cache). Maps thrown [AppException]s to [AppFailure]s and returns
/// them as `Err`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Result<AuthSession>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
  }) async {
    final String trimmedName = '${firstName.trim()} ${lastName.trim()}'.trim();
    final RegisterRequest request = RegisterRequest(
      userType: role,
      name: trimmedName,
      email: email.trim().toLowerCase(),
      password: password,
    );
    try {
      final response = await _remote.register(request);
      final session = AuthSession(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        user: response.user,
        role: role,
      );
      await _local.saveSession(session);
      return Ok<AuthSession>(session);
    } on ServerException catch (e) {
      return Err<AuthSession>(
        ServerFailure(e.message, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      return Err<AuthSession>(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Err<AuthSession>(ServerFailure(e.message));
    }
  }

  @override
  AuthSession? cachedSession() => _local.readSession();

  @override
  Future<void> signOut() => _local.clearSession();
}
