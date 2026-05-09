import 'package:cloud_firestore/cloud_firestore.dart';

class MuseumConfig {
  final int maxDailyCapacity;
  final bool isGlobalOpen;
  final Map<String, DayConfig> calendarOverrides;

  MuseumConfig({
    required this.maxDailyCapacity,
    required this.isGlobalOpen,
    this.calendarOverrides = const {},
  });

  factory MuseumConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final overridesRaw = data['calendar_overrides'] as Map<String, dynamic>? ?? {};
    
    final overrides = overridesRaw.map((key, value) => MapEntry(
      key, 
      DayConfig.fromMap(value as Map<String, dynamic>)
    ));

    return MuseumConfig(
      maxDailyCapacity: data['max_daily_capacity'] ?? 100,
      isGlobalOpen: data['is_global_open'] ?? true,
      calendarOverrides: overrides,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'max_daily_capacity': maxDailyCapacity,
      'is_global_open': isGlobalOpen,
      'calendar_overrides': calendarOverrides.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

enum DayStatus { open, closed, fullyBooked, event }

class DayConfig {
  final DayStatus status;
  final String? reason;
  final int? customCapacity;

  DayConfig({
    required this.status,
    this.reason,
    this.customCapacity,
  });

  factory DayConfig.fromMap(Map<String, dynamic> map) {
    return DayConfig(
      status: DayStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'open'),
        orElse: () => DayStatus.open,
      ),
      reason: map['reason'],
      customCapacity: map['custom_capacity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'reason': reason,
      'custom_capacity': customCapacity,
    };
  }
}
