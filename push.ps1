# On ajoute tous les changements (fichiers renommés, nouveaux fichiers)
git add -A

# On demande un petit message de commit
$message = Read-Host "Message du commit (ex: Maj mods)"
if (-not $message) { $message = "Mise à jour automatique des fichiers" }

# On valide
git commit -m "$message"

# On envoie sur la branche principale (souvent main ou master)
git push

Write-Host "C'est en ligne ! Tes fichiers sont sur GitHub." -ForegroundColor Green