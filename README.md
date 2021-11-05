# rs-t-code

## Pre requsitis:


## How to run the code:-
run the following script
```
export PROJECT_ID=[REPLACE_WITH_PROJECT_ID]
export GKE_AUTHORIZED_CIDR=[REPLACE_WITH_AUTHORIZED_CIDR]
export REGION=[REPLACE_WITH_REGION]

terraform apply \
-var project_id=$PROJECT_ID \
-var gke_authorized_source_ranges=$GKE_AUTHORIZED_CIDR \
-var region=$REGION \
-var zone=$ZONE \
iaac/
```