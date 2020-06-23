
-- uninstall: drop package sendgrid;
create or replace package sendgrid as 

   sendgrid_api_url varchar2(120) := 'https://api.sendgrid.com/v3/mail/send';

   procedure send (
      p_to in varchar2,
      p_subject in varchar2,
      p_body in varchar2 default null,
      p_from in varchar2 default null);

end;
/

show errors 

create or replace package body sendgrid as 

function get_json_body (
   p_to in varchar2,
   p_subject in varchar2,
   p_body in varchar2 default null,
   p_from in varchar2 default null) return varchar2 is 
   r varchar2(32000);
begin 
   r := '
{
   "personalizations": [{
      "to": [{
         "email": "'||p_to||'"
      }]
   }],
   "from": {
      "email": "'||p_from||'"
   },
   "subject": "'||p_subject||'",
   "content": [{
      "type": "text/plain",
      "value": "'||p_body||'"
   }]
}';
   return r;
exception 
   when others then 
      raise;
end;

procedure send (
   p_to in varchar2,
   p_subject in varchar2,
   p_body in varchar2 default null,
   p_from in varchar2 default null) is 
   response varchar2(32000);
   json_body varchar2(3200);
   v_from varchar2(120) := p_from;
begin 
   arcsql.log('Sending email with subject "'||p_subject||'" to '||p_to||'.');
   apex_web_service.g_request_headers.delete();
   apex_web_service.g_request_headers(1).name := 'Content-Type';
   apex_web_service.g_request_headers(1).value := 'application/json'; 
   apex_web_service.g_request_headers(2).name := 'Authorization';  
   apex_web_service.g_request_headers(2).value := 'Bearer '||arcsql.get_setting('sendgrid_api_key');  
   if v_from is null then 
      v_from := arcsql.get_setting('sendgrid_from_address');
   end if;
   json_body := get_json_body(
      p_to=>p_to, 
      p_subject=>p_subject, 
      p_body=>p_body,
      p_from=>v_from);
   arcsql.debug2(json_body);
   response := apex_web_service.make_rest_request(
       p_url         => sendgrid.sendgrid_api_url, 
       p_http_method => 'POST',
       p_body => to_clob(json_body));
   arcsql.debug2(sendgrid.sendgrid_api_url||' response: '||response);
exception
   when others then 
      arcsql.err(error_text=>'sendgrid.send: '||dbms_utility.format_error_stack);
      raise;
end;

end;
/

show errors
