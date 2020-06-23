-- uninstall: drop package arcsql_public_settings;
create or replace package arcsql_public_settings as 
begin 
   -- Your secret SendGrid API key for sending email.
   sendgrid_api_key varchar2(120) := '';
   sendgrid_from_address varchar2(120) := '';
end;
/
