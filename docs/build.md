# Build

The build command is the first part of the deployment process.  
It creates an archive of your source files at a given revision with the ability to run some custom actions, hence preparing your code to be deployed when you want.

## Argument

### revision

Branch, tag or commit id you want to build.

## Options

Options can be passed as environment variable, as variable defined in the config file, as command line argument or as command line variable.  
Options defined in command line take precedence.  
Example for the VERBOSE mode option:

```bash
# command line argument
deploy build -v ...
# command line variable
DEPLOY_VERBOSE=true deploy build ...
# variable defined in the config file
declare -g DEPLOY_VERBOSE=true
# environment variable
export DEPLOY_VERBOSE=true
```
### Config file

File defining everything you might need to build your application. 
This file may include:
- other options like archive directory, repository path and url, ...
- hooks to customize the build to your application needs

This file will be sourced during the build process.

Examples:

```bash
# command line argument
deploy build --config-file=/home/deploy/build-myapp.sh ...
deploy build --config-file /home/deploy/build-myapp.sh ...
deploy build -f /home/deploy/build-myapp.sh ...
# command line variable
DEPLOY_CONFIG_FILE=/home/deploy/build-myapp.sh deploy build ...
# environment variable
export DEPLOY_CONFIG_FILE=/home/deploy/build-myapp.sh
deploy build ...
```

### Archive directory

Path of a directory where the script should store archives produced by this script.  
If the directory does not exists, it will be created.

Examples:

```bash
# command line argument
deploy build --archive-dir=/home/deploy/build-archives ...
deploy build --archive-dir /home/deploy/build-archives ...
deploy build -a /home/deploy/build-archives ...
# command line variable
DEPLOY_ARCHIVE_DIR=/home/deploy/build-archives deploy build ...
# variable defined in the config file
declare -g DEPLOY_ARCHIVE_DIR=/home/deploy/build-archives
# environment variable
export DEPLOY_ARCHIVE_DIR=/home/deploy/build-archives
deploy build ...
```

### Repository path

Path of a directory where the script should store a mirror of your git repository.  
The build script works with a local repository which allows to perform more actions than a remote repository.  
It is always synchronised with your own remote repository. Hence the server you're running on need access to that repository.

If the directory does not exists, a fresh mirror clone will be performed.

Examples:

```bash
# command line argument
deploy build --repository-path=/home/deploy/repository.git ...
deploy build --repository-path /home/deploy/repository.git ...
deploy build -p /home/deploy/repository.git ...
# command line variable
DEPLOY_REPOSITORY_PATH=/home/deploy/repository.git deploy build ...
# variable defined in the config file
declare -g DEPLOY_REPOSITORY_PATH=/home/deploy/repository.git
# environment variable
export DEPLOY_REPOSITORY_PATH=/home/deploy/repository.git
deploy build ...
```

### Repository url

Url or Path to your own (remote?) repository.  
This is your repository where you use to push your changes.  
This repository must be reachable from the build server.

Examples:

```bash
# command line argument
deploy build --repository-url=https://github.com/myorg/myapp.git ...
deploy build --repository-url https://github.com/myorg/myapp.git ...
deploy build -p https://github.com/myorg/myapp.git ...
# command line variable
DEPLOY_REPOSITORY_URL=https://github.com/myorg/myapp.git deploy build ...
# variable defined in the config file
declare -g DEPLOY_REPOSITORY_URL=https://github.com/myorg/myapp.git
# environment variable
export DEPLOY_REPOSITORY_URL=https://github.com/myorg/myapp.git
deploy build ...
```

### Log file

The build script will log any errors and warnings to a file.  
By default, this file will be located in /tmp/deploy.log

Be sure you have write access to this file otherwise it will fail logging silently.

This option is not available in command line arguments

Examples:

```bash
# command line variable
DEPLOY_LOG_FILE=/var/log/deploy.log deploy build ...
# variable defined in the config file
declare -g DEPLOY_LOG_FILE=/var/log/deploy.log
# environment variable
export DEPLOY_LOG_FILE=/var/log/deploy.log
deploy build ...
```
