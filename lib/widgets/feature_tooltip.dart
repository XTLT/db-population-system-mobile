import 'package:flutter/material.dart';
import '../services/tooltip_service.dart';


class FeatureTooltip extends StatelessWidget {
  final String featureId;
  final String message;
  final Widget child;
  final bool showOnce;
  final Duration? waitDuration;
  final bool preferBelow;

  const FeatureTooltip({
    super.key,
    required this.featureId,
    required this.message,
    required this.child,
    this.showOnce = true,
    this.waitDuration,
    this.preferBelow = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showOnce) {
      
      return Tooltip(
        message: message,
        waitDuration: waitDuration,
        preferBelow: preferBelow,
        child: child,
      );
    }

    
    return FutureBuilder<bool>(
      future: _shouldShow(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Tooltip(
            message: message,
            waitDuration: waitDuration,
            preferBelow: preferBelow,
            child: GestureDetector(
              onTap: () {
                
                TooltipService.markShown(featureId);
              },
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }

  Future<bool> _shouldShow() async {
    if (!showOnce) return true;
    return !await TooltipService.hasShown(featureId);
  }
}


class FeatureTooltipIds {
  
  static const String searchButton = 'search_button';
  static const String advancedFilter = 'advanced_filter';
  
  
  static const String syncStatus = 'sync_status';
  static const String syncButton = 'sync_button';
  
  
  static const String exportReport = 'export_report';
  static const String chartInteraction = 'chart_interaction';
  
  
  static const String addPerson = 'add_person';
  static const String editPerson = 'edit_person';
  static const String photoUpload = 'photo_upload';
  
  
  static const String backupCreate = 'backup_create';
  static const String dataRestore = 'data_restore';
  
  
  static const String userManagement = 'user_management';
}
