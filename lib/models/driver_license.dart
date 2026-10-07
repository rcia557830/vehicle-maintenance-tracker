import 'dart:convert';

enum LicenseExpiryStatus { tracked, dueSoon, expiresToday, expired }

/// A personal license, independent of the selected vehicle. Only the printed
/// expiry date and validity are stored; no license number or birthdate is needed.
class DriverLicense {
  DriverLicense({required this.validityYears, required DateTime expiresOn})
    : expiresOn = DateTime(expiresOn.year, expiresOn.month, expiresOn.day);

  static const settingKey = 'driver_license';
  final int validityYears;
  final DateTime expiresOn;

  int daysRemaining(DateTime now) => DateTime.utc(
    expiresOn.year,
    expiresOn.month,
    expiresOn.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;

  LicenseExpiryStatus status(DateTime now) {
    final days = daysRemaining(now);
    if (days < 0) return LicenseExpiryStatus.expired;
    if (days == 0) return LicenseExpiryStatus.expiresToday;
    if (days <= 60) return LicenseExpiryStatus.dueSoon;
    return LicenseExpiryStatus.tracked;
  }

  String statusLabel(DateTime now) => switch (status(now)) {
    LicenseExpiryStatus.tracked => 'Expiry tracked',
    LicenseExpiryStatus.dueSoon => 'Expires soon',
    LicenseExpiryStatus.expiresToday => 'Expires today',
    LicenseExpiryStatus.expired => 'Expired',
  };

  String countdown(DateTime now) {
    final days = daysRemaining(now);
    if (days < 0) return 'Expired ${-days} ${days == -1 ? 'day' : 'days'} ago';
    if (days == 0) return 'Expires today';
    return '$days ${days == 1 ? 'day' : 'days'} remaining';
  }

  String? validate() {
    if (validityYears != 5 && validityYears != 10) {
      return 'Choose 5 or 10 years of validity.';
    }
    if (expiresOn.year < 2000 || expiresOn.year > 2100) {
      return 'Enter an expiry date between 2000 and 2100.';
    }
    return null;
  }

  /// A renewal planning aid, not a determination of LTO eligibility. Clamp leap
  /// day to February's last day and have the user verify the renewed card.
  static DateTime estimateRenewal(DateTime previousExpiry, int years) {
    if (years != 5 && years != 10) {
      throw ArgumentError('Choose 5 or 10 years of validity.');
    }
    final year = previousExpiry.year + years;
    final lastDay = DateTime(year, previousExpiry.month + 1, 0).day;
    return DateTime(
      year,
      previousExpiry.month,
      previousExpiry.day > lastDay ? lastDay : previousExpiry.day,
    );
  }

  String encode() => jsonEncode({
    'validity_years': validityYears,
    'expires_on':
        '${expiresOn.year.toString().padLeft(4, '0')}-'
        '${expiresOn.month.toString().padLeft(2, '0')}-'
        '${expiresOn.day.toString().padLeft(2, '0')}',
  });

  static DriverLicense? decode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final data = jsonDecode(value) as Map<String, dynamic>;
      final text = data['expires_on'] as String;
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
      final date = DateTime.parse(text);
      // DateTime.parse normalizes invalid dates such as February 30.
      if (date.month != int.parse(text.substring(5, 7)) ||
          date.day != int.parse(text.substring(8, 10))) {
        return null;
      }
      final license = DriverLicense(
        validityYears: data['validity_years'] as int,
        expiresOn: date,
      );
      return license.validate() == null ? license : null;
    } catch (_) {
      return null;
    }
  }
}
