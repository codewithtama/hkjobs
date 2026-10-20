import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/hkjobs_dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/html_cell_parser.dart';
import '../../../core/widgets/hk_state_views.dart';

enum OrgTab {
  employees(AppStrings.tabEmployees, ApiEndpoints.karyawanListTable),
  positions(AppStrings.tabPositions, ApiEndpoints.positionListTable),
  branches(AppStrings.tabBranches, ApiEndpoints.branchListTable),
  admins(AppStrings.tabAdmins, ApiEndpoints.adminListTable);

  const OrgTab(this.label, this.endpoint);
  final String label;
  final String endpoint;
}

@immutable
class OrgRow {
  const OrgRow({
    required this.title,
    required this.subtitle,
    required this.meta,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String? badge;
}

class OrgQuery {
  const OrgQuery(this.tab, this.search);

  final OrgTab tab;
  final String search;

  @override
  bool operator ==(Object other) =>
      other is OrgQuery && other.tab == tab && other.search == search;

  @override
  int get hashCode => Object.hash(tab, search);
}

OrgRow _toRow(OrgTab tab, Map<String, Object?> r) {
  String c(int i) => HtmlCellParser.stripHtml(r['$i']);
  switch (tab) {
    case OrgTab.employees:
      return OrgRow(title: c(2), subtitle: c(1), meta: 'Proyek: ${c(3)}');
    case OrgTab.positions:
      return OrgRow(title: c(2), subtitle: c(1), meta: 'Level: ${c(3)}');
    case OrgTab.branches:
      return OrgRow(
          title: '${c(1)} • ${c(2)}', subtitle: c(4), meta: c(3));
    case OrgTab.admins:
      return OrgRow(
        title: c(1),
        subtitle: '${c(5)} • ${c(6)}',
        meta: '${c(2)} • ${c(3)}',
        badge: c(8),
      );
  }
}

final orgListProvider =
    FutureProvider.autoDispose.family<List<OrgRow>, OrgQuery>((ref, q) async {
  final client = ref.watch(hkJobsApiClientProvider);
  final res = await client.fetchDataTable(
    endpoint: q.tab.endpoint,
    length: 50,
    searchQuery: q.search,
  );
  switch (res) {
    case Failure<ParsedDataTableResult>(:final error):
      throw error;
    case Success<ParsedDataTableResult>(:final data):
      return data.rows.map((r) => _toRow(q.tab, r)).toList();
  }
});

class OrganizationScreen extends ConsumerStatefulWidget {
  const OrganizationScreen({super.key});

  @override
  ConsumerState<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends ConsumerState<OrganizationScreen> {
  final TextEditingController _search = TextEditingController();
  OrgTab _tab = OrgTab.employees;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _apply(String q) => setState(() => _query = q.trim());

  @override
  Widget build(BuildContext context) {
    final query = OrgQuery(_tab, _query);
    final async = ref.watch(orgListProvider(query));
    final colors = context.colors;

    return Scaffold(
      floatingActionButton: _tab == OrgTab.admins
          ? FloatingActionButton.extended(
              onPressed: () async {
                final res =
                    await context.push<bool>('/management/create-admin');
                if (res == true && mounted) {
                  ref.invalidate(orgListProvider);
                }
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Tambah Admin'),
            )
          : null,
      body: Column(
      children: [
        Container(
          color: colors.surfaceCard,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: OrgTab.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final t = OrgTab.values[i];
                    return ChoiceChip(
                      label: Text(t.label),
                      selected: t == _tab,
                      onSelected: (_) => setState(() => _tab = t),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              HkSearchField(
                controller: _search,
                onSubmitted: _apply,
                onClear: () {
                  _search.clear();
                  _apply('');
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: async.when(
            loading: () =>
                const HkLoadingView(message: AppStrings.loadingOrganization),
            error: (e, _) => HkErrorView(
              message: e is AppFailure ? e.message : e.toString(),
              onRetry: () => ref.invalidate(orgListProvider(query)),
            ),
            data: (rows) => RefreshIndicator(
              onRefresh: () async => ref.refresh(orgListProvider(query).future),
              child: rows.isEmpty
                  ? ListView(children: const [HkEmptyView()])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rows.length,
                      itemBuilder: (context, i) {
                        final r = rows[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
                                      child: Text(r.title,
                                          style:
                                              context.textStyles.titleMedium),
                                    ),
                                    if (r.badge != null)
                                      HkStatusBadge.fromStatusText(r.badge!),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(r.subtitle,
                                    style: context.monoStyle
                                        .copyWith(color: colors.accent)),
                                const SizedBox(height: 6),
                                Text(r.meta,
                                    style: context.textStyles.bodySmall),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    ),
  );
  }
}
