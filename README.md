
# Harbor Registry Example - AWS
This repo contains terraform code that will quickly:
- Spin up an EC2 instance in AWS
- Install supporting packages
- Install Harbor
- Optionally add a Route 53 DNS entry and add SSL certificates

**DISCLAIMER**:  This code is intended to quickly spin up a demo/example Harbor registry.  There are most certainly optimizations that can and should be made if you are going to use this to spin up a Harbor registry for actual usage.

*Translation*:  YMMV, and do your due diligence if you are going to use this for anything other than a transient test/example deployment.

## Prerequisites
- Obviously, Terraform is required.  This code was originally written for Terraform 1.3.7, and that is reflected in the .tfswitchrc file included.  [TFSwitch](https://tfswitch.warrensbox.com/) is NOT required, but you may find it useful for managing Terraform versions.
- This code assumes you are running an SSH agent and that the key you will use to connect to the newly spun up instance is loaded in that agent.

## Usage
Clone the repo and switch into it:
`git clone https://github.com/bdausses/harbor-registry-example-aws.git`
`cd harbor-registry-example-aws`

Copy the example tfvars file to the actual tfvars file:
`cp terraform.tfvars.example terraform.tfvars`

Set the key_name variable (and optionally, the DNS variables):
`vi terraform.tfvars`

Execute the terraform plan:
`terraform plan`

Assuming that went well, proceed with the apply
`terraform apply`

## Usage
- Clone the repo and switch into it:
`git clone https://github.com/bdausses/harbor-registry-example-aws.git`
- Copy the example tfvars file to the actual tfvars file:
`cp terraform.tfvars.example terraform.tfvars`
- Set the key_name variable (and optionally, the DNS variables):
`vi terraform.tfvars`
- Initialize and apply.
  - `terraform init`
  - `terraform plan`
  - `terraform apply`

## License
This code is licensed under [the Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0).