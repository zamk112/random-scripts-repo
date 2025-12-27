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

$source = @"
using System;
using System.Net;
using System.Runtime.InteropServices;
using System.ComponentModel;

public static class GetCredentials
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct CREDENTIAL
    {
        public int Flags;
        public int Type;
        public IntPtr TargetName;
        public IntPtr Comment;
        public long LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public IntPtr Attributes;
        public IntPtr TargetAlias;
        public IntPtr UserName;
    }

    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredRead(string targetName, uint type, uint flags, out IntPtr credential);

    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern void CredFree(IntPtr credentialPtr);

    private static void CredentialPtrFree(IntPtr credentialPtr)
    {
        try
        {
            CredFree(credentialPtr);
            int errorCode = Marshal.GetLastWin32Error();
            if (errorCode != 0)
            {
                throw new Win32Exception(errorCode);
            }
        }
        catch {
            throw;
        }
    }

    public static NetworkCredential GetCredential(string targetName)
    {
        IntPtr credentialPtr = IntPtr.Zero;
        try
        {
            if (!CredRead(targetName, 1, 0, out credentialPtr))
            {
                int errorCode = Marshal.GetLastWin32Error();
                throw new Win32Exception(errorCode);
            }

            var credential = Marshal.PtrToStructure<CREDENTIAL>(credentialPtr);

            string username = Marshal.PtrToStringUni(credential.UserName);
            string password = credential.CredentialBlob != IntPtr.Zero ? Marshal.PtrToStringUni(credential.CredentialBlob, (int)credential.CredentialBlobSize / 2) : null;

            return new NetworkCredential(username, password);
        }
        catch
        {
            throw;
        }
        finally
        {
            CredentialPtrFree(credentialPtr);
        }
    }
}
"@

try
{
    Add-Type -TypeDefinition $source -Language CSharp
    $credential = [GetCredentials]::GetCredential('test')
    Write-Host "Username: $($credential.UserName)"
    Write-Host "Password: $($credential.Password)"
}
finally
{
    $credential = $null
}

<# 
    .SYNOPSIS
        Retrieves credentials from the Windows Credential Manager using P/Invoke.
    
    .DESCRIPTION
        This script defines a C# class which is stored in a string variable that uses P/Invoke to call Windows API functions for accessing credentials stored in the Windows 
        Credential Manager. It retrieves the username and password for a specified target name. In this example, the target name is hardcoded as 'test'. 
        You need to create a credential with this target name beforehand in the Credential Manager for the script to work.

        Go to Control Panel -> User Accounts -> Credential Manager to add a Windows Credential under Generic Credential with the target name 
        (Internet or network address) 'test' with a username and password.

        Stripped out the comments in the C# code for brevity. See C# solution for full code with comments.
    
    .INPUTS
        None. The target name is hardcoded as 'test' in this example.
    
    .EXAMPLE
        PS> .\GetCredentialsV1.ps1
        Username: DontLookAtMe
        Password: OhNoYouCanSeeMe!
#>