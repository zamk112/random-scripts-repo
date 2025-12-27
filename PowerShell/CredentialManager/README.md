# Motivation
I think many of who work in IT or at least in security, doesn't like the idea of storing credentials in a plain text file or anything of that nature. How about when working with PowerShell (in particular, Windows PowerShell) when you're using credentials to connect to a Database server for example? Would it be possible to access your stored credentials from Credential Manager? 

# Introduction
In my [MSSqlServerHelpers.ps1](../SQLServerHelper/MSSqlServerHelpers.ps1) script, you need to pass a connection string in order to perform some execute some DDL or DML or execute some query on MS SQL Server. It's good if you have integrated security so you don't have to enter any credentials. But you don't have sufficient permissions to do what you want with your login or you need to use a service account to do what you want. So you use a service account which requires a **username** and **password**, and not a good idea when you store it in plain text files. 

One thing that you can do is you can use `Add-Type` cmdlet to add a C# class and then call the C# functions in your PowerShell script. And I am going to do this by calling or P/Invoking functions from **advapi32.dll** which lets me read credentials from the Windows Credential Manager and then freeing up the pointer to the credentials in memory. And yes you can do a lot more with the **advapi32.dll** but I'm just sticking to reading credentials from the Windows Credential Manager and then freeing up the pointer for the retrieved credentials 😊.

But because I am relying on a Windows API, I needed to understand how to call the **advapi32.dll**. For this I created 2 versions which does the same thing:   
 * [GetCredentialsV1.ps1](./GetCredentialsV1.ps1) - This one that contains an inline string with C# within PowerShell script, 
 * [GetCredentialsV2.ps1](./GetCredentialsV2.ps1) - This is one I'm importing a DLL and then calling the function to get the credentials from my PowerShell script.

For the DLL version, I've created a .NET Framework version of the DLL because most of the time I am using Windows PowerShell.

But how do we call the Windows OS API? Let's dive into that!

# Platform Invoke (P/Invoke) and Unmanaged Libraries
P/Invoke lets you access structs, callbacks and functions in unmanaged libraries from your managed code. You just use/integrate the library with your code and then do the functions calls with structs or callbacks to talk to the OS (sort of, or I should say using the OS services). Most of it is available in `System` and `System.Runtime.InteropServices` where most of the P/Invoke magic happens. 

I'll using `DllImport` and `StructLayout` attributes to access functions and setup the variable for storing credentials in a `struct` type variable in the C# code. So we need 3 things from **advapi32.dll**, these are:  
* `CREDENTIAL` - Credentials struct
* `CredRead` - Credential Read function 
* `CredFree` - Credential Free function

On a side note, it doesn't matter what the library was written in (e.g. C#, C++ or Visual Basic), everything gets compiled down to the Microsoft Intermediate Language (MSIL) or Common Intermediate Language (CIL). It matters when you're looking at the documentation of whatever language it was written in and you need to do some translation from one language to C# in this case (or another language that `Add-Type` supports like Visual Basic), which you will see next.

## Credential Struct
The first thing that I created is the Credential struct object. This is so after retrieve the credentials from the credential manager, we can store it in a variable of `CREDENTIAL` type and then later use the username and password in our PowerShell Script. But the documentation [CREDENTIALW (wincred.h) - Win32 apps | Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentialw) shows the struct as a C++ type (and this is the Unicode version of the struct that I want to, use not ASCII version). So we need to use the `StructLayout` to do the mapping. When you define your attribute it should be like the following:  
```csharp
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
```
`StructLayout` lets you control the physical layout of the data fields of a class or struct in memory and why you need this is because it is a way to control unmanaged variable of the type when it's returning the value to your C# library. 

The first parameter for the `StructLayout` is `LayoutKind` which is of `enum` type, and in this case I am setting it to `LayoutKind.Sequential` and this will store data in memory in a sequential manner. You don't need to specify the `LayoutKind` for structs but for documentation purposes I did anyways; but classes you do need to **explicitly** specify it. And the second parameter is `CharSet` because I am using the Unicode version of `CredRead` and `CredFree`. 

There's a bit of mapping I needed to do to map the types within the struct from C++ to C#, please see table below:

|C++ Type                |Description                                                                                             |C# Type |
|------------------------|--------------------------------------------------------------------------------------------------------|--------|
|`DWORD`                 |A 32-bit unsigned integer                                                                               |`int`   |
|`LPWSTR`                |A pointer to a null-terminated string of 16-bit Unicode characters.                                     |`IntPtr`|
|`wchar_t *`             |A pointer to a null-terminated string of 16-bit Unicode characters.                                     |`IntPtr`|
|`FILETIME`              |Contains a 64-bit value representing the number of 100-nanosecond intervals since January 1, 1601 (UTC).|`long`  |
|`LPBYTE`                |A pointer to a BYTE.                                                                                    |`IntPtr`|
|`PCREDENTIAL_ATTRIBUTEW`|The CREDENTIAL_ATTRIBUTE structure contains an application-defined attribute of the credential.         |`IntPtr`|

According to [Windows Data Types (BaseTsd.h) - Win32 apps | Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/winprog/windows-data-types) & [CREDENTIAL_ATTRIBUTEW (wincred.h) - Win32 apps | Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credential_attributew), I'm dealing with some pointer variables which are `LPWSTR` or `wchar_t *` (depending on what runtime you're using), `LPBYTE`, `PCREDENTIAL_ATTRIBUTEW`. And the matched C# type is `IntPtr`. So what is `IntPtr`? `IntPtr` represents an signed pointer or handle, and whose size is platform-specific (32-bit or 64-bit).

