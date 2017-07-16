# Rollback

Sometimes, after a release as been deployed, we spot some errors and wants to rollback to previous version.

There are lots and lots of strategies to rollback. The one used here is simple. Hence it might not suit to your needs.  
The strategy used is as follow:

* for each server, get the previous release. If one server does not have the same previous release as others, it fails. No rollback will be performed.
* call a hook allowing you to perform some actions before we active the previous release
* switch the "current" symlink to the previous release for every server
* call a hook allowing you to perform some actions after the previous release has been activated
* remove the last release. This allows you to run the rollback command several times.
* call a hook allowing you to notify other systems that you have rollback.

Note: we can not rollback only part of our server list yet. It implies to much complexity.

## Argument

### config file

File defining everything you need to rollback your application. 
This file may include:
- other options like current path, release path, ...
- hooks to customize the rollback to your application needs

This file will be sourced during the rollback process.

Examples:

```bash
# command line argument
deploy rollback /home/deploy/rollback-myapp.sh
# command line variable
DEPLOY_CONFIG_FILE=/home/deploy/rollback-myapp.sh deploy rollback
# environment variable
export DEPLOY_CONFIG_FILE=/home/deploy/rollback-myapp.sh
deploy rollback
```

## Options

Options can be passed as environment variable, as variable defined in the config file, as command line argument or as command line variable.  
Options defined in command line take precedence.  
Example for the VERBOSE mode option:

```bash
# command line argument
deploy rollback -v ...
# command line variable
DEPLOY_VERBOSE=true deploy rollback ...
# variable defined in the config file
declare -g DEPLOY_VERBOSE=true
# environment variable
export DEPLOY_VERBOSE=true
```

### Deploy

Specify the path containing current, releases and shared paths.  

If you define the deploy path to "/var/www/my-app", you will have the following directory structure:

> /var/www/my-app
> ├── current -> /var/www/my-app/releases/20170716133032
> ├── releases
> │   ├── 20170716132855
> │   ├── 20170716132913
> │   └── 20170716133032
> └── shared

If you want more fine grained paths, you can use the three options below

Examples:

```bash
# command line argument
deploy rollback --deploy="/var/www/my-app" ...
deploy rollback --deploy "/var/www/my-app" ...
deploy rollback -d "/var/www/my-app" ...
# command line variable
DEPLOY_PATH="/var/www/my-app" rollback ...
# variable defined in the config file
declare -g DEPLOY_PATH="/var/www/my-app"
# environment variable
export DEPLOY_PATH="/var/www/my-app"
deploy rollback ...
```

### Current

Specify the path of the current published version of your code.  

Examples:

```bash
# command line argument
deploy rollback --current="/var/www/my-app/current" ...
deploy rollback --current "/var/www/my-app/current" ...
deploy rollback -c "/var/www/my-app/current" ...
# command line variable
DEPLOY_CURRENT_PATH="/var/www/my-app/current" rollback ...
# variable defined in the config file
declare -g DEPLOY_CURRENT_PATH="/var/www/my-app/current"
# environment variable
export DEPLOY_CURRENT_PATH="/var/www/my-app/current"
deploy rollback ...
```

### Releases

Specify the path where every releases are stored.

Examples:

```bash
# command line argument
deploy rollback --releases="/var/www/my-app/releases" ...
deploy rollback --releases "/var/www/my-app/releases" ...
deploy rollback -c "/var/www/my-app/releases" ...
# command line variable
DEPLOY_RELEASES_PATH="/var/www/my-app/releases" rollback ...
# variable defined in the config file
declare -g DEPLOY_RELEASES_PATH="/var/www/my-app/releases"
# environment variable
export DEPLOY_RELEASES_PATH="/var/www/my-app/releases"
deploy rollback ...
```

### Shared

Specify the path where every persistent files and directories are stored.

Examples:

```bash
# command line argument
deploy rollback --shared="/var/www/my-app/shared" ...
deploy rollback --shared "/var/www/my-app/shared" ...
deploy rollback -c "/var/www/my-app/shared" ...
# command line variable
DEPLOY_SHARED_PATH="/var/www/my-app/shared" rollback ...
# variable defined in the config file
declare -g DEPLOY_SHARED_PATH="/var/www/my-app/shared"
# environment variable
export DEPLOY_SHARED_PATH="/var/www/my-app/shared"
deploy rollback ...
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
