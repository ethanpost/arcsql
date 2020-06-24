
-- Set up for the example.
delete from arcsql_log;
delete from arcsql_sensor where sensor_key='user_table_count_test';
commit;
exec drop_table('sensor_test');

-- Sensor data is store in the ARCSQL_SENSOR table.
select * from arcsql_sensor;

-- Each unique sensor is identified by the SENSOR_KEY.

-- Let's create a new sensor in a procedure and call it.
create or replace procedure sensor_example as
   n number;
begin 
   select count(*) into n from user_tables;
   if arcsql.sensor(
      p_key=>'user_table_count_test',
      p_input=>to_char(n)) then
      arcsql.debug('The number of tables has changed from '||arcsql.g_sensor.old_value||' to '||arcsql.g_sensor.new_value||'.');
   end if;
end;
/

exec sensor_example;

-- You can see the new sensor here.
select * from arcsql_sensor;

-- Run the sensor again and nothing should happen because the # of tables is the same.
exec sensor_example;

-- You shouldn't see any new sensor log entries here.
select * from arcsql_log order by 1 desc;

-- Create a table.
create table sensor_test (x number);

exec sensor_example;

select * from arcsql_log order by 1 desc;

-- Run it one more time and nothing should happen.
exec sensor_example;

select * from arcsql_log order by 1 desc;

exec drop_table('sensor_test');

-- This should detect the change in table count.
exec sensor_example;

select * from arcsql_log order by 1 desc;
