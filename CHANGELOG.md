### What's changed in v0.6.0

* feat: admin role to cluster admin assignment (#7) (by @patrickleet)

  * **New Features**
    * Added `adminRoleArn` field to AutoEKSCluster specification for cluster-admin access via IAM roles
    * Automatic generation of default admin access entries and associated policies when `adminRoleArn` is configured


See full diff: [v0.5.0...v0.6.0](https://github.com/hops-ops/aws-auto-eks-cluster/compare/v0.5.0...v0.6.0)
