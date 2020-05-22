create or replace package body arcsql as

function secs_between_timestamps (time_start in timestamp, time_end in timestamp) return number is
   total_secs number;
   d interval day(9) to second(6);
begin
   d := time_end - time_start;
   total_secs := abs(extract(second from d) + extract(minute from d)*60 + extract(hour from d)*60*60 + extract(day from d)*24*60*60);
   return total_secs;
end;

function secs_since_timestamp (time_stamp timestamp) return number is
   now         timestamp;
   total_secs  number;
   d           interval day(9) to second(6);
begin
   now := cast(sysdate as timestamp);
   d := now - time_stamp;
   total_secs := abs(extract(second from d) + extract(minute from d)*60 + extract(hour from d)*60*60 + extract(day from d)*24*60*60);
   return total_secs;
end;

function str_to_key_str (str in varchar2) return varchar2 is
   new_str varchar2(1000);
begin
   new_str := regexp_replace(str, '[^A-Z|a-z|0-9]', '_');
   return new_str;
end;

function str_random (length in number default 33, string_type in varchar2 default 'an') return varchar2 is
   r varchar2(4000);
   x number := 0;
begin
   x := least(str_random.length, 4000);
   case lower(string_type)
      when 'a' then
         r := dbms_random.string('a', x);
      when 'n' then
         while x > 0 loop
            x := x - 1;
            r := r || to_char(round(dbms_random.value(0, 9)));
         end loop;
      when 'an' then
         r := dbms_random.string('x', x);
   end case;
   return r;
end;

function str_hash_md5 (text varchar2) return varchar2 is 
   r varchar2(1000);
begin
   select dbms_crypto.hash(rawtohex(text), 2) into r from dual;
   return r;
end;

function str_is_email (text varchar2) return boolean is 
begin 
  if regexp_like (text, '^[A-Za-z]+[A-Za-z0-9.]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$') then 
      arcsql.debug('str_is_email: yes: '||text);
      return true;
  else 
      arcsql.debug('str_is_email: no: '||text);
      return false;
   end if;
end;

function str_is_date_y_or_n (text varchar2) return varchar2 is
   x date;
begin
   x := to_date(text, 'MM/DD/YYYY');
   return 'Y';
exception
   when others then
      return 'N';
end;

function str_is_number_y_or_n (text varchar2) return varchar2 is
   x number;
begin
   x := to_number(text);
   return 'Y';
exception
   when others then
      return 'N';
end;

function str_complexity_check
   (text   varchar2,
    chars      integer := null,
    letter     integer := null,
    uppercase  integer := null,
    lowercase  integer := null,
    digit      integer := null,
    special    integer := null) return boolean is
   cnt_letter  integer := 0;
   cnt_upper   integer := 0;
   cnt_lower   integer := 0;
   cnt_digit   integer := 0;
   cnt_special integer := 0;
   delimiter   boolean := false;
   len         integer := nvl (length(text), 0);
   i           integer ;
   ch          char(1 char);
   lang        varchar2(512 byte);
begin
   -- Bug 22730089
   -- Get the current session language and use utl_lms to get the messages.
   -- Under the scenario where the language is not supported ,
   -- only the error code shall be displayed.
   lang := sys_context('userenv','lang');
   -- Classify each character in the text.
   for i in 1..len loop
      ch := substr(text, i, 1);
      if ch = '"' then
         delimiter := true;
         -- Got a delimiter, no need to validate other characters.
         exit;
         -- Observes alphabetic, numeric and special characters.
         -- If a character is neither alphabetic nor numeric,
         -- it is considered special.
      elsif regexp_instr(ch, '[[:alnum:]]') > 0 then
         if regexp_instr(ch, '[[:digit:]]') > 0 then
            cnt_digit := cnt_digit + 1;
         -- Certain characters can be both, numeric and alphabetic,
         -- Such characters will be counted in both categories.
         -- Ex:Roman Numerals('I'(U+2160),'II'(U+2161),'i'(U+2170),'ii'(U+2171))
         end if;
         if regexp_instr(ch, '[[:alpha:]]') > 0 then
            cnt_letter := cnt_letter + 1;
            if regexp_instr(ch, '[[:lower:]]') > 0 then
               cnt_lower := cnt_lower + 1;
            end if;
            -- Certain alphabetic characters can be both upper- or lowercase.
            -- Such characters will be counted in both categories.
            -- Ex:Latin Digraphs and Ligatures ('Nj'(U+01CB), 'Dz'(U+01F2))
            if regexp_instr(ch, '[[:upper:]]') > 0 then
               cnt_upper := cnt_upper + 1;
            end if;
         end if;
      else
         cnt_special := cnt_special + 1;
      end if;
   end loop;
   if delimiter = true then
      return false;
   end if;
   if chars is not null and len < chars then
      return false;
   end if;
   if letter is not null and cnt_letter < letter then
      return false;
   end if;
   if uppercase is not null and cnt_upper < uppercase then
      return false;
   end if;
   if lowercase is not null and cnt_lower < lowercase then
      return false;
   end if;
   if digit is not null and cnt_digit < digit then
      return false;
   end if;
   if special is not null and cnt_special < special then
      return false;
   end if;
   return true;
end;

function num_get_variance_pct (
      p_val number,
      p_pct_chance number,
      p_change_low_pct number,
      p_change_high_pct number,
      p_decimals number default 0) return number is 
   p_new_val number;
begin
   arcsql.debug('num_get_variance_pct: '||p_val||','||p_pct_chance||','||p_change_low_pct||','||p_change_high_pct||','||p_decimals);
   if dbms_random.value(1,100) > p_pct_chance then 
      return p_val;
   end if;
   p_new_val := p_val + round(p_val * dbms_random.value(p_change_low_pct, p_change_high_pct)/100, p_decimals);
   return round(p_new_val, p_decimals);
end;

function num_get_variance (
      p_val number,
      p_pct_chance number,
      p_change_low number,
      p_change_high number,
      p_decimals number default 0) return number is 
   p_new_val number;
begin
   arcsql.debug('num_get_variance: '||p_val||','||p_pct_chance||','||p_change_low||','||p_change_high||','||p_decimals);
   if dbms_random.value(1,100) > p_pct_chance then 
      return p_val;
   end if;
   p_new_val := p_val + round(dbms_random.value(p_change_low, p_change_high), p_decimals);
   return round(p_new_val, p_decimals);
