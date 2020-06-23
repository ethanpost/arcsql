

/*

Make sure the following values are set in one of the arcsql_*_settings package
or the arcsql_config table.

sendgrid_api_key varchar2(120) := '';
   sendgrid_from_address varchar2(120) := '';

*/

exec sendgrid.send(
   to_address=>'post.ethan@gmail.com', 
   subject=>'How do you like SendGrid?', 
   message=>'Hey Ethan, just checking in.');



