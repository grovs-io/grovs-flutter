import 'package:flutter/material.dart' hide Chip;

import '../../data/forms.dart';
import '../controls/basics.dart';
import '../controls/chips.dart';
import '../controls/fields.dart';
import '../controls/key_value_rows.dart';
import '../help.dart';

class LinkFormFields extends StatelessWidget {
  const LinkFormFields(this.form, this.update, {super.key});

  final LinkForm form;
  final void Function(LinkForm Function(LinkForm)) update;

  static String _imageName(String url) => switch (url) {
    '' => 'None',
    sampleImage1 => 'Sample 1',
    sampleImage2 => 'Sample 2',
    _ => url,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SuggestField(
          value: form.title,
          onChanged: (v) => update((f) => f.copyWith(title: v)),
          suggestions: const [],
          label: 'Title',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        SuggestField(
          value: form.subtitle,
          onChanged: (v) => update((f) => f.copyWith(subtitle: v)),
          suggestions: const [],
          label: 'Subtitle',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 10),
        KeyValueRows(
          rows: form.data,
          onChanged: (v) => update((f) => f.copyWith(data: v)),
          label: 'Data',
          info: Help.linkData,
          suggestedKeys: const ['promo', 'user_id', 'screen'],
        ),
        const SizedBox(height: 6),
        FoldRow(
          'More options',
          form.moreSummary(),
          children: [
            ChipPicker(
              options: const ['', sampleImage1, sampleImage2],
              selected: form.imageUrl,
              onSelect: (v) => update((f) => f.copyWith(imageUrl: v)),
              label: 'Image',
              otherLabel: 'URL…',
              otherPlaceholder: 'https://',
              display: _imageName,
            ),
            const SizedBox(height: 10),
            ChipInput(
              values: form.tags,
              onChanged: (v) => update((f) => f.copyWith(tags: v)),
              label: 'Tags',
              info: Help.linkTags,
              placeholder: 'Add tag',
            ),
            SwitchRow(
              'UTM tracking',
              form.utmOn,
              (v) => update((f) => f.copyWith(utmOn: v)),
              info: Help.utm,
            ),
            if (form.utmOn)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        value: form.utmSource,
                        onChanged: (v) =>
                            update((f) => f.copyWith(utmSource: v)),
                        placeholder: 'source',
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: AppTextField(
                        value: form.utmMedium,
                        onChanged: (v) =>
                            update((f) => f.copyWith(utmMedium: v)),
                        placeholder: 'medium',
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: AppTextField(
                        value: form.utmCampaign,
                        onChanged: (v) =>
                            update((f) => f.copyWith(utmCampaign: v)),
                        placeholder: 'campaign',
                      ),
                    ),
                  ],
                ),
              ),
            SwitchRow(
              'Custom redirects',
              form.redirectsOn,
              (v) => update((f) => f.copyWith(redirectsOn: v)),
              supporting: form.redirectsOn ? null : 'uses project',
              info: Help.customRedirects,
            ),
            if (form.redirectsOn) ...[
              _RedirectEditor(
                'Android',
                form.android,
                (r) => update((f) => f.copyWith(android: r)),
              ),
              _RedirectEditor(
                'iOS',
                form.ios,
                (r) => update((f) => f.copyWith(ios: r)),
              ),
              _RedirectEditor(
                'Desktop',
                form.desktop,
                (r) => update((f) => f.copyWith(desktop: r)),
              ),
            ],
            FoldRow(
              'Platform overrides',
              form.overridesSummary(),
              info: Help.platformOverrides,
              children: [
                TriStateRow(
                  'Preview on Android',
                  form.previewAndroid,
                  (v) => update((f) => f.copyWith(previewAndroid: v)),
                ),
                TriStateRow(
                  'Preview on iOS',
                  form.previewIos,
                  (v) => update((f) => f.copyWith(previewIos: v)),
                ),
                TriStateRow(
                  'Clipboard on Android',
                  form.clipboardAndroid,
                  (v) => update((f) => f.copyWith(clipboardAndroid: v)),
                ),
                TriStateRow(
                  'Clipboard on iOS',
                  form.clipboardIos,
                  (v) => update((f) => f.copyWith(clipboardIos: v)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _RedirectEditor extends StatelessWidget {
  const _RedirectEditor(this.platform, this.redirect, this.onChange);

  final String platform;
  final Redirect redirect;
  final ValueChanged<Redirect> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinkField(
            value: redirect.url,
            onChanged: (v) => onChange(redirect.copyWith(url: v)),
            label: platform,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ChipRow(
              sampleRedirects,
              redirect.url,
              (v) => onChange(redirect.copyWith(url: v)),
            ),
          ),
          SwitchRow(
            'Open app if installed',
            redirect.openAppIfInstalled,
            (v) => onChange(redirect.copyWith(openAppIfInstalled: v)),
            showDivider: false,
            info: Help.openAppIfInstalled,
          ),
        ],
      ),
    );
  }
}
