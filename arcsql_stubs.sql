
-- uninstall: drop procedure send_email;
-- To implement another email service replace this procedure!

-- ToDo: Raise error if any line is >1000 characters long.
-- ToDo: Add a quick proc to test email.

begin 
   if not does_procedure_exist('send_email') then 
      execute immediate '
create or replace procedure send_email (
   -- Valid email address to which the email is sent (required). For multiple email addresses, use a comma-separated list
   p_to in varchar2,
   -- Email address from which the email is sent (required). This email address must be a valid address. Otherwise, the message is not sent.
   p_from in varchar2,
   -- Body of the email in plain text, not HTML (required). If a value is passed to p_body_html, then this is the only text the recipient sees. If a value is not passed to p_body_html, then this text only displays for email clients that do not support HTML or have HTML disabled. A carriage return or line feed (CRLF) must be included every 1000 characters.
   p_body in varchar2,
   -- Subject of the email.
   p_subject in varchar2 default null) is
begin 
   arcsql.log(''Sending email with subject "''||p_subject||''" to ''||p_to||''.'');
   apex_mail.send(
      p_to=>p_to,
      p_from=>p_from,
      p_subj=>p_subject,
      p_body=>p_body
      );
   apex_mail.push_queue;
end;
';
   end if;
end;
/

-- uninstall: drop package arcsql_user_setting;

begin 
   if not does_package_exist('arcsql_user_setting') then 
      execute immediate '
create or replace package arcsql_user_setting as 
   foo number;
end;
';
   end if;
end;
/

