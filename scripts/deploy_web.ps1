$ErrorActionPreference = 'Stop'

flutter build web --release --dart-define-from-file=config/pwa.json
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Push-Location build/web
try {
    if (-not (Test-Path '.vercel')) {
        npx --yes vercel@latest link
    }
    npx --yes vercel@latest deploy --prod --yes
}
finally {
    Pop-Location
}
