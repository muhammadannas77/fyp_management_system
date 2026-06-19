import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import 'package:flutter/material.dart';

class DateFormatter {
  static String format(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('d MMM yyyy, h:mm a').format(date);
  }

  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('d MMM yyyy').format(date);
  }

  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

class PhaseData {
  static List<Map<String, dynamic>> get allPhases => [
    {
      'phaseNo': 1,
      'title': 'Project Proposal',
      'duration': '2 Weeks',
      'requirements': [
        'Project title',
        'Problem statement',
        'Objectives',
        'Scope',
        'Proposed solution',
      ],
    },
    {
      'phaseNo': 2,
      'title': 'Literature Review',
      'duration': '3 Weeks',
      'requirements': [
        '5 references minimum',
        'Comparison table',
        'Research gap',
        'References list',
      ],
    },
    {
      'phaseNo': 3,
      'title': 'System Design',
      'duration': '3 Weeks',
      'requirements': [
        'Architecture diagram',
        'Database design',
        'Use case diagram',
        'Wireframes',
      ],
    },
    {
      'phaseNo': 4,
      'title': 'Development & Implementation',
      'duration': '6 Weeks',
      'requirements': [
        'Working application',
        'Firebase integration',
        'Progress report',
        'Screenshots',
      ],
    },
    {
      'phaseNo': 5,
      'title': 'Final Submission & Presentation',
      'duration': '2 Weeks',
      'requirements': [
        'Final application',
        'Documentation',
        'Presentation slides',
        'Demo video',
        'Test cases',
      ],
    },
  ];
}

class StatusHelper {
  static Color getColor(String status) {
    switch (status) {
      case 'locked': return AppColors.locked;
      case 'pending_submission': return AppColors.pendingSubmission;
      case 'submitted': return AppColors.submitted;
      case 'changes_requested': return AppColors.changesRequested;
      case 'approved': return AppColors.approved;
      default: return AppColors.locked;
    }
  }

  static String getLabel(String status) {
    switch (status) {
      case 'locked': return 'Locked';
      case 'pending_submission': return 'Pending Submission';
      case 'submitted': return 'Submitted';
      case 'changes_requested': return 'Changes Requested';
      case 'approved': return 'Approved';
      default: return status;
    }
  }

  static IconData getIcon(String status) {
    switch (status) {
      case 'locked': return Icons.lock;
      case 'pending_submission': return Icons.hourglass_empty;
      case 'submitted': return Icons.upload_file;
      case 'changes_requested': return Icons.edit_note;
      case 'approved': return Icons.check_circle;
      default: return Icons.circle;
    }
  }
}
