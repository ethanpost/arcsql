
-- My free offer is simple. 

-- 1. Install ArcSQL, run it for a day, week, or month...
-- 2. Export the SQL_LOG table to a spreadsheet and send it to me.
-- 3. I will look at the results and let you know what I see.

-- This password was used for a screencast and should not be used.
create user freeoffer identified by "OfferFree!XYZ123";

grant create session to freeoffer;

alter user freeoffer quota 5g on data;

drop user freeoffer cascade;

select sysdate from dual;

select * from sql_snap;

select * from sql_log order by datetime desc;

select * from saas_user;

select * from counter;

exec arcsql.stop;

exec arcsql.run;

select * from config_settings;

select greatest(null, 3) from dual;

exec arcsql.run;

exec arcsql.run_sql_log_update;

select count(*) from dba_extents;

select sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       max(service) service,
       max(module) module,
       max(action) action,
       view_name,
       metric_name,
       current_xx,
       max(avg_hours_since_last_exe) avg_hours_since_last_exe,
       sum(minutes_elapsed) total_minutes_elapsed,
       round(nvl(sum(decode(d, 0, x, null)), 0), 1) xx00,
       round(nvl(sum(decode(d, 1, x, null)), 0), 1) xx01,
       round(nvl(sum(decode(d, 2, x, null)), 0), 1) xx02,
       round(nvl(sum(decode(d, 3, x, null)), 0), 1) xx03,
       round(nvl(sum(decode(d, 4, x, null)), 0), 1) xx04,
       round(nvl(sum(decode(d, 5, x, null)), 0), 1) xx05,
       round(nvl(sum(decode(d, 6, x, null)), 0), 1) xx06,
       round(nvl(sum(decode(d, 7, x, null)), 0), 1) xx07,
       round(nvl(sum(decode(d, 8, x, null)), 0), 1) xx08,
       round(nvl(sum(decode(d, 9, x, null)), 0), 1) xx09,
       round(nvl(sum(decode(d, 10, x, null)), 0), 1) xx10,
       round(nvl(sum(decode(d, 11, x, null)), 0), 1) xx11,
       round(nvl(sum(decode(d, 12, x, null)), 0), 1) xx12,
       round(nvl(sum(decode(d, 13, x, null)), 0), 1) xx13,
       round(nvl(sum(decode(d, 14, x, null)), 0), 1) xx14,
       round(nvl(sum(decode(d, 15, x, null)), 0), 1) xx15,
       round(nvl(sum(decode(d, 16, x, null)), 0), 1) xx16,
       round(nvl(sum(decode(d, 17, x, null)), 0), 1) xx17,
       round(nvl(sum(decode(d, 18, x, null)), 0), 1) xx18,
       round(nvl(sum(decode(d, 19, x, null)), 0), 1) xx19,
       round(nvl(sum(decode(d, 20, x, null)), 0), 1) xx20,
       round(nvl(sum(decode(d, 21, x, null)), 0), 1) xx21,
       round(nvl(sum(decode(d, 22, x, null)), 0), 1) xx22,
       round(nvl(sum(decode(d, 23, x, null)), 0), 1) xx23
       -- round(nvl(sum(decode(d, 24, x, null)), 0), 1) xx24,
       -- round(nvl(sum(decode(d, 25, x, null)), 0), 1) xx25,
       -- round(nvl(sum(decode(d, 26, x, null)), 0), 1) xx26,
       -- round(nvl(sum(decode(d, 27, x, null)), 0), 1) xx27,
       -- round(nvl(sum(decode(d, 28, x, null)), 0), 1) xx28,
       -- round(nvl(sum(decode(d, 29, x, null)), 0), 1) xx29,
       -- round(nvl(sum(decode(d, 30, x, null)), 0), 1) xx30,
       -- round(nvl(sum(decode(d, 31, x, null)), 0), 1) xx31
  from (
select sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       max(service) service,
       max(module) module,
       max(action) action,
       'rolling_24_hours' view_name,
       'XX'||to_char(sysdate, 'HH24') current_xx,
       'minutes_elapsed_by_hour' metric_name,
       to_number(to_char(datetime, 'HH24')) d,
       round(avg(hours_since_last_exe)) avg_hours_since_last_exe,
       round(sum(elapsed_seconds)/60, 1) minutes_elapsed,
       round(sum(elapsed_seconds)/60, 1) x
  from sql_log
 where datetime >= trunc(sysdate-1, 'HH24') 
 group
    by sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       'rolling_24_hours',
       'XX'||to_char(sysdate, 'HH24'),
       'minutes_elapsed_by_hour',
       to_number(to_char(datetime, 'HH24')))
 group
    by sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       view_name,
       metric_name,
       current_xx