end;

procedure backup_table (sourceTable varchar2, newTable varchar2, dropTable boolean := false) is
begin
   if dropTable then
      drop_table(newTable);
   end if;
   execute immediate 'create table '||newTable||' as (select * from '||sourceTable||')';
end;

procedure connect_external_file_as_table (directoryName varchar2, fileName varchar2, tableName varchar2) is
begin
   if does_table_exist(tableName) then
      execute immediate 'drop table '||tableName;
   end if;
   execute immediate '
   create table '||tableName||' (
   text varchar2(1000))
   organization external (
   type oracle_loader
   default directory '||directoryName||'
   access parameters (
   records delimited by newline
   nobadfile
   nodiscardfile
   nologfile
   fields terminated by ''0x0A''
   missing field values are null
   )
   location('''||fileName||''')
   )
   reject limit unlimited';
end;   

procedure write_to_file (directoryName in varchar2, fileName in varchar2, text in varchar2) is
   file_handle utl_file.file_type;
begin
   file_handle := utl_file.fopen(directoryName,fileName, 'A', 32767);
   utl_file.put_line(file_handle, text, true);
   utl_file.fclose(file_handle);
end;

procedure log_alert_log (text in varchar2) is
   -- Disabled for now since it does not work in autonomous cloud database.
   x number;
   begin
--    select count(*) into x from dba_users where user_name='C##CLOUD_OPS';
--    $if x = 1 then
--       sys.dbms_system.ksdwrt(2, text);
--       sys.dbms_system.ksdfls;
--    $else
      x := 0;
   -- $end
end;

function get_audsid return number is 
-- Returns a unique value which can be used to identify the calling session.
begin
   return SYS_CONTEXT('USERENV','sessionid');
end;

function get_days_since_pass_change (username varchar2) return number is 
   n number;
begin
   select round(trunc(sysdate)-trunc(nvl(password_change_date, created)))  
     into n
     from dba_users
    where username=upper(get_days_since_pass_change.username);
   return n;
end;

/* APPLICATION VERSIONING */

Write and read the version you are on, going to, coming from. 

Helpful for maintaining conditional idempotent upgrade paths.

STATUS can be 'SET' or 'CONFIRMED'. SET indicates we are in the middle of a patch or 
upgrade and CONFIRMED indicates successful. get_app_version always returns the 
last confirmed version, not the version you are attempting to upgrade/patch to.

confirm_app_version must be preceded by set_app_version. You can also call 
set_app_version with p_confirmed=True which immediatly sets the status to CONFIRMED.

ToDo: 

- Add logging for failure and success using the logging interface.
- (Unlikely) - Track errors using system wide trigger interface (not built) and report.

*/

procedure set_app_version(
   p_app_name in varchar2, 
   p_version in number,
   p_confirm in boolean := false) is 
   -- Set numeric decimal version for an application.
   pragma autonomous_transaction;
   n number;
   current_status varchar2(10);
   new_status varchar2(10);
begin

   select count(*) into n from app_version where app_name=upper(p_app_name);

   if p_confirm then 
      new_status := 'CONFIRMED';
   else
      new_status := 'SET';
   end if;
   
   if n = 0 then 
      insert into app_version (
         app_name,
         last_version,
         version,
         status) values (
         upper(p_app_name),
         0,
         p_version,
         new_status);
   else 
      select status into current_status from app_version where app_name=upper(p_app_name);
      if current_status = 'CONFIRMED' then 
         -- Only change last_version to version when last attempt was confirmed.
         update app_version 
            set last_version=version,
                -- version now becomes the version we want to go to.
                version=p_version,
                status=new_status
          where app_name=upper(p_app_name);
      elsif current_status = 'SET' then 
         -- If last attempt was not confirmed (failed) then last_version 
         -- remains the same since it is the last confirmed version.
         update app_version 
            set last_version=last_version,
                version=p_version,
                status=new_status
          where app_name=upper(p_app_name);
      end if;
   end if;
   commit;
end;

procedure confirm_app_version(p_app_name in varchar2) is
   pragma autonomous_transaction;
begin
   update app_version 
      set status='CONFIRMED'
    where app_name=upper(p_app_name);
   commit;
end;

function get_app_version(p_app_name in varchar2) return number is 
   v_version number;
begin
   select decode(status, 'SET', last_version, 'CONFIRMED', version)
     into v_version
     from app_version 
    where app_name=upper(p_app_name);
    return v_version;
end;

procedure delete_app_version(p_app_name in varchar2) is 
   pragma autonomous_transaction;
begin 
  delete from app_version where app_name=upper(p_app_name);
  commit;
end;

/* SIMPLE KEY VALUE STORE */

procedure cache (
   cache_key varchar2, 
   p_value varchar2) is
   l_value varchar2(4000);
begin
   
   if not does_cache_key_exist(cache_key) then
      insert into cache (key) values (cache_key);
   end if;
   
   if length(p_value) > 4000 then
      l_value := substr(p_value, 1, 4000);
   end if;
   
   update cache 
      set value=p_value,
          update_time=sysdate
    where key=lower(cache_key);
end;

function return_cached_value (cache_key in varchar2) return varchar2 is 
   r varchar2(4000);
begin
   if does_cache_key_exist(cache_key) then 
      select value into r from cache where key=lower(cache_key);
   else 
      r := null; 
   end if;
   return r;
end;

function does_cache_key_exist (cache_key varchar2) return boolean is
   n number;
begin
   select count(*) into n
     from cache
    where key=lower(cache_key);
   if n = 0 then
      return false;
   else
      return true;
   end if;
end;

procedure delete_cache_key (
   cache_key        varchar2) is
begin
   delete from cache
    where key=lower(cache_key);
end;
   
/* CUSTOM SETTINGS */

procedure remove_config (name varchar2) is
begin
   delete from config_settings where name=remove_config.name;
end;

procedure add_config (name varchar2, value varchar2, description varchar2 default null) is
begin
   -- DO NOT MODIFY IF EXISTS! Update to self.
   update config_settings set value=value where name=lower(add_config.name);
   -- If nothing happened we need to add it.
   if sql%rowcount = 0 then
      insert into config_settings (name, value, description)
        values (lower(add_config.name), add_config.value, description);
   end if;
end;

procedure set_config (name varchar2, value varchar2) is
begin
   update config_settings set value=set_config.value where name=lower(set_config.name);
   if sql%rowcount = 0 then
      add_config(set_config.name, set_config.value);
   end if;
