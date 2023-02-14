###### Cleanup Initial Crossplane EKS resources #####

##Repo: https://github.com/travelspirit-infra/management.git

# Provider setup in Crossplane (From this step onwards, we will be using crossplane-initial-eks-setup directory)

cd crossplane-initial-eks-setup

# Destroying resources

unset KUBECONFIG

kubectl -n team-a delete -f env/tst/argo-eks.yaml

kubectl -n team-a delete -f env/tst/aws-eks.yaml

kubectl -n team-a delete -f env/tst/vpc-eks.yaml