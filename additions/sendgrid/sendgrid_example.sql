

/*

Make sure the following values are set in one of the arcsql_*_settings package
or the arcsql_config table.

sendgrid_api_key varchar2(120) := '';
   sendgrid_from_address varchar2(120) := '';

*/

delete from arcsql_log;
commit;
begin 
   arcsql.log_level := 1;
   sendgrid.send(
      p_to=>'post.ethan@gmail.com', 
      p_subject=>'How do you like SendGrid?', 
      p_body=>'Hey Ethan, just checking in.');
end;
/
select * from arcsql_log order by 1 desc;




