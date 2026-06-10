import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/role_select_screen.dart';
import '../../features/bookings/screens/booking_create_screen.dart';
import '../../features/bookings/screens/my_bookings_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/guide_mode/screens/guide_bookings_screen.dart';
import '../../features/guide_mode/screens/guide_tours_screen.dart';
import '../../features/guide_mode/screens/guide_profile_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/locations/screens/location_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/tours/screens/tour_detail_screen.dart';
import '../theme/app_colors.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _touristShellKey = GlobalKey<NavigatorState>();
final _guideShellKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: _RouterRefreshStream(ref),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final profile = ref.read(profileProvider);

      final isLoggedIn = authState.valueOrNull?.session != null;
      final loc = state.matchedLocation;

      if (!isLoggedIn) return loc == '/login' ? null : '/login';
      if (loc == '/login') return '/home';

      final profileData = profile.valueOrNull;
      final hasRole = profileData != null && profileData['role'] != null;

      if (!hasRole && loc != '/role-select') return '/role-select';

      final role = profileData?['role'] as String?;

      if (hasRole && loc == '/role-select') {
        return role == 'guide' ? '/guide/requests' : '/home';
      }

      // Гид не должен попасть на tourist-только маршруты
      if (role == 'guide' && (loc == '/home' || loc == '/favorites')) {
        return '/guide/requests';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectScreen()),

      // ─── Турист Shell ───────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _touristShellKey,
        builder: (context, state, child) => _TouristShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ─── Гид Shell ──────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _guideShellKey,
        builder: (context, state, child) => _GuideShell(child: child),
        routes: [
          GoRoute(path: '/guide/requests', builder: (_, __) => const GuideBookingsScreen()),
          GoRoute(path: '/guide/tours', builder: (_, __) => const GuideToursScreen()),
          GoRoute(path: '/guide/profile', builder: (_, __) => const GuideProfileScreen()),
        ],
      ),

      // ─── Общие маршруты ─────────────────────────────────────────────
      GoRoute(
        path: '/location/:id',
        builder: (_, state) =>
            LocationDetailScreen(locationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tour/:id',
        builder: (_, state) =>
            TourDetailScreen(tourId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/:tourId',
        builder: (_, state) =>
            BookingCreateScreen(tourId: state.pathParameters['tourId']!),
      ),
      GoRoute(
        path: '/my-bookings',
        builder: (_, __) => const MyBookingsScreen(),
      ),
    ],
  );

  ref.listen(authStateProvider, (_, __) => router.refresh());
  ref.listen(profileProvider, (_, __) => router.refresh());

  return router;
});

class _RouterRefreshStream extends ChangeNotifier {
  _RouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(profileProvider, (_, __) => notifyListeners());
  }
}

// ─── Tourist Shell ────────────────────────────────────────────────────────────

class _TouristShell extends ConsumerWidget {
  final Widget child;
  const _TouristShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final index = loc == '/favorites' ? 1 : loc == '/profile' ? 2 : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        onDestinationSelected: (i) {
          if (i == 0) context.go('/home');
          if (i == 1) context.go('/favorites');
          if (i == 2) context.go('/profile');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppColors.primary),
            label: 'Туры',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite, color: AppColors.primary),
            label: 'Избранное',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

// ─── Guide Shell ──────────────────────────────────────────────────────────────

class _GuideShell extends ConsumerWidget {
  final Widget child;
  const _GuideShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final index = loc == '/guide/tours' ? 1 : loc == '/guide/profile' ? 2 : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        onDestinationSelected: (i) {
          if (i == 0) context.go('/guide/requests');
          if (i == 1) context.go('/guide/tours');
          if (i == 2) context.go('/guide/profile');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox, color: AppColors.primary),
            label: 'Заявки',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.primary),
            label: 'Мои туры',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
