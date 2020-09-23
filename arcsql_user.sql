
define username='arcsql'

-- Direct grant required to create sequences from PL/SQL code.
grant create sequence to &username;
grant create session to &username;
grant create table to &username;
grant create procedure to &username;
grant create view to &username;
grant create trigger to &username;
grant create type to &username;
grant create public synonym to &username;
grant create synonym to &username;
grant drop public synonym to &username;

-- These are used for some lock related views.
grant select on sys.gv_$lock to &username;
grant select on sys.gv_$session to &username;
grant select on sys.gv_$bgprocess to &username;
grant select on gv$locked_object to &username;
grant select on dba_objects to &username;

-- Used to get last password change time.
grant select on dba_users to &username;

-- Used for SQL_LOG.
grant select on gv$sql to &username;
-- Only used if licensed and explicitly specified in the arcsql_config table.
grant select on gv$active_session_history to &username;

-- Used to generate random numbers and strings.
grant execute on dbms_random to &username;

-- Used to hash strings with md5.
grant execute on dbms_crypto to &username;

-- grant select on gv_$database to &username;
-- grant select on gv_$instance to &username;
-- grant select on gv_$session to &username;
-- grant select on gv_$system_event to &username;
-- grant select on gv_$waitstat to &username;
-- grant select on gv_$sysstat to &username;
-- grant alter session to &username;
-- grant dba to &username;
-- grant select any table to &username;
-- grant execute any procedure to &username;
-- grant analyze any to &username;
-- grant select any table to &username;
-- grant alter any table to &username;
-- grant alter any index to &username;
-- grant execute on dbms_system to &username;
-- grant execute on dbms_lock to &username;
-- grant select on dba_free_space to &username;
-- grant select on dba_data_files to &username;
-- grant select on dba_tables to &username;
-- grant select on dba_segments to &username;
-- grant select on dba_indexes to &username;
-- grant select any dictionary to &username;
-- grant create any directory to &username;
-- grant create any synonym to &username;
-- grant create public synonym to &username;
-- grant alter system to &username;
-- grant create user to &username;
-- grant alter user to &username;
-- grant drop user to &username;
-- grant create role to &username;
-- grant grant any object privilege to &username;
-- grant drop any directory to &username;
-- grant create database link to &username;
-- grant EXEMPT ACCESS POLICY to &username;
-- grant drop any table to &username;
-- grant execute on dbms_system to &username;
-- grant execute on dbms_lock to &username;
-- grant delete any table to &username;


-- Required for oracle_monitoring.sql.
grant select on dba_autotask_job_history to &username;
grant select on dba_tablespaces to &username;
grant select on gv$database to &username;

-- Needed to add scheduled jobs.
grant create job to &username;