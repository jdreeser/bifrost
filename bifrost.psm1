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

function bf {
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
    [Switch][Alias("d", "Clean")]$DeleteBranches = $false,
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
    [String]$Filter = '',
    [Switch][Alias("p")]$Pull = $false,
    [Switch][Alias("x")]$Stash = $false,
    [Switch][Alias("s")]$Status = $false,

    [String][Alias("b")]$Branch = '',
    [Switch][Alias("u")]$SetUpstreamOrigin = $false,
    [String][Alias("c")]$Checkout = '',
    [String][Alias("m")]$Merge = '',

    [Switch][Alias("v")]$Verbose = $false,

    [String][Alias("g")]$GitCommand = ''
)

. $PSScriptRoot\io.ps1
. $PSScriptRoot\format.ps1
. $PSScriptRoot\repo.ps1

$ErrorActionPreference = "Stop"

# NONSENSE PARAMETER DETECTION
################################################################################

$command = @{
    "invokedGit" = ($DeleteBranches -or $Abort -or $Fetch -or $List -or $Pull -or $Stash -or $Status -or $Quick -or $GitCommand -or $Log)
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

if($Plain)
{
    $Colors = @(
        $Host.UI.RawUI.ForegroundColor
    )
    $Speed = 0
}

$Color = ($Colors | Get-Random)
$Indent = 0

function IncrementColor {
    $script:Color = GetNextColor -Colors $script:Colors -Color $script:Color
}

function IncrementIndent {
    $script:Indent = GetNextIndent -Scale $script:Scale -Indent $script:Indent -Speed $script:Speed
}

$dir = @{
    "original" = (Get-Location).ToString()
    "current" = ""
}

$script:repos = [ordered]@{}

# SETUP AND REPO RECOGNITION
################################################################################

if ($Path.Length -gt 0)
{
    Set-Location -Path $Path
}

$dir.current = (Get-Location).ToString()

if($Scan)
{
    $script:repos = SearchForRepos -Depth $Depth -ForFile $ForFile -ForDirectory $Directory
    Write-Host "$($script:repos.Count) repos found. writing $File"
    Save -Repos $script:repos
}
else {
    $script:repos = (Load)
}

# maybe after all of that we didn't get any repos after all. in that case we
# need to just take over and scan as a last resort.
if($script:repos.Count -lt 1)
{
    # we echo this to the user because they did not request it
    Write-Host "no repo scan data found. scanning now..."
    $script:repos = SearchForRepos -Depth $Depth -ForFile $ForFile -ForDirectory $ForDirectory
}

# we've tried everything we could, but found no repositories. give up and error
# out.
if($script:repos.Count -lt 1)
{
    ErrorLog "no repositories found"
    Exit
} else {
    $script:repos | ForEach-Object { Write-Host $_.Name }
}

# ok we have some repositories, now we just need to extract and filter them
# if we have a value in -Include
if($Include.Length -gt 0)
{
    $included = StringToList -Arg $Include -Trim
    $toDelete = [System.Collections.ArrayList]@()
    foreach($item in $script:repos.Keys)
    {
        if(!$included.Contains($item))
        {
            $toDelete.Add($item) > $null
        }
    }
    foreach($item in $toDelete)
    {
        $script:repos.Remove($item)
    }
}

# exclude listed repositories.
if($Exclude.Length -gt 0)
{
    $excluded = StringToList -Arg $Exclude -Trim
    $toDelete = [System.Collections.ArrayList]@()
    foreach($item in $script:repos.Keys)
    {
        if($excluded.Contains($item))
        {
            $toDelete.Add($item) > $null
        }
    }
    foreach($item in $toDelete)
    {
        $script:repos.Remove($item)
    }
}

if($DotnetClearLocals)
{
    Write-Host "dotnet nuget locals --clear all"
    dotnet nuget locals --clear all
}

$filterBranches = StringToList $Filter

# MAIN LOGIC
################################################################################

if($command.invokedGit -or $command.invokedOp)
{
    foreach($r in $script:repos.Keys)
    {
        Write-Host "PATH IS $($script:repos[$r].path)"
        # before doing anything, make sure we can access this repo's path. if we
        # can't do that, give up entirely on this repo and move on to the next
        # one.
        if(-Not (Test-Path -Path $script:repos[$r].path))
        {
            if($Verbose)
            {
                ErrorLog "cannot find path $($script:repos[$r].path)"
            }
            continue
        }

        # otherwise we're good, so we can start executing commands
        Set-Location -Path $script:repos[$r].path

        $script:repos[$r].branch = (Git branch --show-current)

        if($filterBranches.Length -gt 0)
        {
            if(-not $filterBranches.Contains($script:repos[$r].branch))
            {
                continue
            }
        }

        $brnch = $script:repos[$r].branch
        WriteBar -Head $r -Tail $brnch #-Colors $Color,$Host.UI.RawUI.ForegroundColor,($Colors[(StringToInt -Str $branch) % $Colors.Count])

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
            if(($dest -eq $script:repos[$r].branch))
            {
                if($Verbose)
                {
                    WriteBarEvent "already on branch $dest"
                }
                break
            } else {
                WriteBarEvent "git checkout $dest"
                Git checkout $dest
                $script:repos[$r].branch = Git branch --show-current
                if($script:repos[$r].branch -eq $dest)
                {
                    WriteBarEvent "$($script:repos[$r].branch)$($Box[0])"
                    break
                }
            }
        }

        if($DeleteBranches)
        {
            Git --no-pager branch --list | ForEach-Object {
                $formatted = $_.Trim(" *")
                if($formatted -ne $script:repos[$r].branch)
                {
                    WriteBarEvent "git branch -D $formatted"
                    Git branch -D $formatted
                } elseif($Verbose) {
                    WriteBarEvent "cannot delete checked out branch"
                }
            }

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
                WriteBarEvent "git push --set-upstream origin $Branch"
                Git push --set-upstream origin $Branch
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
            WriteBar -Tail $script:repos[$r].branch -Separators $Box[3],$Box[2],$Box[0] -Colors $Color,White,$Colors[(StringToInt -Str $script:repos[$r].branch) % $Colors.Count]
        }

        IncrementColor
        IncrementIndent
    }
}

# EXECUTION
################################################################################

Set-Location $dir.current

if($Start)
{
    foreach($key in $script:repos.Keys)
    {
        if($script:repos.$key.path.Length -lt 1)
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
        $SetLocation = CascadePath -dir $dir.current -name $key -file $script:repos.$key.path

        if((-not $filterBranches.Contains($script:repos.$key.branch)) -and ($filterBranches.Count -gt 0))
        {
            continue
        }

        # unused process return that might be useful somehow for some feature
        $proc = Start-Process -FilePath powershell.exe -ArgumentList "$ArgumentList","Set-Location $SetLocation; $item" -Verb RunAs -PassThru
        WriteBar -Head "[$key]" -Tail "$(Split-Path -Leaf $item)" -Separators $Box[0],$Box[0],$Box[0]
        IncrementColor
    }
}

Save -Repos $script:repos

Set-Location $dir.original
}