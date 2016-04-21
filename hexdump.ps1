param (
    [Parameter(Mandatory=$true)][string]$IndexFile,
    [int]$Width = 16,
    [int]$Length = -1
)

if (-Not (Test-Path $IndexFile))
{
    Throw "$($IndexFile) not found."
}

$count = 0
ForEach ($byte in Get-Content -Encoding Byte $IndexFile -ReadCount $Width -TotalCount $Length)
{
    $line = "{0:X8}  " -f $count
    $transcript = ""

    $bytecount = 0
    $byte | ForEach-Object {
        $line += ("{0:X2} " -f $_).PadLeft(2, "0")

        if ($bytecount++ -eq ($Width / 2 - 1))
        {
            $line += " "
        }

        if (![char]::IsControl($_))
        {
            $transcript += [char]$_
        }
        else
        {
            $transcript += "."
        }
    }

    $padding = ($Width - $bytecount + 1) * 3 + $transcript.Length
    if ($bytecount -lt ($Width / 2))
    {
        $padding += 1
    }

    $line += ("|{0}|" -f $transcript).PadLeft($padding, " ")

    echo $line

    $count += $Width
}
