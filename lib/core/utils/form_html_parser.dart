import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

@immutable
class SelectOption {
  const SelectOption({required this.value, required this.label});

  final String value;
  final String label;
}

abstract final class FormHtmlParser {
  /// Mengambil seluruh `<select>` pada halaman form server-rendered, dikunci
  /// oleh atribut `name` (mis. `jobId`, `selectProvince[]`, `admin[]`).
  static Map<String, List<SelectOption>> parseSelects(String htmlSource) {
    final doc = html_parser.parse(htmlSource);
    final result = <String, List<SelectOption>>{};
    for (final select in doc.querySelectorAll('select')) {
      final name = select.attributes['name'];
      if (name == null || name.isEmpty || result.containsKey(name)) continue;
      final options = <SelectOption>[];
      for (final option in select.querySelectorAll('option')) {
        final value = (option.attributes['value'] ?? '').trim();
        if (value.isEmpty) continue;
        options.add(
          SelectOption(
            value: value,
            label: option.text.replaceAll(RegExp(r'\s+'), ' ').trim(),
          ),
        );
      }
      result[name] = options;
    }
    return result;
  }

  /// Pesan validasi CodeIgniter: `<small class="text-danger ...">pesan</small>`.
  static List<String> parseValidationErrors(String htmlSource) {
    final doc = html_parser.parse(htmlSource);
    return doc
        .querySelectorAll('small.text-danger')
        .map((e) => e.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Mengubah potongan HTML deskripsi lowongan menjadi teks polos bernewline.
  static String htmlToPlainText(String source) {
    final withBreaks = source
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
    final fragment = html_parser.parseFragment(withBreaks);
    return (fragment.text ?? '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Teks polos -> HTML aman untuk kolom deskripsi (CKEditor di web).
  static String plainTextToHtml(String text) {
    final escaped = text
        .trim()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    final lines = escaped.split(RegExp(r'\r?\n'));
    return '<p>${lines.join('<br />\r\n')}</p>\r\n';
  }
}
