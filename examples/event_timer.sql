
/*

* Event processing uses autonomous transactions so they will not interfere with
your application's code.

* Events must be started and stopped within the same session since the AUDSID 
is used in the start and stop code.

* Above must be done to support >1 thread processing the same event.

* This code is not designed for millions of events. It is a tool for moderate
event processing and instrumenting your code base. We are dealing with longer
periods here also. Not microseconds. 

* If you call stop_event without starting the event the code will silently 
fail. If we raised an error it could interfere with the application you 
are instrumenting and that acceptable.

* A regularly scheduled purge is run to remove orphans in audsid_event
table. Orphans are created by calling start without calling stop. The default
value is 4 hours old. There is a setting in config_settings to change this.

* If start_event is called again before calling stop no error is returned.
The new start time is recorded. I will be adding some ability to see misses
like this. When you see misses you should look at your instrumentation code
closer and find the code path that is the issue.

*/

-- Clear up the table for the example.
delete from audsid_event;

-- Nothing there.
select * from audsid_event;

-- Note, the calls below will use pragma autonomous_transaction to commit the data.

-- Start an event.
exec arcsql.start_event(event_group => 'hr', subgroup => 'payroll', name => 'batch_job');

-- Now we have a record.
select * from audsid_event;

-- Wait a little while and then end the event.
exec arcsql.stop_event(event_group => 'hr', subgroup => 'payroll', name => 'batch_job');

-- Record should be gone from here now.
select * from audsid_event;

-- Record should be aggregated into this table now.
-- This is the table you will want to integrating into some sort of monitoring.
-- There will be such a monitor build into ArcSQL (future).
select * from event;

-- Subgroup can be null but you have to specify it.
-- Event group and name are required.
exec arcsql.start_event(event_group=>'it', subgroup=>null, name=>'foo');

exec arcsql.stop_event(event_group=>'it', subgroup=>null, name=>'foo');

exec arcsql.delete_event(event_group=>'it', subgroup=>null, name=>'foo');

select * from event;

   