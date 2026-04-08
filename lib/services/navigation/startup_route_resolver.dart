import 'package:aerosaur/routes/routes.dart';
import 'package:aerosaur/services/api/api_client.dart';
import 'package:aerosaur/services/repositories/premium_repository.dart';

class StartupRouteResolver {
  StartupRouteResolver(this._apiClient);

  final ApiClient _apiClient;

  Future<String> resolve(String userId) async {
    try {
      final status = await PremiumRepository(_apiClient).getPremiumStatus(
        userId,
      );
      final isPremium = status['isPremium'] == true;

      return isPremium ? AppRoutes.home : AppRoutes.premium;
    } catch (_) {
      return AppRoutes.home;
    }
  }
}

