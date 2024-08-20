## Azure Cosmos DB for MongoDB

Azure Cosmos DB for MongoDB is a fully-managed NoSQL database service designed to scale horizontally with flexible schemas. It provides high availability, multi-region replication, automated failover, and low-latency read/write operations.

### Design Decisions

- **Automatic Failover**: Configured to enable automatic failover to enhance availability.
- **Multiple Write Locations**: Supports multiple write locations to allow writes in any region.
- **Geo-Redundancy**: Configures paired regions and supports additional regions for enhanced redundancy.
- **Backup Configuration**: Supports both continuous and periodic backups to ensure data safety.
- **Network Security**: Uses virtual network rules, private endpoints, and DNS zones to restrict network access.
- **Monitoring and Alarming**: Implements monitors and alarms for RU consumption and server latency to ensure operational efficiency.
- **Capabilities**: Enables serverless, aggregation pipeline, document-level TTL, and MongoDB version 3.4 capabilities.

### Runbook

#### Connection Issues to MongoDB Instance

If you are experiencing issues connecting to the Azure Cosmos DB instance, verify the connection details and permissions.

Check MongoDB connection info:
```sh
az cosmosdb show --name <cosmosdb_account_name> --resource-group <resource_group>
```

Expected output should contain correct connection strings and available keys.

Ensure you can ping the database endpoint:
```sh
ping <cosmosdb_account_name>.mongo.cosmos.azure.com
```

Check your firewall rules to see if the IP is allowed:
```sh
az cosmosdb list-keys --name <cosmosdb_account_name> --resource-group <resource_group> | jq
```

#### High RU Consumption

If the database is consuming more than the allocated Request Units (RU), investigate the workloads and adjust provisioned RUs or optimize queries.

Monitor RU consumption:
```sh
az monitor metrics list --resource <resource_id> --metric "NormalizedRUConsumption"
```

Optimize queries using indexes:
```sh
db.collection.createIndex({ fieldname: 1 })
```

#### Latency Issues

If you are experiencing high latency, ensure that your configurations leverage the closest region/replica and verify the health.

Check latency metrics:
```sh
az monitor metrics list --resource <resource_id> --metric "ServerSideLatency"
```

Verify database health using Mongo shell:
```javascript
db.serverStatus().opcounters
```

Ensure indexes are in place to optimize read/write efficiency:
```javascript
db.collection.createIndex({ fieldname: 1 })
```

#### Backup and Restore Issues

If you encounter issues with backup or restore processes, check the configured backup settings.

Verify backup settings:
```sh
az cosmosdb show --name <cosmosdb_account_name> --resource-group <resource_group> --query "backupPolicy"
```

Restore data using a point in time restore:
```sh
az cosmosdb restore --name <cosmosdb_account_name> --resource-group <resource_group> --restore-timestamp <timestamp>
```

#### Permission Issues

Ensure the necessary permissions are granted to the service principal or user accessing the Cosmos DB.

Check current permissions:
```sh
az cosmosdb sql role assignment list --account-name <cosmosdb_account_name> --resource-group <resource_group>
```

Grant necessary permissions:
```sh
az cosmosdb sql role assignment create --account-name <cosmosdb_account_name> --resource-group <resource_group> --scope "/" --role-definition-id "<role_id>" --principal-id "<principal_id>"
```

These commands and guidelines should help you effectively manage and troubleshoot your Azure Cosmos DB for MongoDB instances.

