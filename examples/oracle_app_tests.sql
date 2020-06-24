
-- uninstall: drop view v_monitor_autotask_hist;
-- uninstall: delete from arcsql_cache where cache_key='monitor_autotask_job_history';
create or replace view v_monitor_autotask_job_history as 
   select cast(job_start_time+job_duration as date) job_end_time,
          client_name,
          job_info,
          job_status
     from dba_autotask_job_history a,
          (select date_value from arcsql_cache where key='monitor_autotask_job_history') b
    where job_status != 'SUCCEEDED'
      and cast(job_start_time+job_duration as date) >= b.date_value;

create or replace package oracle_app_tests as 
   procedure run_tests;
   procedure monitor_autotask_job_history;
end;  
/

create or replace package body oracle_app_tests as 

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
   if arcsql.init_app_test('Check ALL_JOBS for broken jobs.') then 
      for r in (select * from all_jobs where broken='Y') loop 
         -- ToDo: Unpack cols in cursor here as json and log.
         arcsql.log('Job '''||r.job||''' from ALL_JOBS is broken and last ran on '||to_char(r.last_date, 'YYYY-MM-DD HH24:MI'));
         arcsql.app_test_fail;
      end loop;
      -- This will automatically call pass if fail was not called.
      arcsql.app_test_done;
   end if;
end;

procedure monitor_autotask_job_history is 
begin 
   if not arcsql.does_cache_key_exist('monitor_autotask_job_history') then 
      arcsql.cache_date('monitor_autotask_job_history', sysdate);
   end if; 
   for job in (select * from v_monitor_autotask_job_history) loop
      arcsql.fail('Autotask '||job.job_status||': end_time'||to_char(job.job_end_time, 'YYYY-MM-DD HH24:MI')||', client_name='||job.client_name||', job_info='||job.job_info);
   end loop;
end;

procedure check_for_db_changes is 
   s varchar2(2000);
begin 
   
   select listagg(dbid||' '||name, ',') within group (order by dbid||' '||name) into s from gv$database;
   if arcsql.sensor (
      p_key=>'database_list',
      p_input=>s) then 
      arcsql.notify(arcsql.g_sensor.sensor_message);
   end if;
   
   select listagg(tablespace_name, ',') within group (order by tablespace_name) 
     into s
     from dba_tablespaces;
   if arcsql.sensor (
      p_key=>'tablespace_list',
      p_input=>s) then 
      arcsql.notify(arcsql.g_sensor.sensor_message);
   end if;

end;

procedure run_tests is 
begin 
   add_app_profiles;
   run_job_scheduler_tests;
   monitor_autotask_job_history;
end;

end;
/

