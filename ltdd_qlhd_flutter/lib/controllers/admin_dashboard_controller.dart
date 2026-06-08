import '../models/admin_dashboard_stats.dart';
import '../repositories/admin_repository.dart';

class AdminDashboardController {
  final AdminRepository _repository;

  AdminDashboardController({AdminRepository? repository})
    : _repository = repository ?? AdminRepository();

  Stream<AdminDashboardStats> watchDashboardStats() {
    return _repository.watchDashboardStats();
  }

  Future<AdminDashboardStats> getDashboardStats() {
    return _repository.getDashboardStats();
  }
}
