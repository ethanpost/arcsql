
-- uninstall: exec dbms_scheduler.drop_job('arcsql_run_sql_log_update');
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

-- uninstall: exec dbms_scheduler.drop_job('arcsql_check_alerts');
begin
  if not does_scheduler_job_exist('arcsql_check_alerts') then 
     dbms_scheduler.create_job (
       job_name        => 'arcsql_check_alerts',
       job_type        => 'PLSQL_BLOCK',
       job_action      => 'begin arcsql.check_alerts; end;',
       start_date      => systimestamp,
       repeat_interval => 'freq=minutely;interval=1',
       enabled         => true);
   end if;
end;
/

-- uninstall: exec dbms_scheduler.drop_job('arcsql_check_contact_groups');
begin
  if not does_scheduler_job_exist('arcsql_check_contact_groups') then 
     dbms_scheduler.create_job (
       job_name        => 'arcsql_check_contact_groups',
       job_type        => 'PLSQL_BLOCK',
       job_action      => 'begin arcsql.check_contact_groups; end;',
       start_date      => systimestamp,
       repeat_interval => 'freq=minutely;interval=1',
       enabled         => true);
   end if;
end;
/

