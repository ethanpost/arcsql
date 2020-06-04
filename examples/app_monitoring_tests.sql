create or replace package oracle_hr_testing is 
   procedure add_profiles;
   procedure check_tests;
end;
/

create or replace package body oracle_hr_testing

procedure add_profiles is
begin 
   arcsql.add_test_profile (
      profile_name=>'oracle_hr',
      env_type=>'any',
      test_interval=>15,
      retry_count=>0,
      retry_interval=>0,
      retry_keyword=>'warning',
      failed_keyword=>'warning',
      reminder_interval=>3*60,
      reminder_keyword=>'warning',
      -- Changes reminder interval for each occurance by some number or %.
      reminder_interval_change=>'0',
      abandon_interval=>60*24,
      abandon_keyword=>'abandoned',
      abandon_reset=>'N',
      pass_keyword=>'passing'
      );
end;

procedure check_tests is 
   n number;
begin 
   arcsql.set_test_profile(p_profile_name=>'oracle_hr', p_env_type=>'any');

   if arcsql.app_test('oracle_hr_batch_account_exists') then 
      select count(*) into n from all_users where user_name='BATCH';
      if n = 0 then 
         arcsql.app_fail('Expected BATCH account. Found none.');
      else 
         -- This is required if the current state is in "fail" and you want to reset to "pass".
         arcsql.app_pass;
      end if;
   end if;

end;

end;
/





