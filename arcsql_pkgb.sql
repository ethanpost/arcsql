create or replace package body arcsql as

/* 
-----------------------------------------------------------------------------------
Datetime
-----------------------------------------------------------------------------------
*/

function secs_between_timestamps (time_start in timestamp, time_end in timestamp) return number is
   -- Return the number of seconds between two timestamps.
   -- Doing date math with date type is easy. This function tries to make it just as simple to 
   -- work with a timestamp.
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

procedure raise_invalid_cron_expression (p_expression in varchar2) is 
begin 
   null;
end;

/* 
-----------------------------------------------------------------------------------
Timer
-----------------------------------------------------------------------------------
*/

procedure start_timer(p_key in varchar2) is 
begin 
   -- Sets the timer variable to current time.
   g_timer_start(p_key) := sysdate;
end;

function get_timer(p_key in varchar2) return number is
   -- Returns seconds since last call to 'get_time' or 'start_time' (within the same session).
   r number;
begin 
   r := round((sysdate-nvl(g_timer_start(p_key), sysdate))*24*60*60, 1);
   g_timer_start(p_key) := sysdate;
   return r;
end;

/* 
-----------------------------------------------------------------------------------
Strings
-----------------------------------------------------------------------------------
*/

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
      arcsql.debug2('str_is_email: yes: '||text);
      return true;
  else 
      arcsql.debug2('str_is_email: no: '||text);
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
   -- Return true if the provided string evalutes to a number.
   x number;
begin
   x := to_number(text);
   return 'Y';
exception
   when others then
      return 'N';
end;

function str_complexity_check
   -- Return true if the complexity of 'text' meets the provided requirements.
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

procedure str_raise_complex_value (
   text varchar2, 
   allow_regex varchar2 default null) is 
   -- Raise error if value exceeds max len or contains anything but A-z, 0-9, and _(s).
   m varchar2(120);
   max_len number := 1000;
   s varchar2(1000);
begin 
   if length(text) > max_len then 
      m := 'Value is too long.';
      raise_application_error(-20001, m);
   end if;
   if allow_regex is not null then 
      s := regexp_replace(text, allow_regex);
   else 
      s := text;
   end if;
   m := 'Value contains invalid characters.';
   if regexp_replace(s, '[^0-9A-Za-z_]', '') != s then 
      raise_application_error(-20001, m);
   end if;
end;

function str_remove_text_between (
   p_text in varchar2,
   p_left_char in varchar2,
   p_right_char in varchar2) return varchar2 is 
   -- Removes everything between pairs of characters from a string.
   -- i.e. 'foo [x] bar [y]' becomes 'foo bar'.
   start_pos number;
   end_pos number;
   left_side varchar2(2000);
   right_side varchar2(2000);
   v_text varchar2(2000) := p_text;
begin 
   while instr(v_text, p_left_char) > 0 and instr(v_text, p_right_char) > 0 loop 
      start_pos := instr(v_text, '[');
      end_pos := instr(v_text, ']');
      left_side := rtrim(substr(v_text, 1, start_pos-1));
      right_side := ltrim(substr(v_text, end_pos+1));
      v_text := left_side||' '||right_side;
   end loop;
   return v_text;
end;

function get_token (
   p_list  varchar2,
   p_index number,
   p_delim varchar2 := ',') return varchar2 is 
   -- Return a single member of a list in the form of 'a,b,c'.
   -- Largely taken from https://glosoli.blogspot.com/2006/07/oracle-plsql-function-to-split-strings.html.
   start_pos number;
   end_pos   number;
begin
   if p_index = 1 then
       start_pos := 1;
   else
       start_pos := instr(p_list, p_delim, 1, p_index - 1);
       if start_pos = 0 then
           return null;
       else
           start_pos := start_pos + length(p_delim);
       end if;
   end if;

   end_pos := instr(p_list, p_delim, start_pos, 1);

   if end_pos = 0 then
       return substr(p_list, start_pos);
   else
       return substr(p_list, start_pos, end_pos - start_pos);
   end if;
exception
   when others then
      raise;
end get_token;

function shift_list (
   p_list in varchar2,
   p_token in varchar2 default ',',
   p_shift_count in number default 1,
   p_max_items in number default null) return varchar2 is 
   token_count number;
   v_list varchar2(1000) := trim(p_list);
   v_shift_count number := p_shift_count;
begin 
   if p_list is null or 
      length(trim(p_list)) = 0 then
      return null;
   end if;
   if not p_max_items is null then 
      token_count := regexp_count(v_list, p_token);
      v_shift_count := (token_count + 1) - p_max_items;
   end if;
   if v_shift_count <= 0 then 
      return trim(v_list);
   end if;
   for i in 1 .. v_shift_count loop 
      token_count := regexp_count(v_list, p_token);
      if token_count = 0 then 
         return null;
      else 
         v_list := substr(v_list, instr(v_list, p_token)+1);
      end if;
   end loop;
   return trim(v_list);
end;

/* 
-----------------------------------------------------------------------------------
Numbers
-----------------------------------------------------------------------------------
*/

function num_get_variance_pct (
      p_val number,
      p_pct_chance number,
      p_change_low_pct number,
      p_change_high_pct number,
      p_decimals number default 0) return number is 
   p_new_val number;
begin
   arcsql.debug2('num_get_variance_pct: '||p_val||','||p_pct_chance||','||p_change_low_pct||','||p_change_high_pct||','||p_decimals);
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
   arcsql.debug2('num_get_variance: '||p_val||','||p_pct_chance||','||p_change_low||','||p_change_high||','||p_decimals);
   if dbms_random.value(1,100) > p_pct_chance then 
      return p_val;
   end if;
   p_new_val := p_val + round(dbms_random.value(p_change_low, p_change_high), p_decimals);
   return round(p_new_val, p_decimals);
end;

/* 
-----------------------------------------------------------------------------------
Utilities
-----------------------------------------------------------------------------------
*/

function is_truthy (p_val in varchar2) return boolean is 
begin
   if lower(p_val) in ('y','yes', '1', 'true') then
      return true;
   elsif instr(p_val, ' ') > 0 then 
      if cron_match(p_val) then 
         return true;
      end if;
   end if;
   return false;
end;

function is_truthy_y (p_val in varchar2) return varchar2 is 
begin 
   if is_truthy(p_val) then 
      return 'y';
   else 
      return 'n';
   end if;
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

/* 

APPLICATION VERSIONING 

Write and read the version you are on, going to, coming from. 

Helpful for maintaining conditional idempotent upgrade paths.

STATUS can be 'SET' or 'CONFIRMED'. SET indicates we are in the middle of a patch or 
upgrade and CONFIRMED indicates successful. get_app_version always returns the 
last confirmed version, not the version you are attempting to upgrade/patch to.

confirm_app_version must be preceded by set_app_version. You can also call 
set_app_version with p_confirmed=True which immediately sets the status to CONFIRMED.

ToDo: 

- Add logging for failure and success using the logging interface.
- (Unlikely) - Track errors using system wide trigger interface (not built) and report.

*/

procedure set_app_version(
   p_app_name in varchar2, 
   p_version in number,
   p_confirm in boolean := false) is 
   -- Set status to 'SET' or 'CONFIRMED' and set version you are attempting to patch/upgrade too.
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
exception 
   when others then 
      rollback;
      raise;
end;

procedure confirm_app_version(p_app_name in varchar2) is
   -- Sets the status of the app version to 'CONFIRMED'.
   pragma autonomous_transaction;
begin
   update app_version 
      set status='CONFIRMED'
    where app_name=upper(p_app_name);
   commit;
exception 
   when others then 
      rollback;
      raise;
end;

function get_app_version(p_app_name in varchar2) return number is 
   -- Returns the last 'confirmed' version.
   v_version number;
begin
   select decode(status, 'SET', last_version, 'CONFIRMED', version)
     into v_version
     from app_version 
    where app_name=upper(p_app_name);
    return v_version;
