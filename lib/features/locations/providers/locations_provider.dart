import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/location.dart';

final locationsProvider = FutureProvider<List<LocationModel>>((ref) async {
  final data = await supabase.from('locations').select().order('name');
  return (data as List).map((e) => LocationModel.fromMap(e)).toList();
});

final locationDetailProvider =
    FutureProvider.family<LocationModel?, String>((ref, id) async {
  final data = await supabase
      .from('locations')
      .select()
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return LocationModel.fromMap(data);
});
