
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

begin
  if not does_scheduler_job_exist('arcsql_run_sql_log_update') then 
     dbms_scheduler.create_job (
       job_name        => 'arcsql_run_sql_log_update',
       job_type        => 'PLSQL_BLOCK',
       job_action      => 'begin arcsql.run_sql_log_update; end;',
       start_date      => systimestamp,
       repeat_interval => 'freq=minutely;interval=5',
       enabled         => true);
   end if;
end;
/


begin 
   if not arcsql.does_keyword_exist('alert') then 
      insert into arcsql_keyword (keyword, sends_email) values ('alert', 'Y');
   end if;
end;
/

begin 
   if not arcsql.does_keyword_exist('fail') then 
      insert into arcsql_keyword (keyword, sends_email) values ('fail', 'Y');
   end if;
end;
/

begin 
   if not arcsql.does_keyword_exist('email') then 
      insert into arcsql_keyword (keyword, sends_email) values ('email', 'Y');
   end if;
end;
/

begin 
   if not arcsql.does_keyword_exist('sms') then 
      insert into arcsql_keyword (keyword, sends_email, sends_sms) values ('sms', 'Y', 'Y');
   end if;
end;
/

begin 
   if not arcsql.does_keyword_exist('critical') then 
      insert into arcsql_keyword (keyword, sends_email, sends_sms) values ('critical', 'Y', 'Y');
   end if;
end;
/

begin 
   if not arcsql.does_keyword_exist('warning') then 
      insert into arcsql_keyword (keyword, sends_email, sends_sms) values ('warning', 'Y', 'N');
   end if;
end;
/

begin 
   if not arcsql.does_keyword_exist('info') then 
      insert into arcsql_keyword (keyword, sends_email, sends_sms) values ('info', 'Y', 'N');
   end if;
end;
/

begin 
   if not arcsql.does_keyword_exist('notice') then 
      insert into arcsql_keyword (keyword, sends_email, sends_sms) values ('notice', 'Y', 'N');
   end if;
end;
/


begin 
   if not arcsql.does_keyword_exist('notify') then 
      insert into arcsql_keyword (keyword, sends_email, sends_sms) values ('notify', 'Y', 'N');
   end if;
end;
/