end;

function get_config (name varchar2) return varchar2 is
   config_value varchar2(1000);
begin
   select value into config_value from config_settings where name=lower(get_config.name);
   return config_value;
exception
   when no_data_found then
      return null;
end;

/* SQL LOG */

function get_sql_log_analyze_min_secs return number is
begin  
   return to_number(nvl(arcsql.get_config('sql_log_analyze_min_secs'), 1));
end;

function sql_log_age_of_plan_in_days (
    datetime date,
    plan_hash_value number) return number is
    days_ago number;
begin
    select nvl(round(sysdate-min(datetime), 2), 0)
      into days_ago
      from sql_log
     where plan_hash_value = sql_log_age_of_plan_in_days.plan_hash_value
       and datetime < trunc(sql_log_age_of_plan_in_days.datetime, 'HH24')
       and datetime >= trunc(sql_log_age_of_plan_in_days.datetime-90, 'HH24');
    return days_ago;
end;

function sql_log_count_of_faster_plans (
    datetime               date,
    elap_secs_per_exe      number,
    sql_log_id             number,
    plan_hash_value        number,
    sqlid                  varchar2,
    forcematchingsignature number)
    return number is
    r number;
begin
   if forcematchingsignature > 0 then
      select count(*)
        into r
        from sql_log
       where datetime < trunc(sql_log_count_of_faster_plans.datetime, 'HH24')
         and datetime >= trunc(sql_log_count_of_faster_plans.datetime-90, 'HH24')
         and sql_log_id != sql_log_count_of_faster_plans.sql_log_id
         and plan_hash_value != sql_log_count_of_faster_plans.plan_hash_value
         and decode(executions, 0, 0, elapsed_seconds/executions) <= sql_log_count_of_faster_plans.elap_secs_per_exe*.8
         and sql_id = sqlid
         and force_matching_signature = forcematchingsignature;
   else
      select count(*)
        into r
        from sql_log
       where datetime < trunc(sql_log_count_of_faster_plans.datetime, 'HH24')
         and datetime >= trunc(sql_log_count_of_faster_plans.datetime-90, 'HH24')
         and sql_log_id != sql_log_count_of_faster_plans.sql_log_id
         and plan_hash_value != sql_log_count_of_faster_plans.plan_hash_value
         and decode(executions, 0, 0, elapsed_seconds/executions) <= sql_log_count_of_faster_plans.elap_secs_per_exe*.8
         and sql_id = sqlid;
   end if;
   return r;
end;

function sql_log_count_of_slower_plans (
    datetime               date,
    elap_secs_per_exe      number,
    sql_log_id             number,
    plan_hash_value        number,
    sqlid                  varchar2,
    forcematchingsignature number)
    return number is
    r number;
begin
   if forcematchingsignature > 0 then
      select count(*)
        into r
        from sql_log
       where datetime < trunc(sql_log_count_of_slower_plans.datetime, 'HH24')
         and datetime >= trunc(sql_log_count_of_slower_plans.datetime-90, 'HH24')
         and sql_log_id != sql_log_count_of_slower_plans.sql_log_id
         and plan_hash_value != sql_log_count_of_slower_plans.plan_hash_value
         and decode(executions, 0, 0, elapsed_seconds/executions) >= sql_log_count_of_slower_plans.elap_secs_per_exe*1.2
         and sql_id = sqlid
         and force_matching_signature = forcematchingsignature;
   else
      select count(*)
        into r
        from sql_log
       where datetime < trunc(sql_log_count_of_slower_plans.datetime, 'HH24')
         and datetime >= trunc(sql_log_count_of_slower_plans.datetime-90, 'HH24')
         and sql_log_id != sql_log_count_of_slower_plans.sql_log_id
         and plan_hash_value != sql_log_count_of_slower_plans.plan_hash_value
         and decode(executions, 0, 0, elapsed_seconds/executions) >= sql_log_count_of_slower_plans.elap_secs_per_exe*1.2
         and sql_id = sqlid;
   end if;
   return r;
end;

function sql_log_hours_since_last_exe (sqlid varchar2, forcematchingsignature number) return number is 
   hours_ago number := 0;
   d date;
begin
   select nvl(max(datetime), trunc(sysdate, 'HH24')) into d from sql_log 
    where sql_id=sqlid 
      and force_matching_signature=forcematchingsignature 
      and datetime < trunc(sysdate, 'HH24');
   hours_ago := round((trunc(sysdate, 'HH24')-d)*24, 1);
   return hours_ago;
end;

function sql_log_age_of_sql_in_days (datetime date, sqlid varchar2, forcematchingsignature number) return number is
   days_ago number;
begin
   if forcematchingsignature > 0 then
       select nvl(round(sysdate-min(datetime), 2), 0)
         into days_ago
         from sql_log
        where datetime < trunc(sql_log_age_of_sql_in_days.datetime, 'HH24')
          -- ToDo: Need parameters here, 90 days might not be enough. Trying to limit the amount of data we look at.
          -- ToDo: Some of this meta could be calculated in batch one a day.
          and datetime >= trunc(sql_log_age_of_sql_in_days.datetime-90, 'HH24')
          and sql_id=sqlid
          and force_matching_signature=forcematchingsignature;
    else
       select nvl(round(sysdate-min(datetime), 2), 0)
         into days_ago
         from sql_log
        where datetime < trunc(sql_log_age_of_sql_in_days.datetime, 'HH24')
          and datetime >= trunc(sql_log_age_of_sql_in_days.datetime-90, 'HH24')
          and sql_id=sqlid;
    end if;
    return days_ago;
end;

function sql_log_sql_last_seen_in_days (datetime date, sqlid varchar2, forcematchingsignature number) return number is
   days_ago number;
begin
   if forcematchingsignature > 0 then
       select nvl(round(sysdate-max(datetime), 2), 0)
         into days_ago
         from sql_log
        where sql_id=sqlid
          and force_matching_signature=forcematchingsignature
          and datetime < trunc(sql_log_sql_last_seen_in_days.datetime, 'HH24')
          -- ToDo: Add parameter.
          and datetime >= trunc(sql_log_sql_last_seen_in_days.datetime-90, 'HH24');
    else
       select nvl(round(sysdate-max(datetime), 2), 0)
         into days_ago
         from sql_log
        where sql_id=sqlid
          and datetime < trunc(sql_log_sql_last_seen_in_days.datetime, 'HH24')
          and datetime >= trunc(sql_log_sql_last_seen_in_days.datetime-90, 'HH24');
    end if;
    return nvl(days_ago, 0);
