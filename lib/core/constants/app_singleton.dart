
import 'package:tahseen/features/screens/Splash/data/repo/remote/Splash_repo.dart';
import 'package:tahseen/features/screens/Splash/service/Splash_service.dart';
import 'package:tahseen/features/screens/Splash/controller/Splash_cubit.dart';
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
    ///..................Splash.................///
    _sl.registerLazySingleton(() => SplashRepo(_sl()));
    _sl.registerLazySingleton(() => SplashService(_sl(), _sl()));
    _sl.registerFactory(() => SplashCubit(_sl()));



    // ── Global Services ──────────────────────────────────────────────────────
    _sl.registerLazySingleton<BaseLocalRepo>(() => BaseLocalRepo());
    _sl.registerLazySingleton<DioHelper>(() => DioHelper()..call());

  }
}