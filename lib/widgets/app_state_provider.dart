import 'package:flutter/widgets.dart';
import '../state/app_state.dart';

/// InheritedNotifier that provides AppState to the entire widget tree.
/// Any widget calling [AppStateProvider.of(context)] will automatically
/// rebuild when AppState notifies listeners.
class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  /// Retrieves the nearest [AppState] from the widget tree.
  static AppState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'AppStateProvider not found in widget tree');
    return provider!.notifier!;
  }
}
