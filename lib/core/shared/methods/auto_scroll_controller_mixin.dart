 import 'package:flutter/widgets.dart';

// mixin AutoScrollControllerMixin<T extends StatefulWidget> on State<T> {
//   final Map<String, ScrollController> _controllers = {};

//   ScrollController getScrollController([String name = 'default']) {
//     return _controllers.putIfAbsent(name, () => ScrollController());
//   }
//
//   ScrollController get scrollController => getScrollController();
//
//   void addScrollController(String name, ScrollController controller) {
//     _controllers[name] = controller;
//   }
//
//   @override
//   void dispose() {
//     for (final c in _controllers.values) {
//       try {
//         c.dispose();
//       } catch (_) {}
//     }
//     _controllers.clear();
//     super.dispose();
//   }
// }
 mixin ScrollEndListenerMixin<T extends StatefulWidget> on State<T> {
   late final ScrollController scrollController;
   bool _isTriggered = false;

   double get scrollThreshold => 200;

   /// Must return true when Bloc is loading
   bool get isLoading;

   @override
   void initState() {
     super.initState();
     scrollController = ScrollController();
     scrollController.addListener(_onScroll);
   }

   void _onScroll() {
     if (!scrollController.hasClients || isLoading) return;

     final position = scrollController.position;
     final isNearBottom =
         position.maxScrollExtent - position.pixels <= scrollThreshold;

     if (isNearBottom && !_isTriggered) {
       _isTriggered = true;
       onReachMaxScroll();
     }

     if (!isNearBottom) {
       _isTriggered = false;
     }
   }

   void onReachMaxScroll();

   @override
   void dispose() {
     scrollController.removeListener(_onScroll);
     scrollController.dispose();
     super.dispose();
   }
 }