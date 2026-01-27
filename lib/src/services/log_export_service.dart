import 'package:flutter/material.dart';
import 'package:hibiscus/src/rust/api/init.dart' as init_api;
import 'package:share_plus/share_plus.dart';

class LogExportService {
  static Future<void> shareLogs(BuildContext context) async {
    final shareOrigin = _shareOriginFromContext(context);
    final zipPath = await init_api.exportLogsZip();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zipPath)],
        subject: 'Hibiscus logs',
        text: 'Hibiscus 日志',
        sharePositionOrigin: shareOrigin,
      ),
    );
  }

  static Rect _shareOriginFromContext(BuildContext context) {
    final renderObject = context.findRenderObject();
    final box = renderObject is RenderBox ? renderObject : null;
    if (box == null || !box.hasSize || box.size.isEmpty) {
      return const Rect.fromLTWH(1, 1, 1, 1);
    }
    final origin = box.localToGlobal(Offset.zero);
    final rect = origin & box.size;
    if (rect.isEmpty) return const Rect.fromLTWH(1, 1, 1, 1);
    return rect;
  }
}
