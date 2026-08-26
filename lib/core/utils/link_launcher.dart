import 'package:url_launcher/url_launcher.dart';

Future<void> openExternalLink(String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    throw Exception('링크를 열 수 없습니다');
  }
}