end;

function sql_log_elap_secs_all_sql (datetime date) return number is
   total_secs number;
begin
   select sum(elapsed_seconds)
     into total_secs
     from sql_log
    where datetime >= trunc(sql_log_elap_secs_all_sql.datetime, 'HH24')
      and datetime < trunc(sql_log_elap_secs_all_sql.datetime+(1/24), 'HH24');
   return total_secs;
end;

function sql_log_norm_elap_secs_per_exe (
    datetime               date,
    sqlid                  varchar2,
    forcematchingsignature number
    ) return number is
   n number;
   r number;
begin
   if forcematchingsignature > 0 then
       select decode(sum(executions), 0, 0, sum(elapsed_seconds)/sum(executions)),
              count(*)
         into r,
              n
         from sql_log
        where sql_id=sqlid
          and force_matching_signature=forcematchingsignature
          and datetime >= trunc(sql_log_norm_elap_secs_per_exe.datetime-90);
        -- If less than 30 samples remove sql_id and just use force_matching_signature.
        if n < 30 then
           select decode(sum(executions), 0, 0, sum(elapsed_seconds)/sum(executions)),
                  count(*)
             into r,
                  n
             from sql_log
            where force_matching_signature=forcematchingsignature
              and datetime >= trunc(sql_log_norm_elap_secs_per_exe.datetime-90);
        end if;
    else
       select decode(sum(executions), 0, 0, sum(elapsed_seconds)/sum(executions)),
              count(*)
         into r,
              n
         from sql_log
        where sql_id=sqlid
          and datetime >= trunc(sql_log_norm_elap_secs_per_exe.datetime-90);
    end if;
    return r;
end;

function sql_log_norm_execs_per_hour (datetime date, sqlid varchar2, forcematchingsignature number) return number is
   -- Returns the number of average executions per hour for hours in which a SQL executes.
   record_count number;
   avg_executions number;
begin
   if forcematchingsignature > 0 then
      -- Try to match on SQL ID and SIGNATURE.
      select avg(executions), count(*)
        into avg_executions, record_count
        from sql_log
       where sql_id=sqlid
         and force_matching_signature=forcematchingsignature
         and datetime >= trunc(sql_log_norm_execs_per_hour.datetime-90);
      -- If less than 30 samples try again on SIGNATURE only.
      if record_count < 30 then
         select avg(executions)
           into avg_executions
           from sql_log
          where force_matching_signature=forcematchingsignature
            and datetime >= trunc(sql_log_norm_execs_per_hour.datetime-90);
      end if;
   else
      -- SIGNATURE NOT THERE, USE SQL ID ONLY
      select avg(executions)
        into avg_executions
        from sql_log
       where sql_id=sqlid
         and datetime >= trunc(sysdate-90);
   end if;
   return avg_executions;
end;

function sql_log_norm_io_wait_secs (datetime date, sqlid varchar2, forcematchingsignature number) return number is
   -- Returns the number of average io wait per hour for hours in which a SQL executes.
   record_count number;
   avg_user_io_wait_secs number;
begin
   if forcematchingsignature > 0 then
      -- Try to match on SQL ID and SIGNATURE.
      select avg(user_io_wait_secs), count(*)
        into avg_user_io_wait_secs, record_count
        from sql_log
       where sql_id=sqlid
         and force_matching_signature=forcematchingsignature
         and datetime >= trunc(sql_log_norm_io_wait_secs.datetime-90);
      -- If less than 30 samples try again on SIGNATURE only.
      if record_count < 30 then
         select avg(user_io_wait_secs)
           into avg_user_io_wait_secs
           from sql_log
          where force_matching_signature=forcematchingsignature
            and datetime >= trunc(sql_log_norm_io_wait_secs.datetime-90);
      end if;
   else
      -- SIGNATURE NOT THERE, USE SQL ID ONLY
      select avg(user_io_wait_secs)
        into avg_user_io_wait_secs
        from sql_log
       where sql_id=sqlid
         and datetime >= trunc(sysdate-90);
   end if;
   return avg_user_io_wait_secs;
end;

function sql_log_norm_rows_processed (datetime date, sqlid varchar2, forcematchingsignature number) return number is
   -- Returns the number of average rows processed for this SQL per hour.
   record_count number;
   avg_rows_processed number;
begin
   if forcematchingsignature > 0 then
      -- Try to match on SQL ID and SIGNATURE.
      select avg(rows_processed), count(*)
        into avg_rows_processed, record_count
        from sql_log
       where sql_id=sqlid
         and force_matching_signature=forcematchingsignature
         and datetime >= trunc(sql_log_norm_rows_processed.datetime-90);
      -- If less than 30 samples try again on SIGNATURE only.
      if record_count < 30 then
         select avg(rows_processed)
           into avg_rows_processed
           from sql_log
          where force_matching_signature=forcematchingsignature
            and datetime >= trunc(sql_log_norm_rows_processed.datetime-90);
      end if;
   else
      -- SIGNATURE NOT THERE, USE SQL ID ONLY
      select avg(rows_processed)
        into avg_rows_processed
        from sql_log
       where sql_id=sqlid
         and datetime >= trunc(sysdate-90);
   end if;
   return avg_rows_processed;
end;


procedure sql_log_take_snapshot is
   -- Takes a snapshot of the records returned by sql_snap_view.
   -- Rows are simply inserted into sql_snap. These rows can 
   -- later be compared back to the current values in the view.
   n number;
begin
   n := to_number(nvl(arcsql.get_config('sql_log_sql_text_length'), '100'));
   insert into sql_snap (
      sql_id,
      insert_datetime,
      sql_text,
      executions,
      plan_hash_value,
      elapsed_time,
      force_matching_signature,
      user_io_wait_time,
      rows_processed,
      cpu_time,
      service,
      module,
      action) (select sql_id,
      sysdate,
      substr(sql_text, 1, n),
      executions,
      plan_hash_value,
      elapsed_time,
      force_matching_signature,
      user_io_wait_time,
      rows_processed,
      cpu_time,
      service,
      module,
      action
     from sql_snap_view);
end;

procedure sql_log_save_active_sess_hist is
   -- Pulls more data from gv$active_session_history into our table active_sql_hist if licensed.
   min_elap_secs number;
