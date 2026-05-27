import 'package:flutter/material.dart';

/// Task types for design freelancing work.
/// Can be predefined static constants or dynamic custom-created types.
class TaskType {
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;

  const TaskType({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskType && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  // Predefined constants
  static const carousel = TaskType(
    name: 'carousel',
    displayName: 'Carousel',
    icon: Icons.view_carousel_rounded,
    color: Color(0xFF6366F1), // Indigo
  );

  static const quote = TaskType(
    name: 'quote',
    displayName: 'Quote',
    icon: Icons.format_quote_rounded,
    color: Color(0xFFD946EF), // Fuchsia
  );

  static const infographic = TaskType(
    name: 'infographic',
    displayName: 'Infographic',
    icon: Icons.bar_chart_rounded,
    color: Color(0xFF10B981), // Emerald
  );

  static const graphicPost = TaskType(
    name: 'graphicPost',
    displayName: 'Graphic Post',
    icon: Icons.image_rounded,
    color: Color(0xFFF59E0B), // Amber
  );

  static const other = TaskType(
    name: 'other',
    displayName: 'Other',
    icon: Icons.work_outline_rounded,
    color: Color(0xFF06B6D4), // Cyan
  );

  static const List<TaskType> values = [
    carousel,
    quote,
    infographic,
    graphicPost,
    other,
  ];
}

/// A single freelancing work log entry
class WorkEntry {
  final String id;
  final String clientName;
  final TaskType taskType;
  final String label;    // "Day 1", "Urgent Stroke Carousel", "UK Visas PDF"
  final int hours;
  final int minutes;
  final int seconds;
  final String month;    // "April 2025", "May 2025"
  final String? note;    // Display note (clean)
  final DateTime createdAt;

  const WorkEntry({
    required this.id,
    required this.clientName,
    required this.taskType,
    required this.label,
    required this.hours,
    required this.minutes,
    this.seconds = 0,
    required this.month,
    this.note,
    required this.createdAt,
  });

  factory WorkEntry.create({
    required String id,
    required String clientName,
    required TaskType taskType,
    required String label,
    required int hours,
    required int minutes,
    required int seconds,
    required String month,
    String? note,
  }) {
    return WorkEntry(
      id: id,
      clientName: clientName,
      taskType: taskType,
      label: label,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      month: month,
      note: note,
      createdAt: DateTime.now(),
    );
  }

  /// Parse note and seconds from raw Supabase note
  static Map<String, dynamic> parseNoteAndSeconds(String? dbNote) {
    if (dbNote == null) {
      return {'note': null, 'seconds': 0};
    }
    final regExp = RegExp(r'\s*\[sec:(\d+)\]');
    final match = regExp.firstMatch(dbNote);
    if (match != null) {
      final seconds = int.tryParse(match.group(1) ?? '0') ?? 0;
      final cleanNote = dbNote.replaceFirst(regExp, '').trim();
      return {
        'note': cleanNote.isEmpty ? null : cleanNote,
        'seconds': seconds,
      };
    }
    return {'note': dbNote, 'seconds': 0};
  }

  /// Format note and seconds for Supabase database storage
  String? get supabaseNote {
    if (seconds == 0) return note;
    final base = note ?? '';
    return '$base [sec:$seconds]'.trim();
  }

  /// "4h 32m 15s" or "4h" if 0 mins/secs
  String get formattedTime {
    final parts = <String>[];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 || (hours > 0 && seconds > 0)) {
      parts.add('${minutes.toString().padLeft(2, '0')}m');
    }
    if (seconds > 0) {
      parts.add('${seconds.toString().padLeft(2, '0')}s');
    }
    if (parts.isEmpty) return '0s';
    return parts.join(' ');
  }

  int get totalMinutes => hours * 60 + minutes;
  double get totalHours => (hours * 3600 + minutes * 60 + seconds) / 3600.0;

  WorkEntry copyWith({
    String? clientName,
    TaskType? taskType,
    String? label,
    int? hours,
    int? minutes,
    int? seconds,
    String? month,
    String? note,
    bool clearNote = false,
  }) {
    return WorkEntry(
      id: id,
      clientName: clientName ?? this.clientName,
      taskType: taskType ?? this.taskType,
      label: label ?? this.label,
      hours: hours ?? this.hours,
      minutes: minutes ?? this.minutes,
      seconds: seconds ?? this.seconds,
      month: month ?? this.month,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_name': clientName,
      'task_type': taskType.name,
      'label': label,
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
      'month': month,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WorkEntry.fromJson(Map<String, dynamic> json, List<TaskType> allTaskTypes) {
    final taskStr = json['task_type'] as String;
    final type = allTaskTypes.firstWhere(
      (t) => t.name == taskStr,
      orElse: () {
        final cleanName = taskStr.replaceAll('_', ' ');
        final capitalized = cleanName.isEmpty
            ? 'Other'
            : '${cleanName[0].toUpperCase()}${cleanName.substring(1)}';
        return TaskType(
          name: taskStr,
          displayName: capitalized,
          icon: Icons.work_outline_rounded,
          color: const Color(0xFF94A3B8),
        );
      },
    );
    return WorkEntry(
      id: json['id'] as String,
      clientName: json['client_name'] as String,
      taskType: type,
      label: json['label'] as String,
      hours: json['hours'] as int,
      minutes: json['minutes'] as int,
      seconds: json['seconds'] as int? ?? 0,
      month: json['month'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
