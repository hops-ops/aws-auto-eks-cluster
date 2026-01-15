### What's changed in v0.3.1

* fix: handle m.crossplane.io provider object format for observed state (by @patrickleet)

  The new m.crossplane.io provider returns vpcConfig, identity, and oidc
  as flat objects instead of arrays. This caused $obs.cluster.subnetIds
  to be empty, preventing NodeClass and NodePool from being rendered.

  Now handles both formats:
  - map/object (m.crossplane.io): use directly
  - slice/array (upbound.io): take first element

  Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>


See full diff: [v0.3.0...v0.3.1](https://github.com/hops-ops/aws-auto-eks-cluster/compare/v0.3.0...v0.3.1)
