## Deploying the Vizzy Helm Chart

This helm chart has a top level Vizzy chart, with a Postgresql chart defined as a dependency. When deploying the chart, be sure to specify a username, password, and database name for the postgresql chart.

First pick a username and password for the database and create a kubernetes secret. Be sure to include the host and post:

```bash
kubectl create secret generic vizzy-postgres-secret \
 --from-literal=host=postgres \ # optional, default is postgres
 --from-literal=port=5432 \ # optional, default is 5432
 --from-literal=username=postgres \ # required
 --from-literal=password=******** \ # required
 --from-literal=schema_search_path=public # optional, default is public
```

If you haven't setup the server with credentials follow the [setup](https://github.com/Workday/vizzy#setup) section on the readme.
 
After completing that, add another kubernetes secret for the rails master key that was generated and placed into `secrets.yml.key`. *Do not check in the encryption key into the repository,*

```bash
kubectl create secret generic vizzy-rails-master-key-secret --from-literal=token=**********************
```

Then you can deploy the helm chart, overriding any [values](https://github.com/Workday/vizzy/blob/master/vizzy/values.yaml) necessary. Run the install with this directory using the database username and password from above.

```bash
helm install . \
    --set image.repository=scottcbishop/vizzy \
    --set image.tag=3.1.1 \
    --set image.pullSecret=myregistrykey \
    --set env.vizzyUri.value=vizzy.com \
    --set service.type=LoadBalancer \
    --set replicaCount=1 \
    --set postgresql.postgresUser=postgres \
    --set postgresql.postgresPassword=******** \
    --set postgresql.postgresDatabase=vizzy
 ```
 
    
