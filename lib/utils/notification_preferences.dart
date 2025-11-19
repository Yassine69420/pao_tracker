import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  static const String _notificationsEnabledKey = 'notificationsEnabled';
  static const String _notificationDaysKey = 'notificationDays';

  static Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  static Future<bool> loadNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true; // Default to true
  }

  static Future<void> saveNotificationDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notificationDaysKey, days);
  }

  static Future<int> loadNotificationDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notificationDaysKey) ?? 7; // Default to 7 days
  }
}
