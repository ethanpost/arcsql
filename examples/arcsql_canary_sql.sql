
create or replace procedure arcsql_canary_sql as 
   n number;
   t number;
begin
   arcsql.start_timer('arcsql_canary_1');
   select /* arcsql_canary_1 */ count(*) into n from gv$sql;
   t := arcsql.get_timer('arcsql_canary_1');
   arcsql.log(
      log_text=>'arcsql_canary_1 returned '||n||' rows in '||t||' seconds.',
      metric_name_1=>'sql_canary_1_rowcount',
      metric_1=>n,
      metric_name_2=>'sql_canary_1_elap_sec',
      metric_2=>t);
end;
/

begin
  if not does_scheduler_job_exist('arcsql_run_canary_sql') then 
     dbms_scheduler.create_job (
       job_name        => 'arcsql_run_canary_sql',
       job_type        => 'PLSQL_BLOCK',
       job_action      => 'begin arcsql_canary_sql; end;',
       start_date      => systimestamp,
       repeat_interval => 'freq=hourly;interval=1',
       enabled         => true);
   end if;
end;
/
