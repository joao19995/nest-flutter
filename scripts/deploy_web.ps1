$ErrorActionPreference = 'Stop'

# The Nest API (web app) production origin. Requests go through this PWA's
# Vercel project, which proxies /api to the API so there is no CORS involved.
$apiBaseUrl = 'https://nest-flutter-9k93.vercel.app'

flutter build web --release --dart-define-from-file=config/pwa.json
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$vercelConfig = @{
    rewrites = @(
        @{ source = '/api/:path*'; destination = "$apiBaseUrl/api/:path*" }
    )
} | ConvertTo-Json -Depth 5
Set-Content -Path 'build/web/vercel.json' -Value $vercelConfig

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
