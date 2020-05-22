
/* SQL LOG CONFIG */
exec arcsql.add_config('sql_log_analyze_min_secs', '1', 'Only SQL statements exceeded X seconds of elapsed time per hour will be analyzed.');
-- Do not set this to 'Y' unless you have a license option that allows you to access the active session history tables!
exec arcsql.add_config('sql_log_ash_is_licensed', 'N', 'Enables extra features if you have Tuning/Diagnostics license.');
exec arcsql.add_config('sql_log_sql_text_length', '60', 'The number of characters to capture of actual SQL statement text. Max 100.');

/* ARCSQL VERSION */
exec arcsql.add_config('arcsql_version', '0.0', 'ArcSQL Version - Do not edit this value manually.');

/* EVENTS */
exec arcsql.add_config('purge_event_hours', '4', 'ArcSQL purges data from session_event table older than X hours.');

exec arcsql.set_config('arcsql_version', '0.11');

