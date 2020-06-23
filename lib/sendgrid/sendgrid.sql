
-- uninstall: drop package sendgrid;
create or replace package sendgrid as 

   sendgrid_api_url varchar2(120) := 'https://api.sendgrid.com/v3/mail/send';

   procedure send (
      to_address varchar2,
      subject varchar2,
      message varchar2);

end;
/

show errors 

create or replace package body sendgrid as 

function get_json_body (
   from_address varchar2,
   to_address varchar2,
   subject varchar2,
   message varchar2) return varchar2 is 
   r varchar2(32000);
begin 
   r := '
{
   "personalizations": [{
      "to": [{
         "email": "'||to_address||'"
      }]
   }],
   "from": {
      "email": "'||from_address||'"
   },
   "subject": "'||subject||'",
   "content": [{
      "type": "text/plain",
      "value": "'||message||'"
   }]
}';
   return r;
exception 
   when others then 
      raise;
end;

procedure send (
   to_address varchar2,
   subject varchar2,
   message varchar2) is 
   r varchar2(32000);
   b varchar2(32000);
begin 
   arcsql.debug1('sendgrid.send: '||to_address||' '||subject);
   apex_web_service.g_request_headers.delete();
   apex_web_service.g_request_headers(1).name := 'Content-Type';
   apex_web_service.g_request_headers(1).value := 'application/json'; 
   apex_web_service.g_request_headers(2).name := 'Authorization';  
   apex_web_service.g_request_headers(2).value := 'Bearer '||arcsql.get_setting('sendgrid_api_key');  
   b := get_json_body(
            from_address=>arcsql.get_setting('sendgrid_from_address'), 
            to_address=>send.to_address, 
            subject=>send.subject, 
            message=>send.message);
   arcsql.debug1(b);
   r := apex_web_service.make_rest_request(
       p_url         => sendgrid.sendgrid_api_url, 
       p_http_method => 'POST',
       p_body => to_clob(b));
   arcsql.debug1(sendgrid.sendgrid_api_url||' returned: '||r);
exception
   when others then 
      arcsql.err(error_text=>'send: '||dbms_utility.format_error_stack);
      raise;
end;

end;
/

show errors
