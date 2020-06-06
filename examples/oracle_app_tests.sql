



begin 
   arcsql.add_app_test_profile(
      p_profile_name=>'oracle',
      p_test_interval=>15,
      p_retry_interval=>1,
      p_retry_count=>5,
      p_reminder_interval=>60,
      p_reminder_interval_change=>'200%',
      p_abandon_interval=>60*24,
      p_recheck_interval=>5);
end;
/

begin 
   if arcsql.init_app_test('No broken jobs.') then 
      for r in (select * from all_jobs where broken='Y') loop 
         -- ToDo: Unpack cols in cursor here as json and log.
         arcsql.app_test_fail('');
      end loop;
      arcsql.app_test_done;
   end if;
end;
/
