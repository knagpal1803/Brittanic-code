# Users Manager Ansible Role

An idempotent, multi-platform Ansible role designed to manage groups, establish standard system users, mount authorized SSH cryptographic keys, and clean up deprecated system entities safely.

## Supported Distributions
* Debian / Ubuntu Core
* RedHat Enterprise Linux / Rocky Linux / AlmaLinux 8 & 9

## Variables
Default values are assigned within `defaults/main.yml`:
* `users`: List containing mappings of users, their system groups, and public key data.
* `users_remove`: Simple string array listing account names targeted for total removal.
* `users_default_shell`: Fallback interactives string path (defaults to `/bin/bash`).

## Execution Examples

### 1. Local Playbook Integration
```yaml
- hosts: servers
  become: true
  roles:
    - role: users_manager
      vars:
        users:
          - name: admin_user
            groups: ["sudo", "wheel"]
            ssh_key: "ssh-ed25519 AAA..."
```

### 2. Running Molecule Tests
Ensure you have `molecule`, `molecule-plugins[docker]`, and `ansible` locally ready. Run:
```bash
molecule test
```
