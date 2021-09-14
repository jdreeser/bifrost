
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