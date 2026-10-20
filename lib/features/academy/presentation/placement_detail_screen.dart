import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/form_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../data/academy_repository.dart';
import '../domain/academy_models.dart';

final placementPersonnelProvider = FutureProvider.autoDispose
    .family<List<PlacementPersonnelItem>, String>((ref, placementId) async {
  final repo = ref.watch(academyRepositoryProvider);
  final res = await repo.fetchPlacementPersonnel(placementId);
  switch (res) {
    case Success<PaginatedList<PlacementPersonnelItem>>(:final data):
      return data.items;
    case Failure<PaginatedList<PlacementPersonnelItem>>(:final error):
      throw error;
  }
});

class PlacementDetailScreen extends ConsumerStatefulWidget {
  const PlacementDetailScreen({
    required this.placementId,
    this.placementCode,
    super.key,
  });

  final String placementId;
  final String? placementCode;

  @override
  ConsumerState<PlacementDetailScreen> createState() =>
      _PlacementDetailScreenState();
}

class _PlacementDetailScreenState
    extends ConsumerState<PlacementDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bypassToOps(PlacementPersonnelItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bypass ke Operasional'),
        content: Text(
          'Konfirmasi aktivasi personel ${item.candidateName} menjadi karyawan operasional aktif (NUC Karyawan)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Konfirmasi Bypass'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final repo = ref.read(academyRepositoryProvider);
    final res = await repo.bypassPlacementToOps(
      waitingListPlacementId: item.id,
    );
    if (!mounted) return;
    switch (res) {
      case Success<void>():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personel berhasil di-bypass ke operasional.'),
          ),
        );
        ref.invalidate(placementPersonnelProvider(widget.placementId));
      case Failure<void>(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: context.colors.danger,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(placementPersonnelProvider(widget.placementId));
    final title = widget.placementCode != null
        ? '${FormStrings.placementPersonnelTitle}: ${widget.placementCode}'
        : FormStrings.placementPersonnelTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Container(
            color: context.colors.surfaceCard,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: HkSearchField(
              controller: _searchController,
              hintText: 'Cari nama personel...',
              onSubmitted: (q) =>
                  setState(() => _searchQuery = q.trim().toLowerCase()),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: asyncData.when(
              loading: () => const HkLoadingView(
                message: FormStrings.loadingPersonnel,
              ),
              error: (err, _) {
                final msg = err is AppFailure ? err.message : err.toString();
                return HkErrorView(
                  message: msg,
                  onRetry: () =>
                      ref.invalidate(placementPersonnelProvider(widget.placementId)),
                );
              },
              data: (items) {
                final filtered = items.where((e) {
                  if (_searchQuery.isEmpty) return true;
                  return e.candidateName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(placementPersonnelProvider(widget.placementId));
                    },
                    child: ListView(
                      children: const [
                        HkEmptyView(
                          title: 'Belum ada personel penempatan',
                          subtitle:
                              'Belum ada kandidat yang ditugaskan pada jadwal penempatan ini.',
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(placementPersonnelProvider(widget.placementId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PlacementPersonnelCard(
                          item: item,
                          onBypass: () => _bypassToOps(item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacementPersonnelCard extends StatelessWidget {
  const _PlacementPersonnelCard({
    required this.item,
    required this.onBypass,
  });

  final PlacementPersonnelItem item;
  final VoidCallback onBypass;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.candidateName,
                  style: context.textStyles.titleMedium,
                ),
              ),
              HkStatusBadge.fromStatusText(item.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.positionName,
            style: context.monoStyle.copyWith(color: colors.accent),
          ),
          const SizedBox(height: 6),
          Text(
            'Proyek: ${item.projectName}',
            style: context.textStyles.bodyMedium,
          ),
          if (item.suratTugasPdfUrl.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Surat Tugas: ${item.suratTugasPdfUrl}',
              style: context.textStyles.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onBypass,
              icon: const Icon(Icons.verified_user_outlined, size: 18),
              label: const Text('Bypass ke Ops'),
            ),
          ),
        ],
      ),
    );
  }
}
