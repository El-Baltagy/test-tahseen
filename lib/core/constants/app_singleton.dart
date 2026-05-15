


      import 'package:get_it/get_it.dart';
import 'package:tahseen/core/api_helper/dio_helper.dart';
import 'package:tahseen/core/base/base_local_repo.dart';





class AppSingleton {
  AppSingleton._();
  static final AppSingleton _instance = AppSingleton._();
  factory AppSingleton() => _instance;

  final _sl = GetIt.instance;
  GetIt call() => _sl;

  void init(){


    // ── Global Services ──────────────────────────────────────────────────────
    _sl.registerLazySingleton<BaseLocalRepo>(() => BaseLocalRepo());
    _sl.registerLazySingleton<DioHelper>(() => DioHelper()..call());

  }
}