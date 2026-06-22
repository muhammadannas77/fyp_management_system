/// ------------------------------------------------------------------
/// File: providers.dart
/// Role: State Management (ViewModel)
/// 
/// Description:
/// Handles business logic and state management. Listens to Repository data streams and updates the UI (Screens) using the ChangeNotifier pattern. Prevents the UI from accessing the database directly.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

export 'auth_provider.dart';
export 'project_provider.dart';
export 'other_providers.dart';
