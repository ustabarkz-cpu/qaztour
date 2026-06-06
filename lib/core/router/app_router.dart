import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/role_select_screen.dart';
import '../../features/bookings/screens/booking_create_screen.dart';
import '../../features/bookings/screens/my_bookings_screen.dart';
import '../../features/tours/screens/guide_list_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/guide_mode/screens/guide_bookings_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/locations/screens/location_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/tours/screens/tour_detail_screen.dart';
import '../theme/app_colors.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

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
      if (hasRole && loc == '/role-select') return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectScreen()),

      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

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
      GoRoute(
        path: '/guides/:locationId',
        builder: (_, state) => GuideListScreen(
          locationId: state.pathParameters['locationId']!,
          locationName: state.uri.queryParameters['name'] ?? '',
        ),
      ),
      GoRoute(
        path: '/guide/bookings',
        builder: (_, __) => const GuideBookingsScreen(),
      ),
    ],
  );

  // Обновляем роутер при смене auth/profile, не пересоздавая его
  ref.listen(authStateProvider, (_, __) => router.refresh());
  ref.listen(profileProvider, (_, __) => router.refresh());

  return router;
});

// Связывает router.refresh() с ChangeNotifier для refreshListenable
class _RouterRefreshStream extends ChangeNotifier {
  _RouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(profileProvider, (_, __) => notifyListeners());
  }
}

class _AppShell extends ConsumerWidget {
  final Widget child;
  const _AppShell({required this.child});

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
