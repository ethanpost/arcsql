# Readme 

A hot mess of things I use when working with Oracle. Will be recording videos for each feature and embedding links in the source soon. Under heavy development at the moment.

## Installation

As an administrative user perform the following step.

1. Run arcsql_user.sql ${USERNAME} to provide the required grants to the user who will own the packages. 

Perform the following steps as the user whom received the grants in the last step.

1. Consider running uninstall_arcsql.sql if you are testing development versions of the product to ensure all tables are completely rebuilt.
2. Run the @arcsql_install.sql from the same directory as the user you gave the grants to.

## Uninstall
As the user who owns the ArcSQL objects run the uninstall_arcsql.sql script.

## Author

* Ethan Ray Post - https://e-t-h-a-n.com/ 
* I freelance. Get in touch if you want to hire me for a project.
