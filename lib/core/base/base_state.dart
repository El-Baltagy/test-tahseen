import 'package:flutter/material.dart';
import 'package:tahseen/core/api_helper/dio_error_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared emit wrappers (used inside every feature-specific state)
// ─────────────────────────────────────────────────────────────────────────────

abstract class BaseEmit {}

class Loading extends BaseEmit {}

class ErrorState extends BaseEmit {
  final Failure failure;
  ErrorState(this.failure);
}

class Success<T> extends BaseEmit {
  final T? data;
  Success([this.data]);
}

