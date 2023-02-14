# Intro
TBD: a generic description of what is going to happen.. Maybe a diagram with it?

# Setup Steps

## 1. Local cluster + Crossplane
In the first step of the setup process we are going to create an EKS cluster for our management cluster. We sill create a local cluster, install Crossplane on it and let it create an EKS cluster.

### Create local cluster
Install Kind on your local laptop and then create a local cluster
`kind create cluster -n travelspirit-boot`

Check that the local cluster was created correctly
`kind get clusters`

Create  namespaces
```
kubectl apply -f bootstrap/cluster-resources/in-cluster/crossplane-ns.yaml
kubectl apply -f bootstrap/cluster-resources/in-cluster/travelspirit-management-ns.yaml
```

### Configure AWS
We need to create a Secret in the cluster, holding the AWS credentials

```
# Replace `[...]` with your access key ID`
export AWS_ACCESS_KEY_ID=[...]

# Replace `[...]` with your secret access key
export AWS_SECRET_ACCESS_KEY=[...]

echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
" >aws-creds.conf

kubectl -n crossplane-system create secret generic aws-creds --from-file creds=./aws-creds.conf
```

### Install Crossplane
Install crossplane on cluster (https://docs.crossplane.io/v1.9/getting-started/install-configure/)

```
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm upgrade -i crossplane crossplane-stable/crossplane -n crossplane-system --create-namespace --wait
```

Check Crossplane status

```
helm list -n crossplane-system
kubectl get all -n crossplane-system

```

### Prepare Crossplane

Provider setup in Crossplane (From this step onwards, we will be using crossplane-initial-eks-setup directory)
```
kubectl apply -f bootstrap/cluster-resources/crossplane/provider-aws.yaml

kubectl get provider -w

```
Wait for Provider installation and healthy status to be TRUE, then apply the following:

```
kubectl apply -f bootstrap/cluster-resources/crossplane/provider-config-aws.yaml

kubectl apply -f bootstrap/cluster-resources/crossplane/provider-helm.yaml 

kubectl apply -f bootstrap/cluster-resources/crossplane/provider-kubernetes.yaml 

```

Check status of provider packages, they should all be healthy
`kubectl get pkgrev`


## Create EKS cluster 
Create VPC and network related resources
```
kubectl apply -f bootstrap/cluster-resources/crossplane-packages/vpc-definition.yaml
kubectl apply -f bootstrap/cluster-resources/crossplane-packages/vpc-composition.yaml

```

Create the VPC, where the EKS cluster should reside in
[TBD] the path should be corrected to the argocd application
```
kubectl -n travelspirit-management apply -f ./env/tst/vpc-eks.yaml
```

Verify if resources are created
```
kubectl get vpc
kubectl get subnet
```

kubectl get $resourceKind.
if status of any resource is stuck in FLASE status then  use `kubectl describe $[resourceKind]` to get the events

Create EKS definition and composition for crossplane.
```
kubectl apply -f bootstrap/cluster-resources/crossplane-packages/eks-definition.yaml
kubectl apply -f bootstrap/cluster-resources/crossplane-packages/eks-composition.yaml
```

Actually create the EKS cluster
[TBD] connect to yaml file of to be create application
```
kubectl -n travelspirit-management apply -f ./env/tst/aws-eks.yaml
```

### Verify / check
Verify if resources are created

```
kubectl get cluster
```
**it will take aroung 15-20 mins to provising a cluster along with nodegroups.**

### Connect to new Cluster
For next steps to work correctly, we want to connect our kubectl to our newly created EKS cluster.
```
kubectl --namespace crossplane-system get secret travelspirit-management-cluster-secret --output jsonpath="{.data.kubeconfig}" | base64 -d >kubeconfig.yaml
export KUBECONFIG=$PWD/kubeconfig.yaml
```

## Setup ArgoCD autopilot
To setup argoCD to then take over the bootstrap process and connect to our git repo.

### Install argoCD autopilot CLI
Follow steps in https://argocd-autopilot.readthedocs.io/en/stable/Installation-Guide/

### Bootstrap
First set the git token and repo
```
export GIT_TOKEN=[$TOKEN] # replace with token
export GIT_REPO=https://github.com/travelspirit-infra/management.git
```

Then execute the bootstrap command
```
argocd-autopilot repo bootstrap --recover
```
Wait until the script is ready.

**STORE argoCD admin password in bitwarden**

### Have a look at argocd
As proposed by the bootstrap command, you can connect to the argoCD instance of the management cluster and see whether everything is syncing.
```
kubectl port-forward -n argocd svc/argocd-server 8080:80
```


## TODOS
* Create secret for AWS
** for now https://github.com/vfarcic/cncf-demo/blob/main/crossplane/create-secret-google.sh
* try to get crossplane to work as an application
* move over crossplane yaml files to that application
* continue setting up ECR etc as projects
* update this script with correct file locations
