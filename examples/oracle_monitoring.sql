
/*

This file contains objects related to Oracle monitoring and should be considered
a work in progress. There are a number of ways to monitor things and I am 
trying to include a wide range of examples below. Grants required for this 
are included in the default arcsql_user.sql file.

*/


-- uninstall: drop package arcsql_oracle_monitoring;
create or replace package arcsql_oracle_monitoring as 
   procedure run;
   procedure autotask_job_monitor;
end;  
/

create or replace package body arcsql_oracle_monitoring as 

procedure add_app_profiles is 
begin 
   arcsql.add_app_test_profile(
      p_profile_name=>'oracle',
      p_test_interval=>15,
      p_retry_interval=>1,
      p_retry_count=>5,
      p_reminder_interval=>60,
      p_reminder_backoff=>2,
      p_abandon_interval=>60*24,
      p_recheck_interval=>5);

end;

procedure run_job_scheduler_tests is 
begin 
   if arcsql.init_app_test('Check all_jobs for broken jobs.') then 
      for r in (select * from all_jobs where broken='Y') loop 
         -- ToDo: Unpack cols in cursor here as json and log.
         arcsql.log_fail('Job '''||r.job||''' from ALL_JOBS is broken and last ran on '||to_char(r.last_date, 'YYYY-MM-DD HH24:MI'));
         arcsql.app_test_fail;
      end loop;
      -- This will automatically call pass if fail was not called.
      arcsql.app_test_done;
   end if;
end;

-- uninstall: delete from arcsql_cache where cache_key='autotask_job_monitor';
procedure autotask_job_monitor is 
   -- ToDo: Add monitoring for jobs running excessively long.
   cursor no_success_autotask_jobs is 
   select cast(job_start_time+job_duration as date) job_end_time,
          client_name,
          job_info,
          job_status
     from dba_autotask_job_history a,
          (select nvl(max(date_value), sysdate) date_value 
             from arcsql_cache where key='autotask_job_monitor') b
    where job_status != 'SUCCEEDED'
      and cast(job_start_time+job_duration as date) >= b.date_value;
begin 
   for j in no_success_autotask_jobs loop
      arcsql.log_fail('Autotask '||j.job_status||': end_time='||to_char(j.job_end_time, 'YYYY-MM-DD HH24:MI')||', client_name='||j.client_name||', job_info='||j.job_info);
   end loop;
   arcsql.cache_date('autotask_job_monitor', sysdate);
end;

procedure check_for_db_changes is 
   s varchar2(2000);
begin 
   
   select listagg(dbid||' '||name, ',') within group (order by dbid||' '||name) into s from gv$database;
   if arcsql.sensor (
      p_key=>'database_list',
      p_input=>s) then 
      arcsql.log_notify(arcsql.g_sensor.sensor_message);
   end if;
   
   select listagg(tablespace_name, ',') within group (order by tablespace_name) 
     into s
     from dba_tablespaces;
   if arcsql.sensor (
      p_key=>'tablespace_list',
      p_input=>s) then 
      arcsql.log_notify(arcsql.g_sensor.sensor_message);
   end if;

end;

procedure run is 
begin 
   add_app_profiles;
   arcsql.set_app_test_profile('oracle');
   run_job_scheduler_tests;
   autotask_job_monitor;
end;

end;
/

-- uninstall: exec dbms_scheduler.drop_job('arcsql_oracle_monitoring_job');
begin
  if not does_scheduler_job_exist('arcsql_oracle_monitoring_job') then 
     dbms_scheduler.create_job (
       job_name        => 'arcsql_oracle_monitoring_job',
       job_type        => 'PLSQL_BLOCK',
       job_action      => 'begin arcsql_oracle_monitoring.run; end;',
       start_date      => systimestamp,
       repeat_interval => 'freq=minutely;interval=5',
       enabled         => true);
   end if;
end;
/
