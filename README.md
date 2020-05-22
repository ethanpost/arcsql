
# Readme 

I managed Oracle databases for at least 15 years. I have developed a number of helpful tools and utilities and my goal is to pull a number of those assets together, make them better, and put them here in ArcSQL. Enjoy!

| Feature | Description |
| --- | --- |
| Date & Time Functions | There are just a couple functions at the moment. I will be adding more as needed/requested. |
| String Functions | A few here to start with, more coming. |
| Utilities | Basic utilities that don't fit in other categories easily. |
| Counters | Instrument your code with simple counters which can be tracked, visualized, or alerted on using other tools. |
| Event Timers| Start and stop events in jobs and code. Keep a tally of event count and total elapsed seconds between starts and stops. Data is stored in the EVENT table.
| Locking/Locks | There are some helpful lock related views. Right now they can be queried. In the future there will be some automated monitoring of these views included.
| Schema Change Management | These are functions which allow you to deploy your schema and all changes between versions using a single file. See the arcsql_schema.sql file for some examples.
| Key Value Store | A simple interface for quickly storing and reading values. Good for storing state without needing to create a custom table for every function. |
| Configuration Settings | An interface to create initial configuration settings which can then be modified by your users. |
| SQL Monitoring | A unique and powerful way to monitor SQL. |
| Delivered Task Scheduler | The ability to run a set of delivered tasks easily without needing to custom jobs for each one. |
| **FUTURE** | |
| Alerting | Alerting will be linked to messaging and alert groups.  |
| Sensors | Sensors make it easy to write monitors which trigger when something changes.| 

## Installation

As an administrative user perform the following step.

1. Run arcsql_user.sql ${USERNAME} to provide the required grants to the user who will own the packages. 

Perform the following steps as the user whom received the grants in the last step.

1. Consider running uninstall_arcsql.sql if you are testing development versions of the product to ensure all tables are completely rebuilt.
2. Run arcsql_install_single_file.sql.
3. To start the DBMS_JOB's which run any recurring tasks run "exec arcsql.run;" command.
4. To stop the delivered DBMS_JOB's run "exec arcsql.stop;" command;

## Uninstall
As the user who owns the ArcSQL objects run the uninstall_arcsql.sql script.

## Author

* Ethan Ray Post - https://e-t-h-a-n.com/ 

