
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
   if not arcsql.does_log_type_exist('alert') then 
      insert into arcsql_log_type (log_type, sends_email) values ('alert', 'Y');
   end if;
end;
/

begin 
   if not arcsql.does_log_type_exist('fail') then 
      insert into arcsql_log_type (log_type, sends_email) values ('fail', 'Y');
   end if;
end;
/

begin 
   if not arcsql.does_log_type_exist('email') then 
      insert into arcsql_log_type (log_type, sends_email) values ('email', 'Y');
   end if;
end;
/

begin 
   if not arcsql.does_log_type_exist('sms') then 
      insert into arcsql_log_type (log_type, sends_email, sends_sms) values ('sms', 'Y', 'Y');
   end if;
end;
/

begin 
   if not arcsql.does_log_type_exist('critical') then 
      insert into arcsql_log_type (log_type, sends_email, sends_sms) values ('critical', 'Y', 'Y');
   end if;
end;
/

begin 
   if not arcsql.does_log_type_exist('warning') then 
      insert into arcsql_log_type (log_type, sends_email, sends_sms) values ('warning', 'Y', 'N');
   end if;
end;
/

begin 
   if not arcsql.does_log_type_exist('high') then 
      insert into arcsql_log_type (log_type, sends_email, sends_sms) values ('high', 'Y', 'N');
   end if;
end;
/

begin 
   if not arcsql.does_log_type_exist('moderate') then 
      insert into arcsql_log_type (log_type, sends_email, sends_sms) values ('moderate', 'Y', 'N');
   end if;
end;
/

begin 
   if not arcsql.does_log_type_exist('info') then 
      insert into arcsql_log_type (log_type, sends_email, sends_sms) values ('info', 'Y', 'N');
   end if;
end;
/

begin 
   if not arcsql.does_log_type_exist('low') then 
      insert into arcsql_log_type (log_type, sends_email, sends_sms) values ('low', 'Y', 'N');
   end if;
end;
/

begin 
   if not arcsql.does_log_type_exist('notice') then 
      insert into arcsql_log_type (log_type, sends_email, sends_sms) values ('notice', 'Y', 'N');
   end if;
end;
/

begin 
   if not arcsql.does_log_type_exist('notify') then 
      insert into arcsql_log_type (log_type, sends_email, sends_sms) values ('notify', 'Y', 'N');
   end if;
end;
/

begin
   if not arcsql.does_alert_priority_exist(1) then 
      insert into arcsql_alert_priority (
         priority_level,
         priority_name,
         alert_log_type,
         enabled,
         reminder_log_type,
         reminder_interval,
         reminder_count,
         reminder_backoff_interval,
         abandon_log_type,
         abandon_interval,
         close_log_type,
         close_interval) values (
         1,
         'critical',
         'critical',
         'Y',
         'high',
         60,
         9999,
         2,
         'critical',
         0,
         'critical',
         0);
      commit;
   end if;
end;
/

begin
   if not arcsql.does_alert_priority_exist(2) then 
      insert into arcsql_alert_priority (
         priority_level,
         priority_name,
         alert_log_type,
         enabled,
         reminder_log_type,
         reminder_interval,
         reminder_count,
         reminder_backoff_interval,
         abandon_log_type,
         abandon_interval,
         close_log_type,
         close_interval) values (
         2,
         'high',
         'high',
         'Y',
         'high',
         60,
         9999,
         2,
         'high',
         0,
         'high',
         0);
      commit;
   end if;
end;
/

begin
   if not arcsql.does_alert_priority_exist(3) then 
      insert into arcsql_alert_priority (
         priority_level,
         priority_name,
         alert_log_type,
         enabled,
         reminder_log_type,
         reminder_interval,
         reminder_count,
         reminder_backoff_interval,
         abandon_log_type,
         abandon_interval,
         close_log_type,
         close_interval) values (
         3,
         'moderate',
         'moderate',
         'Y',
         'moderate',
         60*4,
         9999,
         2,
         'moderate',
         0,
         'moderate',
         0);
      commit;
   end if;
end;
/

        
begin
   if not arcsql.does_alert_priority_exist(4) then 
      insert into arcsql_alert_priority (
         priority_level,
         priority_name,
         alert_log_type,
         enabled,
         reminder_log_type,
         reminder_interval,
         reminder_count,
         reminder_backoff_interval,
         abandon_log_type,
         abandon_interval,
         close_log_type,
         close_interval) values (
         4,
         'low',
         'low',
         'Y',
         'low',
         60*24,
         9999,
         2,
         'low',
         0,
         'low',
         0);
      commit;
   end if;
end;
/

begin
   if not arcsql.does_alert_priority_exist(5) then 
      insert into arcsql_alert_priority (
         priority_level,
         priority_name,
         alert_log_type,
         enabled,
         reminder_log_type,
         reminder_interval,
         reminder_count,
         reminder_backoff_interval,
         abandon_log_type,
         abandon_interval,
         close_log_type,
         close_interval) values (
         5,
         'info',
         'info',
         'Y',
         'info',
         0,
         9999,
         2,
         'info',
         0,
         'info',
         0);
      commit;
   end if;
end;
/

