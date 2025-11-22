import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pao_tracker/data/product_repository.dart';
import 'package:pao_tracker/utils/notification_preferences.dart';
import 'data/database_helper.dart';
import 'app.dart';
import 'utils/notification_service.dart';
import 'utils/theme_preferences.dart';

void _unawaited(Future<void> f) {
  f.catchError((e, st) {
    debugPrint('Background task error: $e\n$st');
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  _unawaited(_initEverythingInBackground());

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initEverythingInBackground() async {
  _unawaited(_loadTheme());

  _unawaited(_initDatabase());

  _unawaited(_initNotifications());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _unawaited(_scheduleNotifications());
  });
}

Future<void> _loadTheme() async {
  try {
    final savedTheme = await ThemePreferences.loadThemeMode();
    themeNotifier.value = savedTheme;
    debugPrint('Theme loaded: $savedTheme');
  } catch (e, st) {
    debugPrint('Failed to load theme: $e\n$st');
  }
}

Future<void> _initDatabase() async {
  try {
    await DatabaseHelper.instance.init();
    debugPrint('✅ Database successfully initialized (background).');
  } catch (e, st) {
    debugPrint('❌ Database initialization failed (background): $e\n$st');
  }
}

Future<void> _initNotifications() async {
  try {
    await NotificationService().init();
    debugPrint('✅ Notification service successfully initialized (background).');
  } catch (e, st) {
    debugPrint(
      '❌ Notification service initialization failed (background): $e\n$st',
    );
  }
}

Future<void> _scheduleNotifications() async {
  try {
    final notificationsEnabled =
        await NotificationPreferences.loadNotificationsEnabled();

    if (!notificationsEnabled) {
      debugPrint('Notifications disabled by user preferences.');
      return;
    }

    final notificationDays =
        await NotificationPreferences.loadNotificationDays();

    final products = await ProductRepository.instance.getAll();
    final now = DateTime.now();

    const int expiringSoonNotificationIdOffset = 1;
    const int expiredNotificationIdOffset = 2;

    final List<Future<void>> schedulingFutures = [];

    for (final product in products) {
      final int baseId = product.id.hashCode;

      final expiringSoonDate = product.expiryDate.subtract(
        Duration(days: notificationDays),
      );

      if (expiringSoonDate.isAfter(now)) {
        schedulingFutures.add(
          _safeScheduleNotification(
            id: baseId + expiringSoonNotificationIdOffset,
            title: 'Product Expiring Soon',
            body: '${product.name} is expiring in $notificationDays days.',
            scheduledDate: expiringSoonDate,
          ),
        );
      }

      if (product.expiryDate.isAfter(now)) {
        schedulingFutures.add(
          _safeScheduleNotification(
            id: baseId + expiredNotificationIdOffset,
            title: 'Product Expired',
            body: '${product.name} has expired.',
            scheduledDate: product.expiryDate,
          ),
        );
      }
    }

    if (schedulingFutures.isNotEmpty) {
      await Future.wait(schedulingFutures);
      debugPrint('Scheduled ${schedulingFutures.length} notification(s).');
    }
  } catch (e, st) {
    debugPrint('Error while scheduling notifications: $e\n$st');
  }
}

Future<void> _safeScheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {
  try {
    final now = DateTime.now();
    final scheduled = scheduledDate.isAfter(now)
        ? scheduledDate
        : now.add(const Duration(seconds: 5));

    await NotificationService().scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
    );
  } catch (e, st) {
    debugPrint('Failed to schedule notification (id: $id): $e\n$st');
  }
}
