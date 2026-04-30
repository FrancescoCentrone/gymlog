import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/user_profile.dart';
import 'package:gym_log/data/repositories/user_profile_repository.dart';

// Repository Provider
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});

// User Profile Notifier
class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final repository = ref.watch(userProfileRepositoryProvider);
    return await repository.getUserProfile();
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final repository = ref.read(userProfileRepositoryProvider);
    
    if (profile.id == null) {
      // Create new profile
      await repository.createUserProfile(profile);
    } else {
      // Update existing profile
      await repository.updateUserProfile(profile);
    }
    
    ref.invalidateSelf();
  }

  Future<void> deleteUserProfile(int id) async {
    final repository = ref.read(userProfileRepositoryProvider);
    await repository.deleteUserProfile(id);
    ref.invalidateSelf();
  }
}

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(() {
  return UserProfileNotifier();
});