begin
   min_elap_secs := get_sql_log_analyze_min_secs;
   -- This is only allowed if you have the license to look at these tables.
   if upper(nvl(arcsql.get_config('sql_log_ash_is_licensed'), 'N')) = 'Y' then
      
      if nvl(arcsql.return_cached_value('sql_log_last_active_sql_hist_update'), 'x') != to_char(sysdate, 'YYYYMMDDHH24') then
      
         arcsql.cache('sql_log_last_active_sql_hist_update', to_char(sysdate, 'YYYYMMDDHH24'));
         
         insert into sql_log_active_session_history (
         datetime,
         sql_id,
         sql_text,
         on_cpu,
         in_wait,
         modprg,
         actcli,
         exes,
         elapsed_seconds)
         (
          select trunc(sample_time, 'HH24') sample_time, 
                 a.sql_id,
                 b.sql_text,
                 sum(decode(session_state, 'ON CPU' , 1, 0)) on_cpu,
                 sum(decode(session_state, 'ON CPU' , 0, 1)) in_wait,
                 translate(nvl(module, program), '0123456789', '----------') modprg,
                 translate(nvl(action, client_id), '0123456789', '----------') actcli, 
                 max(sql_exec_id)-min(sql_exec_id)+1 exes,
                 count(*) elapsed_seconds
            from gv$active_session_history a,
                 (select sql_id, sql_text from sql_log 
                   where datetime >= trunc(sysdate-(1/24), 'HH24') 
                     and datetime < trunc(sysdate, 'HH24') 
                     and elapsed_seconds >= min_elap_secs
                   group 
                      by sql_id, sql_text) b
           where a.sql_id=b.sql_id
             and sample_time >= trunc(sysdate-(1/24), 'HH24') 
             and sample_time < trunc(sysdate, 'HH24') 
             and (a.sql_id, a.sql_plan_hash_value) in (
              select sql_id, plan_hash_value from sql_log
               where datetime >= trunc(sysdate-(1/24), 'HH24') 
                 and datetime < trunc(sysdate, 'HH24') 
                 and elapsed_seconds >= min_elap_secs)
           group
              by trunc(sample_time, 'HH24'), 
                 a.sql_id,
                 b.sql_text,
                 translate(nvl(module, program), '0123456789', '----------'),
                 translate(nvl(action, client_id), '0123456789', '----------'));
      end if;
   end if;
end;

procedure sql_log_analyze_window (datetime date default sysdate) is

   cursor c_sql_log (min_elap_secs number) is
   select a.*
     from sql_log a
    where datetime >= trunc(sql_log_analyze_window.datetime, 'HH24')
      and datetime < trunc(sql_log_analyze_window.datetime+(1/24), 'HH24')
      and a.elapsed_seconds > min_elap_secs;

   total_elap_secs              number;
   
begin
   total_elap_secs := sql_log_elap_secs_all_sql(sql_log_analyze_window.datetime);
   -- Loop through each row in SQL_LOG in the result set.
   for s in c_sql_log (get_sql_log_analyze_min_secs) loop
      
      -- We check for nulls below and only set once per hour. Once set we don't need to do it again.

      -- What is the historical avg elap time per exe in seconds for this SQL?
      if s.norm_elap_secs_per_exe is null then
         s.norm_elap_secs_per_exe := sql_log_norm_elap_secs_per_exe(datetime => sql_log_analyze_window.datetime, sqlid => s.sql_id, forcematchingsignature => s.force_matching_signature);
      end if;
      
      -- What is the historical avg # of executes per hr for this SQL?
      if s.norm_execs_per_hour is null then
         s.norm_execs_per_hour := sql_log_norm_execs_per_hour(datetime=>sql_log_analyze_window.datetime, sqlid=>s.sql_id, forcematchingsignature=>s.force_matching_signature);
      end if;

      if s.norm_user_io_wait_secs is null then 
         s.norm_user_io_wait_secs := sql_log_norm_io_wait_secs(datetime=>sql_log_analyze_window.datetime, sqlid=>s.sql_id, forcematchingsignature=>s.force_matching_signature);
      end if;

      if s.norm_rows_processed is null then 
         s.norm_rows_processed := sql_log_norm_rows_processed(datetime=>sql_log_analyze_window.datetime, sqlid=>s.sql_id, forcematchingsignature=>s.force_matching_signature);
      end if;
      
      if s.sql_age_in_days is null then
         s.sql_age_in_days := sql_log_age_of_sql_in_days(datetime=>sql_log_analyze_window.datetime, sqlid=>s.sql_id, forcematchingsignature=>s.force_matching_signature);
      end if;

      if s.hours_since_last_exe is null then 
         s.hours_since_last_exe := sql_log_hours_since_last_exe(sqlid=>s.sql_id, forcematchingsignature=>s.force_matching_signature);
      end if;
      
      if s.sql_last_seen_in_days is null then
         s.sql_last_seen_in_days := sql_log_sql_last_seen_in_days(datetime=>sql_log_analyze_window.datetime, sqlid=>s.sql_id, forcematchingsignature=>s.force_matching_signature);
      end if;

      if s.plan_age_in_days is null then
         s.plan_age_in_days := sql_log_age_of_plan_in_days(datetime=>sql_log_analyze_window.datetime, plan_hash_value=>s.plan_hash_value);
      end if;
      
      s.faster_plans := sql_log_count_of_faster_plans(
         datetime=>s.datetime,
         elap_secs_per_exe=>s.elap_secs_per_exe,
         sql_log_id=>s.sql_log_id,
         plan_hash_value=>s.plan_hash_value,
         sqlid=>s.sql_id,
         forcematchingsignature=>s.force_matching_signature);
         
      s.slower_plans := sql_log_count_of_slower_plans(
         datetime=>s.datetime,
         elap_secs_per_exe=>s.elap_secs_per_exe,
         sql_log_id=>s.sql_log_id,
         plan_hash_value=>s.plan_hash_value,
         sqlid=>s.sql_id,
         forcematchingsignature=>s.force_matching_signature);
         
      s.elap_secs_per_exe_score := 0;
      if s.norm_elap_secs_per_exe > 0 then
         s.elap_secs_per_exe_score := round(s.elap_secs_per_exe/s.norm_elap_secs_per_exe*100);
      end if;
          
      update sql_log
         set elap_secs_per_exe_score = s.elap_secs_per_exe_score,
             executions_score = decode(norm_execs_per_hour, 0, 0, round(s.executions/s.norm_execs_per_hour*100)),
             pct_of_elap_secs_for_all_sql = round(decode(total_elap_secs, 0, 0, s.elapsed_seconds/total_elap_secs*100)),
             io_wait_secs_score = round(decode(s.norm_user_io_wait_secs, 0, 0, user_io_wait_secs / s.norm_user_io_wait_secs * 100)),
             sql_age_in_days = s.sql_age_in_days,
             sql_last_seen_in_days = s.sql_last_seen_in_days,
             faster_plans = s.faster_plans,
             slower_plans = s.slower_plans,
             plan_age_in_days = s.plan_age_in_days,
             norm_elap_secs_per_exe = round(s.norm_elap_secs_per_exe, 2),
             norm_execs_per_hour = round(s.norm_execs_per_hour, 2),
             norm_user_io_wait_secs = round(s.norm_user_io_wait_secs, 2),
             norm_rows_processed = round(s.norm_rows_processed),
             hours_since_last_exe = s.hours_since_last_exe
       where sql_log_id = s.sql_log_id;

      update sql_log 
         set sql_log_score = round(((s.elap_secs_per_exe_score/100)+(executions_score/100))*elapsed_seconds),
             sql_log_total_score = nvl(sql_log_total_score, 0) + round(((s.elap_secs_per_exe_score/100)+(executions_score/100))*elapsed_seconds),
             sql_log_score_count = nvl(sql_log_score_count, 0) + 1
       where sql_log_id = s.sql_log_id;

      update sql_log 
         set sql_log_avg_score = decode(sql_log_score_count, 0, 0, round(sql_log_total_score / sql_log_score_count)),
             sql_log_max_score = greatest(nvl(sql_log_max_score, sql_log_score), nvl(sql_log_score, sql_log_max_score)),
             sql_log_min_score = least(nvl(sql_log_min_score, sql_log_score), nvl(sql_log_score, sql_log_min_score))
       where sql_log_id = s.sql_log_id;
       
   end loop;
