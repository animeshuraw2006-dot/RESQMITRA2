import 'package:flutter/material.dart';

/// One navigator key for the whole app, so pop-ups and the floating Profile
/// button can open screens from anywhere.
final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

/// Tracks the route stack so overlays know which screen is on top.
class AppNav extends NavigatorObserver {
  static final AppNav I = AppNav._();
  AppNav._();

  final List<Route<dynamic>> _stack = [];
  final ValueNotifier<int> tick = ValueNotifier(0);

  Route<dynamic>? get top => _stack.isEmpty ? null : _stack.last;
  String? get topName => top?.settings.name;
  bool get topIsPopup => top is PopupRoute;
  bool isOnStack(String name) => _stack.any((r) => r.settings.name == name);

  void _changed() => WidgetsBinding.instance.addPostFrameCallback((_) => tick.value++);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (i >= 0) {
      if (newRoute != null) {
        _stack[i] = newRoute;
      } else {
        _stack.removeAt(i);
      }
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _changed();
  }
}
