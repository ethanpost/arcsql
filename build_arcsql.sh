#!/usr/bin/env bash

cp /dev/null ./arcsql_uninstall.sql
grep "^@" arcsql_install.sql | sed 's/^@/\.\//' | \
while read file_name; do 
   echo "grep \"^\-\- uninstall:\" \"${file_name}\""
   grep "^\-\- uninstall:" "${file_name}" | cut -d" " -f3- >> ./arcsql_uninstall.sql
done 

echo "define username='arcsql'" > ./grant_arcsql_to_user.sql 
grep "^\-\- grant:" ./arcsql_schema.sql  | cut -d" " -f3- >> ./grant_arcsql_to_user.sql 