end;

procedure sql_log_analyze_sql_log_data (days_back number default 0) is
   cursor times_to_analyze (min_elap_secs number) is
   select distinct trunc(datetime, 'HH24') datetime
     from sql_log
    where elapsed_seconds > min_elap_secs 
      and (elap_secs_per_exe_score is null and datetime >= trunc(sysdate-days_back))
       or datetime >= trunc(sysdate, 'HH24');
begin
   for t in times_to_analyze (get_sql_log_analyze_min_secs) loop
      sql_log_analyze_window(datetime => trunc(t.datetime, 'HH24'));
   end loop;
end;

procedure run_sql_log_update is
   cursor busy_sql is
   -- Matches rows in both sets.
   select a.sql_id,
          a.sql_text,
          a.plan_hash_value,
          a.force_matching_signature,
          b.executions-a.executions executions,
          b.elapsed_time-a.elapsed_time elapsed_time,
          b.user_io_wait_time-a.user_io_wait_time user_io_wait_time,
          b.rows_processed-a.rows_processed rows_processed,
          b.cpu_time-a.cpu_time cpu_time,
          round((sysdate-a.insert_datetime)*24*60*60) secs_between_snaps,
          a.service,
          a.module,
          a.action
     from sql_snap a,
          sql_snap_view b
    where a.sql_id=b.sql_id
      and a.plan_hash_value=b.plan_hash_value
      and a.force_matching_signature=b.force_matching_signature
      -- ToDo: This is one second, need to change to a parameter everywhere.
      and b.elapsed_time-a.elapsed_time >= 1*1000000
      and b.executions-a.executions > 0
   union all
   -- These are new rows which are not in the snapshot.
   select a.sql_id,
          a.sql_text,
          a.plan_hash_value,
          a.force_matching_signature,
          a.executions,
          a.elapsed_time,
          a.user_io_wait_time,
          a.rows_processed,
          a.cpu_time,
          0,
          a.service,
          a.module,
          a.action
     from sql_snap_view a
    where a.elapsed_time >= 1*1000000
      and a.executions > 0
      and not exists (select 'x'
                        from sql_snap b
                       where a.sql_id=b.sql_id
                         and a.plan_hash_value=b.plan_hash_value
                         and a.force_matching_signature=b.force_matching_signature);
   n number;
   last_elap_secs_per_exe  number;
   
