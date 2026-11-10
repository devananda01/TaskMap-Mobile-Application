import 'package:flutter/material.dart';

// A single block of time the user says they're free to study, e.g.
// "9:00 AM - 11:00 AM".
class StudySlot {
  final TimeOfDay start;
  final TimeOfDay end;

  const StudySlot({required this.start, required this.end});

  String get label => '${start.format24h()} – ${end.format24h()}';
}

// Small helper extension so we can print "9:00 AM" without BuildContext
// (TimeOfDay.format() normally needs a context).
extension TimeOfDayFormat on TimeOfDay {
  String format24h() {
    final h = hourOfPeriod == 0 ? 12 : hourOfPeriod;
    final m = minute.toString().padLeft(2, '0');
    final p = period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}

// The focus-preference options shown as pill buttons in the form.
enum FocusPreference { balanced, urgentFirst, oneSubject, lightRevision }

extension FocusPreferenceLabel on FocusPreference {
  String get label {
    switch (this) {
      case FocusPreference.balanced:
        return 'Balanced Schedule';
      case FocusPreference.urgentFirst:
        return 'Prioritize Urgent Tasks';
      case FocusPreference.oneSubject:
        return 'Focus on One Subject';
      case FocusPreference.lightRevision:
        return 'Light Revision Mode';
    }
  }
}
