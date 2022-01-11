<#
.SYNOPSIS
     ________  ___  ________ ________  ________  ________  _________   
    |\   __  \|\  \|\  _____|\   __  \|\   __  \|\   ____\|\___   ___\ 
    \ \  \|\ /\ \  \ \  \__/\ \  \|\  \ \  \|\  \ \  \___|\|___ \  \_| 
     \ \   __  \ \  \ \   __\\ \   _  _\ \  \\\  \ \_____  \   \ \  \  
      \ \  \|\  \ \  \ \  \_| \ \  \\  \\ \  \\\  \|____|\  \   \ \  \ 
       \ \_______\ \__\ \__\   \ \__\\ _\\ \_______\____\_\  \   \ \__\
        \|_______|\|__|\|__|    \|__|\|__|\|_______|\_________\   \|__|
                                                   \|_________|        
.DESCRIPTION
    This tool is a git wrapper that detects your local dev environment and allow you to apply git batch operations to all repositories living in one folder. You can restrict the tool to only certain repos, run all repos at once, delete all local branches, create new branches, merge multiple repos branches at once, and so on.

    Many of these operations are independent of one another and execute in a hardcoded order, to prevent mistakes.
.PARAMETER Scan
    Scans for repositories and saves a file called 'bifrost.json' which lists them in a hashtable.
.PARAMETER ForDirectory
    -ForDirectory <string[,string...]>

    Used with -Scan to scan for repositories that contain the directory. Can be a string or a comma-separated value. '.git' by default.
.PARAMETER ForFile
    -ForFile <string[,string...]>

    Used with -Scan to scan for repositories that contain the file. Can be a string or a comma-separated value. Empty by default.
.PARAMETER Depth
    -Depth <number>

    Determines the search depth when scanning for repositories.
.PARAMETER Help
    Displays usage and examples.
.PARAMETER Start
    Starts the servers.
.PARAMETER ArgumentList
    -ArgumentList <string>

    A string that is passed to the powershell invocation on -Start. For example "-NoExit".
.PARAMETER NoExit
    Passes -NoExit to the powershell invocation on -Start. When using this switch, if the file fails to execute the window will remain open so that errors are visible.
.PARAMETER NoCommit
    When merging, uses git merge --no-commit.
.PARAMETER Speed
    -Speed <number>

    Controls how fast new repositories increment their ending on the screen, when displayed.
.PARAMETER Path
    -Path <string>

    Directory location for the script to run in. This should be a folder that contains many other repositories. If you do not provide a value for -Path, then it defaults to the current working directory.
.PARAMETER DotnetConfig
    -Config <string>

    Path to the config file you want to use with dotnet restore --configfile
.PARAMETER DotnetClearLocals
    Executes dotnet nuget locals --clear one time in the root directory.
.PARAMETER DotnetRestore
    Executes dotnet restore --interactive for each repository if a csproj file is found in that repository. The search for a .csproj file depth is determined with -Depth.

    Warning! Using this switch may require human intervention in order to resolve authentication provider processes, as it uses --interactive.
.PARAMETER Include
    -Include <string[,string...]>

    A comma-separated list of included repos. This is trimmed before using, so that repo names that were auto-completed from the command line are parsed correctly.

    If -Include is empty, then all detected repositories are targeted.
.PARAMETER Exclude
    -Exclude <string[,string..]>

    Repositories to skip during the operation. Overrides repositories in -Include.
.PARAMETER Quick
    Shortens some output for a more compact look.
.PARAMETER Abort
    Executes 'git merge --abort'.
.PARAMETER DeleteBranches
    Deletes local branches.
.PARAMETER Fetch
    Executes 'git fetch'.
.PARAMETER List
    Executes 'git branch --list', which shows all local branches.
.PARAMETER Pull
    Pulls the current branch.
.PARAMETER Stash
    Executes 'git stash --include-untracked'.
.PARAMETER Status
    Executes 'git status'.
.PARAMETER Branch
    -Branch <string>

    Creates a new branch. You cannot create a new branch and merge at the same time. If there is a conflict, merge is run instead of creating a new branch.
