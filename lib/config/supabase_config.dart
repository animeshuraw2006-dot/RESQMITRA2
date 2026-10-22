const String defaultSupabaseUrl = 'https://tgyitcorasmzwnjganmj.supabase.co';
const String defaultSupabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRneWl0Y29yYXNtenduamdhbm1qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIxMzEwMDEsImV4cCI6MjEwNzcwNzAwMX0.5PlCexQl-lA6nxpr81kUmbxukjZzxSMs4Ug_acjeiyA';

const String supabaseUrl =
    String.fromEnvironment('SUPABASE_URL', defaultValue: defaultSupabaseUrl);
const String supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY',
    defaultValue: defaultSupabaseKey);
