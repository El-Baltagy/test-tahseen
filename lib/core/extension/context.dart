import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

extension AppRouterExtension on BuildContext {
  /// Access the [StackRouter] from any [BuildContext].
  StackRouter get router => AutoRouter.of(this);

  /// Push a new [route] onto the stack.
  Future<T?> push<T extends Object?>(PageRouteInfo route) => router.push<T>(route);

  /// Replace the current route with a new [route].
  Future<void> replace(PageRouteInfo route) => router.replace(route);

  /// Push a new [route] and remove all previous routes until the [predicate] is met.
  Future<void> pushAndPopUntil(PageRouteInfo route, {required RoutePredicate predicate}) =>
      router.pushAndPopUntil(route, predicate: predicate);

  /// Pop the current route from the stack.
  Future<bool> pop<T extends Object?>([T? result]) => router.maybePop<T>(result);

  /// Pop all routes until the root route.
  void popUntilRoot() => router.popUntilRoot();

  /// Check if the router can pop.
  bool get canPop => router.canPop();




}
