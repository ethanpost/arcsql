

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
      to_address=>'post.ethan@gmail.com', 
      subject=>'How do you like SendGrid?', 
      message=>'Hey Ethan, just checking in.');
end;
/
select * from arcsql_log order by 1 desc;




