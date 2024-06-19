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

function Install-Cuda {
    param (
        [string]$CudaVersion,
        [string]$CudaVersionChoco
    )

    if (Test-Path -Path "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$CudaVersion" -PathType Container) {
        Write-Host "CUDA $CudaVersion is already installed" -ForegroundColor Green
        Write-Host "Do you want to reinstall? (y/n) [Default: n]: " -ForegroundColor Cyan
        $response = Read-Host
        if ($response -in "Y", "y") {
            Write-Host "Reinstalling CUDA $CudaVersion..." -ForegroundColor Cyan
        } else {
            Write-Host "Skipping CUDA $CudaVersion installation..." -ForegroundColor Cyan
            return
        }
    }
    
    if (-not (Get-Command Import-FunctionIfNotExists -ErrorAction SilentlyContinue)){
        # Allow importing remote functions
        iex (irm Import-RemoteFunction.tc.ht)
        Import-RemoteFunction("Get-GeneralFuncs.tc.ht")
    }

    # Install choco if not already installed
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Clear-ConsoleScreen
        Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    Write-Host "Downloading & Installing CUDA $CudaVersion" -ForegroundColor Cyan
    choco install cuda --version=$CudaVersionChoco -y | Write-Host

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully installed CUDA $CudaVersion" -ForegroundColor Cyan
    } else {
        Write-Host "Failed to install CUDA $CudaVersion" -ForegroundColor Red
        Write-Host "Please install CUDA $CudaVersion manually. Make sure you have your Nvidia Graphics card drivers installed" -ForegroundColor Yellow
        Write-Host "Press enter to continue, or type 1 and enter to install anyway"
        $response = Read-Host
        if ($response -eq "1") {
            Write-Host "Continuing with installation..."
        } else {
            Write-Host "Installation appears as if it failed" -ForegroundColor Red
            Write-Host "Please make sure CUDA $CudaVersion is installed and press Enter to continue." -ForegroundColor Red
            Write-Host "Download CUDA from: https://developer.nvidia.com/cuda-toolkit-archive" -ForegroundColor Cyan
            Read-Host
            return
        }
    }
    Write-Host "Finished installing CUDA $CudaVersion" -ForegroundColor Cyan
}

function Install-Cudnn {
    param (
        [string]$DownloadUrl,
        [string]$CudnnVersion,
        [string]$CudaVersion,
        [bool]$CudnnOptional
    )

    if (Test-Path -Path "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$CudaVersion\bin\cudnn64_8.dll") {
        Write-Host "cuDNN for CUDA $CudaVersion is already installed" -ForegroundColor Green
        
        Write-Host "cuDNN is already installed for CUDA $CudaVersion. Skipping this step." -ForegroundColor Cyan
        Write-Host "Should you need to reinstall, delete: C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$CudaVersion\bin\cudnn64_8.dll"
        return
    }

    if ($CudnnOptional) {
        Write-Host "cuDNN may not be required but may help solve issues later.`nYou will need an Nvidia account.`nDo you want to install cuDNN? (y/n) [Default: n]: "
        $response = Read-Host
        if ($response -in "Y", "y") {
            Write-Host "Installing cuDNN..." -ForegroundColor Cyan
        } else {
            Write-Host "Skipping cuDNN installation..." -ForegroundColor Cyan
            return
        }
    }

    Write-Host "------------`nCUDNN $CudnnVersion`n------------" -ForegroundColor Cyan

    Write-Host "Unfortunately, you need an Nvidia account (Free) to download cuDNN." -ForegroundColor Yellow
    Write-Host "Open the following link in your browser and download it, you will need to sign in:" -ForegroundColor Yellow
    Write-Host $DownloadUrl -ForegroundColor Yellow
    
    Write-Host "`nWhen this is complete, drag and drop it into this window so the file's path appears, and hit Enter." -ForegroundColor Cyan
    Write-Host "Alternatively rename it to 'cudnn.zip' and place it in ($(Get-Location)), then hit Enter to continue." -ForegroundColor Cyan
    
    
    if (-not (Get-Command Import-FunctionIfNotExists -ErrorAction SilentlyContinue)){
        iex (irm Import-RemoteFunction.tc.ht)
    }

    do {
        Write-Host -ForegroundColor Cyan -NoNewline "`nEnter the cuDNN zip's path: "
        $cuDNNzip = Read-Host
        $foundInFolder = $cuDNNzip -eq "" -and (Test-Path "./cudnn.zip")
        if ($foundInFolder) {
            # Get ./cudnn.zip's full path
            $cuDNNzip = (Get-Item "./cudnn.zip").FullName
        }

        $definedElsewhere = (-not $cuDNNzip -eq "") -and (Test-Path $cuDNNzip)
    } while (-not $foundInFolder -and -not $definedElsewhere)
    
    Write-Host "The file does exist at $cuDNNzip. Attempting to use this..."

    Write-Host "Extracting CUDNN $CudnnVersion" -ForegroundColor Cyan
    Expand-Archive -Path $cuDNNzip -DestinationPath "./cudnn"

    Write-Host "Installing CUDNN $CudnnVersion" -ForegroundColor Cyan
    $destinationDir = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$CudaVersion"
    $foldersToCopy = @('bin', 'include', 'lib')
    Get-ChildItem -Path "./cudnn" -Filter "cudnn-windows-*" | ForEach-Object {
        $cuDNNfolder = $_.FullName
    }

    # Merge folders
    Get-ChildItem -Path $cuDNNfolder | ForEach-Object {
        if ($foldersToCopy -contains $_.Name) {
            Write-Host "Copying $($_.Name)\*"
            ForEach-Object { Join-Path $_.FullName '*' } |
                Copy-Item -Destination (Join-Path $destinationDir $_.Name) -Recurse -Force
        }
    }

    # Delete ./cudnn folder
    Remove-Item -Path "./cudnn" -Recurse -Force

    Write-Host "CUDNN Installed." -ForegroundColor Cyan
}

function Install-CudaAndcuDNN {
    param (
        [string]$CudaVersion,
        [bool]$CudnnOptional = $true
    )

    switch ($CudaVersion) {
        "12.5" {
            Install-Cuda -CudaVersion "12.5" -CudaVersionChoco "12.5.0.555"
            Install-Cudnn -DownloadUrl "https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/windows-x86_64/cudnn-windows-x86_64-9.2.0.82_cuda12-archive.zip" -CudnnVersion "9.2.0" -CudaVersion "12.5" -CudnnOptional $CudnnOptional
            Break
        }
        "12.0" {
            Install-Cuda -CudaVersion "12.3" -CudaVersionChoco "12.3.2.546"
            Install-Cudnn -DownloadUrl "https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.6/local_installers/12.x/cudnn-windows-x86_64-8.9.6.50_cuda12-archive.zip" -CudnnVersion "8.9.6" -CudaVersion "12.3" -CudnnOptional $CudnnOptional
            Break
        }
        "11.8" { 
            Install-Cuda -CudaVersion "11.8" -CudaVersionChoco "11.8.0.52206"
            Install-Cudnn -DownloadUrl "https://developer.nvidia.com/downloads/compute/cudnn/secure/8.9.6/local_installers/11.x/cudnn-windows-x86_64-8.9.6.50_cuda11-archive.zip" -CudnnVersion "8.9.6" -CudaVersion "11.8" -CudnnOptional $CudnnOptional
            Break
         }
        Default {
            Write-Host "Please select a CUDA version by passing in CudaVersion"
        }
    }
}