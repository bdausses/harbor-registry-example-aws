
# Harbor Registry Example - AWS
This repo contains terraform code that will quickly:
- Spin up an EC2 instance in AWS
- Install supporting packages
- Install Harbor
- Optionally add a Route 53 DNS entry and add SSL certificates

**DISCLAIMER**:  This code is intended to quickly spin up a demo/example Harbor registry.  There are most certainly optimizations that can and should be made if you are going to use this to spin up a Harbor registry for actual usage.

*Translation*:  YMMV, and do your due diligence if you are going to use this for anything other than a transient test/example deployment.

## Prerequisites
- Terraform is required.  This code was originally written for Terraform 1.3.7, and that is reflected in the .tfswitchrc file included.  [TFSwitch](https://tfswitch.warrensbox.com/) is NOT required, but you may find it useful for managing Terraform versions.
- This code assumes you are running an SSH agent and that the key you will use to connect to the newly spun up instance is loaded in that agent.

## Usage
- Clone the repo and switch into it:
`git clone https://github.com/bdausses/harbor-registry-example-aws.git`
- Copy the example tfvars file to the actual tfvars file:
`cp terraform.tfvars.example terraform.tfvars`
- Use your favorite text editor to set the variables in the `terraform.tfvars` file you just created:
	- Required variable:
		- `key_name` - The name of your SSH Key Pair at AWS.
	- Optional variables:
		- `aws_profile` - The name of the desired AWS CLI profile to use.  Default: `null`
		- `aws_region` - The name of the AWS region to use.  Default: `us-east-1`
		- `domain` - A Route 53 hosted zone.  Use this if you want to assign a DNS name to your instance.  Default: empty string
		- `dns_record` - This is the A record that will be created in the above Route 53 hosted zone.  Default: empty string
		- `instance_size` - EC2 instance size to use.  Default: `t3a.medium`
		- `harbor_admin_password` - The `admin` password for the Harbor registry.  Default: `Harbor12345`
- Initialize and apply.
  - `terraform init`
  - `terraform plan`
  - `terraform apply`

## Outputs
- `instance-connection-string` - This will be an SSH command to SSH to your newly created instance.
- `harbor-registry-url` - URL of your newly created Harbor registry.

## License
This code is licensed under [the Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0).
