import '../core/utils/date_utils.dart';
import 'emotional_record.dart';

/// Filtros aplicables al historial del diario.
class RecordFilter {
  const RecordFilter({this.from, this.to, this.groupId, this.emotionId});

  final DateTime? from;
  final DateTime? to;
  final String? groupId;
  final String? emotionId;

  bool get hasDateRange => from != null || to != null;
  bool get isActive =>
      from != null || to != null || groupId != null || emotionId != null;

  RecordFilter copyWith({
    DateTime? from,
    DateTime? to,
    String? groupId,
    String? emotionId,
    bool clearDates = false,
    bool clearGroup = false,
    bool clearEmotion = false,
  }) {
    return RecordFilter(
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      emotionId: clearEmotion ? null : (emotionId ?? this.emotionId),
    );
  }

  bool matches(EmotionalRecord record) {
    final day = dateOnly(record.eventDate);

    if (from != null && day.isBefore(dateOnly(from!))) return false;
    if (to != null && day.isAfter(dateOnly(to!))) return false;
    if (groupId != null && !record.groupIds.contains(groupId)) return false;
    if (emotionId != null && !record.emotionIds.contains(emotionId)) {
      return false;
    }

    return true;
  }

  @override
  bool operator ==(Object other) {
    return other is RecordFilter &&
        other.from == from &&
        other.to == to &&
        other.groupId == groupId &&
        other.emotionId == emotionId;
  }

  @override
  int get hashCode => Object.hash(from, to, groupId, emotionId);
}