.PARAMETER SetUpstreamOrigin
    If this flag is enabled, when a branch is created with -Branch, then it is automatically pushed with '--set-upstream origin'.
.PARAMETER Checkout
    -Checkout <string[,string...]>

    Executes 'git checkout <branch>'. The parameter passed can be a comma separated list of branches. The repository will checkout the FIRST valid branch in the provided list, and ignores the rest.
.PARAMETER Merge
    Executes 'git merge --no-ff <Merge>' such that the branch indicated by the -Merge parameter is merged into whatever branch the repo is on at the time. Best practice is to run this with -Checkout and -Include for maximum control.

    You cannot merge and create a new branch at the same time. If there is a conflict, the merge is preferred.
.EXAMPLE
    .\bifrost.ps1 -Scan -ForDirectory .git -Path D:\path\to\my\code
    This command scans the given path for repositories that contain the directory '.git' and leaves a new 'bifrost.json' file there. The purpose of the file is to prevent manually scanning for repos each time the script is run.
.EXAMPLE
    .\bifrost.ps1 -Path C:\MyDevFolder -Include web,api -Status -Start -Checkout MyFeatureBranch
    This command executes 'git status; git checkout MyFeatureBranch' in C:\MyDevFolder for only web and api, then executes their launchfiles.
.EXAMPLE
    .\bifrost.ps1 -Abort -Stash -DeleteBranches -Checkout MyFeatureBranch,dev,master
    For all the repositories found in the current directory, abort any merges, stash any changes, delete all branches and then try to checkout from a list of branches.

    If MyFeatureBranch cannot be checked out, then the repo tries to checkout dev. If dev cannot be checked out, master is.

    If the repository is able to checkout MyFeatureBranch, it does not try to checkout any other branch in the list.
.EXAMPLE
    .\bifrost.ps1 -Checkout MyFeatureBranch,MySandboxBranch
    This command attempts to checkout the MyFeatureBranch, but if it does not exist, it tries to checkout MySandboxBranch. This is useful for getting an assortment of servers to share some commonality by giving them a fallback.
.EXAMPLE
    .\bifrost.ps1 -DeleteBranches -Abort -Stash
    This command aborts all merges, stashes all work, and deletes local branches.
.NOTES
    Author: Jack Reeser
    Date: March 9, 2021
#>

Param(
    [Switch]$Scan = $false,
    [String]$ForDirectory = '.git',
    [String]$ForFile = '',
    [Int32]$Depth = 3,

    [Switch][Alias("h")]$Help = $false,

    [Switch]$Start = $false,
    [String]$ArgumentList = '',
    [Switch]$NoExit = $false,
    [Switch]$NoCommit = $false,

    [Int32]$Speed = (Get-Random -Minimum 0 -Maximum 5 ),
    [String]$Path = '',

    [String][Alias("Config")]$DotnetConfig = '',
    [Switch][Alias("Clear")]$DotnetClearLocals = $false,
    [Switch][Alias("Build")]$DotnetBuild = $false,
    [Switch][Alias("Restore")]$DotnetRestore = $false,

    [String][Alias("i")]$Include = '',
    [Switch][Alias("q")]$Quick = $false,
    [String][Alias("e")]$Exclude = '',

    [Switch][Alias("a")]$Abort = $false,
    [Switch][Alias("Clean")]$DeleteBranches = $false,
    [Switch][Alias("f")]$Fetch = $false,
    [Switch][Alias("l")]$List = $false,
    [Switch]$Log = $false,
    [Float]$Scale = 1.0,
    [Array]$Colors = @(
        'Red'
        'Yellow'
        'Green'
        'Cyan'
        'Blue'
        'Magenta'
    ),
    [Array]$Box = @(
        [char]0x25Ba,
        [char]0x2554,
        [char]0x2550,
        [char]0x255A,
        [char]0x2560
    ),
    [Switch]$Plain = $false,
    [Switch][Alias("p")]$Pull = $false,
    [Switch][Alias("x")]$Stash = $false,
    [Switch][Alias("s")]$Status = $false,

    [String][Alias("b")]$Branch = '',
    [String][Alias("d")]$Diff = '',
    [Switch][Alias("u")]$SetUpstreamOrigin = $false,
    [String][Alias("c")]$Checkout = '',
    [String][Alias("m")]$Merge = '',

    [Switch][Alias("v")]$Verbose = $false,

    [String][Alias("g")]$GitCommand = ''
)