end;

function get_new_version(p_app_name in varchar2) return number is 
   -- Returns the version you are currently patching or upgrading too.
   v_version number;
begin 
   select version
     into v_version
     from app_version 
    where app_name=upper(p_app_name);
    return v_version;
end;

procedure delete_app_version(p_app_name in varchar2) is 
   -- Deletes the reference to the app from the APP_VERSION table.
   pragma autonomous_transaction;
begin 
  delete from app_version where app_name=upper(p_app_name);
  commit;
exception 
   when others then 
      rollback;
      raise;
end;

/* 
-----------------------------------------------------------------------------------
Key/Value Database
-----------------------------------------------------------------------------------
*/

procedure cache (
   cache_key varchar2, 
   p_value varchar2) is
   l_value varchar2(4000);
begin

   if not does_cache_key_exist(cache_key) then
      insert into arcsql_cache (key) values (cache_key);
   end if;

   if length(p_value) > 4000 then
      l_value := substr(p_value, 1, 4000);
   end if;

   update arcsql_cache 
      set value=p_value,
          update_time=sysdate
    where key=lower(cache_key);
end;

procedure cache_date (
   cache_key varchar2, 
   p_date date) is
   l_value varchar2(4000);
begin

   if not does_cache_key_exist(cache_key) then
      insert into arcsql_cache (key) values (cache_key);
   end if;

   update arcsql_cache 
      set date_value=p_date,
          update_time=sysdate
    where key=lower(cache_key);

end;

procedure cache_num (
   cache_key varchar2, 
   p_num number) is
begin

   if not does_cache_key_exist(cache_key) then
      insert into arcsql_cache (key) values (cache_key);
   end if;

   update arcsql_cache 
      set num_value=p_num,
          update_time=sysdate
    where key=lower(cache_key);
    
end;

function get_cache (cache_key in varchar2) return varchar2 is 
   r varchar2(4000);
begin
   if does_cache_key_exist(cache_key) then 
      select value into r from arcsql_cache where key=lower(cache_key);
   else 
      r := null; 
   end if;
   return r;
end;

function get_cache_date (cache_key varchar2) return date is 
   r date;
begin 
   if does_cache_key_exist(cache_key) then 
      select date_value into r from arcsql_cache where key=lower(cache_key);
      return r;
   else 
      return null;
   end if;
end;

function get_cache_num (cache_key varchar2) return number is 
   r number;
begin 
   if does_cache_key_exist(cache_key) then 
      select num_value into r from arcsql_cache where key=lower(cache_key);
      return r;
   else 
      return null;
   end if;
end;

function does_cache_key_exist (cache_key varchar2) return boolean is
   n number;
begin
   select count(*) into n
     from arcsql_cache
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
   delete from arcsql_cache
    where key=lower(cache_key);
end;

/* 
-----------------------------------------------------------------------------------
Configuration
-----------------------------------------------------------------------------------
*/

function get_setting(setting_name varchar2) return varchar2 deterministic is 
   v varchar2(1000) := null;
   x varchar2(1000) := null;
   s varchar2(1000);
   v_setting_name varchar2(120) := lower(setting_name);
begin 
   str_raise_complex_value(v_setting_name);
   v := get_config(v_setting_name);
   if not v is null then 
      return v;
   end if;
   s := 'begin :x := arcsql_private_settings.'||setting_name||'; end;';
   begin 
      execute immediate s using out v;
      if not v is null then 
         return v;
      end if;
   exception
      when others then 
         null;
   end;
   s := 'begin :x := arcsql_public_settings.'||setting_name||'; end;';
   begin 
      execute immediate s using out v;
      if not v is null then 
         return v;
      end if;
   exception
      when others then 
         null;
   end;
   raise_application_error(-20001,'get_setting: '||setting_name||' not found.');
end;

procedure remove_config (name varchar2) is
begin
   delete from arcsql_config where name=remove_config.name;
end;

procedure add_config (name varchar2, value varchar2, description varchar2 default null) is
begin
   -- DO NOT MODIFY IF EXISTS! Update to self.
   update arcsql_config set value=value where name=lower(add_config.name);
   -- If nothing happened we need to add it.
   if sql%rowcount = 0 then
      insert into arcsql_config (name, value, description)
        values (lower(add_config.name), add_config.value, description);
   end if;
end;

procedure set_config (name varchar2, value varchar2) is
begin
   update arcsql_config set value=set_config.value where name=lower(set_config.name);
   if sql%rowcount = 0 then
      add_config(set_config.name, set_config.value);
   end if;
end;

function get_config (name varchar2) return varchar2 is
   config_value varchar2(1000);
begin
   select value into config_value from arcsql_config where name=lower(get_config.name);
   return config_value;
exception
   when no_data_found then
      return null;
end;

/* 
-----------------------------------------------------------------------------------
SQL Monitoring
-----------------------------------------------------------------------------------
*/

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
   n := to_number(arcsql.get_setting('sql_log_sql_text_length'));
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

      if nvl(arcsql.get_cache('sql_log_last_active_sql_hist_update'), 'x') != to_char(sysdate, 'YYYYMMDDHH24') then

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
   v_sql_log sql_log%rowtype;
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

            -- Try to load previous record if it exist.
            select max(datetime) into v_sql_log.datetime 
              from sql_log
             where sql_id=s.sql_id 
               and plan_hash_value=s.plan_hash_value 
               and force_matching_signature=s.force_matching_signature 
               and datetime!=trunc(sysdate, 'HH24');

            if not v_sql_log.datetime  is null then 
               select * into v_sql_log
                 from sql_log 
                where sql_id=s.sql_id 
                  and plan_hash_value=s.plan_hash_value 
                  and force_matching_signature=s.force_matching_signature 
                  and datetime=v_sql_log.datetime;
               v_sql_log.rolling_avg_score := shift_list(
                  p_list=>v_sql_log.rolling_avg_score,
                  p_token=>',',
                  p_max_items=>24) || ',' || to_char(v_sql_log.sql_log_avg_score);
            else 
               v_sql_log.rolling_avg_score := null;
            end if;

            -- This is a new SQL or new hour and we need to insert it.
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
               rolling_avg_score,
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
               v_sql_log.rolling_avg_score,
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

/* 
-----------------------------------------------------------------------------------
Counters
-----------------------------------------------------------------------------------
*/

function does_counter_exist (
   counter_group varchar2, 
   subgroup varchar2, 
   name varchar2) return boolean is 
   n number;
begin
   select count(*) into n 
     from arcsql_counter 
    where counter_group=does_counter_exist.counter_group 
      and nvl(subgroup, '~')=nvl(does_counter_exist.subgroup, '~')
      and name=does_counter_exist.name;
   if n > 0 then 
      return true;
   else 
      return false;
   end if;
end;

procedure set_counter (
  counter_group varchar2, 
  subgroup varchar2, 
  name varchar2, 
  equal number default null, 
  add number default null, 
  subtract number default null) is
