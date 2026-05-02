import 'backend_user.dart';

class BackendSession {
  const BackendSession({required this.user, required this.accessToken});

  final BackendUser user;
  final String accessToken;
}
