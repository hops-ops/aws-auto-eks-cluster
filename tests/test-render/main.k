import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.ai.com.ops.hops.aws.v1alpha1 as awsv1alpha1

_items = [

    # Test: Minimal cluster renders IAM roles
    metav1alpha1.CompositionTest{
        metadata.name = "minimal-renders-iam-roles"
        spec = {
            compositionPath = "apis/autoeksclusters/composition.yaml"
            xrdPath = "apis/autoeksclusters/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = awsv1alpha1.AutoEKSCluster{
                metadata.name = "test-cluster"
                spec = {
                    clusterName = "test-cluster"
                    region = "us-east-1"
                    accountId = "123456789012"
                    version = "1.31"
                    subnetIds = ["subnet-aaa", "subnet-bbb"]
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "test-cluster-controlplane"
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "test-cluster-node"
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Policy"
                    metadata.name = "test-cluster-resource-tagging"
                }
            ]
        }
    }

    # Test: Encryption enabled creates KMS key
    metav1alpha1.CompositionTest{
        metadata.name = "encryption-creates-kms"
        spec = {
            compositionPath = "apis/autoeksclusters/composition.yaml"
            xrdPath = "apis/autoeksclusters/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = awsv1alpha1.AutoEKSCluster{
                metadata.name = "test-encrypted"
                spec = {
                    clusterName = "test-encrypted"
                    region = "us-west-2"
                    accountId = "123456789012"
                    version = "1.31"
                    subnetIds = ["subnet-aaa"]
                    encryptionEnabled = True
                }
            }
            assertResources = [
                {
                    apiVersion = "kms.aws.m.upbound.io/v1beta1"
                    kind = "Key"
                    metadata.name = "test-encrypted-secrets"
                }
                {
                    apiVersion = "kms.aws.m.upbound.io/v1beta1"
                    kind = "Alias"
                    metadata.name = "test-encrypted-secrets"
                }
            ]
        }
    }

    # Test: Tags are merged with defaults
    metav1alpha1.CompositionTest{
        metadata.name = "tags-merged-with-defaults"
        spec = {
            compositionPath = "apis/autoeksclusters/composition.yaml"
            xrdPath = "apis/autoeksclusters/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = awsv1alpha1.AutoEKSCluster{
                metadata.name = "test-tags"
                spec = {
                    clusterName = "test-tags"
                    region = "us-east-1"
                    accountId = "123456789012"
                    version = "1.31"
                    subnetIds = ["subnet-aaa"]
                    tags = {environment = "test", team = "platform"}
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "test-tags-controlplane"
                    spec.forProvider.tags = {
                        "hops.ops.com.ai/managed" = "true"
                        "hops.ops.com.ai/autoekscluster" = "test-tags"
                        environment = "test"
                        team = "platform"
                    }
                }
            ]
        }
    }

    # Test: Cluster renders after IAM roles are ready (step 1 observed)
    metav1alpha1.CompositionTest{
        metadata.name = "cluster-renders-after-iam-ready"
        spec = {
            compositionPath = "apis/autoeksclusters/composition.yaml"
            xrdPath = "apis/autoeksclusters/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = awsv1alpha1.AutoEKSCluster{
                metadata.name = "test-cluster"
                spec = {
                    clusterName = "test-cluster"
                    region = "us-east-1"
                    accountId = "123456789012"
                    version = "1.31"
                    subnetIds = ["subnet-aaa", "subnet-bbb"]
                }
            }
            observedResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "test-cluster-controlplane"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "iam-role-controlplane"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "iam-role-controlplane"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:iam::123456789012:role/test-cluster-controlplane", name = "test-cluster-controlplane"}
                    }
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "test-cluster-node"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "iam-role-node"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "iam-role-node"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:iam::123456789012:role/test-cluster-node", name = "test-cluster-node"}
                    }
                }
                {
                    apiVersion = "kms.aws.m.upbound.io/v1beta1"
                    kind = "Key"
                    metadata = {
                        name = "test-cluster-secrets"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "kms-key"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "kms-key"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012", keyId = "12345678-1234-1234-1234-123456789012"}
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "eks.aws.m.upbound.io/v1beta1"
                    kind = "Cluster"
                    metadata.name = "test-cluster"
                }
            ]
        }
    }

    # Test: Permissions boundary applied to IAM roles
    metav1alpha1.CompositionTest{
        metadata.name = "permissions-boundary-applied"
        spec = {
            compositionPath = "apis/autoeksclusters/composition.yaml"
            xrdPath = "apis/autoeksclusters/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = awsv1alpha1.AutoEKSCluster{
                metadata.name = "test-boundary"
                spec = {
                    clusterName = "test-boundary"
                    region = "us-east-1"
                    accountId = "123456789012"
                    version = "1.31"
                    subnetIds = ["subnet-aaa"]
                    permissionsBoundary = "arn:aws:iam::123456789012:policy/EKSBoundary"
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "test-boundary-controlplane"
                    spec.forProvider.permissionsBoundary = "arn:aws:iam::123456789012:policy/EKSBoundary"
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "test-boundary-node"
                    spec.forProvider.permissionsBoundary = "arn:aws:iam::123456789012:policy/EKSBoundary"
                }
            ]
        }
    }

    # Test: Encryption disabled skips KMS resources
    metav1alpha1.CompositionTest{
        metadata.name = "encryption-disabled-no-kms"
        spec = {
            compositionPath = "apis/autoeksclusters/composition.yaml"
            xrdPath = "apis/autoeksclusters/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = awsv1alpha1.AutoEKSCluster{
                metadata.name = "test-nokms"
                spec = {
                    clusterName = "test-nokms"
                    region = "us-east-1"
                    accountId = "123456789012"
                    version = "1.31"
                    subnetIds = ["subnet-aaa"]
                    encryptionEnabled = False
                }
            }
            assertResources = [
                # IAM roles should still render
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "test-nokms-controlplane"
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata.name = "test-nokms-node"
                }
            ]
        }
    }

    # Test: AdminRoleArn creates default admin access entry (after cluster ready)
    metav1alpha1.CompositionTest{
        metadata.name = "admin-role-creates-access-entry"
        spec = {
            compositionPath = "apis/autoeksclusters/composition.yaml"
            xrdPath = "apis/autoeksclusters/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = awsv1alpha1.AutoEKSCluster{
                metadata.name = "test-admin"
                spec = {
                    clusterName = "test-admin"
                    region = "us-east-1"
                    accountId = "123456789012"
                    version = "1.31"
                    subnetIds = ["subnet-aaa"]
                    adminRoleArn = "arn:aws:iam::123456789012:role/Admin"
                }
            }
            observedResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "test-admin-controlplane"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "iam-role-controlplane"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "iam-role-controlplane"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:iam::123456789012:role/test-admin-controlplane", name = "test-admin-controlplane"}
                    }
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "test-admin-node"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "iam-role-node"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "iam-role-node"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:iam::123456789012:role/test-admin-node", name = "test-admin-node"}
                    }
                }
                {
                    apiVersion = "kms.aws.m.upbound.io/v1beta1"
                    kind = "Key"
                    metadata = {
                        name = "test-admin-secrets"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "kms-key"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "kms-key"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:kms:us-east-1:123456789012:key/12345678", keyId = "12345678"}
                    }
                }
                {
                    apiVersion = "eks.aws.m.upbound.io/v1beta1"
                    kind = "Cluster"
                    metadata = {
                        name = "test-admin"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "cluster"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "cluster"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {
                            arn = "arn:aws:eks:us-east-1:123456789012:cluster/test-admin"
                            endpoint = "https://ABCDEF.gr7.us-east-1.eks.amazonaws.com"
                            id = "test-admin"
                            identity = [{oidc = [{issuer = "https://oidc.eks.us-east-1.amazonaws.com/id/ABCDEF"}]}]
                            status = "ACTIVE"
                            vpcConfig = {
                                clusterSecurityGroupId = "sg-012345"
                                subnetIds = ["subnet-aaa"]
                            }
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "eks.aws.m.upbound.io/v1beta1"
                    kind = "AccessEntry"
                    metadata.name = "test-admin-default-admin"
                    spec.forProvider.principalArn = "arn:aws:iam::123456789012:role/Admin"
                }
                {
                    apiVersion = "eks.aws.m.upbound.io/v1beta1"
                    kind = "AccessPolicyAssociation"
                    metadata.name = "test-admin-default-admin-policy"
                }
            ]
        }
    }

    # Test: OIDC provider renders when enabled (after cluster ready with OIDC issuer)
    metav1alpha1.CompositionTest{
        metadata.name = "oidc-enabled-renders-provider"
        spec = {
            compositionPath = "apis/autoeksclusters/composition.yaml"
            xrdPath = "apis/autoeksclusters/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = awsv1alpha1.AutoEKSCluster{
                metadata.name = "test-oidc"
                spec = {
                    clusterName = "test-oidc"
                    region = "us-east-1"
                    accountId = "123456789012"
                    version = "1.31"
                    subnetIds = ["subnet-aaa"]
                    oidc = {enabled = True}
                }
            }
            observedResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "test-oidc-controlplane"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "iam-role-controlplane"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "iam-role-controlplane"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:iam::123456789012:role/test-oidc-controlplane", name = "test-oidc-controlplane"}
                    }
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "test-oidc-node"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "iam-role-node"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "iam-role-node"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:iam::123456789012:role/test-oidc-node", name = "test-oidc-node"}
                    }
                }
                {
                    apiVersion = "kms.aws.m.upbound.io/v1beta1"
                    kind = "Key"
                    metadata = {
                        name = "test-oidc-secrets"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "kms-key"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "kms-key"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:kms:us-east-1:123456789012:key/12345678", keyId = "12345678"}
                    }
                }
                {
                    apiVersion = "eks.aws.m.upbound.io/v1beta1"
                    kind = "Cluster"
                    metadata = {
                        name = "test-oidc"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "cluster"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "cluster"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {
                            arn = "arn:aws:eks:us-east-1:123456789012:cluster/test-oidc"
                            endpoint = "https://ABCDEF.gr7.us-east-1.eks.amazonaws.com"
                            id = "test-oidc"
                            identity = [{oidc = [{issuer = "https://oidc.eks.us-east-1.amazonaws.com/id/ABCDEF"}]}]
                            status = "ACTIVE"
                            vpcConfig = {
                                clusterSecurityGroupId = "sg-012345"
                                subnetIds = ["subnet-aaa"]
                            }
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "OpenIDConnectProvider"
                    metadata.name = "test-oidc"
                    spec.forProvider.url = "https://oidc.eks.us-east-1.amazonaws.com/id/ABCDEF"
                }
            ]
        }
    }

    # Test: Security group rules render when enabled (after cluster ready with SG ID)
    metav1alpha1.CompositionTest{
        metadata.name = "security-group-rules-render"
        spec = {
            compositionPath = "apis/autoeksclusters/composition.yaml"
            xrdPath = "apis/autoeksclusters/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = awsv1alpha1.AutoEKSCluster{
                metadata.name = "test-sg"
                spec = {
                    clusterName = "test-sg"
                    region = "us-east-1"
                    accountId = "123456789012"
                    version = "1.31"
                    subnetIds = ["subnet-aaa"]
                    securityGroupRules = {
                        enabled = True
                        ingress = [
                            {
                                description = "VPN access"
                                cidrIpv4 = "10.0.0.0/8"
                                fromPort = 443
                                toPort = 443
                                ipProtocol = "tcp"
                            }
                        ]
                    }
                }
            }
            observedResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "test-sg-controlplane"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "iam-role-controlplane"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "iam-role-controlplane"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:iam::123456789012:role/test-sg-controlplane", name = "test-sg-controlplane"}
                    }
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "test-sg-node"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "iam-role-node"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "iam-role-node"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:iam::123456789012:role/test-sg-node", name = "test-sg-node"}
                    }
                }
                {
                    apiVersion = "kms.aws.m.upbound.io/v1beta1"
                    kind = "Key"
                    metadata = {
                        name = "test-sg-secrets"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "kms-key"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "kms-key"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {arn = "arn:aws:kms:us-east-1:123456789012:key/12345678", keyId = "12345678"}
                    }
                }
                {
                    apiVersion = "eks.aws.m.upbound.io/v1beta1"
                    kind = "Cluster"
                    metadata = {
                        name = "test-sg"
                        annotations = {
                            "crossplane.io/composition-resource-name" = "cluster"
                            "gotemplating.fn.crossplane.io/composition-resource-name" = "cluster"
                        }
                    }
                    status = {
                        conditions = [{type = "Ready", status = "True", reason = "Available"}]
                        atProvider = {
                            arn = "arn:aws:eks:us-east-1:123456789012:cluster/test-sg"
                            endpoint = "https://ABCDEF.gr7.us-east-1.eks.amazonaws.com"
                            id = "test-sg"
                            identity = [{oidc = [{issuer = "https://oidc.eks.us-east-1.amazonaws.com/id/ABCDEF"}]}]
                            status = "ACTIVE"
                            vpcConfig = {
                                clusterSecurityGroupId = "sg-012345"
                                subnetIds = ["subnet-aaa"]
                            }
                        }
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "SecurityGroupIngressRule"
                    metadata.name = "test-sg-sg-rule-0"
                    spec.forProvider = {
                        cidrIpv4 = "10.0.0.0/8"
                        fromPort = 443
                        toPort = 443
                        ipProtocol = "tcp"
                        description = "VPN access"
                        securityGroupId = "sg-012345"
                    }
                }
            ]
        }
    }

    # Test: External name annotations applied for import scenario
    metav1alpha1.CompositionTest{
        metadata.name = "import-external-names"
        spec = {
            compositionPath = "apis/autoeksclusters/composition.yaml"
            xrdPath = "apis/autoeksclusters/definition.yaml"
            timeoutSeconds = 120
            validate = True
            xr = awsv1alpha1.AutoEKSCluster{
                metadata.name = "test-import"
                spec = {
                    clusterName = "test-import"
                    region = "us-east-1"
                    accountId = "123456789012"
                    version = "1.31"
                    subnetIds = ["subnet-aaa"]
                    externalName = "my-existing-cluster"
                    managementPolicies = ["Create", "Observe", "Update", "LateInitialize"]
                    iam = {
                        controlPlaneRole = {externalName = "my-cluster-cp"}
                        nodeRole = {externalName = "my-cluster-node"}
                    }
                    kms = {externalName = "12345678-1234-1234-1234-123456789012"}
                    nodeConfig = {enabled = False}
                }
            }
            assertResources = [
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "test-import-controlplane"
                        annotations = {"crossplane.io/external-name" = "my-cluster-cp"}
                    }
                    spec.managementPolicies = ["Create", "Observe", "Update", "LateInitialize"]
                }
                {
                    apiVersion = "iam.aws.m.upbound.io/v1beta1"
                    kind = "Role"
                    metadata = {
                        name = "test-import-node"
                        annotations = {"crossplane.io/external-name" = "my-cluster-node"}
                    }
                }
            ]
        }
    }

]

items = _items
