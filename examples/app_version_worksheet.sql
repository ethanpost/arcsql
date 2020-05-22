
select * from app_version;

exec arcsql.set_app_version('FOO', .1);

select arcsql.get_app_version('FOO') from dual;

exec arcsql.confirm_app_version('FOO');

exec arcsql.set_app_version('BAR', 1.2, p_confirm=>TRUE);

select arcsql.get_app_version('BAR') from dual;

exec arcsql.confirm_app_version('BAR');


-- Start my .sql file...

whenever sqlerror exit failure;

exec arcsql.set_app_version('X', 2.0);

begin 
   if arcsql.get_app_version('X') < 1.1 then
      -- Do something...
   end if;
   if arcsql.get_new_version('X') = 2.0 and arcsql.get_app_version('X') = 1.9 then
      -- Do something...
   end if;
end;
/

exec arcsql.confirm_app_version('X');

