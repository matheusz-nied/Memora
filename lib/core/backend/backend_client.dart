import 'contracts/ai_gateway.dart';
import 'contracts/auth_gateway.dart';
import 'contracts/remote_database_gateway.dart';
import 'contracts/storage_gateway.dart';

abstract interface class BackendClient {
  AuthGateway get auth;
  RemoteDatabaseGateway get database;
  StorageGateway get storage;
  AiGateway get ai;
}
