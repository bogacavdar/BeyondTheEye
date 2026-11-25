# Beyond The Eye - Windows surumunu kod imzalama sertifikasiyla imzalar.
# Kullanim (PowerShell):  powershell -ExecutionPolicy Bypass -File imzala.ps1
#
# Gerekenler (bir kez):
#   1. Certum "Standard Code Signing in the Cloud" sertifikasi (SimplySign) alinmis ve etkinlestirilmis olmali.
#   2. SimplySign Desktop kurulu ve acik olmali; telefondaki SimplySign uygulamasindan kodla giris yapilmis olmali
#      (giris yapinca sertifika Windows sertifika deposunda gorunur).
#   3. signtool.exe: Windows SDK ile gelir. Yoksa script nereden kuracagini soyler.
#
# Ne yapar:
#   - GitHub'daki en son Windows surumunu indirir
#   - icindeki .exe dosyalarini imzalar (SHA-256 + Certum zaman damgasi)
#   - imzali surumu Indirilenler klasorune BeyondTheEye-Windows-imzali.zip olarak kaydeder

$ErrorActionPreference = "Stop"
$url = "https://github.com/bogacavdar/BeyondTheEye/releases/download/son-surum/BeyondTheEye-Windows.zip"
$work = Join-Path $env:TEMP "bte_imza"
$out = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads\BeyondTheEye-Windows-imzali.zip"

# signtool'u bul
$signtool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
	Where-Object { $_.FullName -match "x64" } | Sort-Object FullName -Descending | Select-Object -First 1
if (-not $signtool) {
	Write-Host "signtool.exe bulunamadi." -ForegroundColor Red
	Write-Host "Windows SDK'yi kur: https://developer.microsoft.com/windows/downloads/windows-sdk/"
	Write-Host "Kurulumda sadece 'Windows SDK Signing Tools for Desktop Apps' secenegi yeterli."
	exit 1
}

# kod imzalama sertifikasi var mi (SimplySign acik ve giris yapilmis olmali)
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $cert) {
	Write-Host "Kod imzalama sertifikasi bulunamadi." -ForegroundColor Red
	Write-Host "SimplySign Desktop'i ac, telefondaki SimplySign kodunla giris yap ve tekrar dene."
	exit 1
}
Write-Host "Sertifika: $($cert.Subject)" -ForegroundColor Green

# en son surumu indir ve ac
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Path $work | Out-Null
$zip = Join-Path $work "bte.zip"
Write-Host "En son surum indiriliyor..."
Invoke-WebRequest -Uri $url -OutFile $zip
Expand-Archive -Path $zip -DestinationPath (Join-Path $work "oyun")

# imzala
$exes = Get-ChildItem (Join-Path $work "oyun") -Recurse -Filter *.exe
foreach ($e in $exes) {
	Write-Host "Imzalaniyor: $($e.Name)"
	& $signtool.FullName sign /sha1 $cert.Thumbprint /fd sha256 /tr http://time.certum.pl /td sha256 /d "Beyond The Eye" $e.FullName
	if ($LASTEXITCODE -ne 0) { Write-Host "Imzalama basarisiz: $($e.Name)" -ForegroundColor Red; exit 1 }
	& $signtool.FullName verify /pa $e.FullName | Out-Null
}

# imzali zip'i olustur
if (Test-Path $out) { Remove-Item $out -Force }
Compress-Archive -Path (Join-Path $work "oyun\*") -DestinationPath $out
Write-Host ""
Write-Host "Tamam! Imzali surum: $out" -ForegroundColor Green
