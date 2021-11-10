

/*
This package contains user config and should not be over-written if it exists.
*/

-- uninstall: drop package arcsql_user_setting;
begin
   if not does_package_exist(package_name=>'arcsql_user_setting') then
      execute immediate '
      create or replace package arcsql_user_setting as 
         x varchar2(120) := ''foo'';
      end;
      ';
   end if;
end;
/

