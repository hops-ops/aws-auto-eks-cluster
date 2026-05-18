### What's changed in v1.0.0

* feat: opt-in Auto Mode tag propagation + size-floor NodePool defaults (by @patrickleet)

  BREAKING CHANGE: - Add spec.nodeConfig.nodeClass.tags for tags propagated to Auto Mode
    resources. Render the resource-tagging IAM Policy + attachment only
    when nodeClassTags is non-empty (previously always emitted).
  - Add eks.amazonaws.com/instance-memory > 7999 and instance-cpu > 1
    to the default NodePool requirements. Default fleet now skips
    c-family .large (4 GiB) and t.medium-class instances that hit
    max-pod density on monitoring workloads.

  BREAKING CHANGE: existing clusters relying on the default NodePool
  requirements will see Karpenter mark sub-8GiB nodes as drifted and
  replace them with bigger instances on next reconcile.


See full diff: [v0.11.0...v1.0.0](https://github.com/hops-ops/aws-auto-eks-cluster/compare/v0.11.0...v1.0.0)
