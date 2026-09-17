# =============================================================
#   WINDSPACER  (Windows Disk Spacer)
#   -----------------------------------------------------------
#   Makes a drive LOOK completely full by creating one big
#   "spacer" file. Nothing is really written to the disk, and
#   deleting the file hands all the space back instantly.
# =============================================================

$SpacerName  = "spacer.dat"   # name of the file this tool manages
$MinSafetyGB = 1              # never leave a drive with less than this free

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ---------------- small helpers ----------------

function GBfmt($bytes) { "{0:N1} GB" -f ($bytes / 1GB) }

function Wait-ForEnter {
    Write-Host ""
    Write-Host "  Press Enter to go back to the menu..." -ForegroundColor DarkGray -NoNewline
    [void](Read-Host)
}

function Read-MenuChoice($prompt, $labels) {
    Write-Host ""
    Write-Host "  $prompt" -ForegroundColor White
    for ($i = 0; $i -lt $labels.Count; $i++) {
        Write-Host ("   [{0}] {1}" -f ($i + 1), $labels[$i]) -ForegroundColor Gray
    }
    while ($true) {
        $ans = Read-Host "  Type your choice (1-$($labels.Count))"
        $n = 0
        if ([int]::TryParse($ans, [ref]$n) -and $n -ge 1 -and $n -le $labels.Count) { return $n - 1 }
        Write-Host "  Hmm, that's not on the list, pick a number from 1 to $($labels.Count)." -ForegroundColor Yellow
    }
}

function Read-YesNo($prompt) {
    while ($true) {
        $a = (Read-Host "  $prompt (Y/N)").Trim().ToUpper()
        if ($a -eq "Y" -or $a -eq "YES") { return $true }
        if ($a -eq "N" -or $a -eq "NO")  { return $false }
        Write-Host "  Just Y or N, please! :)" -ForegroundColor Yellow
    }
}

function Read-Number($prompt, $min, $max) {
    while ($true) {
        $ans = Read-Host "  $prompt"
        $n = 0.0
        if ([double]::TryParse($ans, [ref]$n) -and $n -ge $min -and $n -le $max) { return $n }
        Write-Host "  Please type a number between $min and $max." -ForegroundColor Yellow
    }
}

# ---------------- drive helpers ----------------

