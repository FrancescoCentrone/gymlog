import 'package:gym_log/data/database/database_helper.dart';
import 'package:gym_log/data/models/user_profile.dart';

class UserProfileRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<UserProfile?> getUserProfile() async {
    final db = await _databaseHelper.database;
    final result = await db.query('user_profile', limit: 1);

    if (result.isNotEmpty) {
      return UserProfile.fromMap(result.first);
    }
    return null;
  }

  Future<int> createUserProfile(UserProfile profile) async {
    final db = await _databaseHelper.database;
    return await db.insert('user_profile', profile.toMap());
  }

  Future<int> updateUserProfile(UserProfile profile) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'user_profile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<int> deleteUserProfile(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'user_profile',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
