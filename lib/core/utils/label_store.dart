import 'package:fprs_frontend/core/services/label_service.dart';

// 앱 프로세스가 살아있는 동안만 유지되는 메모리 캐시.
// 앱을 완전히 종료했다 재실행하면 다시 GET /api/labels를 호출한다.
class LabelStore {
  static Map<String, String> _labels = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      _labels = await LabelService().getLabels();
    } catch (_) {
      // 조회 실패 시 각 화면의 fallback 문구를 그대로 사용
    }
    _loaded = true;
  }

  static String get(String key, String fallback) => _labels[key] ?? fallback;
}