$ErrorActionPreference = "Stop"


# NONSENSE PARAMETER DETECTION
################################################################################

$command = @{
    "invokedGit" = ($DeleteBranches -or $Abort -or $Fetch -or $List -or $Pull -or $Stash -or $Status -or $Quick -or $GitCommand -or $Log -or $Diff)
    "invokedOp" = (($Branch.Length -gt 0) -or ($Checkout.Length -gt 0) -or ($Merge.Length -gt 0) -or $DotnetRestore -or $DotnetBuild)
    "invokedScan" = (($For.Length -gt 0) -or ($Scan))
}

if((-Not $command.invokedGit) -and (-Not $command.invokedOp) -and (-Not $command.invokedScan) -and (-Not $Start) -and (-Not $DotnetClearLocals) -or $Help)
{
    Get-Help -Name $(Join-Path -Path $PSScriptRoot -ChildPath 'bifrost.ps1').ToString() -Detailed
    return
}

# GLOBALS PRE-SETUP
################################################################################

function mod {
    return [Math]::Abs($args[0] % $args[1])
}

if($Plain)
{
    $Colors = @(
        $Host.UI.RawUI.ForegroundColor
    )
    $Speed = 0
}

$color = ($Colors | Get-Random)
$color_index = [array]::IndexOf($Colors, $Color)

$max_width = [System.Math]::Min($Host.UI.RawUI.WindowSize.Width, [Math]::Abs([Int32]($Host.UI.RawUI.WindowSize.Width * $Scale)))
$indent = 0

function GetNextColor {
    $script:color_index = mod ($color_index + 1) $Colors.Count 
    $script:color = $Colors[$color_index]
}

function GetNextIndent {
    $script:indent = mod ($script:indent + $Speed) $max_width
}

$dir = @{
    "original" = (Get-Location).ToString()
    "current" = ""
}

$repos = [ordered]@{}

$file = @{
    "name" = "bifrost.json"
    "path" = ""
}

$sep = [IO.Path]::DirectorySeparatorChar

# FUNCTION DEFINITIONS
################################################################################

# Returns the 'name' of the repo
function GetRepoName {
    param(
        [String]$Name
    )
    return $Name.Replace($dir.current + $sep, "").Split($sep)[0]
}

# Returns the proper filepath that saves results from scan.
function GetFilename {
    return (Join-Path -Path $dir.current -ChildPath $file.name).ToString()
}

# Scans the -Path given for repos and saves them if at least 1 was found.
function ScanAndSave {
    param(
        [String]$File
    )
    Write-Host "scanning for $ForDirectory and $ForFile"

    if($ForDirectory.Length -gt 0)
    {
        $directories = $ForDirectory.Split(" ")
        foreach($d in $directories)
        {
            Get-ChildItem -Force -Depth $Depth -Directory -Filter $d | ForEach-Object {
                $repos[(GetRepoName -Name $_.Parent.Name)] = $_.Parent.FullName
            }
        }
    }

    if($ForFile.Length -gt 0)
    {
        $files = $ForFile.Split(" ")
        foreach($f in $files)
        {
            Get-ChildItem -Force -Depth $Depth -File -Filter $f | ForEach-Object {
                $repos[(GetRepoName -Name $_.DirectoryName)] = $_.FullName
            }
        }
    }

    if($repos.Count -gt 1)
    {
        Write-Host "$($repos.Count) repos found. writing $File"
        $repos | ConvertTo-Json | Out-File -FilePath $File
    } else {
        ErrorLog "could not find multiple repositories"
    }
}

# Tries to load repository data
function LoadFromSave {
    param(
        [String]$File
    )
    $object = Get-Content -Path $File | ConvertFrom-Json
    $object | Get-Member -MemberType *Property | ForEach-Object {
        $repos.($_.name) = $object.($_.name);
    }
}

