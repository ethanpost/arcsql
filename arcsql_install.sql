

@arcsql_schema_support.sql
@arcsql_schema.sql 
@arcsql_pkgh.sql 
@arcsql_pkgb.sql 
alter package arcsql compile;
show errors
alter package arcsql compile body;
show errors
@arcsql_config.sql
@arcsql_jobs.sql
@arcsql_public_settings.sql
-- @arcsql_private_settings.sql
commit;

