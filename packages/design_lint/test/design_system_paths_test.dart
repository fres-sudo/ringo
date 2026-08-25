import 'package:design_lint/src/design_system_paths.dart';
import 'package:test/test.dart';

void main() {
  group('isExemptPath', () {
    test('exempts the design system package itself', () {
      expect(
        isExemptPath('/repo/packages/ui_kit/lib/src/atoms/app_text.dart'),
        isTrue,
      );
    });

    test('exempts generated sources', () {
      for (final path in [
        '/repo/features/example/lib/foo.g.dart',
        '/repo/features/example/lib/foo.freezed.dart',
        '/repo/apps/ringo/lib/app_router.gr.dart',
        '/repo/apps/ringo/lib/di.config.dart',
      ]) {
        expect(isExemptPath(path), isTrue, reason: path);
      }
    });

    test('exempts test files and test directories', () {
      expect(
        isExemptPath('/repo/features/example/test/example_bloc_test.dart'),
        isTrue,
      );
      expect(isExemptPath('/repo/test/example/foo_test.dart'), isTrue);
    });

    test('does NOT exempt ordinary production sources', () {
      expect(
        isExemptPath('/repo/features/example/lib/presentation/example_page.dart'),
        isFalse,
      );
      expect(isExemptPath('/repo/apps/ringo/lib/app/app.dart'), isFalse);
    });

    test('handles Windows-style separators', () {
      expect(
        isExemptPath(r'C:\repo\packages\ui_kit\lib\src\app_text.dart'),
        isTrue,
      );
    });
  });
}
