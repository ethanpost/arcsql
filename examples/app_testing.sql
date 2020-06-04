

declare 
   n number;
begin 
   -- Setup
   delete from app_test where test_name='bar';
   delete from app_test_profile where profile_name='foo';
   -- 
   arcsql.init_test('App test profile does not exist.');
   select 1 into n from app_test_profile where profile_name='foo' having count(*)=0;
   arcsql.pass_test;
   
   -- 
   arcsql.init_test('App test profile exists.');
   arcsql.add_app_test_profile(
      p_profile_name=>'foo',
      p_env_type=>'test');
   arcsql.g_app_test_profile.test_interval := 0;
   arcsql.save_app_test_profile;
   select 1 into n from app_test_profile where profile_name='foo';
   arcsql.pass_test;
   
   --
   arcsql.init_test('Test does not exist.');
   select 1 into n from app_test where test_name='bar' having count(*)=0;
   arcsql.pass_test;
   
   --
   arcsql.init_test('Init test raises error if profile not set.');
   arcsql.g_app_test_profile := null;
   begin 
      if arcsql.init_app_test(p_test_name=>'bar') then
         arcsql.fail_test;
      end if;
   exception 
      when others then 
         arcsql.pass_test;
   end;
   
   --
   arcsql.init_test('Create a simple test.');
   arcsql.set_app_test_profile(p_profile_name=>'foo', p_env_type=>'test');
   delete from app_test where test_name='bar';
   commit;
   if arcsql.init_app_test(p_test_name=>'bar') then
      arcsql.pass_test;
   else 
      arcsql.fail_test;
   end if;
   
   --
   arcsql.init_test('App test expected to fail.');
   if arcsql.init_app_test(p_test_name=>'bar') then
      arcsql.app_test_fail;
   end if;
   arcsql.assert := arcsql.g_app_test.test_status = 'FAIL';
   arcsql.test;
   
   --
   arcsql.init_test('App test expected to pass.');
   if arcsql.init_app_test(p_test_name=>'bar') then
      arcsql.app_test_pass;
   end if;
   arcsql.assert := arcsql.g_app_test.test_status = 'PASS';
   arcsql.test;

exception
   when others then
      arcsql.fail_test;
end;
/


