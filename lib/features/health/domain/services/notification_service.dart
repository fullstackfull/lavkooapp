import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    if (UniversalPlatform.isWeb) return;

    await AwesomeNotifications().initialize(
      UniversalPlatform.isAndroid ? 'resource://mipmap/launcher_icon' : null,
      [
        NotificationChannel(
          channelGroupKey: 'health_group',
          channelKey: 'health_reminders',
          channelName: 'Health Reminders',
          channelDescription: 'Notification channel for health and medication reminders',
          defaultColor: const Color(0xFF9D50BB),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          onlyAlertOnce: true,
          playSound: true,
          criticalAlerts: !UniversalPlatform.isIOS,
        ),
        NotificationChannel(
          channelGroupKey: 'health_group',
          channelKey: 'medication_channel',
          channelName: 'Medication Alarms',
          channelDescription: 'Critical alarms for medication',
          defaultColor: const Color(0xFFBA000D),
          ledColor: Colors.red,
          importance: NotificationImportance.Max,
          playSound: true,
          criticalAlerts: !UniversalPlatform.isIOS,
          locked: true,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'health_group',
          channelGroupName: 'Health Notifications',
        )
      ],
      debug: true,
    );

    // Set listeners
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  Future<void> requestPermissions() async {
    if (UniversalPlatform.isWeb) return;

    var isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      if (UniversalPlatform.isIOS) {
        // Request standard notification permissions for iOS to avoid rejections
        await AwesomeNotifications().requestPermissionToSendNotifications(
          permissions: [
            NotificationPermission.Alert,
            NotificationPermission.Sound,
            NotificationPermission.Badge,
          ],
        );
      } else {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    }

    if (UniversalPlatform.isAndroid) {
      // Specifically check and request Precise Alarm and FullScreenIntent permission (Android 13/14+)
      var currentPermissions = await AwesomeNotifications().checkPermissionList(
        channelKey: 'medication_channel',
        permissions: [
          NotificationPermission.FullScreenIntent,
          NotificationPermission.CriticalAlert,
          NotificationPermission.PreciseAlarms,
        ],
      );

      var missingPermissions = <NotificationPermission>[];
      if (!currentPermissions.contains(NotificationPermission.FullScreenIntent)) {
        missingPermissions.add(NotificationPermission.FullScreenIntent);
      }
      if (!currentPermissions.contains(NotificationPermission.CriticalAlert)) {
        missingPermissions.add(NotificationPermission.CriticalAlert);
      }
      if (!currentPermissions.contains(NotificationPermission.PreciseAlarms)) {
        missingPermissions.add(NotificationPermission.PreciseAlarms);
      }

      if (missingPermissions.isNotEmpty) {
        await AwesomeNotifications().requestPermissionToSendNotifications(
          channelKey: 'medication_channel',
          permissions: missingPermissions,
        );
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {}

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {}

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {}

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    if (kDebugMode) debugPrint('Notification tapped');
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'medication_channel',
        title: title,
        body: body,
        category: NotificationCategory.Alarm,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        fullScreenIntent: !UniversalPlatform.isIOS,
        criticalAlert: !UniversalPlatform.isIOS,
        locked: true,
        autoDismissible: false,
        largeIcon: UniversalPlatform.isAndroid ? 'resource://mipmap/launcher_icon' : null,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'تم تناول الدواء',
          actionType: ActionType.DismissAction,
        ),
        NotificationActionButton(
          key: 'OPEN',
          label: 'فتح التطبيق',
          actionType: ActionType.Default,
        ),
      ],
      schedule: NotificationCalendar.fromDate(
        date: scheduledDate,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  Future<void> showHealthTip({
    required int id,
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'health_reminders',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigText,
      ),
    );
  }
}