## AWS Application Load Balancer setup steps:
=============================================
1. Tags all the subnet with the following tags:

   1.1 For Private subnet:
         - ```key - kubernetes.io/role/internal-elb``` 
         - ```value - 1 ```
           
   1.2 For Public subnet:
       - ```key - kubernetes.io/role/elb```
       - ```value - 1 ```
         

2. Create IAM Policy for AWS Load Balancer Controller. 
   
   2.1 Get policy document using command : 
       ``` 
       curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
       ```
       
   2.2 Apply the policy using command :
      ``` 
             aws iam create-policy \
            --policy-name AWSLoadBalancerControllerIAMPolicy \
            --policy-document file://iam_policy.json 
        ```

3. Install eksctl , kubectl , Helm (if not already)

  3.1 Install EKSCTL using command : 
        ``` 
curl --silent --location \
"https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz -C /tmp

mv /tmp/eksctl /usr/local/bin/eksctl

eksctl version

        ``` 
============

  3.2 Install KUBECTL using command : 

         ``` 
curl -LO "https://dl.k8s.io/release/v1.36.6/bin/linux/amd64/kubectl"

chmod +x kubectl

mv kubectl /usr/local/bin/kubectl

kubectl version --client

        ``` 
============

  3.3 Install HELM using command : 
  
    ``` 
curl -fsSL -o get_helm.sh \
https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4

chmod 700 get_helm.sh 

# ./get_helm.sh

# helm version

    ``` 
============

## Final application configuration

- Use **`chart/`** for the completed project. `tschart/` is an alternative chart, clearly labeled in its own README.
- `cluster/cluster.yaml` requests two workers: desired/minimum `2`, maximum `3`. Verify ready workers in both AZs.
- `chart/values.yaml` enables the ALB Ingress. The template now honors `ingress.enabled`; setting it to `false` omits the Ingress.
- Database Secrets are supplied **outside Helm**. The plaintext credential template has been removed; the Deployment retains its existing Secret names and keys.
- Installer and controller-policy snapshots are explained in [cluster/README.md](cluster/README.md).

### Create database Secrets privately before deploying

Run these commands on the management host after selecting the intended Kubernetes context and namespace. The script prompts for fresh credentials; it does not put credential values in command-line arguments or committed files.

```bash
kubectl config current-context

kubectl create namespace richard-springboot-app --dry-run=client -o yaml |
  kubectl apply -f -

bash scripts/create-db-secrets.sh richard-springboot-app
```

The script creates or updates:

| Secret | Key | Deployment environment variable |
| --- | --- | --- |
| `mysql-username` | `username` | `SPRING_DATASOURCE_USERNAME` |
| `mysql-root-password` | `password` | `SPRING_DATASOURCE_PASSWORD` |

This workflow is for a fresh deployment of the removed project environment. An existing Helm release that owned the old Secret resources needs an ownership/retention migration before upgrade, because removing a resource from a chart can delete it during upgrade.

Then validate and deploy:

```bash
helm lint ./chart

helm upgrade --install richard-springboot ./chart \
  --namespace richard-springboot-app \
  --wait --timeout 10m

kubectl get pods -n richard-springboot-app -o wide
kubectl get nodes -L topology.kubernetes.io/zone
kubectl get ingress -n richard-springboot-app
```

Expected: two ready application pods on workers in different AZs, and an Ingress hostname for the ALB. Helm notes now show how to obtain the ALB URL.

**Before reuse:** replace historical AWS resource IDs, ECR URI, RDS endpoint and key/policy references. Removing a password from the current files does not remove it from older Git commits; rotate any exposed credential that is still valid. No history rewrite or infrastructure deployment is performed by this repository cleanup.
