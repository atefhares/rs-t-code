# rs-t-code

## Prerequisites:
1. install terraform [v0.13+].
2. instal gcloud sdk [277.0.0+].
3. install helm binary [v3.2.0+].
4. Run the following two commands and follow instructions to login with you gcloud account:
    ```
    gcloud auth login
    gcloud auth application-default login
    ```
5. set default project to YOU_PROJECT_ID
    ```
    gcloud config set project [REPLACE_WITH_PROJECT_ID]
    ```
6. clone this repo.
7. `cd` the repo dir and run the following:
    ```
    terraform init iaac/
    ```

## How to apply the code:-
While on repo dir path, run the following script and replace values **without** adding quotes.
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