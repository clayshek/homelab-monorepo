# Homelab-Monorepo Packer README

Details on Packer implementation and usage for this repo. Reference README one level up for additional details.

## Overview

- Code for provisioning Proxmox VM OS image templates, using the [Packer Proxmox builder](https://www.packer.io/docs/builders/proxmox). 
- The proxmox-vars.json file contains required Proxmox API connectivity parameters. Update accordingly.
- Still WIP in some places. Priority has been on provisioning and config.

## Methodology:

  - **Ubuntu 18.04**: Starts from [18.04 "Bionic" Server ISO](http://cdimage.ubuntu.com/releases/18.04/release/). Uses a preseed kick off file, updates packages and distro, adds CloudInit drive to template
  - **Ubuntu 20.04**: Starts from [20.04 "Focal" live Server ISO](https://releases.ubuntu.com/focal/). Uses [autoinstallation](https://ubuntu.com/server/docs/install/autoinstall) config file for initial template build, then configures for a Proxmox ConfigDrive for cloud-init usage when cloned. Long term want to convert to using Ubuntu cloud image, but [this issue](https://github.com/hashicorp/packer-plugin-proxmox/issues/29) with the Packer Proxmox plugin needs resolution to enable that. 
  - **Rocky Linux**: Pending
  - **Windows 2019**: Starts from [Eval download of Server 2019 ISO](https://www.microsoft.com/en-US/evalcenter/evaluate-windows-server-2019?filetype=ISO). Uses autounattend.xml. Preps for Ansible, installs virtio drivers, CloudBase-Init, Windows updates. Syspreps with CloudBase-Init to accept user-data from CloudInit drive when template is provisioned. 
  - **Windows 2022**: Pending
  - **VMware ESXi**: Starts from [ESXi ISO](https://www.vmware.com/go/download-vspherehypervisor). Uses a kickstart file to install ESXi, set basic networking, and enable SSH. Due to lack of mature templating options, creating a dedicated template for each desired VM. Probably overkill given short install time.

## OS Template Status:

  - **Ubuntu 18.04**: Working
  - **Ubuntu 20.04**: Working (somewhat hacky, see notes above). 
  - **[Rocky Linux](https://rockylinux.org/)** 8.5: Working
  - **Windows Server 2019**: Partially working. Base build succeeds, difficulty with Cloudbase-Init integration. Manually finishing the build at this point. 
  - **Windows Server 2022**: Pending
  - **VMware ESXi**: Working (somewhat hacky, see notes above). 


 ## Usage

- Customize variables in proxmox-vars.json and build files as necessary
- `packer build -var-file="proxmox-vars.json" ubuntu/18.04/ubuntu-18-04.json`
- `packer build -var-file="proxmox-vars.json" ubuntu/20.04/ubuntu-20-04.json`
- `packer build -var-file="proxmox-vars.json" windows/2019/windows-2019-proxmox.json`
- `packer build -var-file="proxmox-vars.json" -var-file="esxi/esxi[01-04]-vars.json" esxi/esxi.json`

- Alternatively, use included example [GitHub Actions](docs.github.com/en/actions) workflow files in combination with a [self hosted runner](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners) to run template builds through CI pipelines, and using [GitHub secrets](docs.github.com/en/actions/reference/encrypted-secrets) for the API password. 