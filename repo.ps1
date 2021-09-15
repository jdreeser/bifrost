function GetRepoName {
    param(
        [String]$Cwd = (Get-Item .).FullName,
        [Char]$Separator = [IO.Path]::DirectorySeparatorChar,
        [String]$Name
    )
    return $Name.Replace($Cwd + $Separator, "").Split($Separator)[0]
}

function SearchForRepos {
    param(
        [Int32]$Depth = 3,
        [String]$ForFile = "",
        [String]$ForDirectory = ".git",
        [String]$File = (GetConfigFilePath)
    )
    Write-Host "scanning for $ForDirectory and $ForFile"

    $repos = [ordered]@{}

    if($ForDirectory.Length -gt 0)
    {
        $directories = $ForDirectory.Split(" ")
        foreach($d in $directories)
        {
            Get-ChildItem -Force -Depth $Depth -Directory -Filter $d | ForEach-Object {
                $repos.(GetRepoName -Name $_.Parent.Name) = @{
                    "path" = $_.Parent.FullName
                    "branch" = ""
                }
            }
        }
    }

    if($ForFile.Length -gt 0)
    {
        $files = $ForFile.Split(" ")
        foreach($f in $files)
        {
            Get-ChildItem -Force -Depth $Depth -File -Filter $f | ForEach-Object {
                $repos.(GetRepoName -Name $_.DirectoryName) = @{ 
                    "path" = $_.FullName
                    "branch" = ""
                }
            }
        }
    }

    return $repos
}