having sum(minutes_elapsed) >= 0
union 
select sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       max(service) service,
       max(module) module,
       max(action) action,
       view_name,
       metric_name,
       current_xx,
       max(avg_hours_since_last_exe) avg_hours_since_last_exe,
       sum(minutes_elapsed) total_minutes_elapsed,
       round(nvl(avg(decode(d, 0, x, null)), 0), 1) xx00,
       round(nvl(avg(decode(d, 1, x, null)), 0), 1) xx01,
       round(nvl(avg(decode(d, 2, x, null)), 0), 1) xx02,
       round(nvl(avg(decode(d, 3, x, null)), 0), 1) xx03,
       round(nvl(avg(decode(d, 4, x, null)), 0), 1) xx04,
       round(nvl(avg(decode(d, 5, x, null)), 0), 1) xx05,
       round(nvl(avg(decode(d, 6, x, null)), 0), 1) xx06,
       round(nvl(avg(decode(d, 7, x, null)), 0), 1) xx07,
       round(nvl(avg(decode(d, 8, x, null)), 0), 1) xx08,
       round(nvl(avg(decode(d, 9, x, null)), 0), 1) xx09,
       round(nvl(avg(decode(d, 10, x, null)), 0), 1) xx10,
       round(nvl(avg(decode(d, 11, x, null)), 0), 1) xx11,
       round(nvl(avg(decode(d, 12, x, null)), 0), 1) xx12,
       round(nvl(avg(decode(d, 13, x, null)), 0), 1) xx13,
       round(nvl(avg(decode(d, 14, x, null)), 0), 1) xx14,
       round(nvl(avg(decode(d, 15, x, null)), 0), 1) xx15,
       round(nvl(avg(decode(d, 16, x, null)), 0), 1) xx16,
       round(nvl(avg(decode(d, 17, x, null)), 0), 1) xx17,
       round(nvl(avg(decode(d, 18, x, null)), 0), 1) xx18,
       round(nvl(avg(decode(d, 19, x, null)), 0), 1) xx19,
       round(nvl(avg(decode(d, 20, x, null)), 0), 1) xx20,
       round(nvl(avg(decode(d, 21, x, null)), 0), 1) xx21,
       round(nvl(avg(decode(d, 22, x, null)), 0), 1) xx22,
       round(nvl(avg(decode(d, 23, x, null)), 0), 1) xx23
       -- round(nvl(avg(decode(d, 24, x, null)), 0), 1) xx24,
       -- round(nvl(avg(decode(d, 25, x, null)), 0), 1) xx25,
       -- round(nvl(avg(decode(d, 26, x, null)), 0), 1) xx26,
       -- round(nvl(avg(decode(d, 27, x, null)), 0), 1) xx27,
       -- round(nvl(avg(decode(d, 28, x, null)), 0), 1) xx28,
       -- round(nvl(avg(decode(d, 29, x, null)), 0), 1) xx29,
       -- round(nvl(avg(decode(d, 30, x, null)), 0), 1) xx30,
       -- round(nvl(avg(decode(d, 31, x, null)), 0), 1) xx31
  from (
select sql_id,
       sql_text sql_text,
       plan_hash_value,
       force_matching_signature,
       max(service) service,
       max(module) module,
       max(action) action,
       'rolling_24_hours' view_name,
       'XX'||to_char(sysdate, 'HH24') current_xx,
       avg(hours_since_last_exe) avg_hours_since_last_exe,
       'seconds_per_execute_by_hour' metric_name,
       to_number(to_char(datetime, 'HH24')) d,
       round(sum(elapsed_seconds)/60, 1) minutes_elapsed,
       round(decode(sum(executions), 0, 0, sum(elapsed_seconds)/sum(executions)), 2) x
  from sql_log
 where datetime >= trunc(sysdate-1, 'HH24') 
 group
    by sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       'rolling_24_hours',
       'XX'||to_char(sysdate, 'HH24'),
       'seconds_per_execute_by_hour',
       to_number(to_char(datetime, 'HH24')))
 group
    by sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       view_name,
       metric_name,
       current_xx
