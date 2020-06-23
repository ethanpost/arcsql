

-- uninstall: exec arcsql.stop;
-- uninstall: drop package body arcsql;
-- uninstall: drop package arcsql;

-- uninstall: drop function arcsql_version;
-- grant: grant execute on arcsql_version to &username;
create or replace function arcsql_version return number is 
   n number;
   s varchar2(100);
begin 
   select count(*) into n from user_tables where table_name='ARCSQL_CONFIG';
   if n = 0 then
      return 0;
   else 
      execute immediate 'select max(value) from arcsql_config where name=''arcsql_version''' into s;
      if s is null then 
         return 0;
      else 
         n := to_number(s);
         return n;
      end if;
   end if;
end;
/

-- Some version of this probably comes from Steve Adams of Ixora fame.
-- as well as plenty of other things here.

-- uninstall: drop view locked_objects;
create or replace view locked_objects as (
select session_id,
       oracle_username
,      object_name
,      decode(a.locked_mode,
              0, 'None',           /* Mon Lock equivalent */
              1, 'Null',           /* N */
              2, 'Row-S (SS)',     /* L */
              3, 'Row-X (SX)',     /* R */
              4, 'Share',          /* S */
              5, 'S/Row-X (SSX)',  /* C */
              6, 'Exclusive',      /* X */
       to_char(a.locked_mode)) mode_held
   from gv$locked_object a
   ,    dba_objects b
  where a.object_id = b.object_id)
/

-- uninstall: drop view lockers;
create or replace view lockers as (
select /*+ ordered */
  l.type || '-' || l.id1 || '-' || l.id2  locked_resource,
  nvl(b.name, lpad(to_char(l.sid), 8)) sid, l.inst_id,
  decode(
    l.lmode,
    1, '      N',
    2, '     SS',
    3, '     SX',
    4, '      S',
    5, '    SSX',
    6, '      X'
  )  holding,
  decode(
    l.request,
    1, '      N',
    2, '     SS',
    3, '     SX',
    4, '      S',
    5, '    SSX',
    6, '      X'
  )  wanting,
  l.ctime  seconds
from
  sys.gv_$lock l,
  sys.gv_$session s,
  sys.gv_$bgprocess b
where
  s.inst_id = l.inst_id and
  s.sid = l.sid and
  -- Don't monitor locks from data pump, triggers many false alarms.
  -- Somewhere else we need to monitor for long running data pump jobs.
  s.module not like '%Data Pump%' and
  b.paddr (+) = s.paddr and
  b.inst_id (+) = s.inst_id and
  l.type not in ('MR','TS','RT','XR','CF','RS','CO','AE','BR') and
  nvl(b.name, lpad(to_char(l.sid), 4)) not in ('CKPT','LGWR','SMON','VKRM','DBRM','DBW0','MMON'));


-- uninstall: drop view name_generator;
create or replace view name_generator as 
   select listagg(str, '_') within group (order by str) as name from (
   select str from (
   select distinct str from (
   with data as (select table_name str from dict where table_name not like '%$%')
   select trim(column_value) str from data, xmltable(('"' || replace(str, '_', '","') || '"')))
   order by dbms_random.value)
   where rownum <= 3) 
/

-- uninstall: drop view lock_time;
create or replace view lock_time as (
 select nvl(sum(seconds),0) value
   from lockers);

/* SIMPLE KEY VALUE DATASTORE */