begin
   select count(*) into n from sql_snap where rownum < 2;
   if n = 0 then
      sql_log_take_snapshot;
   else
      for s in busy_sql loop

         update sql_log set
            executions=executions+s.executions,
            elapsed_seconds=round(elapsed_seconds+s.elapsed_time/1000000, 1),
            cpu_seconds=round(cpu_seconds+s.cpu_time/1000000, 1),
            rows_processed=rows_processed+s.rows_processed,
            user_io_wait_secs=round(user_io_wait_secs+s.user_io_wait_time/1000000, 1),
            update_time=sysdate,
            update_count=update_count+1,
            secs_between_snaps=s.secs_between_snaps,
            elap_secs_per_exe = round((elapsed_seconds+s.elapsed_time/1000000) / (executions+s.executions), 3),
            service = s.service,
            module = s.module,
            action = s.action
          where sql_id=s.sql_id
            and plan_hash_value=s.plan_hash_value
            and force_matching_signature=s.force_matching_signature
            and datetime=trunc(sysdate, 'HH24');
         
         if sql%rowcount = 0 then
            -- This is a new SQL and we need to insert it.
            insert into sql_log (
               sql_log_id, 
               sql_id, 
               sql_text, 
               plan_hash_value, 
               force_matching_signature, 
               datetime, 
               executions, 
               elapsed_seconds, 
               cpu_seconds, 
               user_io_wait_secs, 
               rows_processed, 
               update_count, 
               update_time, 
               elap_secs_per_exe, 
               secs_between_snaps,
               sql_log_score_count,
               sql_log_total_score,
               sql_log_avg_score,
               service,
               module,
               action) values (
               seq_sql_log_id.nextval, 
               s.sql_id, s.sql_text, 
               s.plan_hash_value, 
               s.force_matching_signature, 
               trunc(sysdate, 'HH24'), 
               s.executions, 
               round(s.elapsed_time/1000000, 1), 
               round(s.cpu_time/1000000, 1), 
               round(s.user_io_wait_time/1000000, 1), 
               s.rows_processed, 
               1, sysdate, 
               round(s.elapsed_time/1000000/s.executions, 3), 
               s.secs_between_snaps,
               0,
               0,
               null,
               s.service,
               s.module,
               s.action);
         end if;
         
         if s.executions = 0 then
            last_elap_secs_per_exe := 0;
         else
            last_elap_secs_per_exe := round(s.elapsed_time/1000000/s.executions, 3);
         end if;

         if last_elap_secs_per_exe < 2 then
            update sql_log set secs_0_1=round(secs_0_1+s.elapsed_time/1000000, 1) where sql_id=s.sql_id and plan_hash_value=s.plan_hash_value and force_matching_signature=s.force_matching_signature and datetime=trunc(sysdate, 'HH24');
         elsif last_elap_secs_per_exe < 6 then
            update sql_log set secs_2_5=round(secs_2_5+s.elapsed_time/1000000, 1) where sql_id=s.sql_id and plan_hash_value=s.plan_hash_value and force_matching_signature=s.force_matching_signature and datetime=trunc(sysdate, 'HH24');
         elsif last_elap_secs_per_exe < 11 then
            update sql_log set secs_6_10=round(secs_6_10+s.elapsed_time/1000000, 1) where sql_id=s.sql_id and plan_hash_value=s.plan_hash_value and force_matching_signature=s.force_matching_signature and datetime=trunc(sysdate, 'HH24');
         elsif last_elap_secs_per_exe < 61 then
            update sql_log set secs_11_60=round(secs_11_60+s.elapsed_time/1000000, 1) where sql_id=s.sql_id and plan_hash_value=s.plan_hash_value and force_matching_signature=s.force_matching_signature and datetime=trunc(sysdate, 'HH24');
         else
            update sql_log set secs_61_plus=round(secs_61_plus+s.elapsed_time/1000000, 1) where sql_id=s.sql_id and plan_hash_value=s.plan_hash_value and force_matching_signature=s.force_matching_signature and datetime=trunc(sysdate, 'HH24');
         end if;
      end loop;
      delete from sql_snap;
      sql_log_take_snapshot;
   end if;

   sql_log_analyze_sql_log_data;
   sql_log_save_active_sess_hist;

end;


function does_counter_exist (counter_group varchar2, subgroup varchar2, name varchar2) return boolean is 
   n number;
begin
   select count(*) into n 
     from counter 
    where counter_group=does_counter_exist.counter_group 
      and nvl(subgroup, '~')=nvl(does_counter_exist.subgroup, '~')
      and name=does_counter_exist.name;
   if n > 0 then 
      return true;
   else 
      return false;
   end if;
end;

procedure set_counter (counter_group varchar2, subgroup varchar2, name varchar2, equal number default null, add number default null, subtract number default null) is
begin
   if not does_counter_exist(counter_group=>set_counter.counter_group, subgroup=>set_counter.subgroup, name=>set_counter.name) then 
      insert into counter (
      id,
      counter_group,
      subgroup,
      name,
      value,
      update_time) values (
      seq_counter_id.nextval,
      set_counter.counter_group,
      set_counter.subgroup,
      set_counter.name,
      nvl(set_counter.equal, 0),
      sysdate);
   end if;
   update counter 
      set value=nvl(set_counter.equal, value)+nvl(set_counter.add, 0)-nvl(set_counter.subtract, 0),
          update_time = sysdate
    where counter_group=set_counter.counter_group 
      and nvl(subgroup, '~')=nvl(set_counter.subgroup, '~')
      and name=set_counter.name;
end;

procedure delete_counter (counter_group varchar2, subgroup varchar2, name varchar2) is
begin 
   if does_counter_exist(counter_group=>delete_counter.counter_group, subgroup=>delete_counter.subgroup, name=>delete_counter.name) then 
      delete from counter 
       where counter_group=delete_counter.counter_group 
         and nvl(subgroup, '~')=nvl(delete_counter.subgroup, '~')
         and name=delete_counter.name;
   end if;
end;

/* EVENTS */

procedure purge_events is 
/*
Purge records from audsid_event that are older than 4 hours.
>>> purge_events;
*/
   v_hours number;
begin
   v_hours := nvl(arcsql.get_config('purge_event_hours'), 4);
   delete from audsid_event where start_time < sysdate-v_hours/24;
end;

procedure start_event (event_group varchar2, subgroup varchar2, name varchar2) is 
/*
Start timing an event.
>>> start_event (event_group, subgroup, name);
-event_group: Event group (string). Required.
-subgroup: Event subgroup (string). Can be null.
-name: Event name (string). Unique within a event_group and sub_group.
*/
   v_audsid number := get_audsid;
   pragma autonomous_transaction;
begin 
   update audsid_event 
      set start_time=sysdate 
    where audsid=v_audsid
      and event_group=start_event.event_group
      and nvl(subgroup, '~')=nvl(start_event.subgroup, '~')
      and name=start_event.name;
   -- ToDo: If 1 we may need to log a "miss".
   if sql%rowcount = 0 then 
      insert into audsid_event (
         audsid,
         event_group,
         subgroup,
         name,
         start_time) values (
         v_audsid,
         start_event.event_group,
         start_event.subgroup,
         start_event.name,
         sysdate
         );
   end if;
   commit;
exception
   when others then
      rollback;
      raise;
end;

procedure stop_event (event_group varchar2, subgroup varchar2, name varchar2) is 
/*
Stop timing an event.
>>> stop_event (event_group, subgroup, name);
-event_group: Event group (string). Required.
-subgroup: Event subgroup (string). Can be null.
-name: Event name (string). Unique within a event_group and sub_group.
*/
   v_start_time date;
   v_stop_time date;
   v_elapsed_seconds number;
   v_audsid number := get_audsid;
   pragma autonomous_transaction;
