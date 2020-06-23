-- uninstall: drop package arcsql_public_settings;
create or replace package arcsql_public_settings as 
   
   -- List ',' of emails is allowable.
   arcsql_admin_email varchar2(120) := 'post.ethan@gmail.com';

   -- ArcSQL purges data from audsid_event table older than X hours.
   purge_event_hours number := 4;

   -- SQL monitoring
   -- The number of characters to capture of actual SQL statement text. Max 100.
   sql_log_sql_text_length number := 60;
   -- Enables extra features if you have Tuning/Diagnostics license.
   sql_log_ash_is_licensed varchar2(1) := 'N';
   -- Only SQL statements exceeded X seconds of elapsed time per hour will be analyzed.
   sql_log_analyze_min_secs number := 1;

   -- Your secret SendGrid API key for sending email.
   sendgrid_api_key varchar2(120) := '';
   sendgrid_from_address varchar2(120) := '';
end;
/
