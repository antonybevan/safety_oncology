param(
    [string]$P21Exe = "p21",
    [string]$DefinePath = "02_datasets/define/define.xml",
    [string]$SdtmPath = "02_datasets/tabulations",
    [string]$AdamPath = "02_datasets/analysis",
    [string]$OutDir = "05_validation/pinnacle21"
)

$ErrorActionPreference = "Stop"

function Assert-Path([string]$PathValue, [string]$Label) {
    if (-not (Test-Path $PathValue)) {
        throw "$Label path not found: $PathValue"
    }
}

function Invoke-P21Run {
    param(
        [string]$Standard,
        [string]$Version,
        [string]$SourcePath,
        [string]$OutputFile
    )

    $xpt = Get-ChildItem -Path $SourcePath -Filter *.xpt -ErrorAction SilentlyContinue
    if (-not $xpt) {
        Write-Warning "No XPT files found in $SourcePath. Skipping $Standard validation."
        return
    }

    $outputPath = Join-Path $OutDir $OutputFile

    $argsPrimary = @(
        "validate",
        "--standard", $Standard,
        "--standard-version", $Version,
        "--define", $DefinePath,
        "--source", $SourcePath,
        "--report", $outputPath,
        "--format", "csv"
    )

    $argsFallback = @(
        "validate",
        "--standard", $Standard,
        "--source", $SourcePath,
        "--define", $DefinePath,
        "--output", $outputPath,
        "--format", "csv"
    )

    & $P21Exe @argsPrimary
    if ($LASTEXITCODE -eq 0) {
        Write-Host "P21 $Standard validation complete: $outputPath"
        return
    }

    Write-Warning "Primary P21 CLI syntax failed for $Standard. Retrying with fallback syntax."
    & $P21Exe @argsFallback
    if ($LASTEXITCODE -ne 0) {
        throw "P21 validation failed for $Standard. Review CLI syntax for your installed version."
    }

    Write-Host "P21 $Standard validation complete: $outputPath"
}

if (-not (Get-Command $P21Exe -ErrorAction SilentlyContinue)) {
    throw "Pinnacle 21 CLI executable '$P21Exe' not found. Install P21 CLI and re-run this script."
}

Assert-Path -PathValue $DefinePath -Label "Define-XML"
Assert-Path -PathValue $SdtmPath -Label "SDTM source"
Assert-Path -PathValue $AdamPath -Label "ADaM source"

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

Invoke-P21Run -Standard "sdtm" -Version "3.4" -SourcePath $SdtmPath -OutputFile "p21_sdtm_report.csv"
Invoke-P21Run -Standard "adam" -Version "1.3" -SourcePath $AdamPath -OutputFile "p21_adam_report.csv"

Write-Host "Pinnacle 21 validation workflow completed."