# StringToList turns a string into a list of strings
function StringToList {
    param(
        [String]$Arg,
        [Switch]$Trim = $false
    )
    return $Arg.Split(" ") | ForEach-Object {
        if($Trim)
        {
            $_.Trim(".", "\", "/", $sep)
        } else {
            $_
        }
    }
}

function StringToInt {
    Param(
        [String]$Str
    )

    $max = 5
    $total = 0
    foreach($i in [byte[]][char[]]$Str[-$max..-1])
    {
        $total = $total + $i
    }
    return $total
}

function WriteRainbowArray {
    Param(
        [String]$Arguments = "",
        [Array]$Colors = @(
            $script:Color,
            ($Colors | Get-Random),
            $Host.UI.RawUI.ForeGroundColor
        )
    )
    $Arguments = $Arguments.substring(0, [System.Math]::Min($max_width -1, $Arguments.Length))
    $ArgumentSplit = $Arguments.Split("_")
    foreach($argument in $ArgumentSplit) {
        Write-Host -NoNewLine -ForeGroundColor $Colors[([array]::IndexOf($ArgumentSplit, $argument) % $Colors.Count)] "$argument "
    }
    Write-Host
}

function WriteBar {
    Param(
        [String]$Head = '',
        [String]$Tail = '',
        [Array]$Separators = @(
            $Box[1],
            $Box[2],
            $Box[0]
        ),
        [Array]$Colors = @(
            $Color,
            $Host.UI.RawUI.ForeGroundColor,
            $Host.UI.RawUI.ForeGroundColor
        ),
        [String]$Width = $max_width - $indent,
        [Switch]$Short = $false
    )
    Write-Host $Separators[0] -NoNewline -ForegroundColor $Colors[0]
    Write-Host $Separators[1] -NoNewline -ForegroundColor $Colors[0]
    Write-Host $Head -NoNewline -ForegroundColor $Colors[1]
    if(-not $Short)
    {
        Write-Host "".PadRight([System.Math]::Max(0, ($Width - ($Head.Length + $Tail.Length + 3))), $Separators[1]) -NoNewLine -ForegroundColor $Colors[0]
        Write-Host $Tail -NoNewline -ForegroundColor $Colors[2]
        Write-Host $Separators[2] -NoNewLine -ForegroundColor $Colors[0]
    }
    Write-Host
}

# Log normal events while a repo is being processed
function WriteBarEvent {
    if(-not $Quick)
    {
        WriteBar -Head $args -Separators $Box[4],$Box[2],$Box[0] -Short
    }
}

# Log an error
function ErrorLog {
    Write-Host "error: $args ".PadRight(80, '!') -ForegroundColor 'Red'
}

function CascadePath {
    param(
        [String]$dir,
        [String]$name,
        [String]$file
    )
    $dest = ""
    if($file.Length -gt 0)
    {
        try {
            $dest = (Split-Path -Path $file)
            if((Test-Path -Path $dest))
            {
                return $dest
            }
        } catch {
            # Write-Host "failed to Split-Path -Path $dest"
        }
    }
    if($name.Length -gt 0)
    {
        try {
            $dest = (Join-Path -Path $dir -ChildPath $name)
            if((Test-Path -Path $dest))
            {
                return $dest
            }
        } catch {
            # Write-Host "failed to Join-Path -Path $dest"
        }
    }
    return $dir
}

# SETUP AND REPO RECOGNITION
################################################################################

if ($Path -ne '')
{
    Set-Location -Path $Path
}

$dir.current = (Get-Location).ToString()

$file.path = GetFilename

if($Scan)
{
    ScanAndSave -File $file.path
}
elseif(Test-Path -Path $file.path) {
    # we found a file that looks like we can read it, so we try to load it.
    LoadFromSave -File $file.path
}

# maybe after all of that we didn't get any repos after all. in that case we
# need to just take over and scan as a last resort.
if($repos.Count -lt 1)
{
    # we echo this to the user because they did not request it
    Write-Host "no repo scan data found. scanning now..."
    ScanAndSave -File $file.path
}

# we've tried everything we could, but found no repositories. give up and error
# out.
if($repos.Count -lt 1)
{
    ErrorLog "no repositories found"
    Exit
}

# ok we have some repositories, now we just need to extract and filter them
# if we have a value in -Include
if($Include.Length -gt 0)
{
    $included = StringToList -Arg $Include -Trim
    $toDelete = [System.Collections.ArrayList]@()
    foreach($item in $repos.Keys)
    {
        if(!$included.Contains($item))
        {
            $toDelete.Add($item) > $null
        }
    }
    foreach($item in $toDelete)
    {
        $repos.Remove($item)
    }
}

# exclude listed repositories.
if($Exclude.Length -gt 0)
{
    $excluded = StringToList -Arg $Exclude -Trim
    $toDelete = [System.Collections.ArrayList]@()
    foreach($item in $repos.Keys)
    {
        if($excluded.Contains($item))
        {
            $toDelete.Add($item) > $null
        }
    }
    foreach($item in $toDelete)
    {
        $repos.Remove($item)
    }
}

if($DotnetClearLocals)
{
    Write-Host "dotnet nuget locals --clear all"
    dotnet nuget locals --clear all
}

# MAIN LOGIC
################################################################################

if($command.invokedGit -or $command.invokedOp)
{
    foreach($r in $repos.Keys)
    {
        $repo = @{
            "path" = (Join-Path -Path $dir.current -ChildPath $r)
            "branch" = ""
            "name" = $r
        }
        # before doing anything, make sure we can access this repo's path. if we
        # can't do that, give up entirely on this repo and move on to the next
        # one.
        if(-Not (Test-Path -Path $repo.path))
        {
            if($Verbose)
            {
                ErrorLog "cannot find path $($repo.path)"
            }
            continue
        }

        # otherwise we're good, so we can start executing commands
        Set-Location -Path $repo.path

        $repo.branch = (Git branch --show-current).Trim(" ")

        WriteBar -Head $repo.name -Tail $repo.branch -Colors $Color,$Host.UI.RawUI.ForegroundColor,($Colors[(StringToInt -Str $repo.branch) % $Colors.Count])

        if($Abort -or ($Merge.Length -gt 0))
        {
            WriteBarEvent "git merge --abort"
            Git merge --abort
        }

        if($Stash)
        {
            WriteBarEvent "git stash --include-untracked"
            Git stash --include-untracked
        }

        if($Fetch -or ($Checkout.Length -gt 0)) {
            WriteBarEvent "git fetch"
            Git fetch
        }

        foreach($dest in StringToList $Checkout)
        {
            if($dest.Length -lt 1)
            {
                continue
            }
            if(($dest -eq $repo.branch))
            {
                if($Verbose)
                {
                    WriteBarEvent "already on branch $dest"
                }
                break
            } else {
                WriteBarEvent "git checkout $dest"
                Git checkout $dest
                $repo.branch = Git branch --show-current
                if($repo.branch -eq $dest)
                {
                    WriteBarEvent "$($repo.branch)$($Box[0])"
                    break
                }
            }
        }

        if($DeleteBranches)
        {
            Git --no-pager branch --list | ForEach-Object {
                $formatted = $_.Trim(" *")
                if($formatted -ne $repo.branch)
                {
                    WriteBarEvent "git branch -D $formatted"
                    Git branch -D $formatted
                } elseif($Verbose) {
                    WriteBarEvent "cannot delete checked out branch"
                }
            }

            # todo: add a more granular config file to handle things like this instead of hardcoding them
            Get-ChildItem -Recurse -Filter '*.orig' | Remove-Item

            WriteBarEvent "git stash clear"
            Git stash clear
        }

        if($Pull) {
            WriteBarEvent "git pull"
            Git pull
        }

        if($Merge.Length -gt 0)
        {
            if($NoCommit)
            {
                WriteBarEvent "git merge --no-commit --no-ff $Merge"
                Git merge --no-commit --no-ff $Merge
            } else {
                WriteBarEvent "git merge --no-ff $Merge"
                Git merge --no-ff $Merge
            }
        } elseif($Branch.Length -gt 0) {
            WriteBarEvent "git checkout -b $Branch"
            Git checkout -b $Branch
            if($SetUpstreamOrigin){
                $title = "git push --set-upstream origin $Branch"
                $message = "Are you sure you want to push?"
                $choices = "&yes","&no"
                $default = 1 # 0=Yes, 1=No
                $result = $Host.UI.PromptForChoice($title, $message, $choices, $default)
                if ($result -eq 0) {
                    WriteBarEvent "git push --set-upstream origin $Branch"
                    Git push --set-upstream origin $Branch
                } else {
                    WriteBarEvent "skipped git push; your new branch has no upstream!"
                }
            }
        }

        # allow the user to enter any git command
        foreach($command in StringToList $GitCommand)
        {
            if($command)
            {
                if ($command.ToLower() -ne "push")
                {
                    WriteBarEvent "git $command"
                    Git $command
                } 
                else
                {
                    # TODO : display information about repo and ask user for
                    # manual confirmation of push.
                    # As an additional measure, restrict use of "push" in -g
                    # to coincide with a non-empty -Include parameter?
                    ErrorLog "git push is not allowed"
                    Set-Location $dir.original
                    return
                }
            }
        }

        if($Status)
        {
            WriteBarEvent "git status"
            Git status
        }

        if($Log)
        {
            $gitOutput = Git --no-pager log -1 --format=" %h_[%aN]_%s"
            if($gitOutput)
            {
                $tempList = $gitOutput.Split("_")
                $author = "unknown"
                if($tempList.Count -gt 1)
                {
                    $author = $tempList[1].Trim("[]")
                }
                WriteRainbowArray -Arguments $gitOutput -Colors $Color,($Colors[(StringToInt -Str $author) % $Colors.Count]),$Host.UI.RawUI.ForegroundColor
            }
        }

        if($Diff)
        {
            WriteBarEvent "git diff $Diff --compact-summary --exit-code"
            Git diff $Diff --compact-summary --exit-code
        }

        if($List)
        {
            WriteBarEvent "git --no-pager branch --list"
            Git --no-pager branch --list
        }

        # avoid doing a search for a csproj file if dotnet restore was not invoked
        if($DotnetRestore -or $DotnetBuild)
        {
            if((Get-ChildItem -Force -Depth $Depth -File -Filter "*.csproj").Length -gt 0)
            {
                if($DotnetRestore)
                {
                    if ($DotnetConfig.Length -gt 0)
                    {
                        WriteBarEvent "dotnet restore --interactive --configfile ${DotnetConfig}"
                        dotnet restore --interactive --configfile $DotnetConfig
                    } else {
                        WriteBarEvent "dotnet restore --interactive"
                        dotnet restore --interactive
                    }
                }
                if($DotnetBuild)
                {
                    WriteBarEvent "dotnet build"
                    dotnet build
                }
            } else {
                ErrorLog "dotnet invoked, but no csproj file found"
            }
        }

        if(-not $Quick)
        {
            WriteBar -Tail $repo.branch -Separators $Box[3],$Box[2],$Box[0] -Colors $Color,White,$Colors[(StringToInt -Str $repo.branch) % $Colors.Count]
        }

        GetNextColor
        GetNextIndent
    }
}

# EXECUTION
################################################################################

Set-Location $dir.current

if($Start)
{
    foreach($key in $repos.Keys)
    {
        $item = $repos[$key]
        if($item.Length -lt 1)
        {
            continue
        }
        if($ArgumentList.Length -lt 1)
        {
            $ArgumentList = " "
        }
        if($NoExit -and -not $ArgumentList.Contains("-NoExit"))
        {
            $ArgumentList = "$ArgumentList -NoExit"
        }
        $SetLocation = CascadePath -dir $dir.current -name $key -file $item
        # unused process return that might be useful somehow for some feature
        $proc = Start-Process -FilePath powershell.exe -ArgumentList "$ArgumentList","Set-Location $SetLocation; $item" -Verb RunAs -PassThru
        WriteBar -Head "[$key]" -Tail "$(Split-Path -Leaf $item)" -Separators $Box[0],$Box[0],$Box[0]
        GetNextColor
    }
}

Set-Location $dir.original