-- uninstall: drop table cache;
begin
   if not does_table_exist('cache') then
      execute_sql('
      create table cache (
      key         varchar2(200),
      value       varchar2(4000) default null,
      update_time date default sysdate)', false);

      execute_sql('
      alter table cache add constraint pk_cache primary key (key)', false);
   end if;
end;
/

-- uninstall: drop table arcsql_config;
begin
   if not does_table_exist('arcsql_config') then
   
      execute_sql('
      create table arcsql_config (
      name varchar2(100),
      value varchar2(1000),
      description varchar2(1000))', false);
      
      execute_sql('
      create unique index arcsql_config_1 on arcsql_config (name)', true);
      
   end if;
end;
/

/* SQL LOG */

begin 
   if arcsql_version < 1 then
       --drop_table('sql_log');
       --drop_table('sql_log_arc');
       --drop_table('counter');
       --drop_table('event');
       drop_table('sql_snap');
   end if;
end;
/

-- uninstall: drop sequence seq_sql_log_id;
begin 
   if not does_sequence_exist('seq_sql_log_id') then
      execute_sql('create sequence seq_sql_log_id', false);
   end if;
end;
/

-- uninstall: drop table sql_snap;
begin
   if not does_table_exist('sql_snap') then 
      execute_sql('
      create table sql_snap (
      sql_id                    varchar2(13),
      insert_datetime           date,
      sql_text                  varchar2(100),
      plan_hash_value           number,
      executions                number,
      elapsed_time              number,
      force_matching_signature  number,
      user_io_wait_time         number,
      rows_processed            number,
      cpu_time                  number,
      service                   varchar2(100),
      module                    varchar2(100),
      action                    varchar2(100))', false);

    execute_sql('create index sql_snap_1 on sql_snap (sql_id, plan_hash_value, force_matching_signature)', true);

   end if;
end;
/

-- uninstall: drop table sql_log;
begin 
   if not does_table_exist('sql_log') then
      execute_sql('
      create table sql_log (
      sql_log_id                   number,
      sql_id                       varchar2(100),
      sql_text                     varchar2(100),
      plan_hash_value              number,
      plan_age_in_days             number,
      faster_plans                 number,
      slower_plans                 number,
      force_matching_signature     number,
      datetime                     date,
      update_count                 number default 0,
      update_time                  date,
      elapsed_seconds              number,
      cpu_seconds                  number,
      user_io_wait_secs            number,
      io_wait_secs_score           number,
      norm_user_io_wait_secs       number,
      executions                   number,
      executions_score             number,
      norm_execs_per_hour          number,
      elap_secs_per_exe            number,
      elap_secs_per_exe_score      number,
      norm_elap_secs_per_exe       number,
      secs_0_1                     number default 0,
      secs_2_5                     number default 0,
      secs_6_10                    number default 0,
      secs_11_60                   number default 0,
      secs_61_plus                 number default 0,
      pct_of_elap_secs_for_all_sql number,
      sql_age_in_days              number,
      sql_last_seen_in_days        number,
      rows_processed               number,
      norm_rows_processed          number,
      sql_log_score                number,
      sql_log_total_score          number,
      sql_log_score_count          number,
      sql_log_avg_score            number,
      rolling_avg_score            varchar2(120) default null,
      sql_log_max_score            number,
      sql_log_min_score            number,
      secs_between_snaps           number,
      -- These can be updated manually and still be used even if not available in gv$sql.
      service                      varchar2(100),
      module                       varchar2(100),
      action                       varchar2(100),
      hours_since_last_exe         number)', false); 
   end if;

   if not does_index_exist('sql_log_1') then
      execute_sql('create index sql_log_1 on sql_log (sql_id, plan_hash_value, force_matching_signature)', false);
   end if;

   if not does_index_exist('sql_log_2') then
      execute_sql('create index sql_log_2 on sql_log (datetime)', false);
   end if;

   if not does_index_exist('sql_log_3') then
      execute_sql('create index sql_log_3 on sql_log (plan_hash_value)', false);
   end if;

   if not does_index_exist('sql_log_4') then
      execute_sql('create index sql_log_4 on sql_log (sql_log_id)', false);
   end if;

   if not does_index_exist('sql_log_5') then
      execute_sql('create unique index sql_log_5 on sql_log (sql_id, plan_hash_value, force_matching_signature, datetime)', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'norm_user_io_wait_secs') then 
      execute_sql('alter table sql_log add (norm_user_io_wait_secs number)', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'io_wait_secs_score') then 
      execute_sql('alter table sql_log add (io_wait_secs_score number)', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'sql_log_total_score') then 
      execute_sql('alter table sql_log add (sql_log_total_score number)', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'sql_log_score_count') then 
      execute_sql('alter table sql_log add (sql_log_score_count number)', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'sql_log_avg_score') then 
      execute_sql('alter table sql_log add (sql_log_avg_score number)', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'service') then 
      execute_sql('alter table sql_log add (service varchar2(100))', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'module') then 
      execute_sql('alter table sql_log add (module varchar2(100))', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'action') then 
      execute_sql('alter table sql_log add (action varchar2(100))', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'hours_since_last_exe') then 
      execute_sql('alter table sql_log add (hours_since_last_exe number)', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'sql_log_max_score') then 
      execute_sql('alter table sql_log add (sql_log_max_score number)', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'sql_log_min_score') then 
      execute_sql('alter table sql_log add (sql_log_min_score number)', false);
   end if;

   if not does_column_exist(table_name => 'sql_log', column_name => 'rolling_avg_score') then 
      execute_sql('alter table sql_log add (rolling_avg_score varchar2(120) default null)', false);
   end if;
   
end;
/

-- uninstall: drop table sql_log_arc;
begin 
   if not does_table_exist('sql_log_arc') then
       execute_sql('
       create table sql_log_arc (
       sql_log_id                   number,
       sql_id                       varchar2(100),
       sql_text                     varchar2(100),
       plan_hash_value              number,
       plan_age_in_days             number,
       force_matching_signature     number,
       datetime                     date,
       update_count                 number default 0,
       update_time                  date,
       executions                   number,
       elapsed_seconds              number,
       secs_0_1                     number default 0,
       secs_2_5                     number default 0,
       secs_6_10                    number default 0,
       secs_11_60                   number default 0,
       secs_61_plus                 number default 0,
       elap_secs_per_exe_score number,
       executions_score number,
       pct_of_elap_secs_for_all_sql number,
       io_wait_secs_score   number,
       sql_age_in_days              number,
       sql_last_seen_in_days        number,
       faster_plans                 number,
       slower_plans                 number,
       user_io_wait_secs            number,
       rows_processed               number,
       cpu_seconds                  number,
       norm_elap_secs_per_exe     number,
       norm_execs_per_hour        number,
       norm_user_io_wait_secs     number,
       norm_rows_processed        number,
       sql_log_score                number)', false); 
   end if;
   
   if not does_index_exist('sql_log_arc_1') then
      execute_sql('create index sql_log_arc_1 on sql_log_arc (sql_id, plan_hash_value, force_matching_signature)', true);
   end if;
   
   if not does_index_exist('sql_log_arc_2') then
      execute_sql('create index sql_log_arc_2 on sql_log_arc (datetime)', true);
   end if;
   
   if not does_index_exist('sql_log_arc_3') then
      execute_sql('create index sql_log_arc_3 on sql_log_arc (plan_hash_value)', true);
   end if;
   
   if not does_index_exist('sql_log_arc_4') then
      execute_sql('create index sql_log_arc_4 on sql_log_arc (sql_log_id)');
   end if;
   
   if not does_column_exist(table_name => 'sql_log_arc', column_name => 'norm_user_io_wait_secs') then 
      execute_sql('alter table sql_log_arc add (norm_user_io_wait_secs number)');
   end if;

   if not does_column_exist(table_name => 'sql_log_arc', column_name => 'io_wait_secs_score') then 
      execute_sql('alter table sql_log_arc add (io_wait_secs_score number)');
   end if;

end;
/
    
-- uninstall: drop table sql_log_active_session_history;
begin
   if not does_table_exist('sql_log_active_session_history') then
       execute_sql('
       create table sql_log_active_session_history (
       datetime                  date,
       sql_id                    varchar2(13),
       sql_text                  varchar2(100),
       on_cpu                    number,
       in_wait                   number,
       modprg                    varchar2(100),
       actcli                    varchar2(100),
       exes                      number,
       elapsed_seconds           number)', false);
    end if;
    
    execute_sql('create index sql_log_active_session_history_1 on sql_log_active_session_history (datetime)', true);
    
    execute_sql('create index sql_log_active_session_history_2 on sql_log_active_session_history (sql_id)', true);
end;
/

begin
    dbms_stats.gather_table_stats (
       ownname=>user,
       tabname=>'sql_log',
       estimate_percent=>dbms_stats.auto_sample_size,
       method_opt=>'FOR ALL COLUMNS SIZE AUTO',
       degree=>5,
       cascade=>true);
exception
   when others then
      raise;
end;
/

begin
    dbms_stats.gather_table_stats (
       ownname=>user,
       tabname=>'sql_log_arc',
       estimate_percent=>dbms_stats.auto_sample_size,
       method_opt=>'FOR ALL COLUMNS SIZE AUTO',
       degree=>5,
       cascade=>true);
exception
   when others then
      raise;
end;
/

-- uninstall: drop view sql_snap_view;
create or replace view sql_snap_view as (
 select sql_id,
        substr(sql_text, 1, 100) sql_text,
        plan_hash_value,
        force_matching_signature,
        sum(executions) executions,
        sum(elapsed_time) elapsed_time,
        sum(user_io_wait_time) user_io_wait_time,
        sum(rows_processed) rows_processed,
        sum(cpu_time) cpu_time,
        -- I don't thing the max is needed here as this should not be 
        -- a part of the uniqueness of the row but I need to ensure
        -- these values don't make a row unique and so I am taking
        -- max. Consider these values helpful but not 100% reliable.
        max(service) service,
        max(module) module,
        max(action) action
   from gv$sql
  where executions > 0
  group
     by sql_id,
        substr(sql_text, 1, 100),
        plan_hash_value,
        force_matching_signature
 having sum(elapsed_time) > = 1*1000000);

/* COUNTERS */

-- uninstall: drop sequence seq_counter_id;
-- uninstall: drop table arcsql_counter;
begin
   if not does_sequence_exist('seq_counter_id') then 
      execute_sql('create sequence seq_counter_id');
   end if;
   if not does_table_exist('arcsql_counter') then
       execute_sql('
       create table arcsql_counter (
       id number not null,
       counter_group varchar2(100) not null,
       subgroup varchar2(100) default null,
       name varchar2(100) not null,
       value number default 0,
       update_time date default sysdate
       )', false);
    
      execute_sql('create index arcsql_counter_1 on arcsql_counter (name)', true);
    
    end if;
end;
/

/* EVENTS */

-- uninstall: drop sequence seq_event_id;
-- uninstall: drop table arcsql_event;
begin
   if not does_sequence_exist('seq_event_id') then 
      execute_sql('create sequence seq_event_id');
   end if;
   if not does_table_exist('arcsql_event') then
       execute_sql('
       create table arcsql_event (
       id number not null,
       event_group varchar2(100) not null,
       subgroup varchar2(100) default null,
       name varchar2(100) not null,
       event_count number,
       total_secs number,
       last_start_time date,
       last_end_time date
       )', false);
    
      execute_sql('create index arcsql_event_1 on arcsql_event (name)', true);
    
    end if;
end;
/

begin
  if arcsql_version <= 1 then
     -- Changing name of table to audsid_event.
     drop_table('session_event');
  end if;
end;
/

-- uninstall: drop table audsid_event;
begin
   if not does_table_exist('audsid_event') then
       execute_sql('
       create table audsid_event (
       audsid number,
       event_group varchar2(100) not null,
       subgroup varchar2(100) default null,
       name varchar2(100) not null,
       start_time date
       )', false);
    
      execute_sql('create index audsid_event_1 on audsid_event (session_id, serial#, name)', true);
    
    end if;
end;
/

-- uninstall: drop table arcsql_event_log;
begin
   if not does_table_exist('arcsql_event_log') then
       execute_sql('
       create table arcsql_event_log (
       id number not null,
       event_group varchar2(100) not null,
       subgroup varchar2(100) default null,
       name varchar2(100) not null,
       event_count number,
       total_secs number,
       last_start_time date,
       last_end_time date
       )', false);
      execute_sql('create index arcsql_event_log_1 on arcsql_event_log (name)', true);
    end if;
end;
/

-- uninstall: drop sequence seq_version_update_id;
begin
   if not does_sequence_exist('seq_version_update_id') then 
      execute_sql('create sequence seq_version_update_id', false);
   end if;
end;
/

-- uninstall: drop table app_version cascade constraints purge;
begin
   if not does_table_exist('app_version') then 
      execute_sql('
      create table app_version (
      app_name varchar2(100),
      version number,
      last_version number,
      status varchar2(100)
      )', false);
      execute_sql('alter table app_version add constraint pk_app_version primary key (app_name)', false);
   end if;
end;
/

-- Removed this feature and replaced with APP_VERSION instead.
exec drop_table('VERSION_UPDATE');
exec drop_sequence('SEQ_VERSION_UPDATE_ID');

-- uninstall: drop table arcsql_log_type cascade constraints purge;
drop table arcsql_log_type cascade constraints purge;
begin
   -- log_type is forced to lower case.
   -- New values added automatically if log_interface is called and type is not found.
   if not does_table_exist('arcsql_log_type') then 
      execute_sql('
      create table arcsql_log_type (
      log_type varchar2(120),
      sends_email varchar2(1) default ''Y'',
      sends_sms varchar2(1) default ''N''
      )', false);
      execute_sql('alter table arcsql_log_type add constraint pk_arcsql_log_type primary key (log_type)', false);
   end if;
end;
/

-- uninstall: drop sequence seq_arcsql_log_entry;
exec create_sequence('seq_arcsql_log_entry');

-- uninstall: drop table arcsql_log;
begin 
   if not does_table_exist('arcsql_log') then 
      execute_sql('
      create table arcsql_log (
      log_entry number default seq_arcsql_log_entry.nextval,
      log_time date default sysdate,
      log_text varchar2(1000),
      log_type varchar2(25) default ''log'' not null,
      log_key varchar2(120),
      log_tags varchar2(120),
      metric_name_1 varchar2(120) default null,
      metric_1 number default null,
      metric_name_2 varchar2(120) default null,
      metric_2 number default null,
      audsid varchar2(120),
      username varchar2(120))', false);
      execute_sql('
      create index arcsql_log_1 on arcsql_log(log_entry)', false);
      execute_sql('
      create index arcsql_log_2 on arcsql_log(log_time)', false);   
   end if;
   if not does_column_exist('arcsql_log', 'metric_name_1') then 
      execute_sql('alter table arcsql_log add (metric_name_1 varchar2(120) default null)', false);
   end if;
   if not does_column_exist('arcsql_log', 'metric_1') then 
      execute_sql('alter table arcsql_log add (metric_1 number default null)', false);
   end if;
   if not does_column_exist('arcsql_log', 'metric_name_2') then 
      execute_sql('alter table arcsql_log add (metric_name_2 varchar2(120) default null)', false);
   end if;
   if not does_column_exist('arcsql_log', 'metric_2') then 
      execute_sql('alter table arcsql_log add (metric_2 number default null)', false);
   end if;
end;
/

create or replace view database_users as (
select username, account_status, lock_date, created, password_change_date 
  from dba_users);

-- uninstall: drop table test_profile cascade constraints purge;
drop table app_test_profile;
begin
   if not does_table_exist('app_test_profile') then 
      execute_sql('
      create table app_test_profile (
      profile_name varchar2(120),
      -- Environment type, can be something like prod, dev, test...
      env_type varchar2(120) default null,
      is_default varchar2(1) default ''N'',
      test_interval number default 0,
      -- If test is in FAIL or ABANDON we can recheck for PASS more frequently or less using 
      -- the recheck_interval which has precedence over test_interval.
      recheck_interval number default null,
      -- The number of times to retry before failing.
      retry_count number default 0 not null,
      -- The interval to wait before allowing a retry, if null then test_interval is used.
      retry_interval number default 0 not null,
      -- Log type to log when a retry is attempted.
      retry_log_type varchar2(120) default null,
      -- Log type to log when state changes to failed.
      failed_log_type varchar2(120),
      -- Interval to wait between reminders. If null reminders are not sent.
      reminder_interval number default null,
      -- Log type to log when a reminder is sent.
      reminder_log_type varchar2(120),
      -- Dynamically change the interval each time the reminder runs by some # or %.
      reminder_backoff number default 1 not null,
      -- Interval to wait before test is abandoned (test is still run but no reporting takes place if it continues to fail.)
      abandon_interval number default null,
      -- Log type to log when abandon occurs.
      abandon_log_type varchar2(120) default null,
      -- If Y test resets automatically to passing on abandon.
      abandon_reset varchar2(1) default ''N'',
      -- Log type to log when test changes from fail to pass.
      pass_log_type varchar2(120))', false);
      execute_sql('create index test_profile_1 on app_test_profile (profile_name, env_type)', false);
    end if;
end;
/

-- uninstall: drop table app_test cascade constraints purge;
drop table app_test cascade constraints purge;
begin
   if not does_table_exist('app_test') then 
      execute_sql('
      create table app_test (
      test_name varchar2(120) not null,
      test_status varchar2(120) default ''PASS'',
      passed_time date default null,
      failed_time date default null,
      test_start_time date default null,
      test_end_time date default null,
      total_test_count number default 0,
      total_failures number default 0,
      last_reminder_time date default null,
      reminder_interval number default null,
      reminder_count number default 0,
      total_reminders number default 0,
      abandon_time date default null,
      total_abandons number default 0,
      retry_count number default 0,
      -- Sum of all retry attempts.
      total_retries number default 0,
      message varchar2(1000),
      -- ToDo: Add this.
      enabled varchar2(1) default ''Y''
      )', false);
      execute_sql('alter table app_test add constraint pk_app_test primary key (test_name)', false);
   end if;
end;
/

-- uninstall: drop table contact_group cascade constraints purge;
drop table arcsql_contact_group;
begin
   if not does_table_exist('arcsql_contact_group') then 
      execute_sql('
      create table arcsql_contact_group (
      group_name varchar2(120),
      email_addresses varchar2(1000),
      sms_addresses varchar2(1000),
      is_group_enabled varchar2(1) default ''Y'' not null,
      is_group_on_hold varchar2(1) default ''N'' not null,
      is_sms_disabled varchar2(1) default ''N'' not null,
      -- Amount of time the oldest message can sit in the queue before sending all messages in the queue.
      max_queue_secs number default 0,
      -- The amount of time the most recent message can sit in the queue without a new message arriving before sending all of the messages in the queue.
      max_idle_secs number default 0,
      -- The maximum # of messages that the queue can hold before sending all of the messaged in the queue.
      max_count number default 0,
      last_checked date default sysdate not null,
      -- You can create a custom view on arcsql_log to limit which messages this contact group monitors.
      view_name varchar2(120)
      )', false);
      execute_sql('alter table arcsql_contact_group add constraint pk_arcsql_contact_group primary key (group_name)', false);
   end if;
end;
/

-- uninstall: drop table arcsql_alert_priority cascade constraints purge;
drop table arcsql_alert_priority;
begin
   if not does_table_exist('arcsql_alert_priority') then 
      execute_sql('
      create table arcsql_alert_priority (
      priority_level number,
      priority_name varchar2(120),
      alert_log_type varchar2(120) not null,
      -- Truthy values including cron expressions are allowed here.
      enabled varchar2(60) default ''Y'' not null,
      -- Can be a truthy value including cron expression.
      is_default varchar2(120) default null,
      reminder_log_type varchar2(120) default null,
      -- In minutes.
      reminder_interval number default 0 not null,
      reminder_count number default 0 not null,
      -- Reminder interval is multiplied by this value after each reminder to set the subsequent interval.
      reminder_backoff_interval number default 1 not null,
      abandon_log_type varchar2(120) default null,
      abandon_interval number default 0 not null,
      -- Automatically close the alert when interval (min) elapses.
      close_log_type varchar2(120) default null,
      close_interval number default 0 not null
      )', false);
      execute_sql('alter table arcsql_alert_priority add constraint pk_arcsql_alert_priority primary key (priority_level)', false);
      execute_sql('alter table arcsql_alert_priority add constraint arcsql_alert_priority_fk_log_type foreign key (alert_log_type) references arcsql_log_type (log_type) on delete cascade', false);
   end if;
end;
/

exec create_sequence('seq_arcsql_alert');

-- uninstall: drop table arcsql_alert cascade constraints purge;
drop table arcsql_alert;
begin
   if not does_table_exist('arcsql_alert') then 
      execute_sql('
      create table arcsql_alert (
      alert_id number default seq_arcsql_alert.nextval,
      -- Anything not in first set of [] will be used to formulate the alert_key.
      alert_text varchar2(120),
      -- Unique key parsed from alert_text.
      alert_key varchar2(120),
      status varchar2(120) not null,
      priority_level number not null,
      opened date default sysdate,
      closed date default null,
      abandoned date default null,
      reminder_count number default 0,
      last_action date default sysdate,
      reminder_interval number default 0
      )', false);
      execute_sql('alter table arcsql_alert add constraint pk_arcsql_alert primary key (alert_id)', false);
      execute_sql('create unique index arcsql_alert_1 on arcsql_alert (alert_key, opened)', false);
   end if;
end;
/
