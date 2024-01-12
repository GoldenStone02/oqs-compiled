
$Main_Dir = "C:\Users\User\Desktop\oqs-compiled" # Change this to your desired directory
$Install_Dir = "C:\Program Files\oqs-curl"
$SSL_Dir = "C:\Program Files\Common Files\SSL\"

cd $Main_Dir

Write-Host "Downloading liboqs (version 0.9.1)..."

##### Download Phase (liboqs) #####
git clone --branch 0.9.1 https://github.com/open-quantum-safe/liboqs.git
cd liboqs
mkdir build
cd build

##### Build Phase (liboqs) #####
cmake `
  -GNinja `
  -DCMAKE_C_FLAGS="/wd5105" `
  -DCMAKE_INSTALL_PREFIX="$Install_Dir\liboqs" `
  -DCMAKE_BUILD_TYPE=Release `
  -DOQS_ALGS_ENABLED=STD ..
cmake --build . --parallel 8
ninja
ninja install

cd ../../

Write-Host "Downloading openssl (version 3.3.0 dev)..."

##### Download Phase (openssl) #####
git clone -b master https://github.com/openssl/openssl.git
cd openssl

##### Build Phase (openssl) #####
perl Configure no-shared no-fips VC-WIN64A --prefix="$Install_Dir\openssl-curl"
nmake
nmake install_sw install_ssldirs

cd ../

Write-Host "Downloading oqs-provider (version 0.5.3)..."

##### Download Phase (oqs-provider) #####
git clone --depth 1 --branch 0.5.3 https://github.com/open-quantum-safe/oqs-provider.git
cd oqs-provider

##### Build Phase (oqs-provider) #####
cmake `
  -DCMAKE_C_FLAGS="/wd5105" `
  -DOPENSSL_ROOT_DIR="$Install_Dir\openssl-curl" `
  -Dliboqs_DIR="$Install_Dir\liboqs\lib\cmake\liboqs" `
  -DCMAKE_BUILD_TYPE=Release `
  -DCMAKE_PREFIX_PATH="$Install_Dir\oqs-provider" `
  -S . -B build 
cmake --build build --config=Release
ctest --test-dir build -C Release
cmake --install build

cd ../

Write-Host "Adding required configurations for OpenSSL..."

cd $SSL_Dir

$openssl = "openssl.cnf"

$conf = @"
default = default_sect
oqsprovider = oqsprovider_sect

[oqsprovider_sect]
activate = 1
"@

# Editing configuration files doesn't seem to work

# $file = Get-Content -Path $openssl | % {
#   if ($_ -match "# activate = 1")
#   {
#     "activate = 1"
#   }
#   if ($_ -match "default = default_sect")
#   {
#     $conf
#   }
#   else
#   {
#     $_
#   }
# } 

# $file | Out-File -filepath $openssl

cd $Main_Dir

Write-Host "Downloading curl (version 7.81.0)..."

##### Download Phase (curl) #####
# Extracts curl using 7zip 
# (TODO: add support to download 7zip if not installed)
wget https://curl.se/download/curl-7.81.0.zip -O curl-7.81.0.zip
Set-Alias Start-7z "$env:ProgramFiles\7-Zip\7z.exe"
Start-7z x curl-7.81.0.zip curl-7.81.0 y

cd curl-7.81.0\winbuild

##### Build Phase (curl) #####
nmake /f Makefile.vc mode=static WITH_DEVEL="$Install_Dir" WITH_SSL=static MACHINE=x64 SSL_PATH="$Install_Dir\openssl-curl"

Write-Host "`n`n"
Write-Host "Installation Complete!"
Write-Host "Source files can be found in '$Main_Dir'"