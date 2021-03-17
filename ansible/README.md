# Homelab-Monorepo Ansible README

Details on Ansible implementation and usage for this repo. Reference README one level up for additional details.

## Overview

- Initial Ansible run is via Terraform provisioning. Ansible-playbook is run as final step.
- Inventory is dynamically populated by Terraform when resources are provisioned. 
- For Linux resources, a temp ssh key is created by Terraform for provisioning & initial configuration. Part of that config includes replacing the SSH key with a user specified public key.

 ## Usage

- For deployed roles, set applicable variables appropriately.
   - See inventory/group_vars, as well as role specific vars
- Initial connection differences betweeh Linux (SSH) & Windows (WINRM) are handled by the 'linux_conn_params' or 'windows_conn_params' roles. Adjust vars here as/if necessary. E.g., Ansible user for Windows should match what is in the template image. 
- [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) is used for secrets. My vaulted variables won't work for you. Encrypt your own variables and place the Vault password in '.vault_pass' in the ansible directory. Will likely change this to use Hashicorp Vault in the future. 
- Little else to do for initial use. Ansible is called via terraform.
- Subsequent Ansible-only runs can be done to update configs by calling the master playbook files in the ansible directory:
  - Windows: `ansible-playbook -i /inventory --vault-password-file .vault_pass *inventory_role*.yml`
  - Linux: `ansible-playbook -u *username* -i /inventory --private-key *private_key*.pem *inventory_role*.yml`
