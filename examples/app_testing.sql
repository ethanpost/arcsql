
declare
   n number;
begin 
   --
   arcsql.init_test('Use default profile when defined.');
   
   delete from app_test_profile where profile_name in ('foo', 'bar', 'default');
   commit;

   -- Our default profile.
   arcsql.add_app_test_profile(
      p_profile_name=>'foo',
      p_is_default=>'Y',
      p_test_interval=>1);

   -- Not a default profile.
   arcsql.add_app_test_profile(
      p_profile_name=>'bar',
      p_test_interval=>2);

   arcsql.g_app_test_profile := null;

   if arcsql.init_app_test('x') then 
      if arcsql.g_app_test_profile.test_interval = 1 then 
         arcsql.pass_test;
      else 
         arcsql.fail_test;
      end if;
   else 
      arcsql.fail_test;
   end if;
   
   --
   arcsql.init_test('Use non default profile if defined.');
   arcsql.set_app_test_profile(p_profile_name=>'bar');
   if arcsql.g_app_test_profile.test_interval = 2 then 
      arcsql.pass_test;
   else 
      arcsql.fail_test;
   end if;

   -- 
   arcsql.init_test('Using profile with env type that does not exist raises exception.');
   begin 
      arcsql.set_app_test_profile(p_profile_name=>'foo', p_env_type=>'test');
      arcsql.fail_test;
   exception 
      when others then 
         arcsql.pass_test;
   end;

   --
   arcsql.init_test('Change default profile works.');
   arcsql.set_app_test_profile('bar');
   arcsql.g_app_test_profile.is_default := 'Y';
   arcsql.save_app_test_profile;
   arcsql.g_app_test_profile := null;
   if arcsql.init_app_test('x') then 
      if arcsql.g_app_test_profile.test_interval = 2 then 
         arcsql.pass_test;
      else 
         arcsql.fail_test;
      end if;
   else 
      arcsql.fail_test;
   end if;

   --
   arcsql.init_test('Add a duplicate profile with an env type.');
   arcsql.add_app_test_profile (
      p_profile_name=>'bar',
      p_env_type=>'test',
      p_test_interval=>3);
   arcsql.pass_test;

   -- 
   arcsql.init_test('Add a new default profile for test env type.');
   arcsql.add_app_test_profile (
      p_profile_name=>'default',
      p_env_type=>'test',
      p_is_default=>'Y');
   arcsql.g_app_test_profile.test_interval := 4;
   arcsql.save_app_test_profile;
   select count(*) into n from app_test_profile where is_default='Y' and env_type='test' having count(*)=1;
   arcsql.pass_test;

   -- 
    arcsql.init_test('Add a new default profile for null env type.');
    arcsql.add_app_test_profile (
       p_profile_name=>'default',
       p_env_type=>null,
       p_is_default=>'Y');
    arcsql.g_app_test_profile.test_interval := 5;
    arcsql.save_app_test_profile;
    arcsql.pass_test;

    --
    arcsql.init_test('** Success** ');
    arcsql.pass_test;

exception 
   when others then 
      arcsql.fail_test;
end;
/

-- declare 
--    n number;
-- begin 
--    -- Setup
--    delete from app_test where test_name='bar';
--    delete from app_test_profile where profile_name='foo';
   
--    -- 
--    arcsql.init_test('Add a new app profile.');
--    -- This will not throw error if the app profile already exists.
--    arcsql.add_app_test_profile(p_profile_name=>'foo');
--    arcsql.g_app_test_profile.test_interval := 0;
--    arcsql.save_app_test_profile;
--    select 1 into n from app_test_profile where profile_name='foo' and env_type is null;
--    arcsql.pass_test;
   
--    --
--    arcsql.init_test('Test does not exist.');
--    select 1 into n from app_test where test_name='bar' having count(*)=0;
--    arcsql.pass_test;
   
--    --
--    arcsql.init_test('Init test raises error if profile not set.');
--    arcsql.g_app_test_profile := null;
--    begin 
--       if arcsql.init_app_test(p_test_name=>'bar') then
--          arcsql.fail_test;
--       end if;
--    exception 
--       when others then 
--          arcsql.pass_test;
--    end;
   
--    -- 
--    arcsql.init_test('Set profile to foo even when env_type not found.');
--    arcsql.set_app_test_profile(p_profile_name=>'foo', p_env_type=>'x');

--    --
--    arcsql.init_test('Create a simple test.');
--    arcsql.set_app_test_profile(p_profile_name=>'foo');
--    if arcsql.init_app_test(p_test_name=>'bar') then
--       arcsql.pass_test;
--    else 
--       arcsql.fail_test;
--    end if;
   
--    --
--    arcsql.init_test('App test expected to fail.');
--    if arcsql.init_app_test(p_test_name=>'bar') then
--       arcsql.app_test_fail;
--    end if;
--    arcsql.assert := arcsql.g_app_test.test_status = 'FAIL';
--    arcsql.test;
   
--    --
--    arcsql.init_test('App test expected to pass.');
--    if arcsql.init_app_test(p_test_name=>'bar') then
--       arcsql.app_test_pass;
--    end if;
--    arcsql.assert := arcsql.g_app_test.test_status = 'PASS';
--    arcsql.test;

--    --
--    arcsql.init_test('App test expected to retry twice, then fail.');
--    arcsql.g_app_test_profile.retry_count := 2;
   
--    if arcsql.init_app_test(p_test_name=>'bar') then 
--       arcsql.g_app_test.test_status := 'PASS';
--       arcsql.app_test_fail;
--       arcsql.app_test_fail;
--       if arcsql.g_app_test.test_status != 'RETRY' then 
--          arcsql.fail_test;
--       end if;
--       arcsql.app_test_fail;
--       if arcsql.g_app_test.test_status != 'FAIL' then 
--          arcsql.fail_test;
--       end if;
--    end if;
--    arcsql.pass_test;

--    --
--    arcsql.init_test('App test expected to pass again.');
--    if arcsql.init_app_test(p_test_name=>'bar') then
--       arcsql.app_test_pass;
--    end if;
--    arcsql.assert := arcsql.g_app_test.test_status = 'PASS';
--    arcsql.test;

-- exception
--    when others then
--       arcsql.fail_test;
-- end;
-- /


