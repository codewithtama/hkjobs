import 'dart:convert';
import 'package:html/parser.dart' as html_parser;

class ParsedDataTableResult {
  const ParsedDataTableResult({required this.totalRecords, required this.rows});

  final int totalRecords;
  final List<Map<String, Object?>> rows;
}

abstract final class HtmlCellParser {
  static String stripHtml(Object? raw) {
    if (raw == null) return '-';
    final text = raw.toString().trim();
    if (text.isEmpty) return '-';
    if (!text.contains('<')) return text;
    final fragment = html_parser.parseFragment(text);
    final cleaned = (fragment.text ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? '-' : cleaned;
  }

  static String extractFirstNumber(Object? raw, {String fallback = '0'}) {
    if (raw == null) return fallback;
    final text = raw.toString();
    final match = RegExp(r'(\d+)').firstMatch(text);
    return match?.group(1) ?? fallback;
  }

  static List<String> extractHrefs(Object? raw) {
    if (raw == null) return const <String>[];
    final text = raw.toString();
    if (!text.contains('href')) return const <String>[];
    final matches = RegExp(r'''href=["']([^"']+)["']''').allMatches(text);
    final result = <String>[];
    for (final match in matches) {
      final url = match.group(1)?.trim();
      if (url != null && url.isNotEmpty && url != '#') {
        result.add(url.replaceAll(r'\/', '/'));
      }
    }
    return result;
  }

  static String? extractFirstFunctionArg(Object? raw, String functionPrefix) {
    if (raw == null) return null;
    final text = raw.toString();
    final pattern = RegExp('$functionPrefix\\(\\s*[\'"]?(\\d+)[\'"]?\\s*\\)');
    return pattern.firstMatch(text)?.group(1);
  }

  static String? extractTrailingPathId(Object? raw) {
    final hrefs = extractHrefs(raw);
    for (final href in hrefs) {
      final match = RegExp(r'/(\d+)$').firstMatch(href);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  static ParsedDataTableResult parseDataTablePayload(String rawJson) {
    final Object? decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, Object?>) {
      return const ParsedDataTableResult(totalRecords: 0, rows: []);
    }

    final totalRaw = decoded['recordsTotal'] ?? decoded['recordsFiltered'] ?? 0;
    final total = int.tryParse(totalRaw.toString()) ?? 0;

    final dataField = decoded['data'];
    if (dataField is! List<Object?>) {
      return ParsedDataTableResult(totalRecords: total, rows: const []);
    }

    final rows = <Map<String, Object?>>[];
    for (final item in dataField) {
      if (item is Map<String, Object?>) {
        rows.add(item);
      } else if (item is Map) {
        rows.add(item.map((key, value) => MapEntry(key.toString(), value)));
      } else if (item is List) {
        final rowMap = <String, Object?>{};
        for (var i = 0; i < item.length; i++) {
          rowMap[i.toString()] = item[i];
        }
        rows.add(rowMap);
      }
    }
    return ParsedDataTableResult(totalRecords: total, rows: rows);
  }

  static Map<String, String> parseDashboardIdentity(String htmlSource) {
    final doc = html_parser.parse(htmlSource);
    final profileText =
        doc.querySelector('.nav-profile-text p')?.text.trim() ?? '';

    String role = 'Admin';
    String adminId = '52';

    final sidebarLinks = doc.querySelectorAll('#sidebar a');
    bool hasAdminMenu = false;
    bool hasInterviewerLink = false;
    bool hasTrainingMenu = false;

    for (final link in sidebarLinks) {
      final href = link.attributes['href'] ?? '';
      if (href.contains('/admin-carefast')) {
        hasAdminMenu = true;
      }
      final intMatch = RegExp(r'/interviewer/(\d+)').firstMatch(href);
      if (intMatch != null) {
        hasInterviewerLink = true;
        adminId = intMatch.group(1) ?? '158';
      }
      if (href.endsWith('/training')) {
        hasTrainingMenu = true;
      }
    }

    if (hasInterviewerLink && !hasAdminMenu) {
      role = 'Interviewer';
    } else if (hasTrainingMenu && !hasAdminMenu && !hasInterviewerLink) {
      role = 'Trainer';
      adminId = '159';
    } else {
      role = 'Super Admin';
    }

    final isLoginPage =
        doc.querySelector('form.login') != null ||
        (doc.querySelector('title')?.text.contains('Login Admin') ?? false);

    return <String, String>{
      'isLoginPage': isLoginPage ? 'true' : 'false',
      'displayName': profileText.isEmpty ? 'ADMIN HK' : profileText,
      'role': role,
      'adminId': adminId,
    };
  }
}
