import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hediety/utils/constants.dart';
import 'package:hediety/utils/sync_service.dart';

import 'app_theme.dart';


class HedieatyApp extends StatefulWidget {
    final Widget? home;
   const HedieatyApp({super.key, this.home});
  @override
  State<HedieatyApp> createState() => _HedieatyAppState();
}

class _HedieatyAppState extends State<HedieatyApp> {
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _syncService.syncLocalToFirestore(); // Trigger sync when back online
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        navigatorKey: navigatorKey, // Set the navigator key here
        title: 'Hedieaty',
        theme: AppTheme.getTheme(),
        home: widget.home
      ),
    );
  }
}