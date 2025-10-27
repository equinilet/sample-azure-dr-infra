This will create a multi-region SQL Elastic pool; as well as a VM in the primary region that conects to the database.
The VM has the "adventureworks" sample website configured, it connects to the database and is available by browsing to
 http://<vm-public-ip-address>
once the terraform runs.

VM HA is configured in line with the Azure guidelines here
https://learn.microsoft.com/en-us/azure/site-recovery/azure-to-azure-how-to-enable-replication

SQL Server Elastic pool HA is configured in line wiht the Azure guildelines here
https://learn.microsoft.com/en-us/azure/azure-sql/database/active-geo-replication-overview?view=azuresql&tabs=tsql

There is a mechanism for testing this outlined here
https://learn.microsoft.com/en-us/azure/site-recovery/site-recovery-test-failover-to-azure


The terraform configuration uses the tutorial configuration so the setup costs around $1200 per month; it can be reduced
by tweaking the Elastic Pool parameters. 

USAGE

Please populate the sensitive.tfvars file with a valid tenant_id and subscription_id.
Ideally create a new subscription so all changes can be sandboxed there.

run

terraform init

to initialize and

terraform plan --var-file=sensitive.tfvars

to plan or apply to apply.

It takes a while for all of the resources to be created. 