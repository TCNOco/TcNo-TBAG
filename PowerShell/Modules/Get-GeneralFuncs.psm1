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
# This module has commonly used good little snippets for use in my code projects.
# ----------------------------------------

<#
.SYNOPSIS
Clears the console screen and moves the cursor to the top-left corner.

.DESCRIPTION
The Clear-ConsoleScreen function clears the screen and positions the cursor at the top-left corner of the console window. It utilizes an ANSI escape sequence to achieve this effect.
#>
function Clear-ConsoleScreen {
    [CmdletBinding()]
    param()

    $e = [char]27; Write-Host "$e[2J$e[H" -NoNewline
}

function New-LauncherWithErrorHandling {
    param(
        [Parameter(Mandatory=$true)] [string]$ProgramName,
        [Parameter(Mandatory=$true)] [string]$InstallLocation,
        [Parameter(Mandatory=$true)] [string]$RunCommand,
        [Parameter(Mandatory=$true)] [string]$ReinstallCommand,
        [Parameter()] [string]$CondaPath,
        [Parameter()] [string]$CondaEnvironmentName
    )

    if ($CondaPath) {
        Invoke-WebRequest -Uri "https://scriptlauncher-conda.tc.ht/" -OutFile "Launcher.ps1"
    } else {
        Invoke-WebRequest -Uri "https://scriptlauncher.tc.ht/" -OutFile "Launcher.ps1"
    }

    $filePath = "Launcher.ps1"
    $content = Get-Content $filePath
    $content = $content -replace '%PROGRAMNAME%', $ProgramName -replace '%INSTALLLOCATION%', $InstallLocation -replace '%RUNCOMMAND%', $RunCommand -replace '%REINSTALLCOMMAND%', $ReinstallCommand
    if ($CondaPath) {
        $content = $content -replace '%CONDAPATH%', $CondaPath
    }
    if ($CondaEnvironmentName) {
        $content = $content -replace '%CONDAENVIRONMENTNAME%', $CondaEnvironmentName
    }
    
    $content | Set-Content $filePath
}