We need to use static methods from the `Marshal` class, which is in the `System.Runtime.InteropServices` namespace in order to retrieve the values from the pointer variables, some of these methods are:  
  * `Marshal.PtrToStringUni()` - Allocates a managed String and copies all or part of an unmanaged Unicode string into it.
  * `Marshal.PtrToStructure()` - Marshals data from an unmanaged block of memory to a managed object.

## CredReadW, CredFree and return type of GetCredential
When importing the **advapi32.dll** with `DllImport`, I passed in three parameters, these are:  
* `ddlName` - name of the dll for import
* `CharSet` - Character set that we're working with, Unicode in this case.
* `SetLastError` - boolean value for indicating whether the callee sets an error before returning from the attributed method.

The first two function parameters are self explanatory. But let's talk more about `SetLastError` and I set this parameter to `true`. 

`CredRead` return type is a `bool` and need an out variable for credential pointer. If `CredRead` is `false`; I just get the error code with `Marshal.GetLastWin32Error()` and then throw an new exception of type `Win32Exception` and passing the error code as a parameter. And I also wrapped the entire code block in a `try-catch-finally` block to handle any other exceptions and also freeing the credential pointer. 

With `CredFree`, I wrapped it inside another function `CredentialPtrFree` and there's a reason for this. `CredFree` return type is `void`. So after calling `CredFree`, I called `Marshal.GetLastWin32Error()` to see if there is any errors; as long as it returns 0 then all good, otherwise it will throw a new exception of type `Win32Exception`.

Apparently `Win32Exception` is more reliable than `GetLastError` when using the .NET Framework version one. So yeah 😊.

But how do I get the password, where is it stored? The password is stored in `CredentialBlob` variable as a `LPBYTE`, so we need to a pointer to retrieve it. Because it is a pointer to an byte and it is not a `LPWSTR` or `wchar_t *` which usually contains a null terminated value. You also need to specify the size of the password as well. And that information is stored in `CredentialBlobSize`. Because our password is in Unicode in particular Unicode 16, you need to divide `CredentialBlobSize` by 2 as each character takes 2 bytes. When we call `Marshal.PtrToStringUni()`, I use the second overloaded method and pass in the number of characters from the unmanaged Unicode string into it.

Lastly, the return type of `GetCredential` (this is the wrapper function for calling `CredRead`) is `NetworkCredential`, which is from the `System.Net` namespace because I was too lazy to define a my own class or a struct and it plays very nicely with PowerShell too.

# Accessing the Credential Manager
This code was written and tested on Windows 11 running on ARM (since I only have Windows running on my MacBook Air now). You need to store your credentials in Credential Manager -> Windows Credentials as a **Generic Credential**. This is because the type that I passed in as a *generic type* or I should say `CRED_TYPE_GENERIC` as per [CREDENTIALW (wincred.h) - Win32 apps | Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentialw) documentation. This is because, most of the time, I'm not using a Windows specific login and accessing server application like MS SQL with a service account or something. 

You just pass in the target name (your *Internet or network address* in credential manager) and if the target name exists, it will return your username and password as a `NetworkCredential` object. 

# Conclusion
At least you don't have to save your passed in plain text files and you can use the Credential Manager to manage your passwords from the UI (or `cmdkey.exe`). What let me know what you think. Thanks for reading!

# References
* [Platform Invoke (P/Invoke) - .NET | Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/standard/native-interop/pinvoke)
* [What is managed code? - .NET | Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/standard/managed-code)
* [StructLayoutAttribute Class (System.Runtime.InteropServices) | Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/system.runtime.interopservices.structlayoutattribute?view=netframework-4.8.1)
* [DllImportAttribute Class (System.Runtime.InteropServices) | Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/system.runtime.interopservices.dllimportattribute?view=netframework-4.8.1)
* [CREDENTIALW (wincred.h) - Win32 apps | Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentialw)
* [CredReadW function (wincred.h) - Win32 apps | Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credreadw)
* [CredFree function (wincred.h) - Win32 apps | Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credfree)
* [Windows Data Types (BaseTsd.h) - Win32 apps | Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/winprog/windows-data-types)
* [Platform::IntPtr value class | Microsoft Learn](https://learn.microsoft.com/en-us/cpp/cppcx/platform-intptr-value-class?view=msvc-170)
* [FILETIME (minwinbase.h) - Win32 apps | Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-filetime)
* [CREDENTIAL_ATTRIBUTEW (wincred.h) - Win32 apps | Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credential_attributew)
* [Marshal.PtrToStringUni Method (System.Runtime.InteropServices) | Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/system.runtime.interopservices.marshal.ptrtostringuni?view=netframework-4.8.1)
* [Marshal.PtrToStructure Method (System.Runtime.InteropServices) | Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/system.runtime.interopservices.marshal.ptrtostructure?view=netframework-4.8.1)
* [Marshal.GetLastWin32Error Method (System.Runtime.InteropServices) | Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/system.runtime.interopservices.marshal.getlastwin32error?view=netframework-4.8.1#system-runtime-interopservices-marshal-getlastwin32error)
* [NetworkCredential Class (System.Net) | Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/system.net.networkcredential?view=netframework-4.8.1)
* [Add-Type (Microsoft.PowerShell.Utility) - PowerShell | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/add-type?view=powershell-5.1)