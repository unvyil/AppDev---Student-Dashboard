import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PublicHoliday {
  const PublicHoliday({required this.date, required this.name});

  final DateTime date;
  final String name;

  Map<String, dynamic> toJson() => {'date': _dateKey(date), 'name': name};

  factory PublicHoliday.fromJson(Map<String, dynamic> json) => PublicHoliday(
    date: DateTime.parse(json['date'] as String),
    name: json['name'] as String? ?? 'Public holiday',
  );

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class HolidayCalendarData {
  const HolidayCalendarData({
    required this.holidays,
    required this.isOffline,
    required this.year,
  });

  final List<PublicHoliday> holidays;
  final bool isOffline;
  final int year;
}

class PublicHolidayService {
  static String _cacheKey(int year) => 'nager_ph_holidays_$year';

  static Future<HolidayCalendarData> fetch({required int year}) async {
    final preferences = await SharedPreferences.getInstance();
    try {
      final response = await http
          .get(
            Uri.https('date.nager.at', '/api/v3/PublicHolidays/$year/PH'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception('Nager.Date returned HTTP ${response.statusCode}.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Invalid Nager.Date response.');
      }
      final holidays =
          decoded
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .map((entry) {
                final date = DateTime.tryParse(entry['date'] as String? ?? '');
                final name =
                    entry['localName'] as String? ??
                    entry['name'] as String? ??
                    'Public holiday';
                if (date == null) return null;
                return PublicHoliday(
                  date: DateTime(date.year, date.month, date.day),
                  name: name,
                );
              })
              .whereType<PublicHoliday>()
              .toList()
            ..sort((first, second) => first.date.compareTo(second.date));

      await preferences.setString(
        _cacheKey(year),
        jsonEncode(holidays.map((holiday) => holiday.toJson()).toList()),
      );
      return HolidayCalendarData(
        holidays: holidays,
        isOffline: false,
        year: year,
      );
    } catch (_) {
      final cached = preferences.getString(_cacheKey(year));
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached);
          if (decoded is List) {
            final holidays = decoded
                .whereType<Map>()
                .map(
                  (entry) =>
                      PublicHoliday.fromJson(Map<String, dynamic>.from(entry)),
                )
                .toList();
            return HolidayCalendarData(
              holidays: holidays,
              isOffline: true,
              year: year,
            );
          }
        } catch (_) {
          // An invalid cache is treated like an empty offline result.
        }
      }
      return HolidayCalendarData(
        holidays: const [],
        isOffline: true,
        year: year,
      );
    }
  }
}
