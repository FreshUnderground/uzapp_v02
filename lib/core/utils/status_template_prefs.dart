import 'package:shared_preferences/shared_preferences.dart';

import 'status_image_composer.dart';

const String kPrefStatusTemplate = 'wa_status_visual_template';
const String kPrefStatusScheduleEnabled = 'wa_status_custom_schedule_enabled';
const String kPrefStatusScheduleHour = 'wa_status_custom_schedule_hour';
const String kPrefStatusScheduleMinute = 'wa_status_custom_schedule_minute';

class StatusTemplatePrefs {
  static Future<StatusVisualTemplate> loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kPrefStatusTemplate);
    return StatusVisualTemplate.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => StatusVisualTemplate.classic,
    );
  }

  static Future<void> saveTemplate(StatusVisualTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefStatusTemplate, template.name);
  }

  static Future<({bool enabled, int hour, int minute})> loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      enabled: prefs.getBool(kPrefStatusScheduleEnabled) ?? false,
      hour: prefs.getInt(kPrefStatusScheduleHour) ?? 18,
      minute: prefs.getInt(kPrefStatusScheduleMinute) ?? 0,
    );
  }

  static Future<void> saveSchedule({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefStatusScheduleEnabled, enabled);
    await prefs.setInt(kPrefStatusScheduleHour, hour);
    await prefs.setInt(kPrefStatusScheduleMinute, minute);
  }
}
