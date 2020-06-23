

-- Drop our private package to start things off.
exec drop_package('arcsql_private_settings');

-- Should return the value from arcsql_public_settings PL/SQL package header.
select arcsql.get_setting('arcsql_admin_email') from dual;

-- Now create a arcsql_private_settings PL/SQL package header.
create or replace package arcsql_private_settings is 
   arcsql_admin_email varchar2(120) := '...@gmail.com';
end;
/

-- Should return the new value. Private settings over-ride public.
select arcsql.get_setting('arcsql_admin_email') from dual;

-- Add a configuration item to the arcsql_config table using the same setting name.
exec arcsql.add_config('arcsql_admin_email', '---@gmail.com', 'List "," admin emails.');

-- Value from table is returned. This over-rides all package header values.
select arcsql.get_setting('arcsql_admin_email') from dual;

-- Remove the value from the table.
exec arcsql.remove_config('arcsql_admin_email');

-- We should once again get the private value from the package header.
select arcsql.get_setting('arcsql_admin_email') from dual;

-- Drop the package.
exec drop_package('arcsql_private_settings');

-- We should get the public value.
select arcsql.get_setting('arcsql_admin_email') from dual;



