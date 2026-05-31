# retry-helper.ps1 - Generic retry wrapper with exponential backoff
# Usage: powershell -File retry-helper.ps1 -Command "git clone ..." -MaxRetries 3 -InitialDelay 2

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,

    [int]$MaxRetries = 3,

    [int]$InitialDelay = 2,

    [int]$Multiplier = 2,

    [int]$Timeout = 30,

    [ValidateSet("retry","abort","skip")]
    [string]$OnFailure = "retry"
)

$attempt = 0
$lastExitCode = 1

while ($attempt -lt $MaxRetries) {
    $attempt++
    Write-Host "[retry-helper] Attempt $attempt/$MaxRetries : $Command"

    try {
        $job = Start-Job -ScriptBlock {
            param($cmd)
            Invoke-Expression $cmd
        } -ArgumentList $Command

        $completed = Wait-Job $job -Timeout $Timeout

        if ($null -eq $completed) {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            throw "Timeout after ${Timeout}s"
        }

        $output = Receive-Job $job
        $lastExitCode = $job.ChildJobs[0].JobStateInfo.Reason.Data.InvocationInfo.MyCommand
        Remove-Job $job -Force -ErrorAction SilentlyContinue

        if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
            Write-Host "[retry-helper] Success on attempt $attempt"
            if ($output) { Write-Host $output }
            exit 0
        }

        throw "Exit code: $LASTEXITCODE"
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Host "[retry-helper] Failed: $errorMsg" -ForegroundColor Yellow

        if ($OnFailure -eq "abort") {
            Write-Host "[retry-helper] Aborting (OnFailure=abort)" -ForegroundColor Red
            exit 1
        }

        if ($OnFailure -eq "skip") {
            Write-Host "[retry-helper] Skipping (OnFailure=skip)" -ForegroundColor Yellow
            exit 2
        }

        if ($attempt -lt $MaxRetries) {
            $delay = $InitialDelay * [Math]::Pow($Multiplier, $attempt - 1)
            Write-Host "[retry-helper] Waiting ${delay}s before retry..." -ForegroundColor Cyan
            Start-Sleep -Seconds $delay
        }
    }
}

Write-Host "[retry-helper] All $MaxRetries attempts failed" -ForegroundColor Red
exit 1
