import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pao_tracker/data/product_repository.dart';
import 'package:pao_tracker/utils/notification_preferences.dart';
import 'data/database_helper.dart';
import 'app.dart';
import 'utils/notification_service.dart';
import 'utils/theme_preferences.dart';

/// Small helper so we can fire-and-forget futures while still catching errors.
void _unawaited(Future<void> f) {
  f.catchError((e, st) {
    // You can log this to your analytics/logger
    debugPrint('Background task error: $e\n$st');
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Start lightweight synchronous setup if needed (very small tasks only).
  // Do NOT await heavy operations here — they should run in the background.

  // Start background initializations BEFORE runApp if they are quick to start,
  // but do NOT await them so the app shows immediately.
  _unawaited(_initEverythingInBackground());

  // Immediately run the app so splash disappears quickly.
  runApp(const ProviderScope(child: MyApp()));
}

/// Perform heavier initialization work in background (non-blocking to startup).
/// This includes DB init, notification init, loading saved theme, etc.
Future<void> _initEverythingInBackground() async {
  // 1) Load theme early and update themeNotifier (so UI will update when available).
  _unawaited(_loadTheme());

  // 2) Initialize database in background.
  _unawaited(_initDatabase());

  // 3) Initialize notification service in background.
  _unawaited(_initNotifications());

  // 4) Schedule notifications once first frame has rendered (UI ready).
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
    debugPrint('❌ Notification service initialization failed (background): $e\n$st');
  }
}

/// Schedules notifications for products. Runs in background and does not block UI.
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

    // Collect scheduling futures to run concurrently (but not awaited in main thread).
    final List<Future<void>> schedulingFutures = [];

    for (final product in products) {
      // Use stable integer id base. If you have a numeric id in DB prefer that.
      final int baseId = product.id.hashCode;

      // "Expiring soon" notification
      final expiringSoonDate = product.expiryDate.subtract(
        Duration(days: notificationDays),
      );

      if (expiringSoonDate.isAfter(now)) {
        schedulingFutures.add(_safeScheduleNotification(
          id: baseId + expiringSoonNotificationIdOffset,
          title: 'Product Expiring Soon',
          body: '${product.name} is expiring in $notificationDays days.',
          scheduledDate: expiringSoonDate,
        ));
      }

      // "Expired" notification
      if (product.expiryDate.isAfter(now)) {
        schedulingFutures.add(_safeScheduleNotification(
          id: baseId + expiredNotificationIdOffset,
          title: 'Product Expired',
          body: '${product.name} has expired.',
          scheduledDate: product.expiryDate,
        ));
      }
    }

    // Run scheduling concurrently but catch errors inside each scheduling call.
    if (schedulingFutures.isNotEmpty) {
      await Future.wait(schedulingFutures);
      debugPrint('Scheduled ${schedulingFutures.length} notification(s).');
    }
  } catch (e, st) {
    debugPrint('Error while scheduling notifications: $e\n$st');
  }
}

/// Wraps the actual NotificationService call with try/catch so scheduling errors don't bubble up.
Future<void> _safeScheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {
  try {
    // Avoid scheduling notifications in the past.
    final now = DateTime.now();
    final scheduled = scheduledDate.isAfter(now) ? scheduledDate : now.add(const Duration(seconds: 5));

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
