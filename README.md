# Quickstart

1. Make sure you can run ps1 scripts locally
2. `Set-Alias -Name "bifrost" -Value "path/to/bifrost.ps1"`
3. `bifrost -Scan`
4. `bifrost -q`

bifrost will use your current working directory if you do not specify a `-Path`. Look at the `bifrost.json` file that is generated after `-Scan`. You can manually change this file to execute custom commands. For example, when running an npm project, change the value to `"npm i; npm start"`.

If bifrost can't find the directory for an item in `bifrost.json`, it executes the command at `-Path`, which defaults to the current working directory.

# 📃 Config Arguments

These arguments handle bifrost configuration. These are arguments that you might want to set permanently by creating your own Powershell alias for bifrost.

| Argument | Description |
| -------- | ----------- |
| `-Box <char[,char...]>` | Defines the box drawing characters used to delineate repositories from one another |
| `-Colors <string[,string...]>` | Defines the colors used to differentiate repositories from one another. |
| `-ForDirectory <string[,string...]>` | `.git` by default. Used with `-Scan` to determine if any sub-directory is a valid repository. This argument may be a comma separated string like `.git,other,folders` |
| `-ForFile <string[,string...]>` | Null by default. Used with `-Scan` to look for sub-directories which contain the given file or files (if a comma separated string). During a scan, potential repositories are added if they match either `-ForFile` or `-ForDirectory`. |
| `-Depth <number>` | `3` by default. Used with `-Scan` to set the depth of the filesystem search. |
| `-Path` | Current working directory by default. Use this to run bifrost in a different location. |
| `-Scale <float>` | A float that represents the desired scale of the output. |
| `-Speed <number>` | Random by default. Sets the 'speed' of the colored ribbon as repository output is printed. |
| `-Verbose`, `-v` | Enables verbose logging. |

# 🔃 Git Arguments

These arguments execute git commands in all repositories.

| Argument | Git Command | Description |
| -------- | ----------- | ----------- |
| `-Abort`, `-a` | `git abort` | Aborts a merge if it is in progress. |
| `-Branch <string>`, `-b` | `git checkout -b <branch>` | Cannot be used with `-Merge`. If `-Merge` is used, this is ignored. |
| `-Checkout <string[,string...]>`, `-c` | `git checkout <branch>` | Supports comma-separated strings. If multiple branches are indicated, bifrost attempts to checkout each branch from left to right, and stops trying to checkout the current repository on the first success. Practically, this means you can target a feature branch and a "backing branch". Repositories that contain the feature branch will end up on that branch, but repositories that don't have it will end up on the backing branch. |
| `-DeleteBranches`, `-Clean` | `git branch -D <all_local_branches>` | Deletes all local branches except for the currently checked out branch, which may be different for each repository. This is useful for cleaning up your locals. |
| `-Diff`, `-d` | `git diff --compact-summary --exit-code <branch>` | Displays compact summary of git diff target branch. |
| `-Fetch`, `-f` | `git fetch` | Fetches from origin |
| `-List`, `-l` | `git --no-pager branch --list` | Lists local branches |
| `-Log` | `git --no-pager log` | Displays latest commit from log |
| `-Merge <string>`, `-m` | `git merge --no-ff <branch>` | Used with `-Merge` to execute `git merge --no-commit --no-ff <branch>`. |
| `-Pull`, `-p` | `git pull` | Pulls from origin |
| `-Stash`, `-x` | `git stash --include-untracked` | Stashes all local changes |
| `-Status`, `-s` | `git status` | Displays status of repo. |
| `-SetUpstreamOrigin`, `-u` | `git push --set-upstream origin` | Used with `-Branch` to automatically push the new branch to origin. This is the only place where bifrost uses `git push` so be careful when using this. |

# 📎 Other Arguments

These arguments are not git specific, but handle things like running all repositories.

| Argument | Description |
| -------- | ----------- |
| `-ArgumentList <string>` | Arguments that will be passed to Powershell when it is invoked for each repository on `-Start`. |
| `-DotnetConfig <string>`, `-Config` | Used with -DotnetRestore. Allows you to specify a dotnet config file for restore. |
| `-DotnetBuild`, `-Build` | `dotnet build` |
| `-DotnetClearLocals`, `-Clear` | `dotnet nuget locals --clear all` |
| `-DotnetRestore`, `-Restore` | `dotnet restore --interactive` |
| `-Exclude <string[,string...]>`, `-e` | This argument accepts a comma-separated list of repositories which are specifically excluded from the bifrost execution. |
| `-Help`, `-h` | Prints help. |
| `-Include <string[,string...]>`, `-i` | This argument accepts a comma-separated list of repositories which are targeted specifically. Any repository that is not in this list is excluded from any bifrost commands. |
| `-NoExit` | Convenience flag for `-ArgumentList "-NoExit"`. This stops Powershell instances from immediately exiting after completing or after errors. |
| `-Quick`, `-q` | Removes the trailing ribbon when showing output. This command can also be used entirely by itself to display all known repositories and their current branches. |
| `-Scan` | Scans for repositories. If repositories were detected then after this argument is used a `bifrost.json` file will be generated. |
| `-Start` | Starts all of the repos. Make sure that you run this from an elevated terminal, or else you will get spammed with requests to authorize the executions. |

# Non-Repo -Start Values

bifrost works best when it's managing one directory that contains many git repositories, which contain executable files or files that facilitate executing those repositories.

Sometimes, however, you might want to run some other command along with a batch of repositories. For that, manually insert a new key/value pair into your `bifrost.json`. The key that you give it will allow you to specificy it in the `-Include` parameter, while the value will be executed on `-Start`.

For example, let's say you have three repositories in `C:/dev/`:
```
C:/dev/first
C:/dev/second
C:/dev/third
```

You want to run all of their `start.exe` files, but you also want to execute a non-repository bound command one time.

1. `bifrost -Scan -ForFile start.exe`
2. add `"extra": "echo 'hello world'",` to the `bifrost.json`
3. `bifrost -Start -Include first,second,third,extra -NoExit`

When bifrost executes files from the `bifrost.json`, it parses them into an ordered list, which is sorted alphabetically. It just so happens that in this example the order of execution is `extra`, `first`, `second`, `third` because that sequence is already in alphabetic order.