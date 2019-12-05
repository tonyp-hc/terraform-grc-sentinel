# terraform-grc-sentinel
Adapted from: Terraform Guides: [Second-Generation Sentinel Policies](https://github.com/hashicorp/terraform-guides/tree/master/governance/second-generation)

This directory and its sub-directories contain second-generation Sentinel policies and associated [Sentinel Simulator](https://docs.hashicorp.com/sentinel/intro/getting-started/install) test cases and mocks which were created in 2019 for AWS, Microsoft Azure, Google Cloud Platform (GCP), and VMware. It also contains some cloud-agnostic policies and some common, re-usable functions.

Additionally, it contains [Policy Set](https://www.terraform.io/docs/cloud/sentinel/manage-policies.html#the-sentinel-hcl-configuration-file) configuration files so that the cloud-specific and cloud-agnostic policies can easily be added to Terraform Cloud organizations using [VCS Integrations](https://www.terraform.io/docs/cloud/vcs/index.html) after forking this repository.

These policies are generally intended for use with Terraform 0.11 and 0.12. But some policies such as those that check cost estimates can only be used with Terraform 0.12.

## Note about Using These Policies with Terraform Cloud and Enterprise
These policies test whether resources are being destroyed using the [destroy](https://www.terraform.io/docs/cloud/sentinel/import/tfplan.html#value-destroy) and [requires_new](https://www.terraform.io/docs/cloud/sentinel/import/tfplan.html#value-requires_new) values that were added to Terraform Cloud (https://app.terraform.io) on 8/15/2019 and to Terraform Enterprise (formerly known as PTFE) in the v201909-1 release on 9/13/2019. Please upgrade to that release or higher before using these policies on your Terraform Enterprise server. (If you are not currently able to upgrade your TFE server, see an older version of this document for a workaround that allows you to use these policies on older versions of TFE.)

## Mock Files and Test Cases
Sentinel [mock files](https://www.terraform.io/docs/enterprise/sentinel/mock.html) and [test files](https://docs.hashicorp.com/sentinel/commands/config#test-cases) have been provided under the test directory of each cloud so that all the policies can be tested with the [Sentinel Simulator](https://docs.hashicorp.com/sentinel/commands). The mocks were generated from actual Terraform 0.11 and 0.12 plans run against Terraform code that provisioned resources in these clouds. The pass and fail mock files were edited to respectively pass and fail the associated Sentinel policies. Some policies, including those that have multiple rules, have multiple fail mock files with names that indicate which condition or conditions they fail.

## Testing Policies
To test the policies of any of the clouds, please do the following:
1. Download the Sentinel Simulator from the [Sentinel downloads](https://docs.hashicorp.com/sentinel/downloads) page.
1. Unzip the zip file and place the sentinel binary in your path.
1. Clone this repository to your local machine.
1. Navigate to any of the cloud directories (aws, azure, gcp, or vmware) or to the cloud-agnostic directory.
1. Run `sentinel test -verbose` to test all policies for that cloud.
1. If you just want to test a single policy, run `sentinel test -verbose -run=<partial_policy_name>` where \<partial_policy_name\> is enough of the policy name to distinguish it from others in the same directory.

Using the -verbose flag will show you the output that you would see if running the policies in TFE itself. You can drop it if you don't care about that output.

## Policy Set Configuration Files
As mentioned in the introduction of this file, this repository contains [Policy Set](https://www.terraform.io/docs/cloud/sentinel/manage-policies.html#the-sentinel-hcl-configuration-file) configuration files so that the cloud-specific and cloud-agnostic policies can easily be added to Terraform Cloud organizations using [VCS Integrations](https://www.terraform.io/docs/cloud/vcs/index.html) after forking this repository.

Each of these files is called "sentinel.hcl" and should list all policies in its directory with an [Enforcement Level](https://www.terraform.io/docs/cloud/sentinel/manage-policies.html#enforcement-levels) of "advisory". This means that registering these policy sets in a Terraform Cloud or Terraform Enterprise organization will not actually have any impact on provisioning of resources from those organizations even if some of the policy checks do report violations.

Users who wish to actually enforce any of these policies should change the enforcement levels of them to "soft-mandatory" or "hard-mandatory" in their forks of this repository or in other VCS repositories that contain copies of the policies.

## Adding Policies
If you add a new second-generation policy to one of the cloud directories or the cloud-agnostic directory, please add a new stanza to that directory's sentinel.hcl file listing the name of your new policy.

The Sentinel Simulator expects test cases to be in a test/\<policy\> directory under the directory containing the policy being tested where \<policy\> is the name of the policy not including the ".sentinel" extension. When you add new policies for any of the clouds, please be sure to create a new directory with the same name of the policy under that cloud's directory and then add test cases and mock files to that directory.

### Policies that Use the tfconfig Import
The cloud-agnostic policies [prevent-remote-exec-provisioners-on-null-resources](./cloud-agnostic/prevent-remote-exec-provisioners-on-null-resources.sentinel) and [blacklist-provisioners](./cloud-agnostic/blacklist-provisioners.sentinel) policies uses the `tfconfig` import.

The `tfconfig` import treats static values and references to expressions including variables and attributes of other resources differently in Terraform 0.12. Static values will end up in the `config` value of the resource; but expressions will end up in the `references` value instead. In Terraform 0.11, static values and expressions both ended up in the `config` value. So, it is very important that policies using the `tfconfig` import check both the `config` and `references` values of resources.

New policies that use the tfconfig import should ideally include pass-0.11.json, pass-0.12.json, fail-0.11.json, fail-0.12.json, mock-tfconfig-pass-0.11.sentinel, mock-tfconfig-pass-0.12.sentinel, mock-tfconfig-fail-0.11.sentinel and mock-tfconfig-fail-0.12.sentinel files that mock the configuration of relevant resources. However, the files for Terraform 0.11 are not mandatory.

You can look at the test cases of the two policies mentioned to see how these files should be configured. Note that unlike the `tfplan` and `tfstate` imports, the `tfconfig` import does not have a `terraform_version` key. However, you should still generate 0.11 and 0.12 test cases and mocks if you want your policy to support both versions since the mocks generated from Terraform 0.12 plans will differ from those generated from Terraform 0.11 plans.

### Policies that Use the tfstate Import
The Azure policy [restrict-publishers-of-current-vms](./azure/restrict-publishers-of-current-vms.sentinel) policy uses the `tfstate` import.

New policies that use the `tfstate` import should ideally include pass-0.11.json, pass-0.12.json, fail-0.11.json, fail-0.12.json, mock-tfstate-pass-0.11.sentinel, mock-tfstate-pass-0.12.sentinel, mock-tfstate-fail-0.11.sentinel and mock-tfstate-fail-0.12.sentinel files that mock the state of relevant resources. However, the files for Terraform 0.11 are not mandatory.

You can look at the test cases of the [restrict-publishers-of-current-vms](./azure/restrict-publishers-of-current-vms.sentinel) policy to see how these files should be configured.

### Policies that Use the tfrun Import
The cloud-agnostic policies, [limit-proposed-monthly-cost](./cloud-agnostic/limit-proposed-monthly-cost.sentinel), [restrict-cost-and-percentage-increase](./cloud-agnostic/restrict-cost-and-percentage-increase.sentinel), and [./cloud-agnostic/limit-cost-by-workspace-type](./cloud-agnostic/limit-cost-by-workspace-type.sentinel) use the `tfrun` import to check cost estimates. They also include test cases and mocks that use the `tfrun` import.

New policies that use the `tfrun` import should ideally include pass-0.12.json, fail-0.12.json, mock-tfrun-pass-0.12.sentinel, and mock-tfrun-fail-0.12.sentinel files that mock the workspace metadata and/or cost estimates of Terraform 0.12 runs. Since cost estimates are not available for Terraform 0.11 runs, you will not be able to generate `tfrun` mocks for Terraform 0.11 and will therefore not include test cases for Terraform 0.11.

## Terraform Support
Most of these policies have been tested with Terraform 0.11 and 0.12. The main exceptions are those policies such as the cost estimate policies that cannot be used with Terraform 0.11.

