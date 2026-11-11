import 'package:flutter/material.dart';

import '../../models/emotion.dart';
import '../../models/emotion_group.dart';
import '../../models/emotional_record.dart';
import '../../features/diary/diary_screen.dart';
import '../../features/diary/record_detail_screen.dart';
import '../../features/diary/record_form_screen.dart';
import '../../features/emotions/emotion_group_screen.dart';
import '../../features/emotions/emotions_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/insights/summary_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Punto único de navegación para mantener las rutas en un solo lugar.
class AppNavigation {
  AppNavigation._();

  static Future<T?> push<T>(BuildContext context, Widget screen) {
    return Navigator.of(context)
        .push<T>(MaterialPageRoute<T>(builder: (_) => screen));
  }

  static Future<void> openHome(BuildContext context) =>
      push(context, const HomeScreen());

  static Future<void> openEmotions(BuildContext context) =>
      push(context, const EmotionsScreen());

  static Future<void> openEmotionGroup(
    BuildContext context,
    EmotionGroup group,
  ) => push(context, EmotionGroupScreen(group: group));

  static Future<void> openDiary(BuildContext context) =>
      push(context, const DiaryScreen());

  static Future<void> openReports(BuildContext context) =>
      push(context, const ReportsScreen());

  static Future<void> openInsights(BuildContext context) =>
      push(context, const InsightsScreen());

  static Future<void> openSummary(BuildContext context) =>
      push(context, const SummaryScreen());

  static Future<void> openSettings(BuildContext context) =>
      push(context, const SettingsScreen());

  static Future<bool?> openRecordForm(
    BuildContext context, {
    EmotionalRecord? record,
    Emotion? initialEmotion,
    bool focusFreeText = false,
  }) {
    return push<bool>(
      context,
      RecordFormScreen(
        record: record,
        initialEmotion: initialEmotion,
        focusFreeText: focusFreeText,
      ),
    );
  }

  static Future<bool?> openRecordDetail(
    BuildContext context,
    EmotionalRecord record,
  ) {
    return push<bool>(context, RecordDetailScreen(record: record));
  }
}
