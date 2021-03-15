# quickstart

1. Make sure you can run ps1 scripts locally
2. `Set-Alias -Name "bifrost" -Value "path/to/bifrost.ps1"`
3. `bifrost -Scan`
4. `bifrost -q`

Bifrost will use your current working directory if you do not specify a `-Path`.
Look at the `bifrost.json` file that is generated after `-Scan`. You can
manually change this file to execute custom commands. For example, when running
an npm project, change the "file" to run to just `"npm i; npm start"`.

If Bifrost can't find the directory for an item in `bifrost.json`, it will
attempt to execute the command/file in the current working directory, or at
`-Path` if it was supplied.