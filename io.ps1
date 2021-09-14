# Returns the proper filepath that saves results from scan.
function GetConfigFilePath {
    param(
        [String]$Cwd = ((Get-Item .).FullName),
        [String]$Name = ".bifrost.json"
    )
    return (Join-Path -Path $Cwd -ChildPath $Name).ToString()
}