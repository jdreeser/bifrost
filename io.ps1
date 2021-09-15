$defaultFileName = ".bifrost.json"

function GetConfigFilePath {
    param(
        [String]$Cwd = ((Get-Item .).FullName),
        [String]$File = $defaultFileName
    )
    return (Join-Path -Path $Cwd -ChildPath $File).ToString()
}

function Save {
    Param(
        [Hashtable]$Repos,
        [String]$File = $defaultFileName
    )

    if($Repos.Count -gt 1)
    {
        $Repos | ConvertTo-Json | Out-File -FilePath $File
    } else {
        ErrorLog "could not find multiple repositories"
    }
}

function Load {
    param(
        [String]$File = (GetConfigFilePath)
    )
    $local:repositories = [ordered]@{}
    if(Test-Path $File) {
        $object = Get-Content -Path $File | ConvertFrom-Json
        $object | Get-Member -MemberType *Property | ForEach-Object {
            $repo = $_
            Write-Host $repo
            $local:repositories.($repo.name) = $object.($repo.name);
            $object.($repo.name) | Get-Member -MemberType *Property | ForEach-Object {
                $attr = $_
                Write-Host $attr
                $local:repositories.($repo.name).($attr.name) = $object.($repo.name).($attr.name)
                Write-Host $local:repositories.($repo.name)
                Write-Host $local:repositories.($repo.name).($attr.name)
            }
        }
    } else {
        Write-Host "unable to find $File"
    }

    return $local:repositories
}

function CascadePath {
    param(
        [String]$Dir,
        [String]$Name,
        [String]$File
    )
    $dest = ""
    if($File.Length -gt 0)
    {
        try {
            $dest = (Split-Path -Path $File)
            if((Test-Path -Path $dest))
            {
                return $dest
            }
        } catch {
            # Write-Host "failed to Split-Path -Path $dest"
        }
    }
    if($Name.Length -gt 0)
    {
        try {
            $dest = (Join-Path -Path $Dir -ChildPath $Name)
            if((Test-Path -Path $dest))
            {
                return $dest
            }
        } catch {
            # Write-Host "failed to Join-Path -Path $dest"
        }
    }
    return $Dir
}