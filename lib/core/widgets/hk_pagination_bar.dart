import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HkPaginationBar extends StatelessWidget {
  const HkPaginationBar({
    required this.currentPage,
    required this.totalCount,
    required this.onPageChanged,
    this.pageSize = 20,
    super.key,
  });

  final int currentPage;
  final int totalCount;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  int get totalPages => (totalCount <= 0 || pageSize <= 0)
      ? 1
      : ((totalCount + pageSize - 1) ~/ pageSize);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pages = totalPages;
    final hasPrev = currentPage > 1;
    final hasNext = currentPage < pages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        border: Border(
          top: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Hal $currentPage dari $pages • Total $totalCount data',
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: hasPrev ? () => onPageChanged(1) : null,
                icon: const Icon(Icons.first_page_rounded),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                tooltip: 'Halaman Pertama',
              ),
              IconButton(
                onPressed:
                    hasPrev ? () => onPageChanged(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
                iconSize: 22,
                visualDensity: VisualDensity.compact,
                tooltip: 'Sebelumnya',
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$currentPage / $pages',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    hasNext ? () => onPageChanged(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
                iconSize: 22,
                visualDensity: VisualDensity.compact,
                tooltip: 'Berikutnya',
              ),
              IconButton(
                onPressed: hasNext ? () => onPageChanged(pages) : null,
                icon: const Icon(Icons.last_page_rounded),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                tooltip: 'Halaman Terakhir',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
