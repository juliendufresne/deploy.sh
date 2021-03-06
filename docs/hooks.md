Hooks
=====

Some steps (see below) may attach some functions before and/or after they are run.  
This functions are called hooks.

To attach a hook at a specific step, you only need to:

1. create a function accessible from your config file
2. call the `add_hook <hook_type> <function_name>` with the corresponding hooks type and the name of the function you've just defined.

## Example

```bash
# my_build_config.sh
function load_config()
{
    add_hook "build" "do_build"
}

function do_build()
{
    echo "I am showing this message during the build step"
}

load_config
```

In order to use it, simply run the `build` command like this:  
`./deploy build --config-file my_build_config.sh`

## Existing hooks types

List of hooks type and their arguments.  
Every commands available for the build or release command are also available for the deploy command.
 
### During the build command

**build**

hook signature: `build $workspace $revision`

This hook allows you to run whatever your project needs and that can be done on the build server (i.e: probably no database access or other production servers)

### During the release command

**create_shared_links**

hook signature: `create_shared_links $shared_directory`

This hooks is called on each remote servers when at least one of the shared links (defined by DEPLOY_SHARED_ITEMS variable) is missing.  
It aims to create missing shared links during the release steps.

This hooks is only relevant for deployment on dynamic servers. If you always deploy to the same servers, this hook will never be call (unless you removed some shared links).

**pre_send_archive_to_servers**

hook signature: pre_send_archive_to_servers $archive

This hooks is called on the build server before the archive is sent to remote servers.  
It can be used to add some files to the archive at release time.

**post_extract_archive**

hook signature: `post_extract_archive $server_index $current_release_path`

Called after the archive is extracted to each remote servers

> *Note:* `$server_index` allows you to run an action to one server only. Suppose you have to server, this first server will receive `1`, the second `2`, ...

**post_link_release_with_shared_folder**

hook signature: `post_link_release_with_shared_folder $server_index $current_release_path $shared_path`

Called when the shared folder is linked with this release. Use it when you want to create some files or need some files from the shared path.  
You can also use this hook to perform some action right before the revision is activated.

> *Note:* `$server_index` allows you to run an action to one server only. Suppose you have to server, this first server will receive `1`, the second `2`, ...

**post_activate_release**

hook signature: `post_activate_release $server_index $current_path $current_release_path`

Called right after the released revision is live.  

> *Note:* `$server_index` allows you to run an action to one server only. Suppose you have to server, this first server will receive `1`, the second `2`, ...

> *Note:* Since the release is activated, every failed hooks will not stop the execution but an error will be raised.

**post_release**

hook signature: `post_release $revision_file`

Called right before the release command ends.  
`$revision_file` is a path to a copy of the .REVISION file.

> *Note:* Since the release is activated, every failed hooks will not stop the execution but an error will be raised.

### During the rollback command

**pre_activate_previous_release**

hook signature: `pre_activate_previous_release $server_index $current_path $current_release_path $shared_path`

Called before the previous release is activated

> *Note:* `$server_index` allows you to run an action to one server only. Suppose you have to server, this first server will receive `1`, the second `2`, ...

**post_activate_previous_release**

hook signature: `post_activate_previous_release $server_index $current_path $current_release_path $shared_path`

Called right after the previous release revision is live.  

> *Note:* `$server_index` allows you to run an action to one server only. Suppose you have to server, this first server will receive `1`, the second `2`, ...

> *Note:* Since the release is activated, every failed hooks will not stop the execution but an error will be raised.

**post_rollback**

hook signature: `post_rollback`

Called right before the rollback command ends.  

> *Note:* Since the release is activated, every failed hooks will not stop the execution but an error will be raised.