function Get-Drives {
    [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' -and $_.IsReady }
}

function Find-Spacer($drive) {
    # Where this drive's spacer file could live (drive root, or your
    # user folder as fallback for C:, whose root usually needs admin rights)
    $spots = @((Join-Path $drive.Name $SpacerName))
    if ($drive.Name -eq "C:\") { $spots += (Join-Path $env:USERPROFILE $SpacerName) }
    foreach ($p in $spots) {
        if (Test-Path -LiteralPath $p) { return Get-Item -LiteralPath $p }
    }
    return $null
}

# ---------------- display ----------------

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ==================================================" -ForegroundColor Cyan
    Write-Host "            W I N D S P A C E R" -ForegroundColor Cyan
    Write-Host "       make a drive look full, undo it anytime" -ForegroundColor DarkCyan
    Write-Host "  ==================================================" -ForegroundColor Cyan
}

function Write-DriveLine($d) {
    $pct   = [int][math]::Floor(100 * ($d.TotalSize - $d.AvailableFreeSpace) / $d.TotalSize)
    $width = 20
    $fill  = [int][math]::Round($width * $pct / 100)
    $bar   = ("█" * $fill) + ("░" * ($width - $fill))
    $color = if ($pct -ge 90) { "Red" } elseif ($pct -ge 75) { "Yellow" } else { "Green" }
    $tag   = ""
    $sp    = Find-Spacer $d
    if ($sp) { $tag = "   > spacer file: $(GBfmt $sp.Length)" }
    Write-Host ("   {0}  " -f $d.Name.TrimEnd('\')) -NoNewline
    Write-Host $bar -ForegroundColor $color -NoNewline
    Write-Host ("  {0,3}% full   {1} free{2}" -f $pct, (GBfmt $d.AvailableFreeSpace), $tag)
}

function Show-Drives {
    Write-Host ""
    Write-Host "  Your drives right now:" -ForegroundColor White
    foreach ($d in (Get-Drives)) { Write-DriveLine $d }
}

# ---------------- actions ----------------

function Invoke-Fill {
    Show-Banner

    $drives = @(Get-Drives)
    if ($drives.Count -eq 0) {
        Write-Host "  I couldn't find any drives. :(" -ForegroundColor Red
        Wait-ForEnter; return
    }
    $labels = @($drives | ForEach-Object { "{0}   ({1} free right now)" -f $_.Name.TrimEnd('\'), (GBfmt $_.AvailableFreeSpace) })
    $drive  = $drives[(Read-MenuChoice "Which drive should look full?" $labels)]
    $letter = $drive.Name.TrimEnd('\')

    $mode = Read-MenuChoice "How full should it look?" @(
        "Stuffed: fill the whole drive (keeps a little breathing room)",
        "Custom: add a specific amount of fake data"
    )

    if ($mode -eq 0) {
        $margin = @(5, 2, 10)[(Read-MenuChoice "How much breathing room should it keep?" @(
            "5 GB    safest, recommended",
            "2 GB    just enough for Windows to behave",
            "10 GB   lots of spare room"
        ))]
        $addBytes = [math]::Floor(($drive.AvailableFreeSpace - ($margin * 1GB)) / 1MB) * 1MB
        if ($addBytes -le 0) {
            Write-Host ""
            Write-Host "  $letter already has less than $margin GB free, there's nothing to fill!" -ForegroundColor Yellow
            Wait-ForEnter; return
        }
    }
    else {
        $gb       = Read-Number "How many GB of fake data? (for example: 37)" 1 100000
        $addBytes = [math]::Floor($gb * 1GB / 1MB) * 1MB
        $maxAdd   = $drive.AvailableFreeSpace - ($MinSafetyGB * 1GB)
        if ($addBytes -gt $maxAdd) {
            $addBytes = [math]::Floor($maxAdd / 1MB) * 1MB
            Write-Host ""
            Write-Host "  Heads-up: that much won't fit. I'll fill it as far as safely possible instead." -ForegroundColor Yellow
        }
    }

    $freeBefore = $drive.AvailableFreeSpace
    $freeAfter  = $freeBefore - [int64]$addBytes
    $spacer     = Find-Spacer $drive
    $spNow      = if ($spacer) { GBfmt $spacer.Length } else { "none yet" }
    $spAfter    = if ($spacer) { GBfmt ($spacer.Length + [int64]$addBytes) } else { GBfmt $addBytes }

    Write-Host ""
    Write-Host "  ---------------- Here's the plan ----------------" -ForegroundColor Cyan
    Write-Host ("    Drive ............... {0}" -f $letter)
    Write-Host ("    Fake data to add .... {0}" -f (GBfmt $addBytes))
    Write-Host ("    Free space now ...... {0}" -f (GBfmt $freeBefore))
    Write-Host ("    Free space after .... {0}   (it will look FULL)" -f (GBfmt $freeAfter))
    Write-Host ("    Spacer file ......... {0}  ->  {1}" -f $spNow, $spAfter)
    Write-Host "  -------------------------------------------------" -ForegroundColor Cyan

    if ($drive.Name -eq "C:\") {
        Write-Host ""
        Write-Host "  CAREFUL: C: is your Windows drive. While it looks full," -ForegroundColor Yellow
        Write-Host "  Windows may nag you and some apps may misbehave." -ForegroundColor Yellow
        Write-Host "  You can undo it any time with option 2 in the menu." -ForegroundColor Yellow
    }

    Write-Host ""
    if (-not (Read-YesNo "Go ahead?")) {
        Write-Host "  Cancelled, nothing was changed." -ForegroundColor Yellow
        Wait-ForEnter; return
    }

    # Where the spacer file lives (drive root; your user folder as fallback for C:)
    $path = if ($spacer) { $spacer.FullName } else { Join-Path $drive.Name $SpacerName }

    Write-Host ""
    Write-Host "  Filling $letter ... " -NoNewline
    try {
        try { $fs = [System.IO.File]::OpenWrite($path) }
        catch [System.UnauthorizedAccessException] {
            if ($drive.Name -eq "C:\") {
                $path = Join-Path $env:USERPROFILE $SpacerName
                $fs   = [System.IO.File]::OpenWrite($path)
            } else { throw }
        }
        # SetLength reserves the space instantly, no data is ever written
        $fs.SetLength([int64]($fs.Length + $addBytes))
        $fs.Close()
    }
    catch {
        Write-Host "FAILED" -ForegroundColor Red
        Write-Host "  That didn't work: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Try closing this window, then right-clicking the script and choosing" 
        Write-Host "  'Run as administrator'." 
        Wait-ForEnter; return
    }
    Write-Host "done!" -ForegroundColor Green

    # DriveInfo caches its numbers, so grab a fresh copy to see the new reality
    $drive = New-Object System.IO.DriveInfo($drive.Name)
    Write-Host ""
    Write-Host "  All set! Here's $letter now:" -ForegroundColor Green
    Write-DriveLine $drive
    Write-Host ""
    Write-Host ("  It thinks it only has {0} of space left." -f (GBfmt $drive.AvailableFreeSpace))
    Wait-ForEnter
}

function Invoke-Release {
    Show-Banner

    $with = @(Get-Drives | Where-Object { Find-Spacer $_ })
    if ($with.Count -eq 0) {
        Write-Host ""
        Write-Host "  Nothing to release, all your drives are spacer-free!" -ForegroundColor Green
        Wait-ForEnter; return
    }

    $labels = @($with | ForEach-Object { "{0}   give back {1}" -f $_.Name.TrimEnd('\'), (GBfmt (Find-Spacer $_).Length) })
    $labels += "All of them"
    $pick    = Read-MenuChoice "Which drive should get its space back?" $labels
    $targets = if ($pick -eq $labels.Count - 1) { $with } else { @($with[$pick]) }

    Write-Host ""
    if (-not (Read-YesNo "Delete the spacer file(s) and free the space?")) {
        Write-Host "  Cancelled, nothing was changed." -ForegroundColor Yellow
        Wait-ForEnter; return
    }

    $freed = 0
    foreach ($d in $targets) {
        $sp = Find-Spacer $d
        try {
            $freed += $sp.Length
            Remove-Item -LiteralPath $sp.FullName -Force
            $d = New-Object System.IO.DriveInfo($d.Name)
            Write-Host ("  {0}: spacer deleted, {1} free again" -f $d.Name.TrimEnd('\'), (GBfmt $d.AvailableFreeSpace)) -ForegroundColor Green
        }
        catch {
            Write-Host ("  {0}: couldn't delete, {1}" -f $d.Name.TrimEnd('\'), $_.Exception.Message) -ForegroundColor Red
        }
    }
    if ($freed -gt 0) {
        Write-Host ""
        Write-Host ("  Total space returned: {0}" -f (GBfmt $freed)) -ForegroundColor Green
    }
    Wait-ForEnter
}

function Show-About {
    Show-Banner
    Write-Host ""
    Write-Host "  How does this thing work?" -ForegroundColor White
    Write-Host ""
    Write-Host "   Imagine parking a giant cardboard box in your garage."
    Write-Host "   The box holds nothing, but nobody else can park there."
    Write-Host ""
    Write-Host "   This tool creates one big file (spacer.dat) that takes up"
    Write-Host "   real space on the drive, so Windows thinks the drive is full."
    Write-Host "   No actual data is ever written to your disk, which is why"
    Write-Host "   filling 50 GB takes half a second."
    Write-Host ""
    Write-Host "   Deleting the box (option 2 in the menu) hands the whole"
    Write-Host "   garage back instantly. Nothing else on the drive is touched."
    Write-Host ""
    Wait-ForEnter
}

# ---------------- main menu ----------------

while ($true) {
    Show-Banner
    Show-Drives
    $choice = Read-MenuChoice "What would you like to do?" @(
        "Make a drive look full",
        "Release space (undo)",
        "How does this work?",
        "Exit"
    )
    switch ($choice) {
        0 { Invoke-Fill }
        1 { Invoke-Release }
        2 { Show-About }
        3 { Write-Host ""; Write-Host "  Bye! (your space comes back whenever you need it)"; return }
    }
}
