import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../data/models.dart';

Future<void> showUpdateDialog(BuildContext context, OtaConfig config) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: !config.forceUpdate,
    builder: (dialogContext) {
      return AlertDialog(
        icon: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.system_update_rounded,
              color: Colors.white, size: 30),
        ),
        title: const Text('A new version is ready'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'v${config.latestVersionName}',
                    style: const TextStyle(
                      color: AppColors.mintDeep,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'You have v${AppInfo.versionName}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
            if (config.changelog.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                config.changelog,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ],
            if (config.forceUpdate) ...[
              const SizedBox(height: 10),
              const Text(
                'This update is required to keep using the app.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.rose,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!config.forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Later'),
            ),
          FilledButton.icon(
            onPressed: () async {
              final url = config.apkUrl.trim();
              if (url.isEmpty) {
                Navigator.pop(dialogContext);
                AppUtils.showSnack(
                  dialogContext,
                  'No APK link was configured yet.',
                  error: true,
                );
                return;
              }
              final uri = Uri.tryParse(url);
              var opened = false;
              if (uri != null) {
                try {
                  opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {
                  opened = false;
                }
              }
              if (!opened) {
                await Clipboard.setData(ClipboardData(text: url));
                if (dialogContext.mounted) {
                  AppUtils.showSnack(
                    dialogContext,
                    'Download link copied to clipboard.',
                  );
                }
              }
              if (dialogContext.mounted && !config.forceUpdate) {
                Navigator.pop(dialogContext);
              }
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Update now'),
          ),
        ],
      );
    },
  );
}
