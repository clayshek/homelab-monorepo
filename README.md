# Homelab-Monorepo

The ultimate home lab infrastructure as code repo.

## Overview

This code provisions & configures my home lab environment. See https://clayshek.github.io/homelab-monorepo for details. Workloads run either on [Proxmox](https://www.proxmox.com/en/downloads), [K3s](https://k3s.io/) on Raspberry Pis, some on [Heroku](https://www.heroku.com/). 

Tooling here enables provisioning, config, destruction, and reprovisioning of various components including: Windows Active Directory, Hyper-V, Apache CloudStack, Hashicorp Vault, GitHub Actions Runner, Kubernetes, etc (see status matrix below). Components are generally modular and independent, with some obvious exceptions (e.g., Active Directory required for some Windows infra)

## Tools Used 

- [Packer](https://www.packer.io/) for building VM OS (Windows & Linux) templates using [Proxmox builder](https://www.packer.io/docs/builders/proxmox/iso)
- [Terraform](https://www.terraform.io/) for provisioning infrastructure using [Telmate Provider for Proxmox](https://github.com/Telmate/terraform-provider-proxmox)
- [Ansible](https://docs.ansible.com/) for post-provisioning configuration

## Workflow

- Packer builds OS templates on Proxmox, based off of ISO files you've downloaded to Proxmox storage.
  - Packer can be run locally from anywhere with access to Proxmox server(s), or as I have set up, via a self hosted [GitHub Actions Runner](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners) connected to a private GitHub repo
  - The templates are created with an account for initial provisioning & config
  - Both Linux and Windows templates are setup with [CloudInit](https://cloudinit.readthedocs.io/en/latest/) ([CloudBase-Init](cloudbase-init.readthedocs.io/en/latest/) for Windows) and configured with a [Cloud-Init Drive](pve.proxmox.com/wiki/Cloud-Init_Support) in Proxmox

- Terraform is run to provision new VM(s) or LXC container(s) on Proxmox, based on either a VM template created with Packer or a Container template downloaded via Proxmox.  
  - Variables set various provisioning parameters such as hostname, static IP, etc
  - A custom module creates dynamic inventory for Ansible
  - For provisioning, a temp ssh key pair is created for Linux, while the Windows local 'ansible' user account is used for Windows
  - Terraform calls Ansible for post-provisioning config

- Ansible handles various OS & package related configurations
  - Inventory based role assignments determine what plays / tasks are run
  - Ansible can be run independently after initial provisioning. Plays mostly should be idempotent, though some may not be in rare cases. 

## Prerequisites

- A [Proxmox VE](https://www.proxmox.com/en/downloads) virtualization environment
- A server / VM (Linux or WSL on Windows) with the above listed tools installed and a base understanding of how they work 

## Disclaimers & Notes

- All of this is a work in progress. Most here is functional, some possibly is not (yet)
- None of this is "production" quality, you will find some security best practices not being followed in the name of simplicity
- Some of the methods used are not good development or design practices, but accepted as a trade off for simplicity, addressing bugs, etc
- Besides this README, further documentation can be found in code comments or nested READMEs


## Usage

- Clone the repo

### Packer Templates
- Using the included Packer templates isn't required, but the Terraform provisioning expects a template for most workloads.
- See README in Packer directory for more info. 

### Terraform Provisioning
- Modify provisioning variables as appropriate (see README in Terraform directory)
- `terraform init`
- `terraform apply -target=module.*modulename*`

### Ansible Configuration
- Can be run independently, but Terraform hands off to Ansible after provisioning, so not much else required other than modifying variables as appropriate (see README in Ansible directory). 

## Capabilities Status Matrix

| Product | Status |
| ------  | ------ |
| Active Directory | Working |
| Hyper-V (nested) | Partial |
| CloudStack / KVM (nested) | Working |
| Windows Admin Center | Working |
| AWX | Working |
| Hashicorp Vault | Partial |
| GitHub Actions Runner | Working |
| Consul | Pending |
| K3s (Proxmox VMs) | Working |
| K3s (Raspberry Pis) | Working |
| Kubernetes (Proxmox VMs) | Pending |
| Rancher | Working |
| VMware ESXi (nested) | Pending |
| Grafana | Pending |
| OpenStack | Pending |
| Infoblox | Pending |
| RasPi Provisioning | Pending |
| Heroku Integration | Pending |
| Packer Windows 2019 Template | Not Working |
| Packer Windows 2022 Template | Pending |
| Packer Ubuntu 18.04 Template | Working |
| Packer Ubuntu 20.04 Template | Working |
| Packer Rocky Linux Template | Working |
| Packer ESXi Template | Working |

## To-Do

- [X] Add capability to add user ssh key with Ansible
- [ ] Move secrets to Hashicorp Vault
- [ ] Add OpenSSH to windows_common Ansible role
- [ ] Convert Packer from json to hcl
- [ ] Setup remote terraform state

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[GNU GPLv3](https://spdx.org/licenses/GPL-3.0-or-later.html)
