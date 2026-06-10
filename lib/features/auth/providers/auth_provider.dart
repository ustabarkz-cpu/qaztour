import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return supabase.auth.currentUser;
});

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
  return data;
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      const clientId =
          '451259000015-i9q7b65vej18q1i0tj5u22nkjt1ggcug.apps.googleusercontent.com';
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? clientId : null,
        serverClientId: kIsWeb ? null : clientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Отменено');

      final googleAuth = await googleUser.authentication;
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      final user = supabase.auth.currentUser!;
      // Создаём профиль без роли — роль выберет сам пользователь
      await supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': user.userMetadata?['full_name'],
        'avatar_url': user.userMetadata?['avatar_url'],
      }, onConflict: 'id');
    });
  }

  Future<void> setRole(String role) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('profiles').update({'role': role}).eq('id', user.id);
    if (role == 'guide') {
      await supabase.from('guides').upsert({
        'user_id': user.id,
        'name': user.userMetadata?['full_name'] ?? 'Гид',
        'photo_url': user.userMetadata?['avatar_url'],
        'rating': 0.0,
        'reviews_count': 0,
        'experience_years': 0,
        'languages': ['Казахский', 'Русский'],
      }, onConflict: 'user_id');
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await supabase.auth.signOut();
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
