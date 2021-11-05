# rs-t-code

## What is built here
1. ``` iaac ``` dir contains all terraform code required to build a gke cluster and deploy nginx.
2. ``` k8s ``` dir contains a helm chart for nginx deployment.

## Recources created
- VPC with a safe Subnet that has a NAT GW.
- An auto-pilot GKE cluster to deploy Nginx.
- Nginx is deployed by helm manged by terraform helm provider.
- HPA for nginx by CPU utilization.
- A public golobal ip address used with nginx ingress.
- A Cloud Armor securoty policy to protect nginx access.
- An Up-Time check for the public ingress endpoint of nginx that will send an email in case nginx is down.

## Prerequisites
1. install terraform [v0.13+].
2. instal gcloud sdk [277.0.0+].
3. install helm binary [v3.2.0+].
4. Run the following two commands and follow instructions to login with you gcloud account:
    ```
    gcloud auth login
    gcloud auth application-default login
    ```
    note: make sure you have all required IAM permissions to provision the resources created by the code.

5. set default project to YOU_PROJECT_ID
    ```
    gcloud config set project [REPLACE_WITH_PROJECT_ID]
    ```
6. Make sure to maunally create the state file GCS bucket first (name is hard-coded in the main.tf)
7. clone this repo.
8. `cd` the repo dir and run the following:
    ```
    terraform init iaac/
    ```

## How to apply the code
While on repo dir path, run the following script and replace values **without** adding quotes.
```
export PROJECT_ID=[REPLACE_WITH_PROJECT_ID]
export GKE_AUTHORIZED_CIDR=[REPLACE_WITH_AUTHORIZED_CIDR]
export REGION=[REPLACE_WITH_REGION]

terraform apply \
-var project_id=$PROJECT_ID \
-var gke_authorized_source_ranges=$GKE_AUTHORIZED_CIDR \
-var region=$REGION \
iaac/
```

## How to view nginx index page
simply, once deployment is compleleted -> in the gke services dashboard, you should see the created ingress with a random public ip address, use this ip address in your browser window as follows: http://IP_ADD/

## How to test AutoScalling

1. In the HPA config set cpu untilization value to 1% and re-deploy.

2. Use this simple load-testing tool [hey](https://github.com/rakyll/hey):
    ```
    ./hey_linux_amd64 -c 80 -n 1000000 INGRESS_URL
    ```
2. in another shell, watch the HPA status
    ```
    watch -n 2 "kubectl get hpa"
    ```

## Future work
1. Enable IAP protection for nginx access (if required).
2. Make the gke cluster private and deploy a minimal bastion vm that allows only ssh-tunneling to be used for connections to the cluster.
3. Enable HTTPS for the nginx endpoint.
4. Apply PSPs to add more protection to the gke cluster.
5. Modifiy the way that the cluster uses to accesses internet to only allow specfic urls or domains.