begin
   if not does_counter_exist(counter_group=>set_counter.counter_group, subgroup=>set_counter.subgroup, name=>set_counter.name) then 
      insert into arcsql_counter (
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
   update arcsql_counter 
      set value=nvl(set_counter.equal, value)+nvl(set_counter.add, 0)-nvl(set_counter.subtract, 0),
          update_time = sysdate
    where counter_group=set_counter.counter_group 
      and nvl(subgroup, '~')=nvl(set_counter.subgroup, '~')
      and name=set_counter.name;
end;

procedure delete_counter (
  counter_group varchar2, 
  subgroup varchar2, 
  name varchar2) is
begin 
   if does_counter_exist(counter_group=>delete_counter.counter_group, subgroup=>delete_counter.subgroup, name=>delete_counter.name) then 
      delete from arcsql_counter 
       where counter_group=delete_counter.counter_group 
         and nvl(subgroup, '~')=nvl(delete_counter.subgroup, '~')
         and name=delete_counter.name;
   end if;
end;

/* 
 -----------------------------------------------------------------------------------
 Events

 Records event durations in 
 -----------------------------------------------------------------------------------
 */

procedure purge_events is 
/*
Purge records from audsid_event that are older than 4 hours.
>>> purge_events;
*/
   v_hours number;
begin
   v_hours := get_setting('purge_event_hours');
   delete from audsid_event where start_time < sysdate-v_hours/24;
end;

procedure start_event (
   event_group in varchar2, 
   subgroup in varchar2, 
   name in varchar2) is 
-- Start an event timer (autonomous transaction).
-- event_group: Event group (string). Required.
-- subgroup: Event subgroup (string). Can be null.
-- name: Event name (string). Unique within a event_group/sub_group.
   v_audsid number := get_audsid;
   pragma autonomous_transaction;
begin 
   update audsid_event 
      set start_time=sysdate 
    where audsid=v_audsid
      and event_group=start_event.event_group
      and nvl(subgroup, 'x')=nvl(start_event.subgroup, 'x')
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

procedure stop_event (
   event_group in varchar2, 
   subgroup in varchar2, 
   name in varchar2) is 
-- Stop timing an event.
   v_start_time date;
   v_stop_time date;
   v_elapsed_seconds number;
   v_audsid number := get_audsid;
   pragma autonomous_transaction;
begin 
   -- Figure out the amount of time elapsed.
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
         and nvl(subgroup, 'x')=nvl(stop_event.subgroup, 'x')
         and name=stop_event.name;
   exception
      when no_data_found then 
         -- ToDo: Log the miss, do not raise error as it may break user's code.
         return;
   end;

   -- Delete the reference we use to calc elap time for this event/session.
   delete from audsid_event
    where audsid=v_audsid
      and event_group=stop_event.event_group
      and nvl(subgroup, 'x')=nvl(stop_event.subgroup, 'x')
      and name=stop_event.name;

   -- Update the consolidated record in the arcsql_event table.
   update arcsql_event set 
      event_count=event_count+1,
      total_secs=total_secs+v_elapsed_seconds,
      last_start_time=v_start_time,
      last_end_time=v_stop_time
    where event_group=stop_event.event_group
      and nvl(subgroup, '~')=nvl(stop_event.subgroup, '~')
      and name=stop_event.name;

   if sql%rowcount = 0 then 
      insert into arcsql_event (
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

procedure delete_event (
   event_group in varchar2, 
   subgroup in varchar2, 
   name in varchar2) is 
-- Delete event data.
   pragma autonomous_transaction;
   v_audsid number := get_audsid;
begin 
   delete from arcsql_event 
    where event_group=delete_event.event_group
      and nvl(subgroup, 'x')=nvl(delete_event.subgroup, 'x')
      and name=delete_event.name;
   commit;
exception
   when others then 
      rollback;
      raise;
end;

/* 
-----------------------------------------------------------------------------------
Task Scheduling
-----------------------------------------------------------------------------------
*/

procedure start_arcsql is 
   cursor tasks is 
   select * from all_scheduler_jobs 
    where job_name like 'ARCSQL%';
begin 
   for task in tasks loop 
      dbms_scheduler.enable(task.job_name);
   end loop;
   commit;
end;

procedure stop_arcsql is 
   cursor tasks is 
   select * from all_scheduler_jobs 
    where job_name like 'ARCSQL%';
begin 
   for task in tasks loop 
      dbms_scheduler.disable(task.job_name);
   end loop;
   commit;
end;

/* 
-----------------------------------------------------------------------------------
Logging
-----------------------------------------------------------------------------------
*/

procedure set_log_type (p_log_type in varchar2) is 
begin 
   select * into g_log_type from arcsql_log_type
    where log_type=p_log_type;
end;

procedure raise_log_type_not_set is 
begin 
   if g_log_type.log_type is null then  
      raise_application_error(-20001, 'Log type is not set.');
   end if;
end;

function does_log_type_exist (p_log_type in varchar2) return boolean is 
   n number;
begin 
   select count(*) into n from arcsql_log_type 
    where lower(log_type)=lower(p_log_type);
   if n = 0 then 
      return false;
   else 
      return true;
   end if;
end;

procedure log_interface (
   p_text in varchar2, 
   p_key in varchar2, 
   p_tags in varchar2,
   p_level in number,
   p_type in varchar2,
   p_metric_name_1 in varchar2 default null,
   p_metric_1 in number default null,
   p_metric_name_2 in varchar2 default null,
   p_metric_2 in number default null
   ) is 
   pragma autonomous_transaction;
begin
   if not does_log_type_exist(p_type) then 
      insert into arcsql_log_type (
         log_type) values (
         lower(p_type));
   end if;
   if arcsql.log_level >= p_level  then
      insert into arcsql_log (
      log_text,
      log_type,
      log_key,
      log_tags,
      audsid,
      username,
      metric_name_1,
      metric_1,
      metric_name_2,
      metric_2) values (
      p_text,
      lower(p_type),
      p_key,
      p_tags,
      get_audsid,
      user,
      p_metric_name_1,
      p_metric_1,
      p_metric_name_2,
      p_metric_2);
      commit;
   end if;
   commit;
exception 
   when others then 
      rollback;
      raise;
end;

procedure log (
   log_text in varchar2, 
   log_key in varchar2 default null, 
   log_tags in varchar2 default null,
   log_type in varchar2 default 'log',
   metric_name_1 in varchar2 default null,
   metric_1 in number default null,
   metric_name_2 in varchar2 default null,
   metric_2 in number default null) is 
begin
   log_interface(
      p_text=>log_text, 
      p_key=>log_key, 
      p_tags=>log_tags, 
      p_level=>0, 
      p_type=>log_type,
      p_metric_name_1=>metric_name_1,
      p_metric_1=>metric_1,
      p_metric_name_2=>metric_name_2,
      p_metric_2=>metric_2);
end;

procedure notify (
   notify_text in varchar2, 
   notify_key in varchar2 default null, 
   notify_tags in varchar2 default null,
   metric_name_1 in varchar2 default null,
   metric_1 in number default null,
   metric_name_2 in varchar2 default null,
   metric_2 in number default null) is 
begin
   log_interface(
      p_text=>notify_text, 
      p_key=>notify_key, 
      p_tags=>notify_tags, 
      p_level=>0, 
      p_type=>'notify',
      p_metric_name_1=>metric_name_1,
      p_metric_1=>metric_1,
      p_metric_name_2=>metric_name_2,
      p_metric_2=>metric_2);
end;

procedure audit (
   audit_text in varchar2, 
   audit_key in varchar2 default null, 
   audit_tags in varchar2 default null,
   metric_name_1 in varchar2 default null,
   metric_1 in number default null,
   metric_name_2 in varchar2 default null,
   metric_2 in number default null) is 
begin
   log_interface(
      p_text=>audit_text, 
      p_key=>audit_key, 
      p_tags=>audit_tags, 
      p_level=>0, 
      p_type=>'audit',
      p_metric_name_1=>metric_name_1,
      p_metric_1=>metric_1,
      p_metric_name_2=>metric_name_2,
      p_metric_2=>metric_2);
end;

procedure err (
   error_text in varchar2, 
   error_key in varchar2 default null, 
   error_tags in varchar2 default null,
   metric_name_1 in varchar2 default null,
   metric_1 in number default null,
   metric_name_2 in varchar2 default null,
   metric_2 in number default null) is 
begin
   log_interface(
      p_text=>error_text, 
      p_key=>error_key, 
      p_tags=>error_tags, 
      p_level=>-1, 
      p_type=>'error',
      p_metric_name_1=>metric_name_1,
      p_metric_1=>metric_1,
      p_metric_name_2=>metric_name_2,
      p_metric_2=>metric_2);
end;

procedure debug (
   debug_text in varchar2, 
   debug_key in varchar2 default null, 
   debug_tags in varchar2 default null,
   metric_name_1 in varchar2 default null,
   metric_1 in number default null,
   metric_name_2 in varchar2 default null,
   metric_2 in number default null) is 
begin
   log_interface(
      p_text=>debug_text, 
      p_key=>debug_key, 
      p_tags=>debug_tags, 
      p_level=>1, 
      p_type=>'debug',
      p_metric_name_1=>metric_name_1,
      p_metric_1=>metric_1,
      p_metric_name_2=>metric_name_2,
      p_metric_2=>metric_2);
end;

procedure debug2 (
   debug_text in varchar2, 
   debug_key in varchar2 default null, 
   debug_tags in varchar2 default null,
   metric_name_1 in varchar2 default null,
   metric_1 in number default null,
   metric_name_2 in varchar2 default null,
   metric_2 in number default null) is 
begin
   log_interface(
      p_text=>debug_text, 
      p_key=>debug_key, 
      p_tags=>debug_tags, 
      p_level=>2, 
      p_type=>'debug2',
      p_metric_name_1=>metric_name_1,
      p_metric_1=>metric_1,
      p_metric_name_2=>metric_name_2,
      p_metric_2=>metric_2);
end;

procedure debug3 (
   debug_text in varchar2, 
   debug_key in varchar2 default null, 
   debug_tags in varchar2 default null,
   metric_name_1 in varchar2 default null,
   metric_1 in number default null,
   metric_name_2 in varchar2 default null,
   metric_2 in number default null) is 
begin
   log_interface(
      p_text=>debug_text, 
      p_key=>debug_key, 
      p_tags=>debug_tags, 
      p_level=>3, 
      p_type=>'debug3',
      p_metric_name_1=>metric_name_1,
      p_metric_1=>metric_1,
      p_metric_name_2=>metric_name_2,
      p_metric_2=>metric_2);
end;

procedure fail (
   fail_text in varchar2, 
   fail_key in varchar2 default null, 
   fail_tags in varchar2 default null,
   metric_name_1 in varchar2 default null,
   metric_1 in number default null,
   metric_name_2 in varchar2 default null,
   metric_2 in number default null) is 
begin
   log_interface(
      p_text=>fail_text, 
      p_key=>fail_key, 
      p_tags=>fail_tags, 
      p_level=>-1, 
      p_type=>'fail',
      p_metric_name_1=>metric_name_1,
      p_metric_1=>metric_1,
      p_metric_name_2=>metric_name_2,
      p_metric_2=>metric_2);
end;

procedure sms (
   sms_text in varchar2, 
   sms_key in varchar2 default null, 
   sms_tags in varchar2 default null) is 
begin
   log_interface(
      p_text=>sms_text, 
      p_key=>sms_key, 
      p_tags=>sms_tags, 
      p_level=>0, 
      p_type=>'sms');
end;

/* 
-----------------------------------------------------------------------------------
Contact Groups
-----------------------------------------------------------------------------------
*/

procedure set_contact_group (p_group_name in varchar2) is 
begin 
   select * into g_contact_group from arcsql_contact_group where group_name=p_group_name;
end;

procedure raise_contact_group_not_set is 
begin 
   if g_contact_group.group_name is null then  
      raise_application_error(-20001, 'Contact group is not set.');
   end if;
end;

function is_sms_possible return boolean is 
   n number;
begin 
   raise_contact_group_not_set;
   select count(*) into n from arcsql_contact_group 
    where group_name=g_contact_group.group_name 
      and not sms_addresses is null 
      and is_truthy_y(is_group_enabled)='y' 
      and is_truthy_y(is_sms_disabled)='n'
      and is_truthy_y(is_group_on_hold)='n';
   if n > 0 then 
      debug('is_sms_possible: true');
      return true;
   else 
      debug('is_sms_possible: false');
      return false;
   end if;
end;

function is_email_possible return boolean is 
   n number;
begin 
   raise_contact_group_not_set;
   select count(*) into n from arcsql_contact_group 
    where group_name=g_contact_group.group_name 
      and not email_addresses is null 
      and is_truthy_y(is_group_enabled)='y' 
      and is_truthy_y(is_group_on_hold)='n';
   if n > 0 then 
      debug('is_email_possible: true');
      return true;
   else 
      debug('is_email_possible: false');
      return false;
   end if;
end;

function has_sms_messages return boolean is 
   n number;
   sql_text varchar2(1000);
begin
   raise_contact_group_not_set;
   sql_text := '
   select count(*) 
     from '||nvl(g_contact_group.view_name, 'arcsql_log')||' '||'
     where log_time > :b1 and
           log_type in (select log_type from arcsql_log_type where arcsql.is_truthy_y(sends_sms)=''y'')';
   execute immediate sql_text into n using nvl(g_contact_group.last_checked, sysdate);
   if n > 0 then 
      debug('has_sms_messages: true');
      return true;
   else 
      debug('has_sms_messages: false');
      return false;
   end if;
end;

function has_email_messages return boolean is 
   n number;
   sql_text varchar2(1000);
begin
   raise_contact_group_not_set;
   sql_text := '
   select count(*) 
     from '||nvl(g_contact_group.view_name, 'arcsql_log')||' '||'
     where log_time > :b1 and
           log_type in (select log_type from arcsql_log_type where arcsql.is_truthy_y(sends_email)=''y'')';
   execute immediate sql_text into n using nvl(g_contact_group.last_checked, sysdate);
   if n > 0 then 
      debug('has_email_messages: true');
      return true;
   else 
      debug('has_email_messages: false');
      return false;
   end if;
end;

procedure send_sms_messages is 
   type ctype is ref cursor;
   c ctype;
   n arcsql_log%rowtype;
begin 
   debug('Entering send_sms_messages.');
   raise_contact_group_not_set;
   open c for '
   select * from '||nvl(g_contact_group.view_name, 'arcsql_log')||'
    where log_time > :b1 and
          log_type not like ''debug%'' and 
          log_type in (select log_type from arcsql_log_type 
                        where arcsql.is_truthy_y(sends_sms)=''y'')' using g_contact_group.last_checked;
   loop
      fetch c into n;
         exit when c%notfound;
         arcsql.debug('send_sms_messages: '||n.log_entry);
   end loop;
   update arcsql_contact_group set last_checked=sysdate where group_name=g_contact_group.group_name;
   commit;
end;

procedure send_email_messages is 
   type ctype is ref cursor;
   c ctype;
   n arcsql_log%rowtype;
begin 
   debug('Entering send_email_messages.');
   raise_contact_group_not_set;
   open c for '
   select * from '||nvl(g_contact_group.view_name, 'arcsql_log')||'
    where log_time > :b1 and
          log_type not like ''debug%'' and 
          log_type in (select log_type from arcsql_log_type 
                        where arcsql.is_truthy_y(sends_email)=''y'' or 
                              arcsql.is_truthy_y(sends_sms)=''y'')' using g_contact_group.last_checked;
   loop
      fetch c into n;
         exit when c%notfound;
         arcsql.debug('send_email_messages: '||n.log_entry);
   end loop;
   update arcsql_contact_group set last_checked=sysdate where group_name=g_contact_group.group_name;
   commit;
end;

procedure check_contact_groups is 
   cursor contact_groups is 
   select * from arcsql_contact_group;

   function is_max_queue_secs return boolean is 
      v_queue_secs number;
   begin 
      select round((sysdate-min(log_time))/1440)
        into v_queue_secs
        from arcsql_log 
       where log_time > g_contact_group.last_checked;
      if v_queue_secs >= g_contact_group.max_queue_secs then 
         debug('is_max_queue_secs: true');
         return true;
      else 
         debug('is_max_queue_secs: false');
         return false;
      end if;
   end;

   function is_max_idle_secs return boolean is 
      v_idle_secs number;
   begin 
      select round((sysdate-max(log_time))/1440)
        into v_idle_secs
        from arcsql_log 
       where log_time > g_contact_group.last_checked;
      if v_idle_secs >= g_contact_group.max_idle_secs then 
         debug('is_max_idle_secs: true');
         return true;
      else 
         debug('is_max_idle_secs: false');
         return false;
      end if;
   end;

   function is_max_count return boolean is 
      v_count number;
   begin 
      select count(*)
        into v_count
        from arcsql_log 
       where log_time > g_contact_group.last_checked;
      if v_count >= g_contact_group.max_count then 
         debug('is_max_count: true');
         return true;
      else 
         debug('is_max_count: false');
         return false;
      end if;
   end;

begin 
   for contact_group in contact_groups loop 
      set_contact_group(contact_group.group_name);
      debug('Checking contact group '||contact_group.group_name);
      if is_sms_possible and has_sms_messages then 
         send_sms_messages;
         send_email_messages;
      elsif is_email_possible and has_email_messages and (is_max_queue_secs or is_max_idle_secs or is_max_count) then
         send_email_messages;
      end if;
   end loop;
end;

/* 
-----------------------------------------------------------------------------------
Unit Testing
-----------------------------------------------------------------------------------
*/

procedure pass_test is 
begin 
   test_passed := 1;
   test;
end;

procedure fail_test(fail_message in varchar2 default null) is 
begin 
   test_passed := 0;
   test;
   raise_application_error(-20001, '*** Failure *** '||fail_message);
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
   test_passed := -1;
   assert := true;
   assert_true := true;
   assert_false := false;
   arcsql.test_name := init_test.test_name;
end;

 /* 
 -----------------------------------------------------------------------------------
 Application Test Framework
 -----------------------------------------------------------------------------------
 */

function app_test_profile_not_set return boolean is 
begin 
   if g_app_test_profile.profile_name is null then 
      return true;
   else 
      return false;
   end if;
end;

procedure add_app_test_profile (
   p_profile_name in varchar2,
   p_env_type in varchar2 default null,
   p_is_default in varchar2 default 'N',
   p_test_interval in number default 0,
   p_recheck_interval in number default 0,
   p_retry_count in number default 0,
   p_retry_interval in number default 0,
   p_retry_log_type in varchar2 default 'retry',
   p_failed_log_type in varchar2 default 'warning',
   p_reminder_interval in number default 60,
   p_reminder_log_type in varchar2 default 'warning',
   -- Interval is multiplied by this # each time a reminder is sent to set the next interval.
   p_reminder_backoff in number default 1,
   p_abandon_interval in varchar2 default null,
   p_abandon_log_type in varchar2 default 'abandon',
   p_abandon_reset in varchar2 default 'N',
   p_pass_log_type in varchar2 default 'passed'
   ) is
begin
   if not does_app_test_profile_exist(p_profile_name, p_env_type) then
      g_app_test_profile := null;
      g_app_test_profile.profile_name := p_profile_name;
      g_app_test_profile.env_type := p_env_type;
      g_app_test_profile.is_default := p_is_default;
      g_app_test_profile.test_interval := p_test_interval;
      g_app_test_profile.recheck_interval := p_recheck_interval;
      g_app_test_profile.retry_count := p_retry_count;
      g_app_test_profile.retry_interval := p_retry_interval;
      g_app_test_profile.retry_log_type := p_retry_log_type;
      g_app_test_profile.failed_log_type := p_failed_log_type;
      g_app_test_profile.reminder_interval := p_reminder_interval;
      g_app_test_profile.reminder_log_type := p_reminder_log_type;
      g_app_test_profile.reminder_backoff := p_reminder_backoff;
      g_app_test_profile.abandon_interval := p_abandon_interval;
      g_app_test_profile.abandon_log_type := p_abandon_log_type;
      g_app_test_profile.abandon_reset := p_abandon_reset;
      g_app_test_profile.pass_log_type := p_pass_log_type;
      save_app_test_profile;
   end if;
end;

procedure set_app_test_profile (
   p_profile_name in varchar2 default null,
   p_env_type in varchar2 default null) is 
   -- Set g_app_test_profile. If env type not found try where env type is null.
   n number;
   
   function set_exact_app_profile return boolean is 
   -- Match profile name and env type (could be null).
   begin 
      select * into g_app_test_profile 
        from app_test_profile 
       where profile_name=p_profile_name 
         and nvl(env_type, 'x')=nvl(p_env_type, 'x');
      return true;
   exception 
      when others then 
         return false;
   end;

   function set_default_app_profile return boolean is 
   -- Match default profile if configured.
   begin 
      select * into g_app_test_profile 
        from app_test_profile 
       where is_default='Y'
         and 'x'=nvl(p_profile_name, 'x')
         and 'x'=nvl(p_env_type, 'x');
      return true;
   exception 
      when others then 
         return false;
   end;

begin 
   if set_exact_app_profile then 
      return;
   end if;
   if set_default_app_profile then 
      return;
   end if;
   raise_application_error('-20001', 'Matching app profile not found.');
end;

procedure raise_app_test_profile_not_set is 
begin 
   if app_test_profile_not_set then 
      raise_application_error('-20001', 'Application test profile not set.');
   end if;
end;

procedure save_app_test_profile is 
  pragma autonomous_transaction;
begin  
   raise_app_test_profile_not_set;

   -- Each env type can only have one default profile associated with it.
   if g_app_test_profile.is_default='Y' then 
      update app_test_profile set is_default='N'
       where is_default='Y' 
         and nvl(env_type, 'x')=nvl(g_app_test_profile.env_type, 'x');
   end if;

   update app_test_profile set row=g_app_test_profile 
    where profile_name=g_app_test_profile.profile_name
      and nvl(env_type, 'x')=nvl(g_app_test_profile.env_type, 'x');

   if sql%rowcount = 0 then 
      insert into app_test_profile values g_app_test_profile;
   end if;

   commit;
exception 
   when others then 
      rollback;
      raise;
end;

function does_app_test_profile_exist (
   p_profile_name in varchar2,
   p_env_type in varchar2 default null) return boolean is 
   n number;
begin 
   select count(*) into n 
     from app_test_profile 
    where profile_name=p_profile_name
      and nvl(env_type, 'x')=nvl(p_env_type, 'x');
   if n > 0 then 
      return true;
   else 
      return false;
   end if;
end;

procedure set_default_app_test_profile is 
   n number;
begin 
   -- Try to set default by calling set with no parms.
   set_app_test_profile;
end;

procedure raise_app_test_not_set is 
begin
   if g_app_test.test_name is null then 
      raise_application_error('-20001', 'Application test not set.');
   end if;
end;

function init_app_test (p_test_name varchar2) return boolean is
   -- Returns true if the test is enabled and it is time to run the test.
   pragma autonomous_transaction;
   n number;
   time_to_test boolean := false;

   function test_interval return boolean is 
   begin
      if nvl(g_app_test.test_end_time, sysdate-999) + g_app_test_profile.test_interval/1440 <= sysdate then 
         return true;
      else 
         return false;
      end if;
   end;

   function retry_interval return boolean is 
   begin 
      if g_app_test.test_end_time + g_app_test_profile.retry_interval/1440 <= sysdate then
         return true;
      else
         return false;
      end if;
   end;

   function recheck_interval return boolean is 
   begin 
      if nvl(g_app_test_profile.recheck_interval, -1) > -1 then 
         if g_app_test.test_end_time + g_app_test_profile.recheck_interval/1440 <= sysdate then 
            return true;
         end if;
      end if;
      return false;
   end;

begin
   if app_test_profile_not_set then 
      set_default_app_test_profile;
   end if;
   raise_app_test_profile_not_set;
   select count(*) into n from app_test 
    where test_name=p_test_name;
   if n = 0 then 
      insert into app_test (
         test_name,
         test_start_time,
         test_end_time,
         reminder_interval) values (
         p_test_name,
         sysdate,
         null,
         g_app_test_profile.reminder_interval);
      commit;
      time_to_test := true;
   end if;
   select * into g_app_test from app_test where test_name=p_test_name;
   if g_app_test.enabled='N' then 
      return false;
   end if;
   if not g_app_test.test_start_time is null and 
      g_app_test.test_end_time is null then 
      -- ToDo: Log an error here but do not throw an error.
      null;
   end if;
   if g_app_test.test_status in ('RETRY') and retry_interval then 
      if not g_app_test_profile.retry_log_type is null then
         arcsql.log(
            log_text=>'['||g_app_test_profile.retry_log_type||'] Application test '''||g_app_test.test_name||''' is being retried.',
            log_key=>'app_test');
      end if;
      time_to_test := true;
   end if;
   if g_app_test.test_status in ('FAIL', 'ABANDON') and (recheck_interval or test_interval) then 
      time_to_test := true;
   end if;
   if g_app_test.test_status in ('PASS') and test_interval then 
      time_to_test := true;
   end if;
   if time_to_test then 
      debug2('time_to_test=true');
      g_app_test.test_start_time := sysdate;
      g_app_test.test_end_time := null;
      g_app_test.total_test_count := g_app_test.total_test_count + 1;
      save_app_test;
      return true;
   else 
      debug2('time_to_test=false');
      return false;
   end if;
exception 
   when others then 
      rollback;
      raise;
end;

procedure reset_app_test_profile is 
begin 
   raise_app_test_profile_not_set;
   set_app_test_profile(
     p_profile_name=>g_app_test_profile.profile_name,
     p_env_type=>g_app_test_profile.env_type);
end;

procedure app_test_check is 
   -- Sends reminders and changes status to ABANDON when test status is currently FAIL.

   function abandon_interval return boolean is 
   -- Returns true if it is time to abandon this test.
   begin 
      if nvl(g_app_test_profile.abandon_interval, 0) > 0 then 
         if g_app_test.failed_time + g_app_test_profile.abandon_interval/1440 <= sysdate then 
            return true;
         end if;
      end if;
      return false;
   end;

   procedure abandon_test is 
   -- Performs necessary actions when test status changes to 'ABANDON'.
   begin 
      g_app_test.abandon_time := sysdate;
      g_app_test.total_abandons := g_app_test.total_abandons + 1;
      if not g_app_test_profile.abandon_log_type is null then 
         arcsql.log(
            log_text=>'['||g_app_test_profile.abandon_log_type||'] Application test '''||g_app_test.test_name||''' is being abandoned after '||g_app_test_profile.abandon_interval||' minutes.',
            log_key=>'app_test');
      end if;
      -- If reset is Y the test changes back to PASS and will likely FAIL on the next check and cycle through the whole process again.
      if nvl(g_app_test_profile.abandon_reset, 'N') = 'N' then 
         g_app_test.test_status := 'ABANDON';
      else 
         g_app_test.test_status := 'PASS';
      end if;
   end;

   procedure set_next_reminder_interval is 
   begin 
      g_app_test.reminder_interval := g_app_test.reminder_interval * g_app_test_profile.reminder_backoff;
   end;

   function time_to_remind return boolean is 
   -- Return true if it is time to log a reminder for a FAIL'd test.
   begin 
      if nvl(g_app_test.reminder_interval, 0) > 0 and g_app_test.test_status in ('FAIL') then  
         if g_app_test.last_reminder_time + g_app_test.reminder_interval/1440 <= sysdate then
            set_next_reminder_interval;
            return true;
         end if;
      end if;
      return false;
   end;

   procedure do_app_test_reminder is 
   -- Perform actions required when it is time to send a reminder.
   begin 
      g_app_test.last_reminder_time := sysdate;
      g_app_test.reminder_count := g_app_test.reminder_count + 1;
      g_app_test.total_reminders := g_app_test.total_reminders + 1;
      if not g_app_test_profile.reminder_log_type is null then
         arcsql.log(
            log_text=>'['||g_app_test_profile.reminder_log_type||'] A reminder that application test '''||g_app_test.test_name||''' is still failing.',
            log_key=>'app_test');
      end if;
   end;

begin 
   raise_app_test_not_set;
   if g_app_test.test_status in ('FAIL') then 
      if abandon_interval then 
         abandon_test;
      elsif time_to_remind then 
         do_app_test_reminder;
      end if;
   end if;
   save_app_test;
end;

procedure app_test_fail (p_message in varchar2 default null) is 
   -- Called by the test developer anytime the app test fails.
   
   function retries_not_configured return boolean is
   -- Return true if retries are configured for the currently set app test profile.
   begin 
      if nvl(g_app_test_profile.retry_count, 0) = 0 then 
         return true;
      else 
         return false;
      end if;
   end;

   procedure do_app_test_fail is 
   -- Perform the actions required when a test status changes to FAIL.
   begin 
      g_app_test.test_status := 'FAIL';
      g_app_test.failed_time := g_app_test.test_end_time;
      g_app_test.last_reminder_time := g_app_test.test_end_time;
      g_app_test.total_failures := g_app_test.total_failures + 1;
      if not g_app_test_profile.failed_log_type is null then 
         arcsql.log(
            log_text=>'['||g_app_test_profile.failed_log_type||'] Application test '''||g_app_test.test_name||''' has failed.',
            log_key=>'app_test');
      end if;
   end;

   function app_test_pass_fail_already_called return boolean is 
   begin
      if not g_app_test.test_end_time is null then
         return true;
      else
         return false;
      end if;
   end;

begin 
   raise_app_test_not_set;
   if app_test_pass_fail_already_called then 
      return;
   end if;
   arcsql.debug2('app_test_fail');
   g_app_test.test_end_time := sysdate;
   g_app_test.message := p_message;
   if g_app_test.test_status in ('PASS') then 
      if retries_not_configured then 
         do_app_test_fail;
      else
         g_app_test.test_status := 'RETRY';
      end if;
   elsif g_app_test.test_status in ('RETRY') then 
      g_app_test.total_retries := g_app_test.total_retries + 1;
      g_app_test.retry_count := g_app_test.retry_count + 1;
      if nvl(g_app_test.retry_count, 0) >= g_app_test_profile.retry_count or 
         -- If retries are not configured they have been changed and were configured previously or we could
         -- never get to a RETRY state. We will simply fail if this is the case.
         retries_not_configured then 
         do_app_test_fail;
      end if;
   end if;
   app_test_check;
   save_app_test;
end;

procedure app_test_pass is 
   -- Called by the test developer anytime the app test passes.
   
   procedure do_app_pass_test is 
   begin 
      if g_app_test.test_status in ('RETRY') then 
         g_app_test.total_retries := g_app_test.total_retries + 1;
      end if;
      g_app_test.test_status := 'PASS';
      g_app_test.passed_time := g_app_test.test_end_time;
      g_app_test.reminder_count := 0;
      g_app_test.reminder_interval := g_app_test_profile.reminder_interval;
      g_app_test.retry_count := 0;
      if not g_app_test_profile.pass_log_type is null then
         arcsql.log (
            log_text=>'['||g_app_test_profile.pass_log_type||'] Application test '''||g_app_test.test_name||''' is now passing.',
            log_key=>'app_test');
      end if;
   end;

   function app_test_pass_fail_already_called return boolean is 
   begin
      if not g_app_test.test_end_time is null then
         return true;
      else
         return false;
      end if;
   end;

begin 
   raise_app_test_not_set;
   if app_test_pass_fail_already_called then 
      return;
   end if;
   arcsql.debug2('app_test_pass');
   g_app_test.test_end_time := sysdate;
   if g_app_test.test_status not in ('PASS') or g_app_test.passed_time is null then 
      do_app_pass_test;
   end if;
   save_app_test;
end;

procedure app_test_done is 
   -- Marks completion of test. Not required but auto passes any test if fail has not been called. 
begin 
   -- This only runs if app_test_fail has not already been called.
   app_test_pass;
end;

procedure save_app_test is 
   pragma autonomous_transaction;
begin 
   update app_test set row=g_app_test where test_name=g_app_test.test_name;
   commit;
exception 
   when others then 
      rollback;
      raise;
end;

function cron_match (
   p_expression in varchar2,
   p_datetime in date default sysdate) return boolean is 
   v_expression varchar2(120) := upper(p_expression);
   v_min varchar2(120);
   v_hr varchar2(120);
   v_dom varchar2(120);
   v_mth varchar2(120);
   v_dow varchar2(120);
   t_min number;
   t_hr number;
   t_dom number;
   t_mth number;
   t_dow number;

   function is_cron_multiple_true (v in varchar2, t in number) return boolean is 
   begin 
      if mod(t, to_number(replace(v, '/', ''))) = 0 then 
         return true;
      end if;
      return false;
   end;

   function is_cron_in_range_true (v in varchar2, t in number) return boolean is 
      left_side number;
      right_side number;
   begin 
      left_side := get_token(p_list=>v, p_index=>1, p_delim=>'-');
      right_side := get_token(p_list=>v, p_index=>2, p_delim=>'-');
      -- Low value to high value.
      if left_side < right_side then 
         if t >= left_side and t <= right_side then 
            return true;
         end if;
      else 
         -- High value to lower value can be used for hours like 23-2 (11PM to 2AM).
         -- Other examples: minutes 55-10, day of month 29-3, month of year 11-1.
         if t >= left_side or t <= right_side then 
            return true;
         end if;
      end if;
      return false;
   end;

   function is_cron_in_list_true (v in varchar2, t in number) return boolean is 
   begin 
      for x in (select trim(regexp_substr(v, '[^,]+', 1, level)) l
                  from dual
                       connect by 
                       level <= regexp_count(v, ',')+1) 
      loop
         if to_number(x.l) = t then 
            return true;
         end if;
      end loop;
      return false;
   end;

   function is_cron_part_true (v in varchar2, t in number) return boolean is 
   begin 
      if trim(v) = 'X' then 
         return true;
      end if;
      if instr(v, '/') > 0 then 
         if is_cron_multiple_true (v, t) then
            return true;
         end if;
      elsif instr(v, '-') > 0 then 
         if is_cron_in_range_true (v, t) then 
            return true;
         end if;
      elsif instr(v, ',') > 0 then 
         if is_cron_in_list_true (v, t) then 
            return true;
         end if;
      else 
         if to_number(v) = t then 
            return true;
         end if;
      end if;
      return false;
   end;

   function is_cron_true (v in varchar2, t in number) return boolean is 
   begin 
      if trim(v) = 'X' then 
         return true;
      end if;
      for x in (select trim(regexp_substr(v, '[^,]+', 1, level)) l
                  from dual
                       connect by 
                       level <= regexp_count(v, ',')+1) 
      loop
         if not is_cron_part_true(x.l, t) then 
            return false;
         end if;
      end loop;
      return true;
   end;

   function convert_dow (v in varchar2) return varchar2 is 
       r varchar2(120);
   begin 
       r := replace(v, 'SUN', 0);
       r := replace(r, 'MON', 1);
       r := replace(r, 'TUE', 2);
       r := replace(r, 'WED', 3);
       r := replace(r, 'THU', 4);
       r := replace(r, 'FRI', 5);
       r := replace(r, 'SAT', 6);
       return r;
   end;

   function convert_mth (v in varchar2) return varchar2 is 
      r varchar2(120);
   begin 
      r := replace(v, 'JAN', 1);
      r := replace(r, 'FEB', 2);
      r := replace(r, 'MAR', 3);
      r := replace(r, 'APR', 4);
      r := replace(r, 'MAY', 5);
      r := replace(r, 'JUN', 6);
      r := replace(r, 'JUL', 7);
      r := replace(r, 'AUG', 8);
      r := replace(r, 'SEP', 9);
      r := replace(r, 'OCT', 10);
      r := replace(r, 'NOV', 11);
      r := replace(r, 'DEC', 12);
      return r;
   end;

begin 
   -- Replace * with X.
   v_expression := replace(v_expression, '*', 'X');
   raise_invalid_cron_expression(v_expression);

   v_min := get_token(p_list=>v_expression, p_index=>1, p_delim=>' ');
   v_hr := get_token(p_list=>v_expression, p_index=>2, p_delim=>' ');
   v_dom := get_token(p_list=>v_expression, p_index=>3, p_delim=>' ');
   v_mth := convert_mth(get_token(p_list=>v_expression, p_index=>4, p_delim=>' '));
   v_dow := convert_dow(get_token(p_list=>v_expression, p_index=>5, p_delim=>' '));

   t_min := to_number(to_char(p_datetime, 'MI'));
   t_hr := to_number(to_char(p_datetime, 'HH24'));
   t_dom := to_number(to_char(p_datetime, 'DD'));
   t_mth := to_number(to_char(p_datetime, 'MM'));
   t_dow := to_number(to_char(p_datetime, 'D'));

   if not is_cron_true(v_min, t_min) then 
      return false;
   end if;
   if not is_cron_true(v_hr, t_hr) then 
      return false;
   end if;
   if not is_cron_true(v_dom, t_dom) then 
      return false;
   end if;
   if not is_cron_true(v_mth, t_mth) then 
      return false;
   end if;
   if not is_cron_true(v_dow, t_dow) then 
      return false;
   end if;
   return true;
end;

/* 
-----------------------------------------------------------------------------------
Sensor
-----------------------------------------------------------------------------------
*/

procedure set_sensor (p_key in varchar2) is 
begin 
   select * into g_sensor from arcsql_sensor where sensor_key=p_key;
end;

function does_sensor_exist (p_key in varchar2) return boolean is 
   n number;
begin
   select count(*) into n from arcsql_sensor where sensor_key=p_key;
end;

function sensor (
   p_key in varchar2,
   p_input in varchar2,
   p_fail_count in number default 0) return boolean is 
begin 
   update arcsql_sensor 
      set matches=decode(p_input, input, 'Y', 'N'),
          old_input=input,
          input=p_input,
          old_updated=updated,
          updated=sysdate,
          fail_count=fail_count+decode(p_input, input, 0, 1)
    where sensor_key=p_key;
   if sql%rowcount = 0 then 
      insert into arcsql_sensor (
         sensor_key,
         old_input,
         input,
         old_updated,
         updated,
         matches,
         fail_count) values (
         p_key,
         p_input,
         p_input,
         sysdate,
         sysdate,
         'Y',
         0);
      commit;
      return false;
   end if;
   select * into g_sensor from arcsql_sensor where sensor_key=p_key;
   if g_sensor.matches = 'Y' then 
      return false;
   else 
      g_sensor.sensor_message := 'Sensor change detected: '''||g_sensor.sensor_key||'''.
Old input: '||g_sensor.old_input||'
New input :'||g_sensor.input;
      update arcsql_sensor set sensor_message=g_sensor.sensor_message where sensor_key=p_key;
      commit;
      return true;
   end if;
end;

/* 
-----------------------------------------------------------------------------------
Messaging
-----------------------------------------------------------------------------------
*/

-- The messaging interface queue leverages the logging interface.
procedure send_message (
   p_text in varchar2,  
   -- ToDo: Need to set up a default log_type.
   p_log_type in varchar2 default 'email',
   -- ToDo: key is confusing, it sounds unique but it really isn't. Need to come up with something clearer.
   -- p_key in varchar2 default 'arcsql',
   p_tags in varchar2 default null) is 
begin 
   log_interface(
      p_type=>p_log_type,
      p_text=>p_text, 
      p_key=>'message',
      p_tags=>p_tags, 
      p_level=>0);
end;

/* 
-----------------------------------------------------------------------------------
Alerting
-----------------------------------------------------------------------------------
*/

function is_alert_open (p_alert_key in varchar2) return boolean is 
   n number;
begin 
   select count(*) into n from arcsql_alert 
    where alert_key=p_alert_key 
      and status in ('open', 'abandoned');
   if n > 0 then 
      debug('Alert is already open.');
      return true;
   else 
      debug('Alert is not open.');
      return false;
   end if;
end;

function does_alert_priority_exist(p_priority in number) return boolean is 
   n number;
begin 
   select count(*) into n from arcsql_alert_priority where priority_level=p_priority;
   if n > 0 then 
      return true;
   else 
      return false;
   end if;
end;

procedure raise_alert_priority_not_found (p_priority in number) is 
   n number;
begin 
   select count(*) into n from arcsql_alert_priority where priority_level=p_priority;
   if n = 0 then 
      raise_application_error(-20001, 'Alert priority not found.');
   end if;
end;

procedure set_alert_priority (p_priority in number) is 
   n number;
begin 
   raise_alert_priority_not_found(p_priority);
   -- Get the max level alert type which is enabled.
   g_alert_priority := null;
   select max(priority_level) into n 
     from arcsql_alert_priority 
    where priority_level <= p_priority 
      and is_truthy_y(enabled) = 'y';
   if n is null then 
      g_alert_priority.priority_level := 0;
   else 
      select * into g_alert_priority
        from arcsql_alert_priority 
       where priority_level=n;
   end if;
   debug3('Setting alert priority level to '||g_alert_priority.priority_level);
end;

procedure raise_alert_priority_not_set is 
begin 
   if g_alert_priority.priority_level is null then 
      raise_application_error(-20001, 'Alert priority not set.');
   end if;
end;

procedure save_alert_priority is 
begin 
   raise_alert_priority_not_set;
   if does_alert_priority_exist(g_alert_priority.priority_level) then 
      update arcsql_alert_priority set row=g_alert_priority where priority_level=g_alert_priority.priority_level;
   else 
      insert into arcsql_alert_priority values g_alert_priority;
   end if;
end;

function get_default_alert_priority return number is 
   cursor default_priorities is 
   select * from arcsql_alert_priority 
    where is_truthy_y(is_default)='y'
    order 
       by priority_level desc;
begin 
   for priority_level in default_priorities loop 
      return priority_level.priority_level;
   end loop;
   return 3;
end;

procedure set_alert(p_alert_key in varchar2) is 
begin 
   select * into g_alert from arcsql_alert 
    where alert_key=p_alert_key
      and status in ('open', 'abandoned');
   set_alert_priority(g_alert.priority_level);
end;

procedure raise_alert_not_set is 
begin 
   if g_alert.alert_key is null then 
      raise_application_error(-20001, 'Alert is not set.');
   end if;
end;

procedure log_alert (
   p_log_text in varchar2,
   p_log_type in varchar2) is 
begin 
   raise_alert_not_set;
   log_interface (
      p_text=>p_log_text, 
      p_key=>'ALERT-P'||g_alert.priority_level, 
      p_tags=>'alert',
      p_level=>0, 
      p_type=>p_log_type);
end;

function get_alert_key_from_alert_text (p_text in varchar2) return varchar2 is 
begin 
   return lower(replace(str_remove_text_between(p_text, '[', ']'), ' '));
end;

procedure open_alert (
   p_text in varchar2 default null,
   -- Supports levels 1-5 (critical, high, moderate, low, informational).
   p_priority in number default null) is 
   v_priority number := p_priority;
   v_alert_key varchar2(120) := get_alert_key_from_alert_text(p_text);
begin
   debug('Opening an alert.');
   if not is_alert_open(v_alert_key) then 
      if v_priority is null then 
         v_priority := get_default_alert_priority;
      end if;
      set_alert_priority(v_priority);
      -- If all alert types are disabled skip any furthur action.
      if g_alert_priority.priority_level > 0 then
         insert into arcsql_alert (
            alert_key,
            alert_text,
            status,
            priority_level,
            opened,
            closed,
            abandoned,
            reminder_count,
            reminder_interval
            ) values (
            v_alert_key,
            p_text,
            'open',
            g_alert_priority.priority_level,
            sysdate,
            null,
            null,
            0,
            g_alert_priority.reminder_interval
            );
         set_alert(v_alert_key);
         log_alert (
            p_log_text=>'OPEN: '||p_text||' (ALERT-P'||g_alert_priority.priority_level||')',
            p_log_type=>g_alert_priority.alert_log_type);
      end if;
   end if;
end;

procedure close_alert (
   p_text in varchar2, 
   p_is_autoclose in boolean := false) is 
   v_alert_key varchar2(120) := get_alert_key_from_alert_text(p_text);
   v_close varchar2(120) := 'CLOSE';
begin 
   set_alert(v_alert_key);
   update arcsql_alert 
      set closed=sysdate, 
          status='closed',
          last_action=sysdate
    where alert_key=v_alert_key
      and status in ('open', 'abandoned');
   if not g_alert_priority.close_log_type is null and g_alert_priority.priority_level > 0 then
      if p_is_autoclose then 
         v_close := 'AUTOCLOSE';
      end if;
      log_alert (
         p_log_text=>v_close||': '||p_text||' (ALERT-P'||g_alert_priority.priority_level||')',
         p_log_type=>g_alert_priority.alert_log_type);
   end if;
end;

procedure abandon_alert (p_text in varchar2) is 
   v_alert_key varchar2(120) := get_alert_key_from_alert_text(p_text);
begin 
   set_alert(v_alert_key);
   update arcsql_alert 
      set abandoned=sysdate, 
          status='abandoned',
          last_action=sysdate
    where alert_key=v_alert_key
      and status in ('open');
   if not g_alert_priority.abandon_log_type is null and g_alert_priority.priority_level > 0 then
      log_alert (
         p_log_text=>'ABANDON: '||p_text||' (ALERT-P'||g_alert_priority.priority_level||')',
         p_log_type=>g_alert_priority.alert_log_type);
   end if;
end;

procedure remind_alert (p_text in varchar2) is 
   v_alert_key varchar2(120) := get_alert_key_from_alert_text(p_text);
begin 
   set_alert(v_alert_key);
   update arcsql_alert 
      set reminder_interval=reminder_interval*g_alert_priority.reminder_backoff_interval,
          reminder_count=reminder_count+1,
          last_action=sysdate
    where alert_key=v_alert_key
      and status in ('open');
   log_alert (
      p_log_text=>'REMIND: '||p_text||' (ALERT-P'||g_alert_priority.priority_level||')',
      p_log_type=>g_alert_priority.alert_log_type);
end;

procedure check_alerts is 
   cursor alerts is 
   select * from arcsql_alert 
    where status in ('open', 'abandoned');
begin 
   for open_alert in alerts loop 
      set_alert_priority(open_alert.priority_level);
      if g_alert_priority.close_interval > 0 and 
         open_alert.opened+(g_alert_priority.close_interval/1440) < sysdate then 
         close_alert(open_alert.alert_text);
      elsif g_alert_priority.abandon_interval > 0 and 
         open_alert.opened+(g_alert_priority.abandon_interval/1440) < sysdate and 
         open_alert.status = 'open' then 
         abandon_alert(open_alert.alert_text);
      elsif g_alert_priority.reminder_interval > 0 and 
         open_alert.last_action+(g_alert_priority.reminder_interval/1440) < sysdate and
         open_alert.reminder_count < g_alert_priority.reminder_count and 
         open_alert.status = 'open' then 
         remind_alert(open_alert.alert_text);
      end if;
   end loop;
   commit;
exception 
   when others then 
      rollback;
      raise;
end;

end;
/


