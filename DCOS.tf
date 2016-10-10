resource "aws_cloudformation_stack" "DCOS" {
  name = "DCOS1.8Stack"
  template_body = <<STACK
{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Conditions": {
        "RegionIsUsEast1": {
            "Fn::Equals": [
                {
                    "Ref": "AWS::Region"
                },
                "us-east-1"
            ]
        }
    },
    "Description": "DC/OS AWS CloudFormation Template",
    "Mappings": {
        "NATAmi": {
            "ap-northeast-1": {
                "default": "ami-55c29e54"
            },
            "ap-southeast-1": {
                "default": "ami-b082dae2"
            },
            "ap-southeast-2": {
                "default": "ami-996402a3"
            },
            "eu-central-1": {
                "default": "ami-204c7a3d"
            },
            "eu-west-1": {
                "default": "ami-3760b040"
            },
            "sa-east-1": {
                "default": "ami-b972dba4"
            },
            "us-east-1": {
                "default": "ami-4c9e4b24"
            },
            "us-west-1": {
                "default": "ami-2b2b296e"
            },
            "us-west-2": {
                "default": "ami-bb69128b"
            }
        },
        "Parameters": {
            "MasterInstanceType": {
                "default": "m3.xlarge"
            },
            "PrivateSubnetRange": {
                "default": "10.0.0.0/22"
            },
            "PublicSlaveInstanceType": {
                "default": "m3.xlarge"
            },
            "PublicSubnetRange": {
                "default": "10.0.4.0/22"
            },
            "SlaveInstanceType": {
                "default": "m3.xlarge"
            },
            "StackCreationTimeout": {
                "default": "PT45M"
            },
            "VPCSubnetRange": {
                "default": "10.0.0.0/16"
            }
        },
        "RegionToAmi": {
            "ap-northeast-1": {
                "stable": "ami-965899f7"
            },
            "ap-southeast-1": {
                "stable": "ami-3120fe52"
            },
            "ap-southeast-2": {
                "stable": "ami-b1291dd2"
            },
            "eu-central-1": {
                "stable": "ami-3ae31555"
            },
            "eu-west-1": {
                "stable": "ami-b7cba3c4"
            },
            "sa-east-1": {
                "stable": "ami-61e3750d"
            },
            "us-east-1": {
                "stable": "ami-6d138f7a"
            },
            "us-gov-west-1": {
                "stable": "ami-b712acd6"
            },
            "us-west-1": {
                "stable": "ami-ee57148e"
            },
            "us-west-2": {
                "stable": "ami-dc6ba3bc"
            }
        }
    },
    "Metadata": {
        "DcosImageCommit": "e64024af95b62c632c90b9063ed06296fcf38ea5",
        "TemplateGenerationDate": "2016-09-15 23:50:47.015581"
    },
    "Outputs": {
        "DnsAddress": {
            "Description": "Mesos Master",
            "Value": {
                "Fn::GetAtt": [
                    "ElasticLoadBalancer",
                    "DNSName"
                ]
            }
        },
        "ExhibitorS3Bucket": {
            "Description": "Exhibitor S3 bucket name",
            "Value": {
                "Ref": "ExhibitorS3Bucket"
            }
        },
        "PublicSlaveDnsAddress": {
            "Description": "Public slaves",
            "Value": {
                "Fn::GetAtt": [
                    "PublicSlaveLoadBalancer",
                    "DNSName"
                ]
            }
        }
    },
    "Parameters": {
        "AdminLocation": {
            "AllowedPattern": "^([0-9]+\\.){3}[0-9]+\\/[0-9]+$",
            "ConstraintDescription": "must be a valid CIDR.",
            "Default": "0.0.0.0/0",
            "Description": "Optional: Specify the IP range to whitelist for access to the admin zone. Must be a valid CIDR.",
            "MaxLength": "18",
            "MinLength": "9",
            "Type": "String"
        },
        "KeyName": {
            "Description": "Required: Specify your AWS EC2 Key Pair.",
            "Type": "AWS::EC2::KeyPair::KeyName"
        },
        "OAuthEnabled": {
            "AllowedValues": [
                "true",
                "false"
            ],
            "Default": "true",
            "Description": "\nEnable OAuth authentication",
            "Type": "String"
        },
        "PublicSlaveInstanceCount": {
            "Default": "1",
            "Description": "Required: Specify the number of public agent nodes or accept the default.",
            "Type": "Number"
        },
        "SlaveInstanceCount": {
            "Default": "5",
            "Description": "Required: Specify the number of private agent nodes or accept the default.",
            "Type": "Number"
        }
    },
    "Resources": {
        "AdminSecurityGroup": {
            "Properties": {
                "GroupDescription": "Enable admin access to servers",
                "SecurityGroupIngress": [
                    {
                        "CidrIp": {
                            "Ref": "AdminLocation"
                        },
                        "FromPort": "22",
                        "IpProtocol": "tcp",
                        "ToPort": "22"
                    },
                    {
                        "CidrIp": {
                            "Ref": "AdminLocation"
                        },
                        "FromPort": "80",
                        "IpProtocol": "tcp",
                        "ToPort": "80"
                    },
                    {
                        "CidrIp": {
                            "Ref": "AdminLocation"
                        },
                        "FromPort": "443",
                        "IpProtocol": "tcp",
                        "ToPort": "443"
                    }
                ],
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::SecurityGroup"
        },
        "DHCPOptions": {
            "Properties": {
                "DomainName": {
                    "Fn::If": [
                        "RegionIsUsEast1",
                        "ec2.internal",
                        {
                            "Fn::Join": [
                                "",
                                [
                                    {
                                        "Ref": "AWS::Region"
                                    },
                                    ".compute.internal"
                                ]
                            ]
                        }
                    ]
                },
                "DomainNameServers": [
                    "AmazonProvidedDNS"
                ]
            },
            "Type": "AWS::EC2::DHCPOptions"
        },
        "ElasticLoadBalancer": {
            "DependsOn": "GatewayToInternet",
            "Properties": {
                "HealthCheck": {
                    "HealthyThreshold": "2",
                    "Interval": "30",
                    "Target": "HTTP:5050/health",
                    "Timeout": "5",
                    "UnhealthyThreshold": "2"
                },
                "Listeners": [
                    {
                        "InstancePort": "80",
                        "InstanceProtocol": "TCP",
                        "LoadBalancerPort": "80",
                        "Protocol": "TCP"
                    },
                    {
                        "InstancePort": "443",
                        "InstanceProtocol": "TCP",
                        "LoadBalancerPort": "443",
                        "Protocol": "TCP"
                    }
                ],
                "SecurityGroups": [
                    {
                        "Ref": "LbSecurityGroup"
                    },
                    {
                        "Ref": "AdminSecurityGroup"
                    }
                ],
                "Subnets": [
                    {
                        "Ref": "PublicSubnet"
                    }
                ]
            },
            "Type": "AWS::ElasticLoadBalancing::LoadBalancer"
        },
        "ExhibitorS3Bucket": {
            "DeletionPolicy": "Retain",
            "Type": "AWS::S3::Bucket"
        },
        "GatewayToInternet": {
            "DependsOn": "InternetGateway",
            "Properties": {
                "InternetGatewayId": {
                    "Ref": "InternetGateway"
                },
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::VPCGatewayAttachment"
        },
        "InboundNetworkAclEntry": {
            "Properties": {
                "CidrBlock": "0.0.0.0/0",
                "Egress": "false",
                "NetworkAclId": {
                    "Ref": "PublicNetworkAcl"
                },
                "PortRange": {
                    "From": "0",
                    "To": "65535"
                },
                "Protocol": "-1",
                "RuleAction": "allow",
                "RuleNumber": "100"
            },
            "Type": "AWS::EC2::NetworkAclEntry"
        },
        "InternalMasterLoadBalancer": {
            "Properties": {
                "HealthCheck": {
                    "HealthyThreshold": "2",
                    "Interval": "30",
                    "Target": "HTTP:5050/health",
                    "Timeout": "5",
                    "UnhealthyThreshold": "2"
                },
                "Listeners": [
                    {
                        "InstancePort": "5050",
                        "InstanceProtocol": "HTTP",
                        "LoadBalancerPort": "5050",
                        "Protocol": "HTTP"
                    },
                    {
                        "InstancePort": "2181",
                        "InstanceProtocol": "TCP",
                        "LoadBalancerPort": "2181",
                        "Protocol": "TCP"
                    },
                    {
                        "InstancePort": "8181",
                        "InstanceProtocol": "HTTP",
                        "LoadBalancerPort": "8181",
                        "Protocol": "HTTP"
                    },
                    {
                        "InstancePort": "80",
                        "InstanceProtocol": "TCP",
                        "LoadBalancerPort": "80",
                        "Protocol": "TCP"
                    },
                    {
                        "InstancePort": "443",
                        "InstanceProtocol": "TCP",
                        "LoadBalancerPort": "443",
                        "Protocol": "TCP"
                    },
                    {
                        "InstancePort": "8080",
                        "InstanceProtocol": "HTTP",
                        "LoadBalancerPort": "8080",
                        "Protocol": "HTTP"
                    }
                ],
                "Scheme": "internal",
                "SecurityGroups": [
                    {
                        "Ref": "LbSecurityGroup"
                    },
                    {
                        "Ref": "AdminSecurityGroup"
                    },
                    {
                        "Ref": "SlaveSecurityGroup"
                    },
                    {
                        "Ref": "PublicSlaveSecurityGroup"
                    },
                    {
                        "Ref": "MasterSecurityGroup"
                    }
                ],
                "Subnets": [
                    {
                        "Ref": "PublicSubnet"
                    }
                ]
            },
            "Type": "AWS::ElasticLoadBalancing::LoadBalancer"
        },
        "InternetGateway": {
            "DependsOn": "Vpc",
            "Properties": {
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackName"
                        }
                    },
                    {
                        "Key": "Network",
                        "Value": "Public"
                    }
                ]
            },
            "Type": "AWS::EC2::InternetGateway"
        },
        "LbSecurityGroup": {
            "Properties": {
                "GroupDescription": "Mesos Master LB",
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::SecurityGroup"
        },
        "MasterInstanceProfile": {
            "Properties": {
                "Path": "/",
                "Roles": [
                    {
                        "Ref": "MasterRole"
                    }
                ]
            },
            "Type": "AWS::IAM::InstanceProfile"
        },
        "MasterLaunchConfig": {
            "Properties": {
                "AssociatePublicIpAddress": "true",
                "BlockDeviceMappings": [
                    {
                        "DeviceName": "/dev/sdb",
                        "VirtualName": "ephemeral0"
                    }
                ],
                "EbsOptimized": "true",
                "IamInstanceProfile": {
                    "Ref": "MasterInstanceProfile"
                },
                "ImageId": {
                    "Fn::FindInMap": [
                        "RegionToAmi",
                        {
                            "Ref": "AWS::Region"
                        },
                        "stable"
                    ]
                },
                "InstanceType": {
                    "Fn::FindInMap": [
                        "Parameters",
                        "MasterInstanceType",
                        "default"
                    ]
                },
                "KeyName": {
                    "Ref": "KeyName"
                },
                "SecurityGroups": [
                    {
                        "Ref": "MasterSecurityGroup"
                    },
                    {
                        "Ref": "AdminSecurityGroup"
                    }
                ],
                "UserData": {
                    "Fn::Base64": {
                        "Fn::Join": [
                            "",
                            [
                                "#cloud-config\n",
                                "\"coreos\":\n",
                                "  \"units\":\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=AWS Setup: Formats the /var/lib ephemeral drive\n",
                                "      Before=var-lib.mount dbus.service\n",
                                "      [Service]\n",
                                "      Type=oneshot\n",
                                "      RemainAfterExit=yes\n",
                                "      ExecStart=/bin/bash -c \"(blkid -t TYPE=ext4 | grep xvdb) || (/usr/sbin/mkfs.ext4 -F /dev/xvdb)\"\n",
                                "    \"name\": |-\n",
                                "      format-var-lib-ephemeral.service\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=AWS Setup: Mount /var/lib\n",
                                "      Before=dbus.service\n",
                                "      [Mount]\n",
                                "      What=/dev/xvdb\n",
                                "      Where=/var/lib\n",
                                "      Type=ext4\n",
                                "    \"name\": |-\n",
                                "      var-lib.mount\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"mask\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      etcd.service\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"mask\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      update-engine.service\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"mask\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      locksmithd.service\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"name\": |-\n",
                                "      systemd-resolved.service\n",
                                "  - \"command\": |-\n",
                                "      restart\n",
                                "    \"name\": |-\n",
                                "      systemd-journald.service\n",
                                "  - \"command\": |-\n",
                                "      restart\n",
                                "    \"name\": |-\n",
                                "      docker.service\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Before=dcos.target\n",
                                "      [Service]\n",
                                "      Type=oneshot\n",
                                "      StandardOutput=journal+console\n",
                                "      StandardError=journal+console\n",
                                "      ExecStartPre=/usr/bin/mkdir -p /etc/profile.d\n",
                                "      ExecStart=/usr/bin/ln -sf /opt/mesosphere/environment.export /etc/profile.d/dcos.sh\n",
                                "    \"name\": |-\n",
                                "      dcos-link-env.service\n",
                                "  - \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=Pkgpanda: Download DC/OS to this host.\n",
                                "      After=network-online.target\n",
                                "      Wants=network-online.target\n",
                                "      ConditionPathExists=!/opt/mesosphere/\n",
                                "      [Service]\n",
                                "      EnvironmentFile=/etc/mesosphere/setup-flags/bootstrap-id\n",
                                "      Type=oneshot\n",
                                "      StandardOutput=journal+console\n",
                                "      StandardError=journal+console\n",
                                "      ExecStartPre=/usr/bin/curl --keepalive-time 2 -fLsSv --retry 20 -Y 100000 -y 60 -o /tmp/bootstrap.tar.xz https://downloads.dcos.io/dcos/stable/bootstrap/${BOOTSTRAP_ID}.bootstrap.tar.xz\n",
                                "      ExecStartPre=/usr/bin/mkdir -p /opt/mesosphere\n",
                                "      ExecStart=/usr/bin/tar -axf /tmp/bootstrap.tar.xz -C /opt/mesosphere\n",
                                "      ExecStartPost=-/usr/bin/rm -f /tmp/bootstrap.tar.xz\n",
                                "    \"name\": |-\n",
                                "      dcos-download.service\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=Pkgpanda: Specialize DC/OS for this host.\n",
                                "      Requires=dcos-download.service\n",
                                "      After=dcos-download.service\n",
                                "      [Service]\n",
                                "      Type=oneshot\n",
                                "      StandardOutput=journal+console\n",
                                "      StandardError=journal+console\n",
                                "      EnvironmentFile=/opt/mesosphere/environment\n",
                                "      ExecStart=/opt/mesosphere/bin/pkgpanda setup --no-block-systemd\n",
                                "      [Install]\n",
                                "      WantedBy=multi-user.target\n",
                                "    \"enable\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      dcos-setup.service\n",
                                "    \"no_block\": !!bool |-\n",
                                "      true\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |-\n",
                                "      [Unit]\n",
                                "      Description=AWS Setup: Signal CloudFormation Success\n",
                                "      ConditionPathExists=!/var/lib/dcos-cfn-signal\n",
                                "      [Service]\n",
                                "      Type=simple\n",
                                "      Restart=on-failure\n",
                                "      StartLimitInterval=0\n",
                                "      RestartSec=15s\n",
                                "      EnvironmentFile=/opt/mesosphere/environment\n",
                                "      EnvironmentFile=/opt/mesosphere/etc/cfn_signal_metadata\n",
                                "      Environment=\"AWS_CFN_SIGNAL_THIS_RESOURCE=MasterServerGroup\"\n",
                                "      ExecStartPre=/bin/ping -c1 leader.mesos\n",
                                "      ExecStartPre=/opt/mesosphere/bin/cfn-signal\n",
                                "      ExecStart=/usr/bin/touch /var/lib/dcos-cfn-signal\n",
                                "    \"name\": |-\n",
                                "      dcos-cfn-signal.service\n",
                                "    \"no_block\": !!bool |-\n",
                                "      true\n",
                                "  \"update\":\n",
                                "    \"reboot-strategy\": |-\n",
                                "      off\n",
                                "\"write_files\":\n",
                                "- \"content\": |\n",
                                "    https://downloads.dcos.io/dcos/stable\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-flags/repository-url\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    BOOTSTRAP_ID=5b4aa43610c57ee1d60b4aa0751a1fb75824c083\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-flags/bootstrap-id\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    [\"dcos-config--setup_fb65a9430d3fac1c00b3d578ff47a4969723e7ac\", \"dcos-metadata--setup_fb65a9430d3fac1c00b3d578ff47a4969723e7ac\"]\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-flags/cluster-packages.json\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    [Journal]\n",
                                "    MaxLevelConsole=warning\n",
                                "    RateLimitInterval=1s\n",
                                "    RateLimitBurst=20000\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/systemd/journald.conf.d/dcos.conf\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    rexray:\n",
                                "      loglevel: info\n",
                                "      modules:\n",
                                "        default-admin:\n",
                                "          host: tcp://127.0.0.1:61003\n",
                                "      storageDrivers:\n",
                                "      - ec2\n",
                                "      volume:\n",
                                "        unmount:\n",
                                "          ignoreusedcount: true\n",
                                "  \"path\": |-\n",
                                "    /etc/rexray/config.yml\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    MESOS_CLUSTER=",
                                {
                                    "Ref": "AWS::StackName"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/mesos-master-provider\n",
                                "- \"content\": |\n",
                                "    ADMINROUTER_ACTIVATE_AUTH_MODULE=",
                                {
                                    "Ref": "OAuthEnabled"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/adminrouter.env\n",
                                "- \"content\": |\n",
                                "    MASTER_SOURCE=exhibitor_uri\n",
                                "    EXHIBITOR_URI=http://",
                                {
                                    "Fn::GetAtt": [
                                        "InternalMasterLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                ":8181/exhibitor/v1/cluster/status",
                                "\n",
                                "    EXHIBITOR_ADDRESS=",
                                {
                                    "Fn::GetAtt": [
                                        "InternalMasterLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                "",
                                "\n",
                                "    RESOLVERS=169.254.169.253\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/dns_config\n",
                                "- \"content\": |\n",
                                "    EXHIBITOR_BACKEND=AWS_S3\n",
                                "    AWS_REGION=",
                                {
                                    "Ref": "AWS::Region"
                                },
                                "",
                                "\n",
                                "    AWS_S3_BUCKET=",
                                {
                                    "Ref": "ExhibitorS3Bucket"
                                },
                                "",
                                "\n",
                                "    AWS_S3_PREFIX=",
                                {
                                    "Ref": "AWS::StackName"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/exhibitor\n",
                                "- \"content\": |\n",
                                "    {\"uiConfiguration\":{\"plugins\":{\"banner\":{\"enabled\":false,\"backgroundColor\":\"#1E232F\",\"foregroundColor\":\"#FFFFFF\",\"headerTitle\":null,\"headerContent\":null,\"footerContent\":null,\"imagePath\":null,\"dismissible\":null},\"branding\":{\"enabled\":false},\"external-links\": {\"enabled\": false},\n",
                                "\n",
                                "    \"authentication\":{\"enabled\":false},\n",
                                "\n",
                                "    \"oauth\":{\"enabled\":",
                                {
                                    "Ref": "OAuthEnabled"
                                },
                                ",\"authHost\":\"https://dcos.auth0.com\"},",
                                "\n",
                                "\n",
                                "\n",
                                "    \"tracking\":{\"enabled\":true}}}}\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/ui-config.json\n",
                                "- \"content\": |\n",
                                "    AWS_REGION=",
                                {
                                    "Ref": "AWS::Region"
                                },
                                "",
                                "\n",
                                "    AWS_STACK_ID=",
                                {
                                    "Ref": "AWS::StackId"
                                },
                                "",
                                "\n",
                                "    AWS_STACK_NAME=",
                                {
                                    "Ref": "AWS::StackName"
                                },
                                "",
                                "\n",
                                "    AWS_IAM_MASTER_ROLE_NAME=",
                                {
                                    "Ref": "MasterRole"
                                },
                                "",
                                "\n",
                                "    AWS_IAM_SLAVE_ROLE_NAME=",
                                {
                                    "Ref": "SlaveRole"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/cfn_signal_metadata\n",
                                "- \"content\": |\n",
                                "    INTERNAL_MASTER_LB_DNSNAME=",
                                {
                                    "Fn::GetAtt": [
                                        "InternalMasterLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                "",
                                "\n",
                                "    MASTER_LB_DNSNAME=",
                                {
                                    "Fn::GetAtt": [
                                        "ElasticLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/aws_dnsnames\n",
                                "- \"content\": |-\n",
                                "    {}\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/pkginfo.json\n",
                                "- \"content\": \"\"\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/roles/master\n",
                                "- \"content\": \"\"\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/roles/aws_master\n",
                                "- \"content\": \"\"\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/roles/aws\n"
                            ]
                        ]
                    }
                }
            },
            "Type": "AWS::AutoScaling::LaunchConfiguration"
        },
        "MasterRole": {
            "Properties": {
                "AssumeRolePolicyDocument": {
                    "Statement": [
                        {
                            "Action": [
                                "sts:AssumeRole"
                            ],
                            "Effect": "Allow",
                            "Principal": {
                                "Service": [
                                    "ec2.amazonaws.com"
                                ]
                            }
                        }
                    ],
                    "Version": "2012-10-17"
                },
                "Path": "/",
                "Policies": [
                    {
                        "PolicyDocument": {
                            "Statement": [
                                {
                                    "Action": [
                                        "s3:AbortMultipartUpload",
                                        "s3:DeleteObject",
                                        "s3:GetBucketAcl",
                                        "s3:GetBucketPolicy",
                                        "s3:GetObject",
                                        "s3:GetObjectAcl",
                                        "s3:ListBucket",
                                        "s3:ListBucketMultipartUploads",
                                        "s3:ListMultipartUploadParts",
                                        "s3:PutObject",
                                        "s3:PutObjectAcl"
                                    ],
                                    "Effect": "Allow",
                                    "Resource": [
                                        {
                                            "Fn::Join": [
                                                "",
                                                [
                                                    "arn:aws:s3:::",
                                                    {
                                                        "Ref": "ExhibitorS3Bucket"
                                                    },
                                                    "/*"
                                                ]
                                            ]
                                        },
                                        {
                                            "Fn::Join": [
                                                "",
                                                [
                                                    "arn:aws:s3:::",
                                                    {
                                                        "Ref": "ExhibitorS3Bucket"
                                                    }
                                                ]
                                            ]
                                        }
                                    ]
                                },
                                {
                                    "Action": [
                                        "cloudformation:*"
                                    ],
                                    "Effect": "Allow",
                                    "Resource": [
                                        {
                                            "Ref": "AWS::StackId"
                                        },
                                        {
                                            "Fn::Join": [
                                                "",
                                                [
                                                    {
                                                        "Ref": "AWS::StackId"
                                                    },
                                                    "/*"
                                                ]
                                            ]
                                        }
                                    ]
                                },
                                {
                                    "Action": [
                                        "ec2:DescribeKeyPairs",
                                        "ec2:DescribeSubnets",
                                        "autoscaling:DescribeLaunchConfigurations",
                                        "autoscaling:UpdateAutoScalingGroup",
                                        "autoscaling:DescribeAutoScalingGroups",
                                        "autoscaling:DescribeScalingActivities",
                                        "elasticloadbalancing:DescribeLoadBalancers"
                                    ],
                                    "Effect": "Allow",
                                    "Resource": "*"
                                }
                            ],
                            "Version": "2012-10-17"
                        },
                        "PolicyName": "root"
                    }
                ]
            },
            "Type": "AWS::IAM::Role"
        },
        "MasterSecurityGroup": {
            "Properties": {
                "GroupDescription": "Mesos Masters",
                "SecurityGroupIngress": [
                    {
                        "FromPort": "5050",
                        "IpProtocol": "tcp",
                        "SourceSecurityGroupId": {
                            "Ref": "LbSecurityGroup"
                        },
                        "ToPort": "5050"
                    },
                    {
                        "FromPort": "80",
                        "IpProtocol": "tcp",
                        "SourceSecurityGroupId": {
                            "Ref": "LbSecurityGroup"
                        },
                        "ToPort": "80"
                    },
                    {
                        "FromPort": "443",
                        "IpProtocol": "tcp",
                        "SourceSecurityGroupId": {
                            "Ref": "LbSecurityGroup"
                        },
                        "ToPort": "443"
                    },
                    {
                        "FromPort": "8080",
                        "IpProtocol": "tcp",
                        "SourceSecurityGroupId": {
                            "Ref": "LbSecurityGroup"
                        },
                        "ToPort": "8080"
                    },
                    {
                        "FromPort": "8181",
                        "IpProtocol": "tcp",
                        "SourceSecurityGroupId": {
                            "Ref": "LbSecurityGroup"
                        },
                        "ToPort": "8181"
                    },
                    {
                        "FromPort": "2181",
                        "IpProtocol": "tcp",
                        "SourceSecurityGroupId": {
                            "Ref": "LbSecurityGroup"
                        },
                        "ToPort": "2181"
                    }
                ],
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::SecurityGroup"
        },
        "MasterServerGroup": {
            "CreationPolicy": {
                "ResourceSignal": {
                    "Count": 1,
                    "Timeout": {
                        "Fn::FindInMap": [
                            "Parameters",
                            "StackCreationTimeout",
                            "default"
                        ]
                    }
                }
            },
            "DependsOn": "GatewayToInternet",
            "Properties": {
                "AvailabilityZones": [
                    {
                        "Fn::GetAtt": [
                            "PublicSubnet",
                            "AvailabilityZone"
                        ]
                    }
                ],
                "DesiredCapacity": 1,
                "LaunchConfigurationName": {
                    "Ref": "MasterLaunchConfig"
                },
                "LoadBalancerNames": [
                    {
                        "Ref": "ElasticLoadBalancer"
                    },
                    {
                        "Ref": "InternalMasterLoadBalancer"
                    }
                ],
                "MaxSize": 1,
                "MinSize": 1,
                "Tags": [
                    {
                        "Key": "role",
                        "PropagateAtLaunch": "true",
                        "Value": "mesos-master"
                    }
                ],
                "VPCZoneIdentifier": [
                    {
                        "Ref": "PublicSubnet"
                    }
                ]
            },
            "Type": "AWS::AutoScaling::AutoScalingGroup"
        },
        "MasterToMasterIngress": {
            "Properties": {
                "FromPort": "0",
                "GroupId": {
                    "Ref": "MasterSecurityGroup"
                },
                "IpProtocol": "-1",
                "SourceSecurityGroupId": {
                    "Ref": "MasterSecurityGroup"
                },
                "ToPort": "65535"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "MasterToPublicSlaveIngress": {
            "Properties": {
                "FromPort": "0",
                "GroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "IpProtocol": "-1",
                "SourceSecurityGroupId": {
                    "Ref": "MasterSecurityGroup"
                },
                "ToPort": "65535"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "MasterToSlaveIngress": {
            "Properties": {
                "FromPort": "0",
                "GroupId": {
                    "Ref": "SlaveSecurityGroup"
                },
                "IpProtocol": "-1",
                "SourceSecurityGroupId": {
                    "Ref": "MasterSecurityGroup"
                },
                "ToPort": "65535"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "NATInstance": {
            "DependsOn": "GatewayToInternet",
            "Properties": {
                "ImageId": {
                    "Fn::FindInMap": [
                        "NATAmi",
                        {
                            "Ref": "AWS::Region"
                        },
                        "default"
                    ]
                },
                "InstanceType": "m3.medium",
                "KeyName": {
                    "Ref": "KeyName"
                },
                "NetworkInterfaces": [
                    {
                        "AssociatePublicIpAddress": "true",
                        "DeleteOnTermination": "true",
                        "DeviceIndex": "0",
                        "GroupSet": [
                            {
                                "Ref": "SlaveSecurityGroup"
                            },
                            {
                                "Ref": "MasterSecurityGroup"
                            },
                            {
                                "Ref": "AdminSecurityGroup"
                            }
                        ],
                        "SubnetId": {
                            "Ref": "PublicSubnet"
                        }
                    }
                ],
                "SourceDestCheck": "false"
            },
            "Type": "AWS::EC2::Instance"
        },
        "OutboundNetworkAclEntry": {
            "Properties": {
                "CidrBlock": "0.0.0.0/0",
                "Egress": "true",
                "NetworkAclId": {
                    "Ref": "PublicNetworkAcl"
                },
                "PortRange": {
                    "From": "0",
                    "To": "65535"
                },
                "Protocol": "-1",
                "RuleAction": "allow",
                "RuleNumber": "100"
            },
            "Type": "AWS::EC2::NetworkAclEntry"
        },
        "PrivateInboundNetworkAclEntry": {
            "Properties": {
                "CidrBlock": "0.0.0.0/0",
                "Egress": "false",
                "NetworkAclId": {
                    "Ref": "PrivateNetworkAcl"
                },
                "PortRange": {
                    "From": "0",
                    "To": "65535"
                },
                "Protocol": "-1",
                "RuleAction": "allow",
                "RuleNumber": "100"
            },
            "Type": "AWS::EC2::NetworkAclEntry"
        },
        "PrivateNetworkAcl": {
            "Properties": {
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackName"
                        }
                    },
                    {
                        "Key": "Network",
                        "Value": "Public"
                    }
                ],
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::NetworkAcl"
        },
        "PrivateOutboundNetworkAclEntry": {
            "Properties": {
                "CidrBlock": "0.0.0.0/0",
                "Egress": "true",
                "NetworkAclId": {
                    "Ref": "PrivateNetworkAcl"
                },
                "PortRange": {
                    "From": "0",
                    "To": "65535"
                },
                "Protocol": "-1",
                "RuleAction": "allow",
                "RuleNumber": "100"
            },
            "Type": "AWS::EC2::NetworkAclEntry"
        },
        "PrivateRoute": {
            "Properties": {
                "DestinationCidrBlock": "0.0.0.0/0",
                "InstanceId": {
                    "Ref": "NATInstance"
                },
                "RouteTableId": {
                    "Ref": "PrivateRouteTable"
                }
            },
            "Type": "AWS::EC2::Route"
        },
        "PrivateRouteTable": {
            "Properties": {
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackName"
                        }
                    },
                    {
                        "Key": "Network",
                        "Value": "Public"
                    }
                ],
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::RouteTable"
        },
        "PrivateSubnet": {
            "DependsOn": "Vpc",
            "Properties": {
                "CidrBlock": {
                    "Fn::FindInMap": [
                        "Parameters",
                        "PrivateSubnetRange",
                        "default"
                    ]
                },
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackName"
                        }
                    },
                    {
                        "Key": "Network",
                        "Value": "Private"
                    }
                ],
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::Subnet"
        },
        "PrivateSubnetNetworkAclAssociation": {
            "Properties": {
                "NetworkAclId": {
                    "Ref": "PrivateNetworkAcl"
                },
                "SubnetId": {
                    "Ref": "PrivateSubnet"
                }
            },
            "Type": "AWS::EC2::SubnetNetworkAclAssociation"
        },
        "PrivateSubnetRouteTableAssociation": {
            "Properties": {
                "RouteTableId": {
                    "Ref": "PrivateRouteTable"
                },
                "SubnetId": {
                    "Ref": "PrivateSubnet"
                }
            },
            "Type": "AWS::EC2::SubnetRouteTableAssociation"
        },
        "PublicNetworkAcl": {
            "Properties": {
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackName"
                        }
                    },
                    {
                        "Key": "Network",
                        "Value": "Public"
                    }
                ],
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::NetworkAcl"
        },
        "PublicRoute": {
            "DependsOn": "GatewayToInternet",
            "Properties": {
                "DestinationCidrBlock": "0.0.0.0/0",
                "GatewayId": {
                    "Ref": "InternetGateway"
                },
                "RouteTableId": {
                    "Ref": "PublicRouteTable"
                }
            },
            "Type": "AWS::EC2::Route"
        },
        "PublicRouteTable": {
            "DependsOn": "Vpc",
            "Properties": {
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackName"
                        }
                    },
                    {
                        "Key": "Network",
                        "Value": "Public"
                    }
                ],
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::RouteTable"
        },
        "PublicSlaveIngressFive": {
            "Properties": {
                "CidrIp": "0.0.0.0/0",
                "FromPort": "23",
                "GroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "IpProtocol": "udp",
                "ToPort": "5050"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "PublicSlaveIngressFour": {
            "Properties": {
                "CidrIp": "0.0.0.0/0",
                "FromPort": "0",
                "GroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "IpProtocol": "udp",
                "ToPort": "21"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "PublicSlaveIngressOne": {
            "Properties": {
                "CidrIp": "0.0.0.0/0",
                "FromPort": "0",
                "GroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "IpProtocol": "tcp",
                "ToPort": "21"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "PublicSlaveIngressSix": {
            "Properties": {
                "CidrIp": "0.0.0.0/0",
                "FromPort": "5052",
                "GroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "IpProtocol": "udp",
                "ToPort": "32000"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "PublicSlaveIngressThree": {
            "Properties": {
                "CidrIp": "0.0.0.0/0",
                "FromPort": "5052",
                "GroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "IpProtocol": "tcp",
                "ToPort": "32000"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "PublicSlaveIngressTwo": {
            "Properties": {
                "CidrIp": "0.0.0.0/0",
                "FromPort": "23",
                "GroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "IpProtocol": "tcp",
                "ToPort": "5050"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "PublicSlaveLaunchConfig": {
            "Properties": {
                "AssociatePublicIpAddress": "true",
                "BlockDeviceMappings": [
                    {
                        "DeviceName": "/dev/sdb",
                        "VirtualName": "ephemeral0"
                    }
                ],
                "EbsOptimized": "true",
                "IamInstanceProfile": {
                    "Ref": "SlaveInstanceProfile"
                },
                "ImageId": {
                    "Fn::FindInMap": [
                        "RegionToAmi",
                        {
                            "Ref": "AWS::Region"
                        },
                        "stable"
                    ]
                },
                "InstanceType": {
                    "Fn::FindInMap": [
                        "Parameters",
                        "PublicSlaveInstanceType",
                        "default"
                    ]
                },
                "KeyName": {
                    "Ref": "KeyName"
                },
                "SecurityGroups": [
                    {
                        "Ref": "PublicSlaveSecurityGroup"
                    }
                ],
                "UserData": {
                    "Fn::Base64": {
                        "Fn::Join": [
                            "",
                            [
                                "#cloud-config\n",
                                "\"coreos\":\n",
                                "  \"units\":\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=AWS Setup: Formats the /var/lib ephemeral drive\n",
                                "      Before=var-lib.mount dbus.service\n",
                                "      [Service]\n",
                                "      Type=oneshot\n",
                                "      RemainAfterExit=yes\n",
                                "      ExecStart=/bin/bash -c \"(blkid -t TYPE=ext4 | grep xvdb) || (/usr/sbin/mkfs.ext4 -F /dev/xvdb)\"\n",
                                "    \"name\": |-\n",
                                "      format-var-lib-ephemeral.service\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=AWS Setup: Mount /var/lib\n",
                                "      Before=dbus.service\n",
                                "      [Mount]\n",
                                "      What=/dev/xvdb\n",
                                "      Where=/var/lib\n",
                                "      Type=ext4\n",
                                "    \"name\": |-\n",
                                "      var-lib.mount\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"mask\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      etcd.service\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"mask\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      update-engine.service\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"mask\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      locksmithd.service\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"name\": |-\n",
                                "      systemd-resolved.service\n",
                                "  - \"command\": |-\n",
                                "      restart\n",
                                "    \"name\": |-\n",
                                "      systemd-journald.service\n",
                                "  - \"command\": |-\n",
                                "      restart\n",
                                "    \"name\": |-\n",
                                "      docker.service\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Before=dcos.target\n",
                                "      [Service]\n",
                                "      Type=oneshot\n",
                                "      StandardOutput=journal+console\n",
                                "      StandardError=journal+console\n",
                                "      ExecStartPre=/usr/bin/mkdir -p /etc/profile.d\n",
                                "      ExecStart=/usr/bin/ln -sf /opt/mesosphere/environment.export /etc/profile.d/dcos.sh\n",
                                "    \"name\": |-\n",
                                "      dcos-link-env.service\n",
                                "  - \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=Pkgpanda: Download DC/OS to this host.\n",
                                "      After=network-online.target\n",
                                "      Wants=network-online.target\n",
                                "      ConditionPathExists=!/opt/mesosphere/\n",
                                "      [Service]\n",
                                "      EnvironmentFile=/etc/mesosphere/setup-flags/bootstrap-id\n",
                                "      Type=oneshot\n",
                                "      StandardOutput=journal+console\n",
                                "      StandardError=journal+console\n",
                                "      ExecStartPre=/usr/bin/curl --keepalive-time 2 -fLsSv --retry 20 -Y 100000 -y 60 -o /tmp/bootstrap.tar.xz https://downloads.dcos.io/dcos/stable/bootstrap/${BOOTSTRAP_ID}.bootstrap.tar.xz\n",
                                "      ExecStartPre=/usr/bin/mkdir -p /opt/mesosphere\n",
                                "      ExecStart=/usr/bin/tar -axf /tmp/bootstrap.tar.xz -C /opt/mesosphere\n",
                                "      ExecStartPost=-/usr/bin/rm -f /tmp/bootstrap.tar.xz\n",
                                "    \"name\": |-\n",
                                "      dcos-download.service\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=Pkgpanda: Specialize DC/OS for this host.\n",
                                "      Requires=dcos-download.service\n",
                                "      After=dcos-download.service\n",
                                "      [Service]\n",
                                "      Type=oneshot\n",
                                "      StandardOutput=journal+console\n",
                                "      StandardError=journal+console\n",
                                "      EnvironmentFile=/opt/mesosphere/environment\n",
                                "      ExecStart=/opt/mesosphere/bin/pkgpanda setup --no-block-systemd\n",
                                "      [Install]\n",
                                "      WantedBy=multi-user.target\n",
                                "    \"enable\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      dcos-setup.service\n",
                                "    \"no_block\": !!bool |-\n",
                                "      true\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |-\n",
                                "      [Unit]\n",
                                "      Description=AWS Setup: Signal CloudFormation Success\n",
                                "      ConditionPathExists=!/var/lib/dcos-cfn-signal\n",
                                "      [Service]\n",
                                "      Type=simple\n",
                                "      Restart=on-failure\n",
                                "      StartLimitInterval=0\n",
                                "      RestartSec=15s\n",
                                "      EnvironmentFile=/opt/mesosphere/environment\n",
                                "      EnvironmentFile=/opt/mesosphere/etc/cfn_signal_metadata\n",
                                "      Environment=\"AWS_CFN_SIGNAL_THIS_RESOURCE=PublicSlaveServerGroup\"\n",
                                "      ExecStartPre=/bin/ping -c1 leader.mesos\n",
                                "      ExecStartPre=/opt/mesosphere/bin/cfn-signal\n",
                                "      ExecStart=/usr/bin/touch /var/lib/dcos-cfn-signal\n",
                                "    \"name\": |-\n",
                                "      dcos-cfn-signal.service\n",
                                "    \"no_block\": !!bool |-\n",
                                "      true\n",
                                "  \"update\":\n",
                                "    \"reboot-strategy\": |-\n",
                                "      off\n",
                                "\"write_files\":\n",
                                "- \"content\": |\n",
                                "    https://downloads.dcos.io/dcos/stable\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-flags/repository-url\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    BOOTSTRAP_ID=5b4aa43610c57ee1d60b4aa0751a1fb75824c083\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-flags/bootstrap-id\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    [\"dcos-config--setup_fb65a9430d3fac1c00b3d578ff47a4969723e7ac\", \"dcos-metadata--setup_fb65a9430d3fac1c00b3d578ff47a4969723e7ac\"]\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-flags/cluster-packages.json\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    [Journal]\n",
                                "    MaxLevelConsole=warning\n",
                                "    RateLimitInterval=1s\n",
                                "    RateLimitBurst=20000\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/systemd/journald.conf.d/dcos.conf\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    rexray:\n",
                                "      loglevel: info\n",
                                "      modules:\n",
                                "        default-admin:\n",
                                "          host: tcp://127.0.0.1:61003\n",
                                "      storageDrivers:\n",
                                "      - ec2\n",
                                "      volume:\n",
                                "        unmount:\n",
                                "          ignoreusedcount: true\n",
                                "  \"path\": |-\n",
                                "    /etc/rexray/config.yml\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    MESOS_CLUSTER=",
                                {
                                    "Ref": "AWS::StackName"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/mesos-master-provider\n",
                                "- \"content\": |\n",
                                "    ADMINROUTER_ACTIVATE_AUTH_MODULE=",
                                {
                                    "Ref": "OAuthEnabled"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/adminrouter.env\n",
                                "- \"content\": |\n",
                                "    MASTER_SOURCE=exhibitor_uri\n",
                                "    EXHIBITOR_URI=http://",
                                {
                                    "Fn::GetAtt": [
                                        "InternalMasterLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                ":8181/exhibitor/v1/cluster/status",
                                "\n",
                                "    EXHIBITOR_ADDRESS=",
                                {
                                    "Fn::GetAtt": [
                                        "InternalMasterLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                "",
                                "\n",
                                "    RESOLVERS=169.254.169.253\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/dns_config\n",
                                "- \"content\": |\n",
                                "    EXHIBITOR_BACKEND=AWS_S3\n",
                                "    AWS_REGION=",
                                {
                                    "Ref": "AWS::Region"
                                },
                                "",
                                "\n",
                                "    AWS_S3_BUCKET=",
                                {
                                    "Ref": "ExhibitorS3Bucket"
                                },
                                "",
                                "\n",
                                "    AWS_S3_PREFIX=",
                                {
                                    "Ref": "AWS::StackName"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/exhibitor\n",
                                "- \"content\": |\n",
                                "    {\"uiConfiguration\":{\"plugins\":{\"banner\":{\"enabled\":false,\"backgroundColor\":\"#1E232F\",\"foregroundColor\":\"#FFFFFF\",\"headerTitle\":null,\"headerContent\":null,\"footerContent\":null,\"imagePath\":null,\"dismissible\":null},\"branding\":{\"enabled\":false},\"external-links\": {\"enabled\": false},\n",
                                "\n",
                                "    \"authentication\":{\"enabled\":false},\n",
                                "\n",
                                "    \"oauth\":{\"enabled\":",
                                {
                                    "Ref": "OAuthEnabled"
                                },
                                ",\"authHost\":\"https://dcos.auth0.com\"},",
                                "\n",
                                "\n",
                                "\n",
                                "    \"tracking\":{\"enabled\":true}}}}\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/ui-config.json\n",
                                "- \"content\": |\n",
                                "    AWS_REGION=",
                                {
                                    "Ref": "AWS::Region"
                                },
                                "",
                                "\n",
                                "    AWS_STACK_ID=",
                                {
                                    "Ref": "AWS::StackId"
                                },
                                "",
                                "\n",
                                "    AWS_STACK_NAME=",
                                {
                                    "Ref": "AWS::StackName"
                                },
                                "",
                                "\n",
                                "    AWS_IAM_MASTER_ROLE_NAME=",
                                {
                                    "Ref": "MasterRole"
                                },
                                "",
                                "\n",
                                "    AWS_IAM_SLAVE_ROLE_NAME=",
                                {
                                    "Ref": "SlaveRole"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/cfn_signal_metadata\n",
                                "- \"content\": |\n",
                                "    INTERNAL_MASTER_LB_DNSNAME=",
                                {
                                    "Fn::GetAtt": [
                                        "InternalMasterLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                "",
                                "\n",
                                "    MASTER_LB_DNSNAME=",
                                {
                                    "Fn::GetAtt": [
                                        "ElasticLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/aws_dnsnames\n",
                                "- \"content\": |-\n",
                                "    {}\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/pkginfo.json\n",
                                "- \"content\": \"\"\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/roles/slave_public\n",
                                "- \"content\": \"\"\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/roles/aws\n"
                            ]
                        ]
                    }
                }
            },
            "Type": "AWS::AutoScaling::LaunchConfiguration"
        },
        "PublicSlaveLoadBalancer": {
            "DependsOn": "GatewayToInternet",
            "Properties": {
                "HealthCheck": {
                    "HealthyThreshold": "2",
                    "Interval": "5",
                    "Target": "HTTP:9090/_haproxy_health_check",
                    "Timeout": "2",
                    "UnhealthyThreshold": "2"
                },
                "Listeners": [
                    {
                        "InstancePort": "80",
                        "InstanceProtocol": "TCP",
                        "LoadBalancerPort": "80",
                        "Protocol": "TCP"
                    },
                    {
                        "InstancePort": "443",
                        "InstanceProtocol": "TCP",
                        "LoadBalancerPort": "443",
                        "Protocol": "TCP"
                    }
                ],
                "SecurityGroups": [
                    {
                        "Ref": "PublicSlaveSecurityGroup"
                    }
                ],
                "Subnets": [
                    {
                        "Ref": "PublicSubnet"
                    }
                ]
            },
            "Type": "AWS::ElasticLoadBalancing::LoadBalancer"
        },
        "PublicSlaveSecurityGroup": {
            "Properties": {
                "GroupDescription": "Mesos Slaves Public",
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::SecurityGroup"
        },
        "PublicSlaveServerGroup": {
            "CreationPolicy": {
                "ResourceSignal": {
                    "Count": {
                        "Ref": "PublicSlaveInstanceCount"
                    },
                    "Timeout": {
                        "Fn::FindInMap": [
                            "Parameters",
                            "StackCreationTimeout",
                            "default"
                        ]
                    }
                }
            },
            "DependsOn": "GatewayToInternet",
            "Properties": {
                "AvailabilityZones": [
                    {
                        "Fn::GetAtt": [
                            "PublicSubnet",
                            "AvailabilityZone"
                        ]
                    }
                ],
                "DesiredCapacity": {
                    "Ref": "PublicSlaveInstanceCount"
                },
                "LaunchConfigurationName": {
                    "Ref": "PublicSlaveLaunchConfig"
                },
                "LoadBalancerNames": [
                    {
                        "Ref": "PublicSlaveLoadBalancer"
                    }
                ],
                "MaxSize": {
                    "Ref": "PublicSlaveInstanceCount"
                },
                "MinSize": {
                    "Ref": "PublicSlaveInstanceCount"
                },
                "Tags": [
                    {
                        "Key": "role",
                        "PropagateAtLaunch": "true",
                        "Value": "mesos-slave"
                    }
                ],
                "VPCZoneIdentifier": [
                    {
                        "Ref": "PublicSubnet"
                    }
                ]
            },
            "Type": "AWS::AutoScaling::AutoScalingGroup"
        },
        "PublicSlaveToMasterIngress": {
            "Properties": {
                "FromPort": "0",
                "GroupId": {
                    "Ref": "MasterSecurityGroup"
                },
                "IpProtocol": "-1",
                "SourceSecurityGroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "ToPort": "65535"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "PublicSlaveToPublicSlaveIngress": {
            "Properties": {
                "FromPort": "0",
                "GroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "IpProtocol": "-1",
                "SourceSecurityGroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "ToPort": "65535"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "PublicSlaveToSlaveIngress": {
            "Properties": {
                "FromPort": "0",
                "GroupId": {
                    "Ref": "SlaveSecurityGroup"
                },
                "IpProtocol": "-1",
                "SourceSecurityGroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "ToPort": "65535"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "PublicSubnet": {
            "DependsOn": "Vpc",
            "Properties": {
                "CidrBlock": {
                    "Fn::FindInMap": [
                        "Parameters",
                        "PublicSubnetRange",
                        "default"
                    ]
                },
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackName"
                        }
                    },
                    {
                        "Key": "Network",
                        "Value": "Public"
                    }
                ],
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::Subnet"
        },
        "PublicSubnetNetworkAclAssociation": {
            "Properties": {
                "NetworkAclId": {
                    "Ref": "PublicNetworkAcl"
                },
                "SubnetId": {
                    "Ref": "PublicSubnet"
                }
            },
            "Type": "AWS::EC2::SubnetNetworkAclAssociation"
        },
        "PublicSubnetRouteTableAssociation": {
            "Properties": {
                "RouteTableId": {
                    "Ref": "PublicRouteTable"
                },
                "SubnetId": {
                    "Ref": "PublicSubnet"
                }
            },
            "Type": "AWS::EC2::SubnetRouteTableAssociation"
        },
        "SlaveInstanceProfile": {
            "Properties": {
                "Path": "/",
                "Roles": [
                    {
                        "Ref": "SlaveRole"
                    }
                ]
            },
            "Type": "AWS::IAM::InstanceProfile"
        },
        "SlaveLaunchConfig": {
            "Properties": {
                "AssociatePublicIpAddress": "false",
                "BlockDeviceMappings": [
                    {
                        "DeviceName": "/dev/sdb",
                        "VirtualName": "ephemeral0"
                    }
                ],
                "EbsOptimized": "true",
                "IamInstanceProfile": {
                    "Ref": "SlaveInstanceProfile"
                },
                "ImageId": {
                    "Fn::FindInMap": [
                        "RegionToAmi",
                        {
                            "Ref": "AWS::Region"
                        },
                        "stable"
                    ]
                },
                "InstanceType": {
                    "Fn::FindInMap": [
                        "Parameters",
                        "SlaveInstanceType",
                        "default"
                    ]
                },
                "KeyName": {
                    "Ref": "KeyName"
                },
                "SecurityGroups": [
                    {
                        "Ref": "SlaveSecurityGroup"
                    }
                ],
                "UserData": {
                    "Fn::Base64": {
                        "Fn::Join": [
                            "",
                            [
                                "#cloud-config\n",
                                "\"coreos\":\n",
                                "  \"units\":\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=AWS Setup: Formats the /var/lib ephemeral drive\n",
                                "      Before=var-lib.mount dbus.service\n",
                                "      [Service]\n",
                                "      Type=oneshot\n",
                                "      RemainAfterExit=yes\n",
                                "      ExecStart=/bin/bash -c \"(blkid -t TYPE=ext4 | grep xvdb) || (/usr/sbin/mkfs.ext4 -F /dev/xvdb)\"\n",
                                "    \"name\": |-\n",
                                "      format-var-lib-ephemeral.service\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=AWS Setup: Mount /var/lib\n",
                                "      Before=dbus.service\n",
                                "      [Mount]\n",
                                "      What=/dev/xvdb\n",
                                "      Where=/var/lib\n",
                                "      Type=ext4\n",
                                "    \"name\": |-\n",
                                "      var-lib.mount\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"mask\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      etcd.service\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"mask\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      update-engine.service\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"mask\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      locksmithd.service\n",
                                "  - \"command\": |-\n",
                                "      stop\n",
                                "    \"name\": |-\n",
                                "      systemd-resolved.service\n",
                                "  - \"command\": |-\n",
                                "      restart\n",
                                "    \"name\": |-\n",
                                "      systemd-journald.service\n",
                                "  - \"command\": |-\n",
                                "      restart\n",
                                "    \"name\": |-\n",
                                "      docker.service\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Before=dcos.target\n",
                                "      [Service]\n",
                                "      Type=oneshot\n",
                                "      StandardOutput=journal+console\n",
                                "      StandardError=journal+console\n",
                                "      ExecStartPre=/usr/bin/mkdir -p /etc/profile.d\n",
                                "      ExecStart=/usr/bin/ln -sf /opt/mesosphere/environment.export /etc/profile.d/dcos.sh\n",
                                "    \"name\": |-\n",
                                "      dcos-link-env.service\n",
                                "  - \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=Pkgpanda: Download DC/OS to this host.\n",
                                "      After=network-online.target\n",
                                "      Wants=network-online.target\n",
                                "      ConditionPathExists=!/opt/mesosphere/\n",
                                "      [Service]\n",
                                "      EnvironmentFile=/etc/mesosphere/setup-flags/bootstrap-id\n",
                                "      Type=oneshot\n",
                                "      StandardOutput=journal+console\n",
                                "      StandardError=journal+console\n",
                                "      ExecStartPre=/usr/bin/curl --keepalive-time 2 -fLsSv --retry 20 -Y 100000 -y 60 -o /tmp/bootstrap.tar.xz https://downloads.dcos.io/dcos/stable/bootstrap/${BOOTSTRAP_ID}.bootstrap.tar.xz\n",
                                "      ExecStartPre=/usr/bin/mkdir -p /opt/mesosphere\n",
                                "      ExecStart=/usr/bin/tar -axf /tmp/bootstrap.tar.xz -C /opt/mesosphere\n",
                                "      ExecStartPost=-/usr/bin/rm -f /tmp/bootstrap.tar.xz\n",
                                "    \"name\": |-\n",
                                "      dcos-download.service\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |\n",
                                "      [Unit]\n",
                                "      Description=Pkgpanda: Specialize DC/OS for this host.\n",
                                "      Requires=dcos-download.service\n",
                                "      After=dcos-download.service\n",
                                "      [Service]\n",
                                "      Type=oneshot\n",
                                "      StandardOutput=journal+console\n",
                                "      StandardError=journal+console\n",
                                "      EnvironmentFile=/opt/mesosphere/environment\n",
                                "      ExecStart=/opt/mesosphere/bin/pkgpanda setup --no-block-systemd\n",
                                "      [Install]\n",
                                "      WantedBy=multi-user.target\n",
                                "    \"enable\": !!bool |-\n",
                                "      true\n",
                                "    \"name\": |-\n",
                                "      dcos-setup.service\n",
                                "    \"no_block\": !!bool |-\n",
                                "      true\n",
                                "  - \"command\": |-\n",
                                "      start\n",
                                "    \"content\": |-\n",
                                "      [Unit]\n",
                                "      Description=AWS Setup: Signal CloudFormation Success\n",
                                "      ConditionPathExists=!/var/lib/dcos-cfn-signal\n",
                                "      [Service]\n",
                                "      Type=simple\n",
                                "      Restart=on-failure\n",
                                "      StartLimitInterval=0\n",
                                "      RestartSec=15s\n",
                                "      EnvironmentFile=/opt/mesosphere/environment\n",
                                "      EnvironmentFile=/opt/mesosphere/etc/cfn_signal_metadata\n",
                                "      Environment=\"AWS_CFN_SIGNAL_THIS_RESOURCE=SlaveServerGroup\"\n",
                                "      ExecStartPre=/bin/ping -c1 leader.mesos\n",
                                "      ExecStartPre=/opt/mesosphere/bin/cfn-signal\n",
                                "      ExecStart=/usr/bin/touch /var/lib/dcos-cfn-signal\n",
                                "    \"name\": |-\n",
                                "      dcos-cfn-signal.service\n",
                                "    \"no_block\": !!bool |-\n",
                                "      true\n",
                                "  \"update\":\n",
                                "    \"reboot-strategy\": |-\n",
                                "      off\n",
                                "\"write_files\":\n",
                                "- \"content\": |\n",
                                "    https://downloads.dcos.io/dcos/stable\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-flags/repository-url\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    BOOTSTRAP_ID=5b4aa43610c57ee1d60b4aa0751a1fb75824c083\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-flags/bootstrap-id\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    [\"dcos-config--setup_fb65a9430d3fac1c00b3d578ff47a4969723e7ac\", \"dcos-metadata--setup_fb65a9430d3fac1c00b3d578ff47a4969723e7ac\"]\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-flags/cluster-packages.json\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    [Journal]\n",
                                "    MaxLevelConsole=warning\n",
                                "    RateLimitInterval=1s\n",
                                "    RateLimitBurst=20000\n",
                                "  \"owner\": |-\n",
                                "    root\n",
                                "  \"path\": |-\n",
                                "    /etc/systemd/journald.conf.d/dcos.conf\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    rexray:\n",
                                "      loglevel: info\n",
                                "      modules:\n",
                                "        default-admin:\n",
                                "          host: tcp://127.0.0.1:61003\n",
                                "      storageDrivers:\n",
                                "      - ec2\n",
                                "      volume:\n",
                                "        unmount:\n",
                                "          ignoreusedcount: true\n",
                                "  \"path\": |-\n",
                                "    /etc/rexray/config.yml\n",
                                "  \"permissions\": |-\n",
                                "    0644\n",
                                "- \"content\": |\n",
                                "    MESOS_CLUSTER=",
                                {
                                    "Ref": "AWS::StackName"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/mesos-master-provider\n",
                                "- \"content\": |\n",
                                "    ADMINROUTER_ACTIVATE_AUTH_MODULE=",
                                {
                                    "Ref": "OAuthEnabled"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/adminrouter.env\n",
                                "- \"content\": |\n",
                                "    MASTER_SOURCE=exhibitor_uri\n",
                                "    EXHIBITOR_URI=http://",
                                {
                                    "Fn::GetAtt": [
                                        "InternalMasterLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                ":8181/exhibitor/v1/cluster/status",
                                "\n",
                                "    EXHIBITOR_ADDRESS=",
                                {
                                    "Fn::GetAtt": [
                                        "InternalMasterLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                "",
                                "\n",
                                "    RESOLVERS=169.254.169.253\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/dns_config\n",
                                "- \"content\": |\n",
                                "    EXHIBITOR_BACKEND=AWS_S3\n",
                                "    AWS_REGION=",
                                {
                                    "Ref": "AWS::Region"
                                },
                                "",
                                "\n",
                                "    AWS_S3_BUCKET=",
                                {
                                    "Ref": "ExhibitorS3Bucket"
                                },
                                "",
                                "\n",
                                "    AWS_S3_PREFIX=",
                                {
                                    "Ref": "AWS::StackName"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/exhibitor\n",
                                "- \"content\": |\n",
                                "    {\"uiConfiguration\":{\"plugins\":{\"banner\":{\"enabled\":false,\"backgroundColor\":\"#1E232F\",\"foregroundColor\":\"#FFFFFF\",\"headerTitle\":null,\"headerContent\":null,\"footerContent\":null,\"imagePath\":null,\"dismissible\":null},\"branding\":{\"enabled\":false},\"external-links\": {\"enabled\": false},\n",
                                "\n",
                                "    \"authentication\":{\"enabled\":false},\n",
                                "\n",
                                "    \"oauth\":{\"enabled\":",
                                {
                                    "Ref": "OAuthEnabled"
                                },
                                ",\"authHost\":\"https://dcos.auth0.com\"},",
                                "\n",
                                "\n",
                                "\n",
                                "    \"tracking\":{\"enabled\":true}}}}\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/ui-config.json\n",
                                "- \"content\": |\n",
                                "    AWS_REGION=",
                                {
                                    "Ref": "AWS::Region"
                                },
                                "",
                                "\n",
                                "    AWS_STACK_ID=",
                                {
                                    "Ref": "AWS::StackId"
                                },
                                "",
                                "\n",
                                "    AWS_STACK_NAME=",
                                {
                                    "Ref": "AWS::StackName"
                                },
                                "",
                                "\n",
                                "    AWS_IAM_MASTER_ROLE_NAME=",
                                {
                                    "Ref": "MasterRole"
                                },
                                "",
                                "\n",
                                "    AWS_IAM_SLAVE_ROLE_NAME=",
                                {
                                    "Ref": "SlaveRole"
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/cfn_signal_metadata\n",
                                "- \"content\": |\n",
                                "    INTERNAL_MASTER_LB_DNSNAME=",
                                {
                                    "Fn::GetAtt": [
                                        "InternalMasterLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                "",
                                "\n",
                                "    MASTER_LB_DNSNAME=",
                                {
                                    "Fn::GetAtt": [
                                        "ElasticLoadBalancer",
                                        "DNSName"
                                    ]
                                },
                                "",
                                "\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/etc/aws_dnsnames\n",
                                "- \"content\": |-\n",
                                "    {}\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/setup-packages/dcos-provider-aws--setup/pkginfo.json\n",
                                "- \"content\": \"\"\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/roles/slave\n",
                                "- \"content\": \"\"\n",
                                "  \"path\": |-\n",
                                "    /etc/mesosphere/roles/aws\n"
                            ]
                        ]
                    }
                }
            },
            "Type": "AWS::AutoScaling::LaunchConfiguration"
        },
        "SlaveRole": {
            "Properties": {
                "AssumeRolePolicyDocument": {
                    "Statement": [
                        {
                            "Action": [
                                "sts:AssumeRole"
                            ],
                            "Effect": "Allow",
                            "Principal": {
                                "Service": [
                                    "ec2.amazonaws.com"
                                ]
                            }
                        }
                    ],
                    "Version": "2012-10-17"
                },
                "Policies": [
                    {
                        "PolicyDocument": {
                            "Statement": [
                                {
                                    "Action": [
                                        "cloudformation:*"
                                    ],
                                    "Effect": "Allow",
                                    "Resource": [
                                        {
                                            "Ref": "AWS::StackId"
                                        },
                                        {
                                            "Fn::Join": [
                                                "",
                                                [
                                                    {
                                                        "Ref": "AWS::StackId"
                                                    },
                                                    "/*"
                                                ]
                                            ]
                                        }
                                    ]
                                },
                                {
                                    "Action": [
                                        "ec2:CreateTags",
                                        "ec2:DescribeInstances",
                                        "ec2:CreateVolume",
                                        "ec2:DeleteVolume",
                                        "ec2:AttachVolume",
                                        "ec2:DetachVolume",
                                        "ec2:DescribeVolumes",
                                        "ec2:DescribeVolumeStatus",
                                        "ec2:DescribeVolumeAttribute",
                                        "ec2:CreateSnapshot",
                                        "ec2:CopySnapshot",
                                        "ec2:DeleteSnapshot",
                                        "ec2:DescribeSnapshots",
                                        "ec2:DescribeSnapshotAttribute",
                                        "autoscaling:DescribeAutoScalingGroups",
                                        "cloudwatch:PutMetricData"
                                    ],
                                    "Effect": "Allow",
                                    "Resource": "*"
                                }
                            ],
                            "Version": "2012-10-17"
                        },
                        "PolicyName": "Slaves"
                    }
                ]
            },
            "Type": "AWS::IAM::Role"
        },
        "SlaveSecurityGroup": {
            "Properties": {
                "GroupDescription": "Mesos Slaves",
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::SecurityGroup"
        },
        "SlaveServerGroup": {
            "CreationPolicy": {
                "ResourceSignal": {
                    "Count": {
                        "Ref": "SlaveInstanceCount"
                    },
                    "Timeout": {
                        "Fn::FindInMap": [
                            "Parameters",
                            "StackCreationTimeout",
                            "default"
                        ]
                    }
                }
            },
            "DependsOn": "GatewayToInternet",
            "Properties": {
                "AvailabilityZones": [
                    {
                        "Fn::GetAtt": [
                            "PrivateSubnet",
                            "AvailabilityZone"
                        ]
                    }
                ],
                "DesiredCapacity": {
                    "Ref": "SlaveInstanceCount"
                },
                "LaunchConfigurationName": {
                    "Ref": "SlaveLaunchConfig"
                },
                "MaxSize": {
                    "Ref": "SlaveInstanceCount"
                },
                "MinSize": {
                    "Ref": "SlaveInstanceCount"
                },
                "Tags": [
                    {
                        "Key": "role",
                        "PropagateAtLaunch": "true",
                        "Value": "mesos-slave"
                    }
                ],
                "VPCZoneIdentifier": [
                    {
                        "Ref": "PrivateSubnet"
                    }
                ]
            },
            "Type": "AWS::AutoScaling::AutoScalingGroup"
        },
        "SlaveToMasterIngress": {
            "Properties": {
                "FromPort": "0",
                "GroupId": {
                    "Ref": "MasterSecurityGroup"
                },
                "IpProtocol": "-1",
                "SourceSecurityGroupId": {
                    "Ref": "SlaveSecurityGroup"
                },
                "ToPort": "65535"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "SlaveToMasterLBIngress": {
            "Properties": {
                "FromPort": "2181",
                "GroupId": {
                    "Ref": "LbSecurityGroup"
                },
                "IpProtocol": "tcp",
                "SourceSecurityGroupId": {
                    "Ref": "SlaveSecurityGroup"
                },
                "ToPort": "2181"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "SlaveToPublicSlaveIngress": {
            "Properties": {
                "FromPort": "0",
                "GroupId": {
                    "Ref": "PublicSlaveSecurityGroup"
                },
                "IpProtocol": "-1",
                "SourceSecurityGroupId": {
                    "Ref": "SlaveSecurityGroup"
                },
                "ToPort": "65535"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "SlaveToSlaveIngress": {
            "Properties": {
                "FromPort": "0",
                "GroupId": {
                    "Ref": "SlaveSecurityGroup"
                },
                "IpProtocol": "-1",
                "SourceSecurityGroupId": {
                    "Ref": "SlaveSecurityGroup"
                },
                "ToPort": "65535"
            },
            "Type": "AWS::EC2::SecurityGroupIngress"
        },
        "VPCDHCPOptionsAssociation": {
            "DependsOn": "Vpc",
            "Properties": {
                "DhcpOptionsId": {
                    "Ref": "DHCPOptions"
                },
                "VpcId": {
                    "Ref": "Vpc"
                }
            },
            "Type": "AWS::EC2::VPCDHCPOptionsAssociation"
        },
        "Vpc": {
            "Properties": {
                "CidrBlock": {
                    "Fn::FindInMap": [
                        "Parameters",
                        "VPCSubnetRange",
                        "default"
                    ]
                },
                "EnableDnsHostnames": "true",
                "EnableDnsSupport": "true",
                "Tags": [
                    {
                        "Key": "Application",
                        "Value": {
                            "Ref": "AWS::StackName"
                        }
                    },
                    {
                        "Key": "Network",
                        "Value": "Public"
                    }
                ]
            },
            "Type": "AWS::EC2::VPC"
        }
    }
}
STACK
}