having sum(minutes_elapsed) >= 0
union 
select sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       max(service) service,
       max(module) module,
       max(action) action,
       view_name,
       metric_name,
       current_xx,
       max(avg_hours_since_last_exe) avg_hours_since_last_exe,
       sum(minutes_elapsed) total_minutes_elapsed,
       round(nvl(avg(decode(d, 0, x, null)), 0), 1) xx00,
       round(nvl(avg(decode(d, 1, x, null)), 0), 1) xx01,
       round(nvl(avg(decode(d, 2, x, null)), 0), 1) xx02,
       round(nvl(avg(decode(d, 3, x, null)), 0), 1) xx03,
       round(nvl(avg(decode(d, 4, x, null)), 0), 1) xx04,
       round(nvl(avg(decode(d, 5, x, null)), 0), 1) xx05,
       round(nvl(avg(decode(d, 6, x, null)), 0), 1) xx06,
       round(nvl(avg(decode(d, 7, x, null)), 0), 1) xx07,
       round(nvl(avg(decode(d, 8, x, null)), 0), 1) xx08,
       round(nvl(avg(decode(d, 9, x, null)), 0), 1) xx09,
       round(nvl(avg(decode(d, 10, x, null)), 0), 1) xx10,
       round(nvl(avg(decode(d, 11, x, null)), 0), 1) xx11,
       round(nvl(avg(decode(d, 12, x, null)), 0), 1) xx12,
       round(nvl(avg(decode(d, 13, x, null)), 0), 1) xx13,
       round(nvl(avg(decode(d, 14, x, null)), 0), 1) xx14,
       round(nvl(avg(decode(d, 15, x, null)), 0), 1) xx15,
       round(nvl(avg(decode(d, 16, x, null)), 0), 1) xx16,
       round(nvl(avg(decode(d, 17, x, null)), 0), 1) xx17,
       round(nvl(avg(decode(d, 18, x, null)), 0), 1) xx18,
       round(nvl(avg(decode(d, 19, x, null)), 0), 1) xx19,
       round(nvl(avg(decode(d, 20, x, null)), 0), 1) xx20,
       round(nvl(avg(decode(d, 21, x, null)), 0), 1) xx21,
       round(nvl(avg(decode(d, 22, x, null)), 0), 1) xx22,
       round(nvl(avg(decode(d, 23, x, null)), 0), 1) xx23
       -- round(nvl(avg(decode(d, 24, x, null)), 0), 1) xx24,
       -- round(nvl(avg(decode(d, 25, x, null)), 0), 1) xx25,
       -- round(nvl(avg(decode(d, 26, x, null)), 0), 1) xx26,
       -- round(nvl(avg(decode(d, 27, x, null)), 0), 1) xx27,
       -- round(nvl(avg(decode(d, 28, x, null)), 0), 1) xx28,
       -- round(nvl(avg(decode(d, 29, x, null)), 0), 1) xx29,
       -- round(nvl(avg(decode(d, 30, x, null)), 0), 1) xx30,
       -- round(nvl(avg(decode(d, 31, x, null)), 0), 1) xx31
  from (
select sql_id,
       sql_text sql_text,
       plan_hash_value,
       force_matching_signature,
       max(service) service,
       max(module) module,
       max(action) action,
       'rolling_24_hours' view_name,
       'XX'||to_char(sysdate, 'HH24') current_xx,
       avg(hours_since_last_exe) avg_hours_since_last_exe,
       'sql_log_avg_score' metric_name,
       to_number(to_char(datetime, 'HH24')) d,
       round(sum(elapsed_seconds)/60, 1) minutes_elapsed,
       round(avg(sql_log_avg_score)) x
  from sql_log
 where datetime >= trunc(sysdate-1, 'HH24') 
 group
    by sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       'rolling_24_hours',
       'XX'||to_char(sysdate, 'HH24'),
       'sql_log_avg_score',
       to_number(to_char(datetime, 'HH24')))
 group
    by sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       view_name,
       metric_name,
       current_xx
