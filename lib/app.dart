import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/hk_state_views.dart';
import 'features/academy/presentation/academy_screen.dart';
import 'features/academy/presentation/placement_detail_screen.dart';
import 'features/academy/presentation/training_participants_screen.dart';
import 'features/app_update/presentation/app_update_controller.dart';
import 'features/app_update/presentation/widgets/app_update_dialog.dart';
import 'features/auth/domain/admin_session.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/interview/presentation/interview_participants_screen.dart';
import 'features/interview/presentation/interview_screen.dart';
import 'features/management/presentation/create_admin_screen.dart';
import 'features/management/presentation/create_interview_screen.dart';
import 'features/management/presentation/create_placement_screen.dart';
import 'features/management/presentation/create_training_screen.dart';
import 'features/management/presentation/create_vacancy_screen.dart';
import 'features/organization/presentation/organization_screen.dart';
import 'features/recruitment/presentation/recruitment_screen.dart';
import 'features/recruitment/presentation/vacancy_applicants_screen.dart';
import 'features/scanner/presentation/qr_scanner_screen.dart';

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen<AsyncValue<AdminSession?>>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading && !auth.hasValue) return '/splash';
      final loggedIn = auth.valueOrNull != null;
      final atLogin = state.matchedLocation == '/login';
      final atSplash = state.matchedLocation == '/splash';
      if (!loggedIn) return atLogin ? null : '/login';
      if (atLogin || atSplash) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) =>
            const Scaffold(body: HkLoadingView(message: AppStrings.signingInMessage)),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (_, _) => const _Shell(tab: 0, child: DashboardScreen()),
      ),
      GoRoute(
        path: '/recruitment',
        builder: (_, _) => const _Shell(tab: 1, child: RecruitmentScreen()),
      ),
      GoRoute(
        path: '/interview',
        builder: (_, _) => const _Shell(tab: 2, child: InterviewScreen()),
      ),
      GoRoute(
        path: '/academy',
        builder: (_, _) => const _Shell(tab: 3, child: AcademyScreen()),
      ),
      GoRoute(
        path: '/organization',
        builder: (_, _) => const _Shell(tab: 4, child: OrganizationScreen()),
      ),
      GoRoute(
        path: '/scanner',
        builder: (_, _) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/management/create-admin',
        builder: (_, _) => const CreateAdminScreen(),
      ),
      GoRoute(
        path: '/management/create-interview',
        builder: (_, _) => const CreateInterviewScreen(),
      ),
      GoRoute(
        path: '/management/create-training',
        builder: (_, _) => const CreateTrainingScreen(),
      ),
      GoRoute(
        path: '/management/create-vacancy',
        builder: (_, _) => const CreateVacancyScreen(),
      ),
      GoRoute(
        path: '/management/create-placement',
        builder: (_, _) => const CreatePlacementScreen(),
      ),
      GoRoute(
        path: '/recruitment/applicants/:id',
        builder: (_, state) => VacancyApplicantsScreen(
          vacancyId: state.pathParameters['id']!,
          vacancyCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/interview/participants/:id',
        builder: (_, state) => InterviewParticipantsScreen(
          interviewId: state.pathParameters['id']!,
          interviewCode: state.uri.queryParameters['code'],
          vacancyCode: state.uri.queryParameters['vacancy'],
        ),
      ),
      GoRoute(
        path: '/training/participants/:id',
        builder: (_, state) => TrainingParticipantsScreen(
          trainingId: state.pathParameters['id']!,
          trainingCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/academy/placement-detail/:id',
        builder: (_, state) => PlacementDetailScreen(
          placementId: state.pathParameters['id']!,
          placementCode: state.uri.queryParameters['code'],
        ),
      ),
    ],
  );
});

class _Shell extends ConsumerStatefulWidget {
  const _Shell({required this.tab, required this.child});

  final int tab;
  final Widget child;

  static const List<String> _paths = <String>[
    '/dashboard',
    '/recruitment',
    '/interview',
    '/academy',
    '/organization',
  ];

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUpdateControllerProvider.notifier).checkForUpdates();
    });
  }

  Future<void> _manualCheckUpdate() async {
    final info = await ref
        .read(appUpdateControllerProvider.notifier)
        .checkForUpdates(isManual: true);
    if (!mounted) return;
    if (info != null) {
      if (info.hasUpdate) {
        await AppUpdateDialog.show(context, info);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aplikasi sudah versi terbaru (v${info.currentVersion})',
            ),
          ),
        );
      }
    } else {
      final err = ref.read(appUpdateControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Gagal memeriksa pembaruan aplikasi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppUpdateState>(appUpdateControllerProvider, (prev, next) {
      final info = next.info;
      if (info != null && info.hasUpdate && !next.hasDismissed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppUpdateDialog.show(context, info);
          }
        });
      }
    });

    final session = ref.watch(authControllerProvider).valueOrNull;
    final updateState = ref.watch(appUpdateControllerProvider);
    final hasUpdate = updateState.info?.hasUpdate == true;

    final isAdmin = session?.role == AdminRole.superAdmin ||
        session?.role == AdminRole.supervisor;

    final canScanQr = session?.role == AdminRole.interviewer ||
        session?.role == AdminRole.trainer;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: HkStatusBadge(
                label: session?.role.label ?? '',
                tone: HkBadgeTone.accent,
              ),
            ),
          ),
          if (hasUpdate)
            IconButton(
              tooltip:
                  'Pembaruan v${updateState.info!.latestVersion} Tersedia',
              onPressed: () =>
                  AppUpdateDialog.show(context, updateState.info!),
              icon: const Badge(
                smallSize: 8,
                child: Icon(
                  Icons.system_update_rounded,
                  color: Color(0xFFD85B1C),
                ),
              ),
            ),
          PopupMenuButton<String>(
            tooltip: 'Opsi Lainnya',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'update') {
                _manualCheckUpdate();
              } else if (val == 'logout') {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'update',
                child: Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 20,
                      color: hasUpdate
                          ? const Color(0xFFD85B1C)
                          : context.colors.textPrimary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      hasUpdate
                          ? 'Perbarui Aplikasi (v${updateState.info!.latestVersion})'
                          : 'Cek Pembaruan',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(AppStrings.logoutLabel),
                  ],
                ),
              ),
            ],
          ),
          if (canScanQr)
            IconButton(
              tooltip: 'Pindai QR Kehadiran',
              onPressed: () => context.push('/scanner'),
              icon: const Icon(Icons.qr_code_scanner_rounded),
            ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.tab,
        onDestinationSelected: (i) => context.go(_Shell._paths[i]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: AppStrings.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.badge_outlined),
            selectedIcon: const Icon(Icons.badge_rounded),
            label: AppStrings.navRecruitment,
            enabled: isAdmin,
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note_rounded),
            label: AppStrings.navInterview,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school_rounded),
            label: AppStrings.navAcademy,
            enabled: isAdmin,
          ),
          NavigationDestination(
            icon: const Icon(Icons.apartment_outlined),
            selectedIcon: const Icon(Icons.apartment_rounded),
            label: AppStrings.navMaster,
            enabled: isAdmin,
          ),
        ],
      ),
    );
  }
}

class HkJobsApp extends ConsumerWidget {
  const HkJobsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLightTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
