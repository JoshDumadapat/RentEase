# PowerShell script to get SHA-1 fingerprint for Google Sign-In
# Run this script from the project root directory

Write-Host "Getting SHA-1 fingerprint for debug keystore..." -ForegroundColor Cyan
Write-Host ""

$debugKeystore = "$env:USERPROFILE\.android\debug.keystore"

if (Test-Path $debugKeystore) {
    Write-Host "Found debug keystore at: $debugKeystore" -ForegroundColor Green
    Write-Host ""
    Write-Host "SHA-1 Fingerprint:" -ForegroundColor Yellow
    Write-Host "==================" -ForegroundColor Yellow
    
    keytool -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android | Select-String -Pattern "SHA1:" | ForEach-Object {
        $sha1 = ($_ -split "SHA1:")[1].Trim()
        Write-Host $sha1 -ForegroundColor Green
        Write-Host ""
        Write-Host "Copy this SHA-1 fingerprint and add it to Firebase Console:" -ForegroundColor Cyan
        Write-Host "1. Go to https://console.firebase.google.com/" -ForegroundColor White
        Write-Host "2. Select your project: renteasedb" -ForegroundColor White
        Write-Host "3. Project Settings > Your apps > Android app" -ForegroundColor White
        Write-Host "4. Click 'Add fingerprint' and paste the SHA-1 above" -ForegroundColor White
        Write-Host "5. Download the updated google-services.json" -ForegroundColor White
        Write-Host "6. Replace android/app/google-services.json with the new file" -ForegroundColor White
    }
} else {
    Write-Host "Debug keystore not found at: $debugKeystore" -ForegroundColor Red
    Write-Host ""
    Write-Host "The debug keystore will be created automatically when you build the app." -ForegroundColor Yellow
    Write-Host "Try building the app first, then run this script again." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

