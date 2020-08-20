# Hornet Private Tangle AMI


## Quick start

To build the Hornet Private Tangle:

1. `git clone` this repo to your computer.
1. Install [Packer](https://www.packer.io/).
1. Configure your AWS credentials using one of the [options supported by the AWS
   SDK](http://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html). Usually, the easiest option is to
   set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.
1. Update the `variables` section of the `config.json` Packer template to configure the AWS region and Nomad version
   you wish to use.
1. Run `packer build config.json`.

When the build finishes, it will output the IDs of the new AMIs. 

Source: https://github.com/hashicorp/terraform-aws-nomad/tree/master/examples/nomad-consul-ami

## Parameters

### Private Tangle duration

The default parameters will make this private tangle last around 1 year (`DURATION (in days)=2^DEPTH*TICK / 60*60*24)`.
If you wish to modify this duration, please adjust the `tick` and `depth` variables in the `config.json` file based on the calculus above.

### Custom coordinator seed

The default parameters will automatically generate a coordinator address. You can change the variable `coordinator_address` in order to fill in a custom one.