begin 

   begin
      select start_time,
             sysdate stop_time,
             round((sysdate-start_time)*24*60*60, 3) elapsed_seconds
        into v_start_time,
             v_stop_time,
             v_elapsed_seconds
        from audsid_event 
       where audsid=v_audsid
         and event_group=stop_event.event_group
         and nvl(subgroup, '~')=nvl(stop_event.subgroup, '~')
         and name=stop_event.name;
   exception
      when no_data_found then 
         -- ToDo: Log the miss, do not raise error as it may break user's code.
         return;
   end;

   delete from audsid_event
    where audsid=v_audsid
      and event_group=stop_event.event_group
      and nvl(subgroup, '~')=nvl(stop_event.subgroup, '~')
      and name=stop_event.name;

   update event set 
      event_count=event_count+1,
      total_secs=total_secs+v_elapsed_seconds,
      last_start_time=v_start_time,
      last_end_time=v_stop_time
    where event_group=stop_event.event_group
      and nvl(subgroup, '~')=nvl(stop_event.subgroup, '~')
      and name=stop_event.name;

   if sql%rowcount = 0 then 
      insert into event (
         id,
         event_group,
         subgroup,
         name,
         event_count,
         total_secs,
         last_start_time,
         last_end_time) values (
         seq_event_id.nextval,
         stop_event.event_group,
         stop_event.subgroup,
         stop_event.name,
         1,
         v_elapsed_seconds,
         v_start_time,
         v_stop_time
         );
   end if;
   commit;
exception
   when others then
      rollback;
      raise;
end;

procedure delete_event (event_group varchar2, subgroup varchar2, name varchar2) is 
/*
Delete all references to an event.
>>> delete_event (event_group, subgroup, name);
-event_group: Event group (string). Required.
-subgroup: Event subgroup (string). Can be null.
-name: Event name (string). Unique within a event_group and sub_group.
*/
   pragma autonomous_transaction;
   v_audsid number := get_audsid;
begin 
   delete from event 
    where event_group=delete_event.event_group
      and nvl(subgroup, '~')=nvl(delete_event.subgroup, '~')
      and name=delete_event.name;
   commit;
exception
   when others then 
      rollback;
      raise;
end;

/* BUILT IN JOB WINDOWS */

procedure run is 
   n number;
begin 
   if not does_matching_job_exist('arcsql.run_every_1_minutes') then
      dbms_job.submit(n, 'arcsql.run_every_1_minutes;', sysdate+(1/1440), 'sysdate+(1/1440)');
   end if;
   if not does_matching_job_exist('arcsql.run_every_5_minutes') then
      dbms_job.submit(n, 'arcsql.run_every_5_minutes;', sysdate+(5/1440), 'sysdate+(5/1440)');
   end if;
   commit;
end;

procedure stop is 
begin 
   remove_matching_jobs('arcsql.run_every_');
   commit;
end;

procedure run_every_1_minutes is 
begin 
   set_counter(counter_group=>'arcsql', subgroup=>'task_scheduler', name=>'run_every_1_minutes', add=>1);
   commit;
end;

procedure run_every_5_minutes is 
begin 
   run_sql_log_update;
   purge_events;
   commit;
end;

/* LOGGING */

procedure log_interface (
   log_text in varchar2, 
   log_key in varchar2, 
   log_tags in varchar2,
   log_level in number,
   log_type in varchar2
   ) is 
   pragma autonomous_transaction;
begin
   if arcsql.log_level >= log_interface.log_level  then
      insert into arcsql_log (
      log_text,
      log_type,
      log_key,
      log_tags,
      audsid,
      username) values (
      log_interface.log_text,
      log_interface.log_type,
      log_interface.log_key,
      log_interface.log_tags,
      get_audsid,
      user);
      commit;
   end if;
end;

procedure log (log_text in varchar2, log_key in varchar2 default null, log_tags in varchar2 default null) is 
   pragma autonomous_transaction;
begin
   log_interface(log_text, log_key, log_tags, 0, 'log');
end;

procedure audit (audit_text in varchar2, audit_key in varchar2 default null, audit_tags in varchar2 default null) is 
   pragma autonomous_transaction;
begin
   log_interface(audit_text, audit_key, audit_tags, 0, 'audit');
end;

procedure err (error_text in varchar2, error_key in varchar2 default null, error_tags in varchar2 default null) is 
   pragma autonomous_transaction;
begin
   log_interface(error_text, error_key, error_tags, -1, 'error');
end;

procedure debug (debug_text in varchar2, debug_key in varchar2 default null, debug_tags in varchar2 default null) is 
   pragma autonomous_transaction;
begin
   log_interface(debug_text, debug_key, debug_tags, 1, 'debug');
   dbms_output.put_line('debug: '||debug_text);
end;

procedure debug2 (debug_text in varchar2, debug_key in varchar2 default null, debug_tags in varchar2 default null) is 
   pragma autonomous_transaction;
begin
   log_interface(debug_text, debug_key, debug_tags, 2, 'debug2');
   dbms_output.put_line('debug2: '||debug_text);
end;

procedure debug3 (debug_text in varchar2, debug_key in varchar2 default null, debug_tags in varchar2 default null) is 
   pragma autonomous_transaction;
begin
   log_interface(debug_text, debug_key, debug_tags, 3, 'debug3');
   dbms_output.put_line('debug3: '||debug_text);
end;

procedure alert (alert_text in varchar2, alert_key in varchar2 default null, alert_tags in varchar2 default null) is 
   pragma autonomous_transaction;
begin
   log_interface(alert_text, alert_key, alert_tags, -1, 'alert');
end;

procedure fail (fail_text in varchar2, fail_key in varchar2 default null, fail_tags in varchar2 default null) is 
   pragma autonomous_transaction;
begin
   log_interface(fail_text, fail_key, fail_tags, -1, 'fail');
end;

/* UNIT TESTING */

procedure pass_test is 
begin 
   test_passed := 1;
   test;
end;

procedure fail_test is 
begin 
   test_passed := 0;
   test;
   raise_application_error(-20001, '*** Unit Test Failure ***');
end;

procedure test is 
begin
   if test_passed = 1 then 
      dbms_output.put_line('passed: '||arcsql.test_name);
   elsif test_passed = 0 then 
      dbms_output.put_line('failed: '||arcsql.test_name);
      arcsql.fail(arcsql.test_name);
   elsif assert_true != true or assert_false != false or assert != true then
      dbms_output.put_line('failed: '||arcsql.test_name);
      arcsql.fail(arcsql.test_name);
   else 
      dbms_output.put_line('passed: '||arcsql.test_name);
   end if;
   init_test('unknown');
end;

procedure init_test(test_name varchar2) is 
begin
   arcsql.debug('init_test: '||test_name);
   test_passed := -1;
   assert := true;
   assert_true := true;
   assert_false := false;
   arcsql.test_name := init_test.test_name;
end;

end;
/

show errors
