# Homelab-Monorepo Packer README

Details on Packer implementation and usage for this repo. Reference README one level up for additional details.

## Overview

- Packer, using the [Proxmox builder](https://www.packer.io/docs/builders/proxmox), is used to create base OS image templates. 
- The proxmox-vars.json file contains required Proxmox API connectivity parameters. Update accordingly.
- ** Mostly, Packer here is just barely working and needs some work. Have spent more time on provisioning and config **
- Methodology:

  - Ubuntu 18.04: Uses a preseed kick off file, updates packages and distro, adds CloudInit drive to template
  - Windows 2019: Uses autounattend.xml. Preps for Ansible, installs CloudBase-Init, Windows updates. Syspreps with CloudBase-Init to accept user-data from CloudInit drive when template is provisioned. 

- Current status of different OS platforms:

  - Ubuntu 18.04: Works
  - Ubuntu 20.04: Not working, more to do with new [autoinstallation](https://ubuntu.com/server/docs/install/autoinstall) unattended feature
  - Windows Server 2019: Partially working. Base build succeeds, difficulty with Cloudbase-Init integration. Manually finishing the build at this point. 


 ## Usage

- Customize variables in proxmox-vars.json and build files as necessary
- `packer build -var-file="proxmox-vars.json" ubuntu/18.04/ubuntu-18-04.json`
- `packer build -var-file="proxmox-vars.json" windows/2019/windows-2019-proxmox.json`

- Alternatively, use included example [GitHub Actions](docs.github.com/en/actions) workflow files in combination with a [self hosted runner](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners) to run template builds through CI pipelines, and using [GitHub secrets](docs.github.com/en/actions/reference/encrypted-secrets) for the API password. 