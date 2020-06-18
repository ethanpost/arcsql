


create or replace procedure test_arcsql_alerting as 
begin 
   arcsql.init_app_test('Create an alert.');
   arcsql.open_alert (
      p_alert_id=>'test_alert',
      -- Supports levels 1-5 (critical, high, moderate, low, informational).
      p_level=>1,
      p_keyword=>'critical',
      p_

end;
/


exec test_arcsql_alerting;

drop procedure test_arcsql_alerting;

