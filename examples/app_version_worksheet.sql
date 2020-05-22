
select * from app_version;

exec arcsql.set_app_version('FOO', .1);

select arcsql.get_app_version('FOO') from dual;

exec arcsql.confirm_app_version('FOO');

exec arcsql.set_app_version('BAR', 1.2, p_confirm=>TRUE);

select arcsql.get_app_version('BAR') from dual;

exec arcsql.confirm_app_version('BAR');