# quickstart

1. Make sure you can run ps1 scripts locally
2. `Set-Alias -Name "bifrost" -Value "path/to/bifrost.ps1"`
3. `bifrost -Scan`
4. `bifrost -q`

Bifrost will use your current working directory if you do not specify a `-Path`.
Look at the `bifrost.json` file that is generated after `-Scan`. You can
manually change this file to execute custom commands. For example, when running
an npm project, change the value to `"npm i; npm start"`.

If Bifrost can't find the directory for an item in `bifrost.json`, it executes
the command at `-Path`, which defaults to the current working directory.

# non-repository -Start values

Bifrost works best when it's managing one directory that contains many git
repositories, which contain executable files or files that facilitate
executing those repositories.

Sometimes, however, you might want to run some other command along with a batch
of repositories. For that, manually insert a new key/value pair into your
`bifrost.json`. The key that you give it will allow you to specificy it in the
`-Only` parameter, while the value will be executed on `-Start`.

For example, let's say you have three repositories in `C:/dev/`. You want to run
all of their `start.exe` files, but you also want to execute a non-repository
command.

1. `bifrost -Scan -ForFile start.exe`
2. add `"extra": "echo 'hello world'",` to the `bifrost.json`
3. `bifrost -Start -Only first,second,third,extra -NoExit`