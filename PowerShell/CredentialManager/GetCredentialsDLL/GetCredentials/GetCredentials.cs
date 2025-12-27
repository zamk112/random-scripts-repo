using System;
using System.Net;
using System.Runtime.InteropServices;
using System.ComponentModel;

/*
    Copyright (c) 2025 Zamsheed Khan

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

public static class GetCredentials
{
    /// <summary>
    /// CREDENTIAL structure as defined in Windows API, mapped with StructLayout attribute.
    /// </summary>
    /// <remarks>For retrieval of stored credentials from Windows Credential Manager.
    /// The layout of the struct is sequential in memory and working a with Unicode character set.</remarks>
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

    /// <summary>
    /// P/Invoke declaration for CredRead function from advapi32.dll.
    /// Used to read a credential from the Windows Credential Manager.
    /// </summary>
    /// <param name="targetName">The of the credentials that you want to retrieve from the Credential Manager</param>
    /// <param name="type">The of credential that your attempting to access.</param>
    /// <param name="flags">A bit member that identifies the characters of credential.</param>
    /// <param name="credential">Pointer to a single allocated block buffer to return the credential.</param>
    /// <returns>Boolean value to indicate whether the credential retrieval was successful or not, if not 
    ///          successful use the Marshal.GetLastWin32Error() and Win32Exception() to diagnose error</returns>
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredRead(string targetName, uint type, uint flags, out IntPtr credential);

    /// <summary>
    /// P/Invoke declaration for CredFree function from advapi32.dll.
    /// Used to free memory allocated for a credential retrieved from the Windows Credential Manager.
    /// </summary>
    /// <param name="credentialPtr">Pointer to the buffer to be freed.</param>
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern void CredFree(IntPtr credentialPtr);

    /// <summary>
    /// Wrapper function to call P/Invoke CredFree()
    /// </summary>
    /// <remarks>This method should be called to free unmanaged memory associated with credentials obtained
    /// from native Windows credential APIs. Retrieving the password requires retrieving from CredentialBlob which is a pointer
    /// to a byte address in memory, and since the struct and functions are the unicode version of the API, each character is 2 bytes.
    /// Therefore, the CredentialBlobSize must be divided by 2 to get the correct length when converting to a string.
    /// Passing an invalid or already freed pointer may result in an exception. And function will handle the exception by retrieving 
    /// the error code with Marshal.GetLastWin32Error() and throwing the exception with some context with Win32Exception()</remarks>
    /// <param name="credentialPtr">A pointer to the credential structure to be freed. Must be a valid 
    /// pointer previously allocated by a credential management function.</param>
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

    /// <summary>
    /// Retrieves the generic credentials associated with the specified target name from the Windows Credential Manager.
    /// </summary>
    /// <remarks>This method accesses the Windows Credential Manager to retrieve stored credentials. If the credential does not exist or
    /// cannot be read, a Win32Exception is thrown with the corresponding error code. When P/Invoke to CredRead is called, the parameter 
    /// type is set to 1 or CRED_TYPE_GENERIC and flags is set to 0, since it is only retrieving credentials that are Generic Credentials.</remarks>
    /// <param name="targetName">The name of the target resource for which to retrieve credentials. This value identifies the credential entry in
    /// the Windows Credential Manager. Cannot be null or empty.</param>
    /// <returns>A NetworkCredential object containing the user name and password for the specified target.</returns>

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