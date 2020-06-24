
-- uninstall: drop procedure send_email;
create or replace procedure send_email (
   p_to in varchar2,
   p_from in varchar2,
   p_subject in varchar2,
   p_body in varchar2) is 
begin 
   arcsql.log('Sending email with subject "'||p_subject||'" to '||p_to||'.');
end;
/

-- uninstall: drop package arcsql_private_settings;
create or replace package arcsql_private_settings as 
   foo number;
end;
/