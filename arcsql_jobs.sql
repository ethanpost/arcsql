
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
