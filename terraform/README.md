# Homelab-Monorepo Terraform README

Details on Terraform implementation and usage for this repo. Reference README one level up for additional details. 

## Overview

- The module / child module implementation of the code in this repo allows for specific components to be provisioned / destroyed independently from each other. 
- The child modules in the "live" directory contain the declarative code & additional variables for provisioning the desired resources. Each contain local variables that can / should be modified appropriately based on environment & implementation specifics.
- The main.tf in the root module allows for a single 'terraform init' run. It *could* be applied in full (with the result of kicking off all child module resource builds), but shouldn't be. Instead, suggest using [targeting](https://www.terraform.io/docs/cli/commands/plan.html#resource-targeting) to run only desired child modules. E.g., `terraform apply -target=module.active-directory` 
- The [Telmate Terraform Provider Plugin for Proxmox](github.com/Telmate/terraform-provider-proxmox) is used by this module. It will be auto installed via 'terraform init'
- The Proxmox API connection parameters and credentials need to be set as Terraform variables (reference variables.tf) either using a .tfvars file, inline -vars, environment variables, and/or updating the defaults in variables.tf.
- The 'modules' directory contains module defintions for the following (which are called by the 'live' modules):
  - pve-lxc: Uses Telmate provider to create & manage Proxmox LXC containers
  - pve-vm: Uses Telmate provider to create & manage Proxmox QEMU virtual machines
  - create-ansible-inventory: Custom module that dynamically creates inventory files in the /ansible/inventory directory, which are later referenced by Ansible for post-provisioning configuration
 

## Usage

- Set Proxmox variables appropriately (reference variables.tf), including proxmox_api_pass (which can be an env variable)
- Set local variables in /live module files as appropriate for provisioning
- For some modules, additional customization of Ansible variables for post-provisioning config may be necessary. Currently all variables are set specific to my implementation.
- Run `terraform init` from within the terraform directory
- Run `terraform plan|apply|destroy -target=module.*modulename*`. See root module main.tf or /live directory for module names. 
  - Optionally add `-compact-warnings` to hide verbose warnings related to resource targeting. 