import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

import '../data/forms.dart';
import '../data/key_value.dart';
import '../data/link_tools.dart';
import 'call_code.dart';
import 'log.dart';

class LinkActions {
  LinkActions._();

  static TestAction generate(LinkForm form) {
    final subtitle = _blankToNull(form.subtitle);
    final image = _blankToNull(form.imageUrl);
    final data = toValueMap(form.data);
    final tags = form.tags.isEmpty ? null : form.tags;
    final redirects = form.redirectsOn
        ? CustomRedirects(
            ios: _toSdk(form.ios),
            android: _toSdk(form.android),
            desktop: _toSdk(form.desktop),
          )
        : null;
    final tracking = form.utmOn
        ? TrackingParams(
            utmCampaign: _blankToNull(form.utmCampaign),
            utmSource: _blankToNull(form.utmSource),
            utmMedium: _blankToNull(form.utmMedium),
          )
        : null;
    final params = GenerateLinkParams(
      title: form.title.trim(),
      subtitle: subtitle,
      imageURL: image,
      data: data.isEmpty ? null : data,
      tags: tags,
      customRedirects: redirects,
      showPreviewIos: form.previewIos.toBool(),
      showPreviewAndroid: form.previewAndroid.toBool(),
      copyToClipboardIos: form.clipboardIos.toBool(),
      copyToClipboardAndroid: form.clipboardAndroid.toBool(),
      tracking: tracking,
    );
    final code = callCode('generateLink', [
      ('title', params.title),
      ('subtitle', subtitle),
      ('imageURL', image),
      ('data', params.data),
      ('tags', tags),
      (
        'customRedirects',
        form.redirectsOn
            ? {
                'android': _describe(form.android),
                'ios': _describe(form.ios),
                'desktop': _describe(form.desktop),
              }
            : null,
      ),
      ('showPreviewIos', params.showPreviewIos),
      ('showPreviewAndroid', params.showPreviewAndroid),
      ('copyToClipboardIos', params.copyToClipboardIos),
      ('copyToClipboardAndroid', params.copyToClipboardAndroid),
      (
        'tracking',
        form.utmOn
            ? {
                'utmSource': form.utmSource,
                'utmMedium': form.utmMedium,
                'utmCampaign': form.utmCampaign,
              }
            : null,
      ),
    ]);
    return TestAction(LogType.create, 'Generate link', code, () async {
      final link = await Grovs().generateLink(params);
      return ActionResult(
        LogState.ok,
        'sent',
        value: link,
        code: '$code\n\n-> "$link"',
      );
    });
  }

  static TestAction details(String path) {
    final code = callCode('linkDetails', [('path', path)]);
    return TestAction(LogType.inspect, 'Link details $path', code, () async {
      final details = await Grovs().linkDetails(path);
      return ActionResult(
        LogState.ok,
        '${flatten(details.raw).length} fields',
        code: '$code\n\n-> ${render(details.raw)}',
      );
    });
  }

  static String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static CustomLinkRedirect? _toSdk(Redirect r) => r.url.trim().isEmpty
      ? null
      : CustomLinkRedirect(
          url: r.url.trim(),
          openAppIfInstalled: r.openAppIfInstalled,
        );

  static Map<String, Object>? _describe(Redirect r) => r.url.trim().isEmpty
      ? null
      : {'url': r.url.trim(), 'openAppIfInstalled': r.openAppIfInstalled};
}
