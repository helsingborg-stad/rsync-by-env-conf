# Sync

This script synchronizes files from a remote server to a local directory using `rsync`. It only executes a post-sync script if files have changed.

## Features
- Uses `rsync` for efficient file synchronization.
- Supports exclusion and inclusion files.
- Runs a post-sync script automatically if files were modified.
- Allows dry-run mode for testing.
- Supports simplified SSH access via `~/.ssh/config`.

## Installation
Ensure you have `rsync` and `ssh` installed on your system.

```sh
sudo apt install rsync openssh-client
```

## Usage
Run the script with a config file:

```sh
./sync.sh --config=config.env
```

Use dry-run mode to preview changes:

```sh
./sync.sh --config=config.env --dry-run
```

## Configuration
Create a configuration file (e.g., `config.env`) with the following content:

```ini
# SSH destination (user@host)
SSH_DEST="web" # See example SSH config below

# SSH port (default is 22)
SSH_PORT=3022

# Remote folder path (absolute path on remote server)
REMOTE_FOLDER="/var/www/prod/"

# Local destination directory
LOCAL_DEST="/var/www/prod/"
```

### Exclusion and Inclusion Files
Optionally, create files for exclusions and inclusions:
- `config.env.exclude.txt` → List of patterns to exclude.
- `config.env.include.txt` → List of patterns to include.

Example `config.env.exclude.txt`:
```
*.log
node_modules/
```

## Post-Sync Script
If changes are detected, the script will execute a corresponding post-sync script named:

```
config.env.post-run.sh
```

Example `config.env.post-run.sh`:

```sh
#!/bin/bash
systemctl restart nginx
echo "Post-sync script completed."
```

Ensure it is executable:

```sh
chmod +x config.env.post-run.sh
```

## Simplified SSH Access
To avoid specifying long SSH commands, map the host in your SSH configuration file (`~/.ssh/config`):

```ini
Host remote-srv
   UpdateHostKeys no
   User remoteuser
   IdentityFile ~/.ssh/remote_server_id_rsa
   HostName 0.0.0.0
   Port 22
```

Now, instead of using `user@0.0.0.0`, you can simply use `remote-srv` in your `config.env`:

```ini
SSH_DEST="remote-srv"
```

## License
MIT License