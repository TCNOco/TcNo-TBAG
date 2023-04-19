# Copyright (C) 2023 TroubleChute (Wesley Pyburn)
# Licensed under the GNU General Public License v3.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.gnu.org/licenses/gpl-3.0.en.html
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#    
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ----------------------------------------

Write-Host "Welcome to TroubleChute's kohya_ss installer!" -ForegroundColor Cyan
Write-Host "kohya_ss as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-19]`n`n" -ForegroundColor Cyan

# We'll create C:\TCHT\Ooba if it doesn't already exist:
if (!(Test-Path -Path "C:\TCHT")) {
    New-Item -ItemType Directory -Path "C:\TCHT"
}

# Then CD into C:\TCHT\
Set-Location "C:\TCHT\"

# 1. Install Chocolatey
Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install or update Git if not already installed
Write-Host "`nInstalling Git..." -ForegroundColor Cyan
iex (irm install-git.tc.ht)

# 3. Install vcredist
choco install vcredist-all -y

# 4. Download kohya_ss
git clone https://github.com/bmaltais/kohya_ss.git
cd kohya_ss

# 5. Check if Conda or Python is installed
# Check if Conda is installed
$condaFound = Get-Command conda -ErrorAction SilentlyContinue
if (-not $condaFound) {
    # Try checking if conda is installed a little deeper... (May not always be activated for user)
    # Allow importing remote functions
    iex (irm Get-CondaPath.tc.ht)
    $condaFound = Open-Conda # This checks for Conda, returns true if conda is hoooked
    Update-SessionEnvironment
}

# If conda found: create environment
if ($condaFound) {
    Write-Host "`n`nDo you want to install kohya_ss in a Conda environment called 'kss'?`nYou won't need to activate it, but it helps to get the recommended version of Python?"-ForegroundColor Cyan

    do {
        Write-Host -ForegroundColor Cyan -NoNewline "`n`nUse Conda (y/n): "
        $installWhisper = Read-Host
    } while ($installWhisper -notin "Y", "y", "N", "n")
    
    if ($installWhisper -eq "y" -or $installWhisper -eq "Y") {
        conda create -n kss python=3.10.9 -y
        conda activate kss
    } else {
        $condaFound = $false
        Write-Host "Checking for Python instead..."
    }
}

$python = "python"
if (-not ($condaFound)) {
    # Try Python instead
    # Check if Python returns anything (is installed - also is 3.10.6 - 3.10.11)
    Try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])') {
            Write-Host "Python version $($matches[1]) is installed." -ForegroundColor Green
        }
    }
    Catch {
        Write-Host "Python is not installed." -ForegroundColor Yellow
        Write-Host "`nInstalling Python 3.10.11." -ForegroundColor Cyan
        choco install python --version=3.10.11 -y
        Update-SessionEnvironment
    }

    # Verify Python install
    Try {
        $pythonVersion = &$python --version 2>&1
        if ($pythonVersion -match 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])') {
            Write-Host "Python version $($matches[1]) is installed." -ForegroundColor Green
        }
        else {
            Write-Host "Python version is not between 3.10.6 and 3.10.11." -ForegroundColor Yellow
            Write-Host "Assuming you've installed the correct version, please enter the comand you use to access Python 3.9/3.10." -ForegroundColor Yellow
        
            $pythonProgramName = Read-Host "Enter the Python program name (e.g. python3, python310):"
            $pythonVersion = &$pythonProgramName --version 2>&1
            if ($pythonVersion -match 'Python([3].[1][0-1].[6-9]|3.10.1[0-1])') {
                Write-Host "Python version $($matches[1]) is installed."
                $python = $pythonProgramName
            } else {
                Write-Host "Python version is not between 3.10.6 and 3.10.11."
                Write-Host "Alternatively, follow this guide for manual installation: https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs" -ForegroundColor Red
                Read-Host "Process can try to continue, but will likely fail. Press any key to continue..."
            }
        }
    }
    Catch {
        Write-Host "Python version is not between 3.10.6 - 3.10.11."
        Write-Host "Alternatively, follow this guide for manual installation: https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs..." -ForegroundColor Red
        Read-Host "Process can try to continue, but will likely fail. Press any key to continue..."
    }
}

# 6. Replace choices in setup.bat
(Get-Content setup.bat) | ForEach-Object {
    if ($_ -like 'set /p uninstall_choice="Enter your choice (1 or 2): "*') {
        'set uninstall_choice=1'
    } else {
        $_
    }
} | Set-Content setup-modified.bat

# 8. Optional: CUDNN
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want to download CUDNN (~700MB)? You will need an Nvidia account. (y/n)"
    $cudnn = Read-Host
} while ($cudnn -notin "Y", "y", "N", "n")

if ($cudnn -in "Y","y") {
    Write-Host "Please:`n1. Open: https://developer.nvidia.com/rdp/cudnn-download`n2. Log in.`n3. Expand the latest cuDNN (matching your CUDA version)`n4. Click 'Local Installer for Windows (Zip)'`n5. Rename the zip to 'cudnn.zip'`n6. Move to C:\TCHT\kohya_ss`nYou can do nothing and continue to cancel this operation." -ForegroundColor Cyan
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    $zipFilePath = (Resolve-Path "cudnn.zip").Path
    if (Test-Path $zipFilePath) {
        Write-Host "Extracting..." -ForegroundColor Green
        # Set the path to the ZIP file and the destination folder
        $destinationFolder = (Resolve-Path "cudnn_windows").Path

        # Create the destination folder if it does not exist
        if (-not (Test-Path -Path $destinationFolder -PathType Container)) {
            New-Item -ItemType Directory -Path $destinationFolder | Out-Null
        }

        # Extract every .dll file from the ZIP file and copy it to the destination folder
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($zipFilePath).Entries `
            | Where-Object { $_.Name -like '*.dll' } `
            | ForEach-Object {
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$destinationFolder\$($_.Name)", $true)
            }

        Write-Host "Done!`nYou can now delete cudnn.zip (You may want to use it elsewhere so I won't auto-delete)"

        .\venv\Scripts\activate
        python .\tools\cudann_1.8_install.py
    } else {
        Write-Host "CUDNN download cancelled."
    }
}

# Continue with installation
./setup-modified.bat

# Delete setup-modified.bat
Remove-Item setup-modified.bat

# 7. Create desktop shortcuts?
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts? (y/n): "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n")

iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
if ($shortcuts -in "Y","y") {
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading kohya_ss icon (not official)..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/kohya.ico' -OutFile 'kohya.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "kohya_ss"
    $targetPath = "gui-user.bat"
    $IconLocation = 'kohya.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
    
}