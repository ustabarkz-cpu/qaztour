import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://qiwlhmzwbxkldoggxggb.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFpd2xobXp3YnhrbGRvZ2d4Z2diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA1ODMzMjEsImV4cCI6MjA5NjE1OTMyMX0.4JKGFNcsm-AsD56YIxv3JmD7AxXNf69-Sn1vV2FtcmI';

SupabaseClient get supabase => Supabase.instance.client;
