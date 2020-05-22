#!/usr/bin/env bash

(
cat ./arcsql_schema_support.sql
echo ""
cat ./arcsql_schema.sql 
echo ""
cat ./arcsql_pkgh.sql 
echo ""
cat ./arcsql_pkgb.sql 
echo ""
echo "alter package arcsql compile;"
echo "alter package arcsql compile body;"
echo ""
cat ./arcsql_config.sql
echo ""
) > ./arcsql_install_single_file.sql 

(
cat <<EOF
/*
ArcSQL should be installed.

If something went wrong...

   * Did you run the arcsql_user.sql which grants this user the right permissions?
   * Did you try running the install script again?
   * Send me an email, post.ethan@gmail.com.

-- Start/Add the DBMS_JOB's to run delivered tasks.
exec arcsql.run;

-- Stop/Remove the DBMS_JOB's above.
exec arcsql.stop;

*/
EOF
) >> ./arcsql_install_single_file.sql 

grep "^\-\- uninstall:" ./arcsql_schema.sql  | cut -d" " -f3- > ./uninstall_arcsql.sql 

echo "define username='foo'" > ./grant_arcsql_to_user.sql 
grep "^\-\- grant:" ./arcsql_schema.sql  | cut -d" " -f3- >> ./grant_arcsql_to_user.sql 



