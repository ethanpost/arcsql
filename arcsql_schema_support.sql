
-- uninstall: drop procedure execute_sql;
create or replace procedure execute_sql (
  sql_text varchar2, 
  ignore_errors boolean := false) authid current_user is
begin
   execute immediate sql_text;
exception
   when others then
      if not ignore_errors then
         raise;
      end if;
end;
/

-- uninstall: drop procedure drop_object;
create or replace procedure drop_object (object_name varchar2, object_type varchar2) is
   n number;
begin
   select count(*) into n
     from user_objects 
    where object_name=upper(drop_object.object_name)
      and object_type=upper(drop_object.object_type);
   if n > 0 then
      execute immediate 'drop '||upper(drop_object.object_type)||' '||upper(drop_object.object_name);
   end if;
exception
   when others then
      raise;
end;
/

-- uninstall: drop function does_object_exist;
create or replace function does_object_exist (object_name varchar2, object_type varchar2) return boolean authid current_user is
   n number;
begin
   if upper(does_object_exist.object_type) = 'TYPE' then
      select count(*) into n 
        from user_types
       where type_name=upper(does_object_exist.object_name);
   elsif upper(does_object_exist.object_type) = 'CONSTRAINT' then
      select count(*) into n 
        from user_constraints
       where constraint_name=upper(does_object_exist.object_name);
   elsif upper(does_object_exist.object_type) = 'PACKAGE' then
      select count(*) into n 
        from all_source 
       where name=upper(does_object_exist.object_name) 
         and type='PACKAGE';
   else
      select count(*) into n 
        from user_objects 
       where object_type = upper(does_object_exist.object_type)
         and object_name = upper(does_object_exist.object_name);
   end if;
   if n > 0 then
      return true;
   else
      return false;
   end if;
end;
/

-- uninstall: drop function does_package_exist;
create or replace function does_package_exist (package_name in varchar2) return boolean is 
begin 
  if does_object_exist(does_package_exist.package_name, 'PACKAGE') then
      return true;
   else
      return false;
   end if;
end;
/

-- uninstall: drop procedure drop_package;
create or replace procedure drop_package (package_name in varchar2) is 
begin 
   if does_package_exist(drop_package.package_name) then 
      execute_sql('drop package '||drop_package.package_name);
   end if;
end;
/

-- uninstall: drop function does_table_exist;
create or replace function does_table_exist (table_name varchar2) return boolean is
begin
   if does_object_exist(does_table_exist.table_name, 'TABLE') then
      return true;
   else
      return false;
   end if;
end;
/

-- uninstall: drop function does_column_exist;
create or replace function does_column_exist (table_name varchar2, column_name varchar2) return boolean is
   n number;
begin
   select count(*) into n from user_tab_columns 
    where table_name=upper(does_column_exist.table_name)
      and column_name=upper(does_column_exist.column_name);
   if n > 0 then
      return true;
   else
      return false;
   end if;
exception 
when others then
   raise;
end;
/

-- uninstall: drop function does_index_exist;
create or replace function does_index_exist (index_name varchar2) return boolean is
begin
   if does_object_exist(does_index_exist.index_name, 'INDEX') then
      return true;
   else
      return false;
   end if;
exception
when others then
   raise;
end;
/

-- uninstall: drop function does_constraint_exist;
create or replace function does_constraint_exist (constraint_name varchar2) return boolean is
begin
   if does_object_exist(does_constraint_exist.constraint_name, 'CONSTRAINT') then
      return true;
   else
      return false;
   end if;
exception
when others then
   raise;
end;
/

-- uninstall: drop procedure drop_index;
create or replace procedure drop_index(index_name varchar2) is 
begin
  if does_object_exist(drop_index.index_name, 'INDEX') then
    drop_object(drop_index.index_name, 'INDEX');
  end if;
exception
  when others then
     raise;
end;
/

-- uninstall: drop procedure drop_table;
create or replace procedure drop_table(table_name varchar2) is
begin
    drop_object(drop_table.table_name, 'TABLE');
end;
/

-- uninstall: drop function does_sequence_exist;
create or replace function does_sequence_exist (sequence_name varchar2) return boolean is
   n number;
begin
   select count(*) into n 
     from user_sequences
    where sequence_name=upper(does_sequence_exist.sequence_name);
   if n = 0 then
      return false;
   else
      return true;
   end if;
exception
   when others then
      raise; 
end;
/

-- uninstall: drop procedure drop_sequence;
create or replace procedure drop_sequence (sequence_name varchar2) is 
begin  
    drop_object(sequence_name, 'SEQUENCE');
end;
/

-- uninstall: drop procedure create_sequence;
create or replace procedure create_sequence (sequence_name in varchar2) is 
begin
   if not does_sequence_exist(sequence_name) then
      execute_sql('create sequence '||sequence_name, false);
   end if;
end;
/

-- uninstall: drop function does_scheduler_job_exist;
create or replace function does_scheduler_job_exist (p_job_name in varchar2) return boolean is
   n number;
begin 
   select count(*) into n from all_scheduler_jobs
    where job_name=upper(p_job_name);
   if n = 0 then 
      return false;
   else 
      return true;
   end if;
end;
/

-- Needs to be a standalong func here and not in arcsql package becuase authid current user is used.
-- uninstall: drop function num_get_val_from_sql;
create or replace function num_get_val_from_sql(sql_text in varchar2) return number authid current_user is 
   n number;
begin
   execute immediate sql_text into n;
   return n;
end;
/

-- uninstall: drop function does_database_account_exist;
create or replace function does_database_account_exist (username varchar2) return boolean is 
   n number;
begin
   select count(*) into n from all_users 
    where username=upper(does_database_account_exist.username);
   if n = 1 then 
      return true;
   else 
      return false;
   end if;
end;
/
