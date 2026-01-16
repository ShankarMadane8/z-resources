$ErrorActionPreference = "Stop"

$SoftwareDir = Resolve-Path (Join-Path $PSScriptRoot "..\SOFTWARE_INSTALLED")
if (-not (Test-Path $SoftwareDir)) {
    New-Item -ItemType Directory -Path $SoftwareDir
}

$ELK = @(
    @{
        Name = "elasticsearch"
        Url  = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.11.1-windows-x86_64.zip"
        Zip  = "elasticsearch.zip"
    },
    @{
        Name = "logstash"
        Url  = "https://artifacts.elastic.co/downloads/logstash/logstash-8.11.1-windows-x86_64.zip"
        Zip  = "logstash.zip"
    },
    @{
        Name = "kibana"
        Url  = "https://artifacts.elastic.co/downloads/kibana/kibana-8.11.1-windows-x86_64.zip"
        Zip  = "kibana.zip"
    }
)

foreach ($item in $ELK) {
    $TargetDir = Join-Path $SoftwareDir $item.Name
    if (Test-Path $TargetDir) {
        Write-Host "[SKIP] $($item.Name) already exists in $TargetDir" -ForegroundColor Yellow
        continue
    }

    $ZipPath = Join-Path $SoftwareDir $item.Zip
    $Success = $false
    $RetryCount = 0
    $MaxRetries = 10

    while (-not $Success -and $RetryCount -lt $MaxRetries) {
        try {
            Write-Host "[DOWNLOAD] Downloading $($item.Name) (Attempt $($RetryCount + 1))..." -ForegroundColor Cyan
            # Use curl.exe with -C - to resume if partial file exists
            & curl.exe -L -C - -o "$ZipPath" "$($item.Url)"
            if ($LASTEXITCODE -eq 0) {
                $Success = $true
            }
            else {
                Write-Host "[ERROR] curl failed with exit code $LASTEXITCODE. Retrying..." -ForegroundColor Red
                $RetryCount++
                Start-Sleep -Seconds 5
            }
        }
        catch {
            Write-Host "[ERROR] Download failed: $($_.Exception.Message). Retrying..." -ForegroundColor Red
            $RetryCount++
            Start-Sleep -Seconds 5
        }
    }

    if (-not $Success) {
        Write-Error "Failed to download $($item.Name) after $MaxRetries attempts."
    }

    Write-Host "[EXTRACT] Extracting $($item.Name)... (Using tar for speed)" -ForegroundColor Cyan
    try {
        # Using tar.exe -xf which is much faster than Expand-Archive
        & tar.exe -xf "$ZipPath" -C "$SoftwareDir"
        
        # The zip usually extracts to a folder like elasticsearch-8.11.1
        $ExtractedFolder = Get-ChildItem -Path $SoftwareDir -Directory -Filter "$($item.Name)-*" | Select-Object -First 1
        if ($ExtractedFolder) {
            Write-Host "[OK] Found extracted folder: $($ExtractedFolder.Name)" -ForegroundColor Green
            if (Test-Path $TargetDir) { Remove-Item $TargetDir -Recurse -Force }
            Rename-Item -Path $ExtractedFolder.FullName -NewName $item.Name
            Write-Host "[OK] $($item.Name) installed to $TargetDir" -ForegroundColor Green
        }
        else {
            Write-Host "[WARN] Could not find extracted folder for $($item.Name). Checking if folder already named correctly..." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[ERROR] Extraction failed for $($item.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    }
}

Write-Host "`n[DONE] ELK Stack Installation Complete!" -ForegroundColor Green
