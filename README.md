# Submarine

Rails multi-tenant project management front-end for Harvest time tracking application. Two-way synchronization of Harvest data allowing rapid access and manipulation of local Harvest data.

## Deployment

`heroku labs:enable user-env-compile`

## Synchronization

Schedule regular synchronization

`rake sync:harvest[subdomain]`

Synchronizing time entries requires significant processing

`rake sync:time[subdomain,2000,2050]`
