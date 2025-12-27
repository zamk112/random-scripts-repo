# Copyright (c) 2025 Zamsheed Khan

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

Push-Location $PSScriptRoot

try
{
    if (Test-Path ".\GetCredentialsDLL\GetCredentials\bin\Release\GetCredentials.dll" -PathType Leaf)
    {
        Add-Type -Path .\GetCredentialsDLL\GetCredentials\bin\Release\GetCredentials.dll
    }
    elseif (Test-Path ".\GetCredentialsDLL\GetCredentials\bin\Debug\GetCredentials.dll" -PathType Leaf) {
        Add-Type -Path .\GetCredentialsDLL\GetCredentials\bin\Debug\GetCredentials.dll
    }
    else
    {
        throw "DLL not found. Please build the project to generate the DLL before running this script."
    }

    $credential = [GetCredentials]::GetCredential('test')
    Write-Host "Username: $($credential.UserName)"
    Write-Host "Password: $($credential.Password)"
}
finally
{
    $credential = $null
    Pop-Location
}

<# 
    .SYNOPSIS
        Retrieves credentials from the Windows Credential Manager using P/Invoke.
    
    .DESCRIPTION
        This script imports a DLL library which contains a C# class that uses P/Invoke to call Windows API functions for accessing credentials stored in the 
        Windows Credential Manager. It retrieves the username and password for a specified target name. In this example, the target name is hardcoded as 'test'. 
        You need to create a credential with this target name beforehand in the Credential Manager for the script to work.

        Go to Control Panel -> User Accounts -> Credential Manager to add a Windows Credential under Generic Credential with the target name 
        (Internet or network address) 'test' with a username and password.
    
    .INPUTS
        None. The target name is hardcoded as 'test' in this example.
    
    .EXAMPLE
        PS> .\GetCredentialsV1.ps1
        Username: DontLookAtMe
        Password: OhNoYouCanSeeMe!
#>