having sum(minutes_elapsed) >= 0
 order
    by 12 desc, 11;


select sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       max(service) service,
       max(module) module,
       max(action) action,
       view_name,
       metric_name,
       current_xx,
       max(avg_hours_since_last_exe) avg_hours_since_last_exe,
       sum(minutes_elapsed) total_minutes_elapsed,
       round(nvl(avg(decode(d, 0, x, null)), 0), 1) xx00,
       round(nvl(avg(decode(d, 1, x, null)), 0), 1) xx01,
       round(nvl(avg(decode(d, 2, x, null)), 0), 1) xx02,
       round(nvl(avg(decode(d, 3, x, null)), 0), 1) xx03,
       round(nvl(avg(decode(d, 4, x, null)), 0), 1) xx04,
       round(nvl(avg(decode(d, 5, x, null)), 0), 1) xx05,
       round(nvl(avg(decode(d, 6, x, null)), 0), 1) xx06,
       round(nvl(avg(decode(d, 7, x, null)), 0), 1) xx07,
       round(nvl(avg(decode(d, 8, x, null)), 0), 1) xx08,
       round(nvl(avg(decode(d, 9, x, null)), 0), 1) xx09,
       round(nvl(avg(decode(d, 10, x, null)), 0), 1) xx10,
       round(nvl(avg(decode(d, 11, x, null)), 0), 1) xx11,
       round(nvl(avg(decode(d, 12, x, null)), 0), 1) xx12,
       round(nvl(avg(decode(d, 13, x, null)), 0), 1) xx13,
       round(nvl(avg(decode(d, 14, x, null)), 0), 1) xx14,
       round(nvl(avg(decode(d, 15, x, null)), 0), 1) xx15,
       round(nvl(avg(decode(d, 16, x, null)), 0), 1) xx16,
       round(nvl(avg(decode(d, 17, x, null)), 0), 1) xx17,
       round(nvl(avg(decode(d, 18, x, null)), 0), 1) xx18,
       round(nvl(avg(decode(d, 19, x, null)), 0), 1) xx19,
       round(nvl(avg(decode(d, 20, x, null)), 0), 1) xx20,
       round(nvl(avg(decode(d, 21, x, null)), 0), 1) xx21,
       round(nvl(avg(decode(d, 22, x, null)), 0), 1) xx22,
       round(nvl(avg(decode(d, 23, x, null)), 0), 1) xx23
       -- round(nvl(avg(decode(d, 24, x, null)), 0), 1) xx24,
       -- round(nvl(avg(decode(d, 25, x, null)), 0), 1) xx25,
       -- round(nvl(avg(decode(d, 26, x, null)), 0), 1) xx26,
       -- round(nvl(avg(decode(d, 27, x, null)), 0), 1) xx27,
       -- round(nvl(avg(decode(d, 28, x, null)), 0), 1) xx28,
       -- round(nvl(avg(decode(d, 29, x, null)), 0), 1) xx29,
       -- round(nvl(avg(decode(d, 30, x, null)), 0), 1) xx30,
       -- round(nvl(avg(decode(d, 31, x, null)), 0), 1) xx31
  from (
select sql_id,
       sql_text sql_text,
       plan_hash_value,
       force_matching_signature,
       max(service) service,
       max(module) module,
       max(action) action,
       'rolling_24_hours' view_name,
       'XX'||to_char(sysdate, 'HH24') current_xx,
       avg(hours_since_last_exe) avg_hours_since_last_exe,
       'sql_log_avg_score' metric_name,
       to_number(to_char(datetime, 'HH24')) d,
       round(sum(elapsed_seconds)/60, 1) minutes_elapsed,
       round(avg(sql_log_avg_score)) x
  from sql_log
 where datetime >= trunc(sysdate-1, 'HH24') 
 group
    by sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       'rolling_24_hours',
       'XX'||to_char(sysdate, 'HH24'),
       'sql_log_avg_score',
       to_number(to_char(datetime, 'HH24')))
 group
    by sql_id,
       sql_text,
       plan_hash_value,
       force_matching_signature,
       view_name,
       metric_name,
       current_xx
having sum(minutes_elapsed) >= 0
 order
    by 12 desc, 11;