



create or replace procedure arcsql_canary_sql as 
   n number;
begin
   select /* arcsql_canary_1 */ count(*) into n from gv$sql;
   -- ToDo: Track as stats when that feature is developed.
   -- ToDo: Add elapsed time to log entry.
   arcsql.log('arcsql_canary_1.rowcount: '||n);
end;
/

begin
  if not does_scheduler_job_exist('arcsql_canary_sql') then 
     dbms_scheduler.create_job (
       job_name        => 'arcsql_canary_sql',
       job_type        => 'PLSQL_BLOCK',
       job_action      => 'begin arcsql_canary_sql; end;',
       start_date      => systimestamp,
       repeat_interval => 'freq=hourly;interval=1',
       enabled         => true);
   end if;
end;
/
