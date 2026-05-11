import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

PluginBase createPlugin() => TahseenLints();

class TahseenLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        ArchitectureRegistrationRule(),
      ];
}

class ArchitectureRegistrationRule extends DartLintRule {
  ArchitectureRegistrationRule() : super(code: _code);

  static const _code = LintCode(
    name: 'architecture_registration_missing',
    problemMessage: 'This component must be registered in the appropriate registry.',
    correctionMessage: 'Add this class to AppSingleton.init() or AppRouter.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  // Static caches to persist across multiple files
  static String? _singletonCache;
  static DateTime? _lastSingletonMTime;
  
  static String? _routerCache;
  static DateTime? _lastRouterMTime;

  String _stripComments(String content) {
    var stripped = content.replaceAll(RegExp(r'//.*'), '');
    stripped = stripped.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    return stripped;
  }

  String? _getSingletonContent(String rootPath) {
    try {
      final file = File(p.join(rootPath, 'lib', 'core', 'constants', 'app_singleton.dart'));
      if (!file.existsSync()) return null;

      final mTime = file.lastModifiedSync();
      if (_singletonCache == null || _lastSingletonMTime == null || mTime.isAfter(_lastSingletonMTime!)) {
        _singletonCache = _stripComments(file.readAsStringSync());
        _lastSingletonMTime = mTime;
      }
      return _singletonCache;
    } catch (_) {
      return null;
    }
  }

  String? _getRouterContent(String rootPath) {
    try {
      final file = File(p.join(rootPath, 'lib', 'core', 'app', 'route.dart'));
      if (!file.existsSync()) return null;

      final mTime = file.lastModifiedSync();
      if (_routerCache == null || _lastRouterMTime == null || mTime.isAfter(_lastRouterMTime!)) {
        _routerCache = _stripComments(file.readAsStringSync());
        _lastRouterMTime = mTime;
      }
      return _routerCache;
    } catch (_) {
      return null;
    }
  }

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.path;
    if (!filePath.contains('lib${Platform.pathSeparator}features') && !filePath.contains('lib/features')) return;
    if (filePath.contains('.g.dart') || filePath.contains('.gr.dart') || filePath.contains('.freezed.dart')) return;

    final normalizedPath = p.normalize(filePath);
    final libMatch = RegExp(r'[\\/]lib[\\/]').firstMatch(normalizedPath);
    if (libMatch == null) return;
    final rootPath = normalizedPath.substring(0, libMatch.start);
    
    final singletonContent = _getSingletonContent(rootPath);
    final routerContent = _getRouterContent(rootPath);

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;

      final baseClass = extendsClause.superclass.toSource().split('<').first.trim();

      if (['BaseCubit', 'BaseService', 'BaseRemoteRepo', 'BaseRepo', 'BaseLocalRepo'].contains(baseClass)) {
        if (singletonContent != null) {
          final regExp = RegExp('\\b$className\\b');
          if (!regExp.hasMatch(singletonContent)) {
            reporter.reportErrorForToken(_code, node.name);
          }
        }
      }
    });

    context.registry.addInstanceCreationExpression((node) {
      final constructorName = node.constructorName.type.toSource().split('<').first.trim();
      if (constructorName == 'Scaffold') {
        final classNode = node.thisOrAncestorOfType<ClassDeclaration>();
        if (classNode != null) {
          final widgetName = classNode.name.lexeme;
          if (routerContent != null) {
             final regExp = RegExp('\\b$widgetName\\b');
             final routeName = widgetName.replaceAll('Page', '').replaceAll('Screen', '') + 'Route';
             final routeRegExp = RegExp('\\b$routeName\\b');
             
             if (!regExp.hasMatch(routerContent) && !routeRegExp.hasMatch(routerContent)) {
                reporter.reportErrorForToken(_code, classNode.name);
             }
          }
        }
      }
    });
  }
}
