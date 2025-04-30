# Log start
$logPath = "C:\kasper_copy\process_log.txt" # File to write log
Start-Transcript -Path $logPath -Append

# Configuration
$nasPath = "\\10.55.34.5\Shared"
$localPath = "C:\Shared"
$shareName = "Shared"  # Share file name
$exeName = "installer.exe"  # File to be checked

# Destination and source full paths
$sourceFile = Join-Path $nasPath $exeName
$targetFile = Join-Path $localPath $exeName

# Stop sharing
try {
    $share = Get-WmiObject -Class Win32_Share | Where-Object { $_.Name -eq $shareName }
    if ($share) {
        $result = $share.Delete()
        if ($result.ReturnValue -eq 0) {
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Share '$shareName' deleted successfully."
        } else {
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Failed to delete share '$shareName'. Return code: $($result.ReturnValue)"
        }
    } else {
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Share '$shareName' not found."
    }
} catch {
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Error deleting share: $_"
}

Start-Sleep -Seconds 2

# Function: File Size and Date comparison
function Compare-FileSimple($sourcePath, $targetPath) {
    if ((Test-Path $sourcePath) -and (Test-Path $targetPath)) {
        $src = Get-Item $sourcePath
        $tgt = Get-Item $targetPath
        return ($src.Length -ne $tgt.Length) -or ($src.LastWriteTime -ne $tgt.LastWriteTime)
    } else {
        return $true
    }
}

# File control
if (Compare-FileSimple $sourceFile $targetFile) {
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Change detected. Beginning copy process..."

    # Remove read-only
    if (Test-Path $targetFile) {
        try { (Get-Item $targetFile).Attributes = 'Normal' } catch {}
    }

    # Copying process
    try {
        Copy-Item -Path $sourceFile -Destination $targetFile -Force
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Copy completed."
    } catch {
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Copy error: $_"
    }
} else {
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - No modification found. Operation skipped."
}

# Recreate share
try {
    cmd.exe /c "net share $shareName=$localPath /GRANT:Everyone,READ" | Out-Null
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Share '$shareName' successfully created."
} catch {
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Share creation error: $_"
}

Start-Sleep -Seconds 2

Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Task completed successfully."

# Close log file
Stop-Transcript