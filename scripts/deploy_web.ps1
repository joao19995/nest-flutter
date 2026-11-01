$ErrorActionPreference = 'Stop'

# The Nest API (web app) production origin. Requests go through this PWA's
# Vercel project, which proxies /api to the API so there is no CORS involved.
$apiBaseUrl = 'https://nest-flutter-9k93.vercel.app'

# The PWA is its own Vercel project. Never deploy build/web to the API project
# (nest-flutter): that would replace the Next.js app and remove /api.
$projectName = 'nest-pwa'

flutter build web --release --dart-define-from-file=config/pwa.json
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$vercelConfig = @{
    rewrites = @(
        @{ source = '/api/:path*'; destination = "$apiBaseUrl/api/:path*" }
    )
} | ConvertTo-Json -Depth 5
Set-Content -Path 'build/web/vercel.json' -Value $vercelConfig -Encoding ascii

Push-Location build/web
try {
    npx --yes vercel@latest deploy --prod --yes --project $projectName --create-if-missing
}
finally {
    Pop-Location
}
