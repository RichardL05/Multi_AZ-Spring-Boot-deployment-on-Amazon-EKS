# Cluster configuration and supporting snapshots

The final application chart is `../chart/`. `cluster.yaml` now requests two private workers with `desiredCapacity: 2`, `minSize: 2`, and `maxSize: 3`. Confirm that ready workers actually occupy both configured AZs after provisioning.

## Installer and controller-file map

| Repository path | Identity | Use |
| --- | --- | --- |
| `get_helm.sh` at repository root | Helm 4 installer snapshot | Recorded project Helm major version; the guide records 4.3.2 |
| `cluster/get_helm.sh` | Helm 3 installer snapshot | Alternative installer retained for reference |
| `iam_policy.json` at repository root | Verified match to AWS Load Balancer Controller `v2.5.4` policy | Canonical policy for the recorded controller chart `1.5.5` |
| `cluster/iam_policy.json` | Alternative policy snapshot; exact release provenance not recorded | Do not substitute for the root policy without selecting and verifying a matching controller release |
| `cluster/crds.yaml` | Additional controller CRD snapshot; exact release provenance not recorded | Use CRDs supplied by the controller release you actually select |

The two policies are valid JSON but contain different permissions. File location does not establish version compatibility. Keep the controller chart, IAM policy and CRDs aligned to one release.

The AWS IDs, policy ARN and SSH key name in `cluster.yaml` remain historical environment references. Replace them before recreating infrastructure; editing this file does not resize an existing node group.

[Official controller installation guide](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/)
