# Proxmox Deployment Automation

Automated script deployment system for synchronizing scripts from your Windows development environment to Proxmox hosts.

## Files

- `deployment-config.json` - Configuration file mapping hosts to scripts
- `deploy-to-proxmox.ps1` - Deployment automation script

## Configuration

Edit `deployment-config.json` to define deployment targets:

```json
{
    "hosts": [
        {
            "name": "intel-1250p",
            "alias": "intel-1250p",
            "user": "root",
            "targetDir": "/root/sh/",
            "scripts": [
                "infrastructure/proxmox/lxc-setup.sh",
                ...
            ]
        }
    ]
}
```

**Fields:**
- `name`: Display name for the host
- `alias`: SSH alias from `~/.ssh/config`
- `user`: SSH username (typically `root`)
- `targetDir`: Destination directory on remote host
- `scripts`: Array of script paths relative to repository root

## Usage

### Deploy to All Hosts

```powershell
cd ~/Documents/git/dev/infrastructure/deployment
./deploy-to-proxmox.ps1
```

### Deploy to Specific Host

```powershell
./deploy-to-proxmox.ps1 -Hosts "intel-1250p"
```

### Dry Run (Simulate)

```powershell
./deploy-to-proxmox.ps1 -DryRun
```

### WhatIf Mode

```powershell
./deploy-to-proxmox.ps1 -WhatIf
```

## Requirements

- SSH keys configured for passwordless authentication
- `~/.ssh/config` with host aliases (e.g., `intel-1250p`, `intel-n6005`)
- OpenSSH installed (included in Windows 10/11)

## Workflow

1. Edit scripts in repository: `~/Documents/git/dev/infrastructure/proxmox/`
2. Test changes locally
3. Commit to git
4. Run deployment script
5. Scripts are automatically copied and made executable

## Safety

- Supports `-WhatIf` for simulation
- Shows progress for each file
- Reports errors clearly
- Automatically sets execute permissions (`chmod +x`)

## Integration

Add to your workflow:

```powershell
# After updating scripts
git add infrastructure/proxmox/*.sh
git commit -m "Update Proxmox scripts"
git push

# Deploy to hosts
cd infrastructure/deployment
./deploy-to-proxmox.ps1
```
