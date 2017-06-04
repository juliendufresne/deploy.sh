# deploy.sh

Deploy your project(s) using shell scripts.
 
## Requirements

This deployment strategy assumes:

* a server to **build** your project(s)
* **bash** is installed on every involved servers (build and target servers)
* project(s) versioned under **git**
* the build server can access target servers using **ssh** and **rsync**

## How it works?

This script is composed of mainly 2 commands: `build` and `release`.  
The first one is meant to create an archive file for a given revision.  
It should be immutable in a way that if you call this command twice for the same revision, it should produce the exact same content: an archive.

The latter command deploy an archive produced by the `build` command to a determined target server(s).

## The build command

```bash
deploy build [options] <revision>
```

### The build process

1. Refresh the local repository. The script maintains a repository stored within the build server. If you have specified a remote repository url, this steps will refresh the local repository
2. Create a workspace in the build server's temporary directory.
3. Extract git content of the specified revision using `git archive`
4. Generate a .REVISION file in the root directory of the workspace. This file will contain the commit sha of the current revision.
5. Call a user defined hook name "build". This is where you can add some specific action to do during the build step.
6. Archive the workspace in a tar.bz2 file.

> Use the `--help` option for more details about this command.

## The release command

```bash
deploy release [options] <config-file> <archive-file> [<server-name> ...]
```

**config-file**: a configuration file containing every details needed to deploy to servers. **TODO: explain the config file content**  
**archive-file**: the archive file produced by the build command.  
**server-name**: optional. Name of one or more servers to deploy to. It filters the server list provided by the config-file and allows to deploy to less servers than in a normal process.

### The release process

1. Test ssh connection to specified servers
2. Ensure directory structure exists within each servers, creating it if not. **TODO: explain the directory structure**
3. Ensure defined shared items exists in the shared folder. Call hook "create_shared_links" if an item does not exists and check again.
4. Send archive to every servers
5. Extract archive within every servers and rename the folder with the current date
6. Link release with shared items defined in the config file
7. Activate the release. **TODO: explain what it means**
8. Clean old releases.

> Use the `--help` option for more details about this command.

## Advanced features

* [Enhance deployment with hooks](docs/hooks.md)
