// // lib/core/utils/cubit_stream_bridge.dart
// import 'dart:async';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:rxdart/rxdart.dart';
//
// class CubitStreamBridge {
//   final List<StreamSubscription> _subscriptions = [];
//
//   void connect<S, T>(
//       Cubit<S> source,
//       Cubit<T> target,
//       void Function(S sourceState, Cubit<T> targetCubit) onData,
//       ) {
//     final sub = source.stream.listen((s) => onData(s, target));
//     _subscriptions.add(sub);
//   }
//
//   void connectMany(List<Cubit> cubits, void Function() onAnyChange) {
//     for (final c in cubits) {
//       _subscriptions.add(c.stream.listen((_) => onAnyChange()));
//     }
//   }
//
//   void combineMany(List<Cubit> cubits, void Function(Map<Cubit, dynamic> states) onCombined) {
//     if (cubits.isEmpty) return;
//     final streams = cubits.map((c) => c.stream).toList();
//     final combined = CombineLatestStream.list<dynamic>(streams);
//     final sub = combined.listen((values) {
//       final map = <Cubit, dynamic>{};
//       for (var i = 0; i < cubits.length; i++) {
//         map[cubits[i]] = values[i];
//       }
//       onCombined(map);
//     });
//     _subscriptions.add(sub);
//   }
//
//   void combineLatest3<A, B, C>(Cubit<A> a, Cubit<B> b, Cubit<C> c, void Function(A, B, C) onData) {
//     final combined = CombineLatestStream.combine3<A, B, C, void>(a.stream, b.stream, c.stream, (x, y, z) => null);
//     final sub = combined.listen((_) {
//       onData(a.state as A, b.state as B, c.state as C);
//     });
//     _subscriptions.add(sub);
//   }
//
//   void close() {
//     for (final s in _subscriptions) {
//       s.cancel();
//     }
//     _subscriptions.clear();
//   }
// }
