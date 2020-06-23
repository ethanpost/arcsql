-- uninstall: drop package arcsql_public_settings;
create or replace package arcsql_public_settings as 
   
   -- List ',' of emails is allowable.
   arcsql_admin_email varchar2(120) := 'post.ethan@gmail.com';

   -- Your secret SendGrid API key for sending email.
   sendgrid_api_key varchar2(120) := '';
   sendgrid_from_address varchar2(120) := '';
end;
/
