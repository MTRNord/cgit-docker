# Cgit Docker with Gitolite

[![GitHub](https://img.shields.io/github/license/LuqueDaniel/cgit-docker?style=flat-square)](https://github.com/LuqueDaniel/cgit-docker/blob/main/LICENSE)

Docker image for [Cgit](https://git.zx2c4.com/cgit/about/) a web interface for [Git](https://git-scm.com/) repositories, integrated with [Gitolite](https://gitolite.com/) for Git repository management and access control.

The image compiles and deploys Cgit with Nginx and fcgiwrap, and includes Gitolite for managing Git repositories via SSH.

## Quick Start

To build and run the container:

```bash
# Build the image
docker build -t cgit-gitolite .

# Run the container
docker run -d \
  --name cgit \
  -p 8080:8080 \
  -p 2222:22 \
  -v gitolite-data:/var/lib/git \
  cgit-gitolite
```

Then open `http://localhost:8080` in your browser to access the Cgit web interface.

## Cgit configuration

* You can check and edit the Cgit configuration of the image in the [`cgitrc`](https://github.com/LuqueDaniel/cgit-docker/blob/main/cgitrc) file.
* The Nginx configuration is in the [`cgit_nginx.conf`](https://github.com/LuqueDaniel/cgit-docker/blob/main/) file.
* [`cgit_build.conf`](https://github.com/LuqueDaniel/cgit-docker/blob/main/cgit_build.conf) contains environment variables for Cgit compilation. You need to edit it if you want to use different paths.

If you want to use your own settings you can mount your `cgitrc` file:

```bash
docker run -d \
  --name cgit \
  -p 8080:8080 \
  -p 2222:22 \
  -v gitolite-data:/var/lib/git \
  -v /path/to/your/cgitrc:/opt/cgit/cgitrc:ro \
  cgit-gitolite
```

The Cgit configuration uses Gitolite's `projects.list` file for repository discovery, with a fallback to scanning `/var/lib/git/repositories` if the projects.list doesn't exist yet.

## SSH Host Keys

By default, SSH host keys are generated on first container start. This means the host key will change if you recreate the container, causing SSH warnings.

### Setting Up Persistent SSH Host Keys

For production use, you should persist SSH host keys across container restarts:

**Quick method:** Use the provided script:

```bash
./generate-ssh-host-keys.sh
```

This will generate all necessary host keys in the `./ssh-host-keys` directory and show you the exact Docker command to use.

**Manual method:**

1. **Generate SSH host keys locally** (one time):

```bash
mkdir -p ./ssh-host-keys
ssh-keygen -t rsa -f ./ssh-host-keys/ssh_host_rsa_key -N ""
ssh-keygen -t ecdsa -f ./ssh-host-keys/ssh_host_ecdsa_key -N ""
ssh-keygen -t ed25519 -f ./ssh-host-keys/ssh_host_ed25519_key -N ""
```

2. **Mount the host keys when running the container**:

```bash
docker run -d \
  --name cgit \
  -p 8080:8080 \
  -p 2222:22 \
  -v gitolite-data:/var/lib/git \
  -v $(pwd)/ssh-host-keys/ssh_host_rsa_key:/etc/ssh/ssh_host_rsa_key:ro \
  -v $(pwd)/ssh-host-keys/ssh_host_rsa_key.pub:/etc/ssh/ssh_host_rsa_key.pub:ro \
  -v $(pwd)/ssh-host-keys/ssh_host_ecdsa_key:/etc/ssh/ssh_host_ecdsa_key:ro \
  -v $(pwd)/ssh-host-keys/ssh_host_ecdsa_key.pub:/etc/ssh/ssh_host_ecdsa_key.pub:ro \
  -v $(pwd)/ssh-host-keys/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key:ro \
  -v $(pwd)/ssh-host-keys/ssh_host_ed25519_key.pub:/etc/ssh/ssh_host_ed25519_key.pub:ro \
  cgit-gitolite
```

3. **Verify the host key fingerprint**:

```bash
ssh-keygen -lf ./ssh-host-keys/ssh_host_ed25519_key.pub
```

Now your SSH host keys will remain consistent across container restarts, and users won't see "host key changed" warnings.

**Security Note:** Keep these host keys secure and backed up. If compromised, regenerate them and inform all users of the new fingerprints.

## Gitolite Integration

This image includes Gitolite for Git repository management with SSH access control.

### Initial Setup

1. **Start the container** with SSH port exposed:

   ```bash
   docker run -d \
     --name cgit \
     -p 8080:8080 \
     -p 2222:22 \
     -v gitolite-data:/var/lib/git \
     cgit-gitolite
   ```

2. **Get the default admin SSH key** (generated on first run):

   ```bash
   docker exec -it <container-name> cat /var/lib/git/.ssh/admin
   ```

   Save this private key to your local machine as `~/.ssh/gitolite-admin` and set proper permissions:

   ```bash
   chmod 600 ~/.ssh/gitolite-admin
   ```

3. **Clone the gitolite-admin repository**:

   ```bash
   git clone ssh://git@localhost:2222/gitolite-admin
   ```

### Managing Repositories

Gitolite manages repositories through the special `gitolite-admin` repository:

1. **Add users** by adding their public SSH keys to `keydir/` directory:

   ```bash
   cd gitolite-admin
   cp ~/user.pub keydir/username.pub
   ```

2. **Configure repository access** in `conf/gitolite.conf`:

   ```
   repo my-project
       RW+     =   admin
       RW      =   developer
       R       =   @all
   
   repo another-repo
       RW+     =   admin
   ```

3. **Commit and push changes**:

   ```bash
   git add .
   git commit -m "Added new user and repository"
   git push
   ```

   Gitolite will automatically create and configure repositories based on your configuration.

### Using Your Own Admin Key

To use your own SSH key instead of the auto-generated one:

1. Generate your SSH key pair (if you don't have one):

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/gitolite-admin
```

2. Mount your public key when starting the container:

```bash
docker run -d \
  --name cgit \
  -p 8080:8080 \
  -p 2222:22 \
  -v gitolite-data:/var/lib/git \
  -v ~/.ssh/gitolite-admin.pub:/var/lib/git/.ssh/admin.pub:ro \
  cgit-gitolite
```

### Viewing Repositories in Cgit

All repositories managed by Gitolite will automatically appear in Cgit at `http://localhost:8080`.

**Repository Discovery:** Cgit uses Gitolite's `projects.list` file (`/var/lib/gitolite3/projects.list`) to discover repositories. This ensures that only repositories that Gitolite has marked as publicly visible will appear in Cgit. If a repository doesn't appear, check that it's properly configured in your `gitolite.conf` file.

By default, the gitolite-admin repository is visible. To hide it, add this to your `conf/gitolite.conf` in the gitolite-admin repository:

```
repo gitolite-admin
    config gitweb.deny = true
```

Then commit and push the changes.

## References

* [Cgit README](https://git.zx2c4.com/cgit/tree/README)
* [Cgit configuration](https://git.zx2c4.com/cgit/tree/cgitrc.5.txt)
* [cgit - ArchWiki](https://wiki.archlinux.org/title/Cgit)
* [Gitolite Documentation](https://gitolite.com/gitolite/index.html)
* [Gitolite Basic Administration](https://gitolite.com/gitolite/basic-admin.html)
