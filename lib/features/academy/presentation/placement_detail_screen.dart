import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/form_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_pagination_bar.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../data/academy_repository.dart';
import '../domain/academy_models.dart';

typedef PlacementPersonnelParams = ({
  String placementId,
  int page,
  String searchQuery,
});

final placementPersonnelProvider = FutureProvider.autoDispose
    .family<PaginatedList<PlacementPersonnelItem>, PlacementPersonnelParams>(
        (ref, params) async {
  final repo = ref.watch(academyRepositoryProvider);
  final res = await repo.fetchPlacementPersonnel(
    params.placementId,
    page: params.page,
    limit: 20,
    searchQuery: params.searchQuery,
  );
  switch (res) {
    case Success<PaginatedList<PlacementPersonnelItem>>(:final data):
      return data;
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
  int _page = 1;

  PlacementPersonnelParams get _params => (
        placementId: widget.placementId,
        page: _page,
        searchQuery: _searchQuery,
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openExternalUrl(String url, {required String label}) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label belum tersedia.'),
          backgroundColor: context.colors.warning,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tautan $label tidak valid: $trimmed'),
          backgroundColor: context.colors.danger,
        ),
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka $label: $trimmed'),
          backgroundColor: context.colors.danger,
        ),
      );
    }
  }

  Future<void> _bypassToOps(PlacementPersonnelItem item) async {
    if (item.isAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Personel ini sudah diterima di proyek dan telah aktif di operasional.',
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bypass ke Operasional'),
        content: Text(
          'Konfirmasi aktivasi personel ${item.candidateName} menjadi karyawan operasional aktif (NUC Karyawan)?\n\n'
          'Tindakan ini digunakan jika Field Manager di lokasi proyek belum sempat memverifikasi penerimaan di sistem.',
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
        ref.invalidate(placementPersonnelProvider(_params));
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
    final asyncData = ref.watch(placementPersonnelProvider(_params));
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
              onSubmitted: (q) => setState(() {
                _searchQuery = q.trim();
                _page = 1;
              }),
              onClear: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _page = 1;
                });
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
                      ref.invalidate(placementPersonnelProvider(_params)),
                );
              },
              data: (data) {
                if (data.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(placementPersonnelProvider(_params));
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

                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(placementPersonnelProvider(_params));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: data.items.length,
                          itemBuilder: (context, index) {
                            final item = data.items[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PlacementPersonnelCard(
                                item: item,
                                onBypass: () => _bypassToOps(item),
                                onOpenUrl: (url, label) =>
                                    _openExternalUrl(url, label: label),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (data.totalCount > 0)
                      HkPaginationBar(
                        currentPage: data.page,
                        totalCount: data.totalCount,
                        pageSize: data.pageSize,
                        onPageChanged: (p) => setState(() => _page = p),
                      ),
                  ],
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
    required this.onOpenUrl,
  });

  final PlacementPersonnelItem item;
  final VoidCallback onBypass;
  final void Function(String url, String label) onOpenUrl;

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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (item.suratTugasDownloadUrl.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () =>
                      onOpenUrl(item.suratTugasDownloadUrl, 'Surat Tugas'),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Unduh Surat Tugas'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (item.suratTugasPdfUrl.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () =>
                      onOpenUrl(item.suratTugasPdfUrl, 'PDF Bertanda Tangan'),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Lihat PDF'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (item.isAccepted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.successMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: colors.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personel Diterima di Proyek',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: colors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sudah aktif di Operasional (Field Manager telah konfirmasi - Tidak perlu Bypass Ops).',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Menunggu konfirmasi penerimaan dari Field Manager di proyek.',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onBypass,
                    icon: const Icon(Icons.verified_user_outlined, size: 16),
                    label: const Text('Bypass ke Ops'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
