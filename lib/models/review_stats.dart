class ReviewDay {
  const ReviewDay({required this.day, required this.count});

  final DateTime day;
  final int count;

  String get apiDay =>
      '${day.year.toString().padLeft(4, '0')}'
      '${day.month.toString().padLeft(2, '0')}'
      '${day.day.toString().padLeft(2, '0')}';

  factory ReviewDay.fromJson(Map<String, dynamic> json) {
    final rawDay = json['day'];
    final rawCount = json['count'];
    if (rawDay is! String || !RegExp(r'^\d{8}$').hasMatch(rawDay)) {
      throw const FormatException('Invalid review day');
    }
    if (rawCount is! int || rawCount < 0) {
      throw const FormatException('Invalid review count');
    }

    final year = int.parse(rawDay.substring(0, 4));
    final month = int.parse(rawDay.substring(4, 6));
    final dayOfMonth = int.parse(rawDay.substring(6, 8));
    final parsed = DateTime.utc(year, month, dayOfMonth);
    if (parsed.year != year ||
        parsed.month != month ||
        parsed.day != dayOfMonth) {
      throw const FormatException('Invalid review day');
    }
    return ReviewDay(day: parsed, count: rawCount);
  }
}

class ReviewStatsSeries {
  const ReviewStatsSeries({required this.days, required this.timezone});

  final List<ReviewDay> days;
  final String timezone;

  factory ReviewStatsSeries.fromData(
    dynamic data, {
    required int expectedDays,
  }) {
    if (data is! Map) {
      throw const FormatException('Review stats data is not an object');
    }
    final rawDays = data['days'];
    final timezone = data['timezone'];
    if (rawDays is! List || timezone != 'UTC') {
      throw const FormatException('Invalid review stats payload');
    }
    if (rawDays.length != expectedDays) {
      throw const FormatException('Unexpected review stats length');
    }

    final parsed = rawDays
        .map((raw) {
          if (raw is! Map) {
            throw const FormatException('Invalid review day entry');
          }
          return ReviewDay.fromJson(Map<String, dynamic>.from(raw));
        })
        .toList(growable: false);

    for (var i = 1; i < parsed.length; i++) {
      if (parsed[i].day.difference(parsed[i - 1].day).inDays != 1) {
        throw const FormatException('Review days are not dense and ordered');
      }
    }
    return ReviewStatsSeries(days: parsed, timezone: timezone as String);
  }

  int get totalReviews => days.fold(0, (total, day) => total + day.count);
  int get todayReviews => days.isEmpty ? 0 : days.last.count;
  int get activeDays => days.where((day) => day.count > 0).length;
  double get dailyAverage => days.isEmpty ? 0 : totalReviews / days.length;

  List<int> get weekdayTotals {
    final totals = List<int>.filled(7, 0);
    for (final entry in days) {
      totals[entry.day.weekday - 1] += entry.count;
    }
    return totals;
  }

  static ReviewStatsSeries aggregate(List<ReviewStatsSeries> series) {
    if (series.isEmpty) {
      return const ReviewStatsSeries(days: [], timezone: 'UTC');
    }
    final baseline = series.first;
    for (final item in series.skip(1)) {
      if (item.timezone != 'UTC' || item.days.length != baseline.days.length) {
        throw const FormatException('Review series do not align');
      }
      for (var i = 0; i < baseline.days.length; i++) {
        if (item.days[i].day != baseline.days[i].day) {
          throw const FormatException('Review series do not align');
        }
      }
    }

    return ReviewStatsSeries(
      timezone: 'UTC',
      days: List<ReviewDay>.generate(
        baseline.days.length,
        (index) => ReviewDay(
          day: baseline.days[index].day,
          count: series.fold(
            0,
            (total, item) => total + item.days[index].count,
          ),
        ),
        growable: false,
      ),
    );
  }
}
