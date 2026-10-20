import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/hk_pagination_bar.dart';
import '../../../core/widgets/hk_state_views.dart';
import '../domain/academy_models.dart';
import 'academy_controller.dart';
import 'widgets/assign_placement_dialog.dart';

class _RowData {
  const _RowData({
    required this.title,
    required this.subtitle,
    required this.meta,
    this.badge,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String? badge;
  final VoidCallback? onTap;
}

class AcademyScreen extends ConsumerStatefulWidget {
  const AcademyScreen({super.key});

  @override
  ConsumerState<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends ConsumerState<AcademyScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_RowData> _rows(AcademyViewState s, AcademyController controller) {
    switch (s.activeTab) {
      case AcademySubTab.placementWaiting:
        return s.waitingPlacements
            .map((e) => _RowData(
                  title: e.applicantName,
                  subtitle: '${e.positionName} • ${e.city}',
                  meta:
                      '${e.phone} • ${e.email}\nSkor PKL: ${e.pklScore} • Lolos PKL: ${e.passedDate}',
                  badge: 'Lolos PKL',
                  onTap: () async {
                    final assigned = await AssignPlacementDialog.show(
                      context,
                      candidate: e,
                    );
                    if (assigned == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Kandidat berhasil ditugaskan ke jadwal penempatan.',
                          ),
                        ),
                      );
                      await controller.refresh();
                    }
                  },
                ))
            .toList();
      case AcademySubTab.placementSchedules:
        return s.placementSchedules
            .map((e) => _RowData(
                  title: e.code,
                  subtitle: '${e.projectName} • ${e.positionName}',
                  meta: 'Kuota: ${e.quota} • Tanggal: ${e.date}',
                  onTap: () => context.push(
                    '/academy/placement-detail/${e.id}?code=${e.code}',
                  ),
                ))
            .toList();
      case AcademySubTab.academyNus:
        return s.academyAccounts
            .map((e) => _RowData(
                  title: e.fullName,
                  subtitle: 'NUS Pelamar',
                  meta: e.nusCode,
                ))
            .toList();
      case AcademySubTab.psikotes:
        return s.psikotesQuestions
            .map((e) => _RowData(
                  title: e.question,
                  subtitle: '${e.type} • ${e.level}',
                  meta: 'Pilihan: ${e.choices.join(' / ')}\nJawaban: ${e.answer}',
                ))
            .toList();
      case AcademySubTab.trainingOffline:
        return s.trainingRecords
            .map((e) => _RowData(
                  title: e.participantName,
                  subtitle: '${e.vacancyCode} • ${e.scheduleDate}',
                  meta: 'Trainer: ${e.trainerName} • Skor: ${e.score}\nCatatan: ${e.reason}',
                  badge: e.status,
                  onTap: () => context.push(
                    '/training/participants/${e.id}?code=${e.vacancyCode}',
                  ),
                ))
            .toList();
      case AcademySubTab.fieldManagers:
        return s.fieldManagers
            .map((e) => _RowData(
                  title: e.name,
                  subtitle: '${e.nuc} • ${e.email}',
                  meta: 'HP: ${e.phone} • Dibuat: ${e.createdAt}',
                  badge: e.status,
                ))
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(academyControllerProvider);
    final activeTab =
        asyncState.valueOrNull?.activeTab ?? AcademySubTab.placementWaiting;
    final controller = ref.read(academyControllerProvider.notifier);

    Widget? buildFab() {
      if (activeTab == AcademySubTab.placementSchedules) {
        return FloatingActionButton.extended(
          onPressed: () async {
            final res =
                await context.push<bool>('/management/create-placement');
            if (res == true && mounted) {
              await controller.refresh();
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Buat Jadwal Penempatan'),
        );
      }
      if (activeTab == AcademySubTab.trainingOffline) {
        return FloatingActionButton.extended(
          onPressed: () async {
            final res =
                await context.push<bool>('/management/create-training');
            if (res == true && mounted) {
              await controller.refresh();
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Jadwal Training'),
        );
      }
      return null;
    }

    return Scaffold(
      floatingActionButton: buildFab(),
      body: Column(
      children: [
        Container(
          color: context.colors.surfaceCard,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AcademySubTab.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tab = AcademySubTab.values[index];
                    return ChoiceChip(
                      label: Text(tab.label),
                      selected: tab == activeTab,
                      onSelected: (_) {
                        _searchController.clear();
                        controller.selectTab(tab);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              HkSearchField(
                controller: _searchController,
                onSubmitted: controller.updateSearch,
                onClear: () {
                  _searchController.clear();
                  controller.updateSearch('');
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: asyncState.when(
            loading: () =>
                const HkLoadingView(message: AppStrings.loadingAcademy),
            error: (err, _) => HkErrorView(
              message: err is AppFailure ? err.message : err.toString(),
              onRetry: controller.refresh,
            ),
            data: (viewState) {
              final rows = _rows(viewState, controller);
              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.refresh,
                      child: rows.isEmpty
                          ? ListView(children: const [HkEmptyView()])
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: rows.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _RowCard(data: rows[i]),
                              ),
                            ),
                    ),
                  ),
                  if (viewState.totalCount > 0)
                    HkPaginationBar(
                      currentPage: viewState.page,
                      totalCount: viewState.totalCount,
                      pageSize: viewState.pageSize,
                      onPageChanged: controller.goToPage,
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

class _RowCard extends StatelessWidget {
  const _RowCard({required this.data});

  final _RowData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: data.onTap,
      child: Container(
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
                  data.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleMedium,
                ),
              ),
              if (data.badge != null) ...[
                const SizedBox(width: 8),
                HkStatusBadge.fromStatusText(data.badge!),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(data.subtitle,
              style: context.monoStyle.copyWith(color: colors.accent)),
          const SizedBox(height: 6),
          Text(data.meta, style: context.textStyles.bodySmall),
        ],
      ),
    ),
  );
  }
}
