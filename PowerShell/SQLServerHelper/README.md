# Motivation
Since I have worked with SQL Server of most my IT career, I have used PowerShell to perform ETLs or some kind of automation where I need to ingest or egress data from SQL Server. Reason why I stuck with PowerShell is because most the time, IT admins have locked down my Windows PC/Laptop. So installing things is not easy, especially when you can't install IDEs (like Visual Studio or even VS Code) or extensions for IDEs and/or SDKs or runtimes (E.g. Python, PowerShell Core, etc...). 

The only thing you have is PowerShell but can be locked too where you're not allowed to install modules (I think at least). The [SqlHelpers.ps1](./SqlHelpers.ps1) script that I have developed allows me to do automation and ETLs when just running DML and queries to retrieve data (large quantities of data!) on SSMS doesn't cut it (provided that I can execute PowerShell script, the rest is all good 👍). 

And also just saying I have not even tried [SQL Server Module](https://learn.microsoft.com/en-us/powershell/module/sqlserver/?view=sqlserver-ps) as yet either but it looks like it's more DBA admins than your Dev.

# Introduction
As I may have eluded in the previous section. This script is meant for PowerShell which runs on .NET Framework not .NET core. As of writing this README file. PowerShell running on the .NET Framework is running version 4.7.8, which still working and ticking along on Windows today. 

However, `System.Data.SqlClient` is deprecated in .NET Core. Microsoft recommends to use `Microsoft.Data.SqlClient` instead. But `System.Data.SqlClient` is intended for .NET Framework version of PowerShell but it does with with PowerShell Core. For PowerShell Core, I recommend to use `Microsoft.Data.SqlClient` instead.

This script I wrote it using the PowerShell ISE (not my favorite VS Code Editor because using PowerCore with in 🥲) on Windows 11 on ARM and running SQL Server on Docker which is running on my MacOS. Make sure you create another database if you want to run this script in it's entirety or test the `Copy-SqlBulk` cmdlet.

In terms of the Database I used, I just used the sample [AdventureWorks Database](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver17&tabs=ssms) to test and write my code.

You just import [SqlHelpers.ps1](./SqlHelpers.ps1) into your script like I have in [Main.ps1](./Main.ps1) which I will go through later and then have your fun with SQL Server or Servers!

# SQLHelpers.ps1 file
This file only contains 3 cmdlets but it lets you do a lot of things! From querying and retrieving data and executing DMLs and DDLs statements. `Get-SqlData` and `Invoke-SqlNonQuery` have common parameters which are:  
* `$ConnectionString` - For connecting the MS SQL Server.
* `$SqlString` - SQL string that you want to execute on SQL Server.
* `$SqlParameters` - SQL parameters which can just one or many but the type has to be of `System.Data.SqlClient.SqlParameter`.

With SQL parameters, of course if it's a web application you want to use parameters to prevent SQL injection attacks (and yes, you can host websites with PowerShell script running on IIS, I have done it! But it is slow 😒). But there's nothing wrong with additional type checking, especially when you want to do some automation or run it as a job with Task Scheduler or something...

But `Copy-SqlBulk` saves you a lot of time with not writing scripts for doing inserts, just copy the data into a object that is of type `System.Data.DataTable`, manipulate the data and it's definition if you need to inside the object and then sent it to your destination server.

## `Get-SqlData`
Starting of with `Get-SqlData`. One strange thing is when you create a new object of type `System.Data.DataTable` and then have a `return` statement to return to the cmdlet caller. The object type changes from `System.Data.DataTable` to `System.Array`. I no longer have Windows running on my gaming PC (too old now) but this is why you need to create an object of type `System.Data.DataTable` and pass it in to the cmdlet otherwise it will just print out the table on the console. 

It might be okay being `System.Array` type but you need a `System.Data.DataTable` object to use with `Copy-SqlBulk` cmdlet. So that's why the cmdlet is written in this way.

## `Invoke-SqlNonQuery`
I don't need to explain too much for this one, you can use it to execute your DMLs such as `INSERT`, `UPDATE`, `DELETE` commands along with stored procedures that do not return any data. So go hard!

## `Copy-SqlBulk`
When I used found out about `System.Data.SqlClient.SqlBulkCopy`, I have not stopped using it ever since. Like I said in the Introduction section. This saves you a lot of time by not writing SQL strings for doing inserts. Especially when your copying data that have the same table schema, which basically no alteration of the definition inside the `System.Data.DataTable` object! All you need to pass in the `System.Data.DataTable` object, the destination connection string and the destination table name to cmdlet. Easy peasy!

# Main.ps1 file
The [Main.ps1](./Main.ps1) is a demonstration file. But it is also how I setup my script for automation and running it on a scheduler (e.g. Task Scheduler). Everything is in a `try-catch-finally` block. Usually when I am debugging I usually comment out the lines containing:  
* `Push-Location $PSScriptRoot`
* `Pop-Location`

`Push-Location $PSScriptRoot` makes sure it `cd` into the directory where it is running. and then `Pop-Location` which is in the `finally` block makes sure that it goes back to the default directory even if the script fails. I also use `Start-Transcript` and `Stop-Transcript` to log everything out to a text log file (for debugging and also audit purposes) but for now I have commented it out.

And I like importing my script like I have done in this script with `. .\MSSqlServerHelpers.ps1`. 

## config.json file
At the moment for this demonstration purposes, I have create a config file in json format and then read it in.  
```pwsh
    $ConnectionStrings = Get-Content -Path ./config.json -Raw | ConvertFrom-Json
```

I don't like doing this, but there is better way of doing this (which I will do later because it involves writing some C# code), by reading credentials from the Windows Credential manager. But this is just a way to storing connection string. It's okay if you're using integrated security for authentication to SQL server but not okay when you're using username and password. 

## Creating Parameters
If you're going to use `System.Data.SqlClient.SqlParameter` and pass it into `Get-SqlData` or `Invoke-SqlNonQuery`, there's 3 ways I have done it which are:  
```pwsh
    $idParameter = New-Object System.Data.SqlClient.SqlParameter
    $idParameter.ParameterName = "@ID"
    $idParameter.SqlDbType = [System.Data.SqlDbType]::Int
    $idParameter.Value = 999
```

Or

```pwsh
    $sizeParameter = New-Object System.Data.SqlClient.SqlParameter("@Size", 52)
```

Or

```pwsh
    $productLineParameter = New-Object System.Data.SqlClient.SqlParameter -ArgumentList "@ProductLine", [System.Data.SqlDbType]::VarChar
    $productLineParameter.Value = "R";
```

I like the first way because you're being explicit about everything. The second and third way is basically how you would initialise it in C#, essentially constructor arguments. 

## Cannot use `GO` statements
You'll notice that in [CREATE TABLE Production.Product Script.sql](./SqlScripts/CREATE%20TABLE%20Production.Product%20Script.sql). I have commented out things before the `CREATE TABLE` statement and the `GO` statement after. And the reason for this is that `GO` is a utility statement which is only recognised by:  
* `sqlcmd` and `osql` utilities,
* `SSMS` tool 

`SqlCommand.ExecuteNonQuery()` does not recognise it. So you cannot use the `GO` statement in your SQL script(s). When you try to load a SQL file with everything uncommented into a variable and then execute it, like I have with:  
```pwsh
    $createProductionProductScript = Get-Content -Path '.\SqlScripts\CREATE TABLE Production.Product Script.sql' -Raw
    Invoke-SqlNonQuery -ConnectionString $ConnectionStrings.DestinationConnectionString -SqlString $createProductionProductScript
```

It will throw errors. You will need to run everything as separate commands in your PowerShell script.

# Conclusion
Even though [SqlHelpers.ps1](./SqlHelpers.ps1) is small, it packs a lot of functionality. I hope you get to use it or change it to suit your needs!


# References
* [System.Data.SqlClient Namespace](https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient?view=windowsdesktop-9.0)
* [SqlConnection Class (System.Data.SqlClient)](https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqlconnection?view=netframework-4.8.1)
* [SqlParameter Class (Microsoft.Data.SqlClient)](https://learn.microsoft.com/en-us/dotnet/api/microsoft.data.sqlclient.sqlparameter?view=sqlclient-dotnet-6.0)
* [SqlDataAdapter.SelectCommand Property (System.Data.SqlClient)](https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqldataadapter.selectcommand?view=netframework-4.8.1)
* [SqlCommand.ExecuteNonQuery Method](https://learn.microsoft.com/en-us/dotnet/api/microsoft.data.sqlclient.sqlcommand.executenonquery?view=sqlclient-dotnet-core-6.1)
* [SQL Server Utilities Statements - GO](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/sql-server-utilities-statements-go?view=sql-server-ver17)