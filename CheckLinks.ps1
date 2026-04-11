# Correction de l'encodage pour éviter les caractères bizarres
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- CONFIGURATION ---
$baseUrl = "https://github.com/Thinsh0/ServerPoto/raw/refs/heads/main/"
$localRoot = Get-Location
$serverDir = "servers"
$maxThreads = 15  # On passe à 15 pour aller encore plus vite

Write-Host "Lancement du check parallèle (Throttling: $maxThreads)..." -ForegroundColor Yellow
Write-Host "---"

# Récupérer tous les fichiers
$files = Get-ChildItem -Path (Join-Path $localRoot $serverDir) -Recurse -File
$total = $files.Count
$counter = 0
$runningJobs = @()

foreach ($file in $files) {
    $relativePath = $file.FullName.Replace($localRoot.Path, "").TrimStart('\').Replace('\', '/')
    $url = $baseUrl + $relativePath

    # Bloc de test
    $scriptBlock = {
        param($url, $path)
        try {
            $req = [System.Net.HttpWebRequest]::Create($url)
            $req.Method = "HEAD"
            $req.Timeout = 5000
            $res = $req.GetResponse()
            $res.Close()
            return New-Object PSObject -Property @{ Path = $path; Status = "OK" }
        } catch {
            return New-Object PSObject -Property @{ Path = $path; Status = "FAIL"; Url = $url }
        }
    }

    # Lancement du job
    $runningJobs += Start-Job -ScriptBlock $scriptBlock -ArgumentList $url, $relativePath
    $counter++

    # Limiteur de threads
    while (($runningJobs | Where-Object { $_.JobStateInfo.State -eq 'Running' }).Count -ge $maxThreads) {
        Start-Sleep -Milliseconds 50
    }

    Write-Progress -Activity "Envoi des requêtes HEAD" -Status "$counter / $total" -PercentComplete (($counter / $total) * 100)
}

Write-Host "Attente des derniers résultats..." -ForegroundColor Cyan
$failCount = 0

# Récupération des résultats
foreach ($job in $runningJobs) {
    $data = Wait-Job $job | Receive-Job
    Remove-Job $job # On supprime le job manuellement (compatible PS 5.1)
    
    if ($data.Status -eq "OK") {
        Write-Host "[OK] " -NoNewline -ForegroundColor Green
        Write-Host $data.Path
    } else {
        Write-Host "[ERREUR] " -NoNewline -ForegroundColor Red
        Write-Host "$($data.Path) (404)"
        $failCount++
    }
}

Write-Host "---"
Write-Host "Vérification terminée." -ForegroundColor Yellow
if ($failCount -eq 0) {
    Write-Host "Félicitations : 0 erreur. Tout est en ligne !" -ForegroundColor Green
} else {
    Write-Host "$failCount erreurs détectées." -ForegroundColor Red
    Write-Host "IMPORTANT : Si tout est en erreur, vérifie ton 'baseUrl' dans le script." -ForegroundColor Cyan
}

Pause