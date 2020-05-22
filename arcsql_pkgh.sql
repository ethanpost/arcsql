create or replace package arcsql as

   /* DATES AND TIME */

   -- Return the # of seconds between two timestamps.
   function secs_between_timestamps (time_start in timestamp, time_end in timestamp) return number;
   -- return the # of seconds since a timestamp.
   function secs_since_timestamp(time_stamp timestamp) return number;

   /* STRINGS */

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
   -- Return true if string appears to be an email address.
   function str_is_email (text varchar2) return boolean;
   
   -- Borrowed and adapted from the ora_complexity_check function.
   function str_complexity_check
   (text   varchar2,
    chars      integer := null,
    letter     integer := null,
    uppercase  integer := null,
    lowercase  integer := null,
    digit      integer := null,
    special    integer := null) return boolean;

   /* NUMBERS */

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

   /* UTILITIES */

   -- Create a copy of a table and possibly drop the existing copy if it already exists.
   procedure backup_table (sourceTable varchar2, newTable varchar2, dropTable boolean := false);
   -- Connect to an external file as a local table.
   procedure connect_external_file_as_table (directoryName varchar2, fileName varchar2, tableName varchar2);
   -- Write an entry to the alert log. 
   procedure log_alert_log (text in varchar2);
   -- Return a unique number which identifies the calling session.
   function get_audsid return number;

   function get_days_since_pass_change (username varchar2) return number;

   /* APPLICATION VERSIONING */
   procedure set_app_version(
      p_app_name in varchar2, 
      p_version in number,
      p_confirm in boolean := false);
   procedure confirm_app_version(p_app_name in varchar2);
   function get_app_version(p_app_name in varchar2) return number;
   procedure delete_app_version(p_app_name in varchar2);
   
   /* SIMPLE VALUE KEY STORE */

   procedure cache (cache_key varchar2, p_value varchar2);
   function return_cached_value (cache_key varchar2) return varchar2;
   function does_cache_key_exist (cache_key varchar2) return boolean;
   procedure delete_cache_key (cache_key varchar2);
   
   /* CUSTOM CONFIG */

   -- Add a config setting. Forced to lcase. If already exists nothing happens.
   procedure add_config (name varchar2, value varchar2, description varchar2 default null);
   -- Update a config setting. Created if it doesn't exist.
   procedure set_config (name varchar2, value varchar2);
   -- Remove a config setting. 
   procedure remove_config (name varchar2);
   -- Return the config value. Returns null if it does not exist.
   function  get_config (name varchar2)  return varchar2;

   /* SQL LOG (Monitoring) */

   procedure run_sql_log_update;

   /* BUILT IN JOB WINDOWS */

   -- Creates the DBMS_JOBS required to run the scheduled tasks below.
   procedure run;
   procedure stop;
   -- Removes the DBMS_JOBS associated with the scheduled tasks below.
   procedure run_every_1_minutes;
   procedure run_every_5_minutes;

   /* COUNTERS */

   function does_counter_exist (counter_group varchar2, subgroup varchar2, name varchar2) return boolean;
   -- Sets a counter to a value. Is created if it doesn't exist.
   procedure set_counter (counter_group varchar2, subgroup varchar2, name varchar2, equal number default null, add number default null, subtract number default null);
    -- Deletes a counter. Nothing happens if it doesn't exist.
   procedure delete_counter (counter_group varchar2, subgroup varchar2, name varchar2);

   /* EVENTS */

   -- Starts an event. It is linked to the current session.
   procedure start_event (event_group varchar2, subgroup varchar2, name varchar2);
   -- Stops an event. Must have been started within the same session.
   procedure stop_event (event_group varchar2, subgroup varchar2, name varchar2);
   -- Deletes an event from the event table. This is a global action, not session.
   procedure delete_event (event_group varchar2, subgroup varchar2, name varchar2);

   /* LOGGING */
   -- -1 Nothing is logged.
   -- 0 Non debug calls are logged.
   -- 1 through 3 determines which debug calls make it through.
   log_level number default 1;
   procedure log (log_text in varchar2, log_key in varchar2 default null, log_tags in varchar2 default null);
   procedure audit (audit_text in varchar2, audit_key in varchar2 default null, audit_tags in varchar2 default null);
   procedure err (error_text in varchar2, error_key in varchar2 default null, error_tags in varchar2 default null);
   procedure debug (debug_text in varchar2, debug_key in varchar2 default null, debug_tags in varchar2 default null);
   procedure debug2 (debug_text in varchar2, debug_key in varchar2 default null, debug_tags in varchar2 default null);
   procedure debug3 (debug_text in varchar2, debug_key in varchar2 default null, debug_tags in varchar2 default null);
   procedure alert (alert_text in varchar2, alert_key in varchar2 default null, alert_tags in varchar2 default null);
   procedure fail (fail_text in varchar2, fail_key in varchar2 default null, fail_tags in varchar2 default null);
   /* UNIT TESTING */

   -- -1 initialized, 1 true, 0 false
   test_name varchar2(255) := null;
   test_passed number := -1;
   assert boolean := true;
   assert_true boolean := true;
   assert_false boolean := false;
   procedure pass_test;
   procedure fail_test;
   procedure init_test(test_name varchar2);
   procedure test;

end;
/

show errors