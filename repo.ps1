function GetRepoName {
    param(
        [String]$Cwd = (Get-Item .).FullName,
        [Char]$Separator = [IO.Path]::DirectorySeparatorChar,
        [String]$Name
    )
    return $Name.Replace($Cwd + $Separator, "").Split($Separator)[0]
}