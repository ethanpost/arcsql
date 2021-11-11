-- uninstall: drop package arcsql_default_setting;
create or replace package arcsql_default_setting as 
   
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

   -- Used with the is_dev function to determine if the current env is dev or not.
   env varchar2(3) := 'dev';

   -- ==== Optional Library Configuration Values ====

   -- The following sections are for optional libraries that may or may not
   -- be installed. If they are you should set these values in your private 
   -- arcsql_instance package header.

   -- SAAS AUTH
   -- This address needs to be one of the approved senders if using APEX email.
   saas_auth_from_address varchar2(120) := 'Set this to the from address when sending emails.';
   -- Salt is added to user's pass to create the final encrypted hash.
   saas_auth_salt varchar2(120) := 'Set this to a random sentence.';

   -- SENDGRID 
   -- Your SendGrid API key.
   sendgrid_api_key varchar2(120) := '';
   -- "from address" to use. Use the domain you set up with SendGrid.
   sendgrid_from_address varchar2(120) := '';

end;
/
