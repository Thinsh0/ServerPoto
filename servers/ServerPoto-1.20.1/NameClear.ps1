[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- CONFIGURATION ---
$directoryPath = Get-Location

Write-Host "Nettoyage ultra-strict (Mode LiteralPath) dans : $directoryPath" -ForegroundColor Yellow
Write-Host "---"

# On récupère tous les fichiers
$files = Get-ChildItem -Path $directoryPath -Recurse -File | Where-Object { $_.Extension -ne ".ps1" }

foreach ($file in $files) {
    $parentDir = $file.DirectoryName
    $oldFullName = $file.FullName
    $ext = $file.Extension.ToLower()
    $nameOnly = $file.BaseName

    # 1. Suppression des accents
    $normalized = $nameOnly.Normalize([System.Text.NormalizationForm]::FormD)
    $cleanName = ""
    foreach ($char in $normalized.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($char) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            $cleanName += $char
        }
    }

    # 2. On ne garde QUE les lettres et chiffres
    $cleanName = $cleanName -replace '[^a-zA-Z0-9]', '_'

    # 3. Nettoyage des underscores et passage en minuscules
    $cleanName = ($cleanName -replace '_+', '_').Trim('_').ToLower()

    $newName = "$cleanName$ext"
    $newFullName = Join-Path $parentDir $newName

    # 4. Renommage si le nom a changé
    if ($file.Name -ne $newName) {
        # Gestion des conflits (si deux fichiers arrivent au même nom nettoyé)
        if (Test-Path -LiteralPath $newFullName) {
            $count = 1
            while (Test-Path -LiteralPath (Join-Path $parentDir "$cleanName`_$count$ext")) { $count++ }
            $newName = "$cleanName`_$count$ext"
            $newFullName = Join-Path $parentDir $newName
        }
        
        try {
            # --- LA CORRECTION EST ICI : -LiteralPath au lieu de -Path ---
            Rename-Item -LiteralPath $oldFullName -NewName $newName -Force -ErrorAction Stop
            Write-Host "SUCCÈS : $($file.Name) -> $newName" -ForegroundColor Green
        } catch {
            Write-Host "ÉCHEC : Impossible de renommer $($file.Name). Raison : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "---"
Write-Host "Nettoyage terminé ! Vérifie ton dossier." -ForegroundColor Cyan
Pause