import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'auth/auth_notifier.dart';
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    getToken: () => ref.read(tokenStorageProvider).getToken(),
    onUnauthorized: () => ref.read(authProvider.notifier).logout(),
  );
});
