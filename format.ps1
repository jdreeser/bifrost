
function GetNextColor {
    param(
        [Array]$Colors = @($Host.UI.RawUI.ForegroundColor),
        [String]$Color = $Host.UI.RawUI.ForegroundColor
    )
    $i = [array]::IndexOf($Colors, $Color)
    return $(if ($i -ne -1) { $Colors[($i + 1) % $Colors.Count] } else { $Color })
}

function GetMaxWidth {
    param(
        [Int32]$Width = $Host.UI.RawUI.WindowSize.Width,
        [Float]$Scale = 1.0
    )

    return [Math]::Min($Width, [Math]::Abs([Int32]($Width * $Scale)))
}

function GetNextIndent {
    param(
        [Float]$Scale = 1.0,
        [Int32]$Indent = 0,
        [Int32]$Speed = 0
    )
    if($Speed -lt 0) {
        $Speed = 0
    }
    if($Indent -lt 0) {
        $Indent = 0
    }
    if($Scale -lt 0.1) {
        $Scale = 1.0
    }
    return ($Indent + $Speed) % (GetMaxWidth -Scale $Scale)
}

function StringToList {
    param(
        [String]$Str,
        [Switch]$Trim = $false,
        [Char]$Sep = [IO.Path]::DirectorySeparatorChar
    )
    return $Str.Split(" ") | ForEach-Object {
        if($Trim)
        {
            $_.Trim(".", "\", "/", $Sep)
        } else {
            $_
        }
    }
}

function WriteRainbowArray {
    Param(
        [String]$Arguments = "",
        [Array]$Colors = @(
            $Host.UI.RawUI.ForeGroundColor,
            ($Colors | Get-Random),
            $Host.UI.RawUI.ForeGroundColor
        )
    )
    $Arguments = $Arguments.substring(0, [System.Math]::Min((GetMaxWidth -Scale $Scale) - 1, $Arguments.Length))
    $ArgumentSplit = $Arguments.Split("_")
    foreach($argument in $ArgumentSplit) {
        Write-Host -NoNewLine -ForeGroundColor $Colors[([array]::IndexOf($ArgumentSplit, $argument) % $Colors.Count)] "$argument "
    }
    Write-Host
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

function WriteBar {
    Param(
        [String]$Head = '',
        [String]$Tail = '',
        [Array]$Separators = @(
            $script:Box[1],
            $script:Box[2],
            $script:Box[0]
        ),
        [Array]$Colors = @(
            $Host.UI.RawUI.ForeGroundColor,
            $Host.UI.RawUI.ForeGroundColor,
            $Host.UI.RawUI.ForeGroundColor
        ),
        [String]$Width = (GetMaxWidth - $Indent),
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

function WriteBarEvent {
    if(-not $Quick)
    {
        WriteBar -Head $args -Separators $Box[4],$Box[2],$Box[0] -Short
    }
}

function ErrorLog {
    Write-Host "error: $args ".PadRight(80, '!') -ForegroundColor 'Red'
}