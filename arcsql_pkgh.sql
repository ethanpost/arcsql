
-- uninstall: drop package arcsql;
create or replace package arcsql as

   /* 
   -----------------------------------------------------------------------------------
   Datetime
   -----------------------------------------------------------------------------------
   */

   -- Return the # of seconds between two timestamps.
   function secs_between_timestamps (time_start in timestamp, time_end in timestamp) return number;
   -- return the # of seconds since a timestamp.
   function secs_since_timestamp(time_stamp timestamp) return number;

   /* 
   -----------------------------------------------------------------------------------
   Timer
   -----------------------------------------------------------------------------------
   */

   type table_type is table of date index by varchar2(120);

   g_timer_start table_type;
   procedure start_timer(p_key in varchar2);
   function get_timer(p_key in varchar2) return number;

   /* 
   -----------------------------------------------------------------------------------
   Strings
   -----------------------------------------------------------------------------------
   */

   -- Return a string with all non-numeric characters (including blanks) removed.
   function str_only_num (text varchar2) return varchar2;
   -- Return Y if string converts to a date, else N. Assumes 'MM/DD/YYYY' format.
   function str_is_date_y_or_n (text varchar2) return varchar2;
   -- Return Y if string converts to a number, else N.
   function str_is_number_y_or_n (text varchar2) return varchar2;
   -- Returns string. Anything not A-Z, a-z, or 0-9 is replaced with a '_'.
   function str_to_key_str (str in varchar2) return varchar2;
   -- Returns a random string of given type.
   function str_random (length in number default 33, string_type in varchar2 default 'an') return varchar2;
   -- Hash a string using MD5. 
   function str_hash_md5 (text varchar2) return varchar2;
   function encrypt_sha256 (text varchar2) return varchar2 deterministic;
   -- Return true if string appears to be an email address.
   function str_is_email (text varchar2) return boolean;
   -- Return count of str within str. Can handle >1 length p_char.
   function str_count (
      p_str varchar2, 
      p_char varchar2)
      return number;

   -- Borrowed and adapted from the ora_complexity_check function.
   function str_complexity_check
      (text   varchar2,
       chars      integer := null,
       letter     integer := null,
       uppercase  integer := null,
       lowercase  integer := null,
       digit      integer := null,
       special    integer := null) return boolean;

   function str_remove_text_between (
      p_text in varchar2,
      p_left_char in varchar2,
      p_right_char in varchar2) return varchar2;

   function get_token (
      p_list  varchar2,
      p_index number,
      p_delim varchar2 := ',') return varchar2;

   function shift_list (
      p_list in varchar2,
      p_token in varchar2 default ',',
      p_shift_count in number default 1,
      p_max_items in number default null) return varchar2;

   function str_eval_math (
      p_expression in varchar2,
      p_decimals in number := 2) return number;

   procedure str_raise_complex_value (
      text varchar2, 
      allow_regex varchar2 default null);

   procedure str_raise_not_defined(p_str in varchar2 default null);

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
      p_decimals number default 0) return number;

   function num_get_variance (
      p_val number,
      p_pct_chance number,
      p_change_low number,
      p_change_high number,
      p_decimals number default 0) return number;

   function num_random_gauss (
      p_mean number := 0, 
      p_dev number := 1, 
      p_min number := null, 
      p_max number := null) return number;

   /* 
   -----------------------------------------------------------------------------------
   Utilities
   -----------------------------------------------------------------------------------
   */

   function is_truthy (p_val in varchar2) return boolean;
   function is_truthy_y (p_val in varchar2) return varchar2;
   -- Create a copy of a table and possibly drop the existing copy if it already exists.
   procedure backup_table (sourceTable varchar2, newTable varchar2, dropTable boolean := false);
   -- Connect to an external file as a local table.
   procedure connect_external_file_as_table (directoryName varchar2, fileName varchar2, tableName varchar2);
   -- Write an entry to the alert log. 
   procedure log_alert_log (text in varchar2);
   -- Return a unique number which identifies the calling session.
   function get_audsid return number;

   function get_days_since_pass_change (username varchar2) return number;

   /* 
   -----------------------------------------------------------------------------------
   Application Versioning
   -----------------------------------------------------------------------------------
   */

   procedure set_app_version(
      p_app_name in varchar2, 
      p_version in number,
      p_confirm in boolean := false);
   procedure confirm_app_version(p_app_name in varchar2);
   function get_app_version(p_app_name in varchar2) return number;
   procedure delete_app_version(p_app_name in varchar2);

   /* 
   -----------------------------------------------------------------------------------
   Key/Value Database
   -----------------------------------------------------------------------------------
   */

   -- Cache a string.
   procedure cache (cache_key varchar2, p_value varchar2);
   -- Specifically cache a date.
   procedure cache_date (cache_key in varchar2, p_date in date);
   -- Specifically cach a number.
   procedure cache_num (cache_key in varchar2, p_num in number);
   function get_cache (cache_key varchar2) return varchar2;
   function get_cache_date (cache_key varchar2) return date;
   function get_cache_num (cache_key varchar2) return number;
   function does_cache_key_exist (cache_key varchar2) return boolean;
   procedure delete_cache_key (cache_key varchar2);

   /* 
   -----------------------------------------------------------------------------------
   Configuration
   -----------------------------------------------------------------------------------
   */

   -- Be ware of the difference between a "setting" and "config" here. 
   -- "config" functions only deal with the values found in arcsql_config table.
   -- "get_setting" looks arcsql_config table, then arcsql_user_setting package,
   -- and then in arcsql_default_setting package. 

   -- Also note all config names are forced to lower-case.

   -- Returns value for the setting. 
   function get_setting(setting_name varchar2) return varchar2 deterministic;
   -- Add a config value to the arcsql_config table. If already exists nothing happens.
   procedure add_config (name varchar2, value varchar2, description varchar2 default null);
   -- Update a config value in the arcsql_config table. Creates it if it doesn't exist.
   procedure set_config (name varchar2, value varchar2);
   -- Remove a config value from the arcsql_config table. 
   procedure remove_config (name varchar2);
   -- Return the config value. Returns null if it does not exist.
   function get_config (name varchar2) return varchar2;
   -- Returns true if get_setting for "env" is set to dev.
   function is_dev return boolean;

   /* 
   -----------------------------------------------------------------------------------
   SQL Monitoring
   -----------------------------------------------------------------------------------
   */

   procedure run_sql_log_update;

   /* 
   -----------------------------------------------------------------------------------
   Setting and getting sys_context values.
   -----------------------------------------------------------------------------------
   */

   procedure set_sys_context (
      p_namespace in varchar2,
      p_attribute in varchar2,
      p_value in varchar2,
      p_client_id in varchar2 default null);

   function get_sys_context (
      p_namespace in varchar2,
      p_attribute in varchar2) return varchar2;
   
   /* 
   -----------------------------------------------------------------------------------
   Counters
   -----------------------------------------------------------------------------------
   */

   function does_counter_exist (counter_group varchar2, subgroup varchar2, name varchar2) return boolean;
   -- Sets a counter to a value. Is created if it doesn't exist.
   procedure set_counter (counter_group varchar2, subgroup varchar2, name varchar2, equal number default null, add number default null, subtract number default null);
    -- Deletes a counter. Nothing happens if it doesn't exist.
   procedure delete_counter (counter_group varchar2, subgroup varchar2, name varchar2);

   /*
   -----------------------------------------------------------------------------------
   Request counter user for quickly implementing rate limits.
   -----------------------------------------------------------------------------------
   */

   procedure count_request (
      p_request_key in varchar2, 
      p_sub_key in varchar2 default null);

   function get_request_count (
      p_request_key in varchar2, 
      p_sub_key in varchar2 default null, 
      p_min in number default 1) return number;

   function get_current_request_count (
      p_request_key in varchar2, 
      p_sub_key in varchar2 default null) return number;

   /* 
   -----------------------------------------------------------------------------------
   Events
   -----------------------------------------------------------------------------------
   */

   procedure start_event (
      p_event_key in varchar2, 
      p_sub_key in varchar2, 
      p_name in varchar2);

   procedure stop_event (
      p_event_key in varchar2, 
      p_sub_key in varchar2, 
      p_name in varchar2);

   procedure delete_event (
      p_event_key in varchar2, 
      p_sub_key in varchar2, 
      p_name in varchar2);

   procedure purge_events;

   /* 
   -----------------------------------------------------------------------------------
   Logging
   -----------------------------------------------------------------------------------
   */

   log_level number default 1;

   g_log_type arcsql_log_type%rowtype;

   procedure set_log_type (p_log_type in varchar2);

   procedure raise_log_type_not_set;

   function does_log_type_exist (p_log_type in varchar2) return boolean;

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
      );

   procedure log (
      log_text in varchar2, 
      log_key in varchar2 default null, 
      log_tags in varchar2 default null,
      log_type in varchar2 default 'log',
      metric_name_1 in varchar2 default null,
      metric_1 in number default null,
      metric_name_2 in varchar2 default null,
      metric_2 in number default null);

   procedure log_notify (
      notify_text in varchar2, 
      notify_key in varchar2 default null, 
      notify_tags in varchar2 default null,
      metric_name_1 in varchar2 default null,
      metric_1 in number default null,
      metric_name_2 in varchar2 default null,
      metric_2 in number default null);

   procedure log_audit (
      audit_text in varchar2, 
      audit_key in varchar2 default null, 
      audit_tags in varchar2 default null,
      metric_name_1 in varchar2 default null,
      metric_1 in number default null,
      metric_name_2 in varchar2 default null,
      metric_2 in number default null);

   procedure log_err (
      error_text in varchar2, 
      error_key in varchar2 default null, 
      error_tags in varchar2 default null,
      metric_name_1 in varchar2 default null,
      metric_1 in number default null,
      metric_name_2 in varchar2 default null,
      metric_2 in number default null);

   procedure debug (
      debug_text in varchar2, 
      debug_key in varchar2 default null, 
      debug_tags in varchar2 default null,
      metric_name_1 in varchar2 default null,
      metric_1 in number default null,
      metric_name_2 in varchar2 default null,
      metric_2 in number default null);

   procedure debug2 (
      debug_text in varchar2, 
      debug_key in varchar2 default null, 
      debug_tags in varchar2 default null,
      metric_name_1 in varchar2 default null,
      metric_1 in number default null,
      metric_name_2 in varchar2 default null,
      metric_2 in number default null);

   procedure debug3 (
      debug_text in varchar2, 
      debug_key in varchar2 default null, 
      debug_tags in varchar2 default null,
      metric_name_1 in varchar2 default null,
      metric_1 in number default null,
      metric_name_2 in varchar2 default null,
      metric_2 in number default null);

   procedure log_fail (
      fail_text in varchar2, 
      fail_key in varchar2 default null, 
      fail_tags in varchar2 default null,
      metric_name_1 in varchar2 default null,
      metric_1 in number default null,
      metric_name_2 in varchar2 default null,
      metric_2 in number default null);

   procedure log_sms (
      sms_text in varchar2, 
      sms_key in varchar2 default null, 
      sms_tags in varchar2 default null);

    procedure log_email (
      email_text in varchar2, 
      email_key in varchar2 default null, 
      email_tags in varchar2 default null);
   
   /* 
   -----------------------------------------------------------------------------------
   Contact Groups
   -----------------------------------------------------------------------------------
   */
   
   g_contact_group arcsql_contact_group%rowtype;
   procedure set_contact_group (p_group_name in varchar2);
   procedure send_email_messages;
   procedure raise_contact_group_not_set;
   procedure check_contact_groups;

   /* 
   -----------------------------------------------------------------------------------
   Alerts
   -----------------------------------------------------------------------------------
   */

   g_alert_priority arcsql_alert_priority%rowtype;
   g_alert arcsql_alert%rowtype;

   function is_alert_open (p_alert_key in varchar2) return boolean;

   function does_alert_priority_exist (p_priority in number) return boolean;

   procedure set_alert_priority (p_priority in number);

   procedure save_alert_priority;

   -- Returns 3 if nothing is set.
   function get_default_alert_priority return number;

   procedure open_alert (
      p_text in varchar2 default null,
      p_priority in number default null);

   procedure close_alert (
      p_text in varchar2, 
      p_is_autoclose in boolean := false);

   procedure check_alerts;

   /* 
   -----------------------------------------------------------------------------------
   Unit Testing
   -----------------------------------------------------------------------------------
   */

   -- -1 initialized, 1 true, 0 false
   test_name varchar2(255) := null;
   test_passed number := -1;
   assert boolean := true;
   assert_true boolean := true;
   assert_false boolean := false;
   procedure pass_test;
   procedure fail_test(fail_message in varchar2 default null);
   procedure init_test(test_name varchar2);
   procedure test;

   /* 
   -----------------------------------------------------------------------------------
   Application Monitoring/Testing
   -----------------------------------------------------------------------------------
   */

   -- Stores the current app test profile.
   g_app_test_profile app_test_profile%rowtype;

   -- Stores the current app test record.
   g_app_test app_test%rowtype;

   procedure add_app_test_profile (
      -- 
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
      p_reminder_backoff in number default 1,
      p_abandon_interval in varchar2 default null,
      p_abandon_log_type in varchar2 default 'abandon',
      p_abandon_reset in varchar2 default 'N',
      p_pass_log_type in varchar2 default 'passed'
      );

   procedure set_app_test_profile (
      p_profile_name in varchar2 default null,
      p_env_type in varchar2 default null);

   procedure reset_app_test_profile;

   procedure save_app_test_profile;

   procedure save_app_test;

   function does_app_test_profile_exist (
      p_profile_name in varchar2 default null,
      p_env_type in varchar2 default null) return boolean;

   function init_app_test (p_test_name varchar2) return boolean;

   procedure app_test_fail(p_message in varchar2 default null);

   procedure app_test_pass;

   procedure app_test_done;

   function cron_match (
      p_expression in varchar2,
      p_datetime in date default sysdate) return boolean;

   /* 
   -----------------------------------------------------------------------------------
   Sensor
   -----------------------------------------------------------------------------------
   */

   g_sensor arcsql_sensor%rowtype;

   procedure set_sensor (p_key in varchar2);

   function does_sensor_exist (p_key in varchar2) return boolean;

   function sensor (
      p_key in varchar2,
      p_input in varchar2,
      p_fail_count in number default 0) return boolean;

   /* 
   -----------------------------------------------------------------------------------
   Messaging
   -----------------------------------------------------------------------------------
   */

   procedure send_message (
      p_text in varchar2,  
      -- ToDo: Need to set up a default log_type.
      p_log_type in varchar2 default 'email',
      -- ToDo: key is confusing, it sounds unique but it really isn't. Need to come up with something clearer.
      -- p_key in varchar2 default 'arcsql',
      p_tags in varchar2 default null);

   /* 
   -----------------------------------------------------------------------------------
   Oracle APEX
   -----------------------------------------------------------------------------------
   */

   function apex_get_app_name return varchar2;
   function apex_get_app_alias return varchar2;


end;
/

