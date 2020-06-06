create or replace package oracle_app_tests as 
   procedure run_tests;
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
         arcsql.log('Job '''||r.job||''' from ALL_JOBS is broken and last ran on '||to_char(last_date, 'YYYY-MM-DD HH24:MI'));
         arcsql.app_test_fail;
      end loop;
      -- This will automatically call pass if fail was not called.
      arcsql.app_test_done;
   end if;
end;

procedure run_tests is 
begin 
   add_app_profiles;
   run_job_scheduler_tests;
end;

end;
/

