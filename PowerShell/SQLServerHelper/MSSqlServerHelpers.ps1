
# MIT License

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

function Get-SqlData
{
    param(
         [Parameter(Mandatory=$true)][string]$ConnectionString
        ,[Parameter(Mandatory=$true)][string]$SqlString
        ,[Parameter(Mandatory=$false)][System.Data.DataTable]$OutDataTable
        ,[Parameter(Mandatory=$false)][ValidateScript({if ($_ -is [System.Data.SqlClient.SqlParameter]) { return $true } 
                                                       if ($_ -is [System.Array]){ return ($_ | Where-Object { $_ -isnot [System.Data.SqlClient.SqlParameter] }) }
                                                       return $false
                                                      })]$SqlParameters
    )

    #$OutDataTable = New-Object System.Data.DataTable

    try {
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = $ConnectionString

        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.CommandText = $SqlString
        $SqlCmd.Connection = $SqlConnection

        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd
        
         if ($SqlParameters -is [System.Array] -and $null -ne $SqlParameters -and $SqlParameters.Count -gt 0) 
         {
            $SqlCmd.Parameters.AddRange($([System.Data.SqlClient.SqlParameter[]]$SqlParameters))
         }

         if ($SqlParameters -is [System.Data.SqlClient.SqlParameter] -and $null -ne $SqlParameters)
         {
            [void]$SqlCmd.Parameters.Add($SqlParameters)
         }

        if ($null -eq $OutDataTable)
        {
            $OutDataTable = New-Object System.Data.DataTable
            [void]$SqlAdapter.Fill($OutDataTable)
            $OutDataTable
        }
        else
        {
            [void]$SqlAdapter.Fill($OutDataTable)
        }

        #return $OutDataTable        
    }
    catch {
        Write-Error $_
    }
    finally {
        $SqlAdapter.Dispose()
        $SqlCmd.Dispose()
        $SqlConnection.Close()
        $SqlConnection.Dispose()
        $ConnectionString = $null
    }

    <#
        .SYNOPSIS
        Cmdlet for executing queries to retrieve data from SQL Server

        .DESCRIPTION
        This Cmdlet lets you execute queries that returns data from SQL Server. 
        Usually your normal SELECT statements to query your tables or views. Or execute stored procedures that returns data.
        
        .PARAMETER ConnectionString
        You need to pass in the connection string to the SQL Server that you're connecting to. 
        E.g. Server=[SERVER];Database=[DATABASE];User Id=[USER_NAME];Password=[PASSWORD];TrustServerCertificate=True;

        .PARAMETER SqlString
        SqlString is the string you pass in for executing your SQL query on SQL Server. Make it as complicated as your want :)

        .PARAMETER OutDataTable
        If you want to store the data and use it within your code, you will need to create a System.Data.DataTable object and pass it in. 
        Otherwise if you leave it blank, it will output the results on the console.

        .PARAMETER SqlParameters
        You can pass in one SQL parameter or many in an array. Provided the type is System.Data.SqlClient.SqlParameter.

        .INPUTS
        None. You can't pipe objects to Get-SqlData

        .OUTPUTS
        None. There are no outputs

    #>
}

function Invoke-SqlNonQuery
{
    param(
         [Parameter(Mandatory=$true)][string]$ConnectionString
        ,[Parameter(Mandatory=$true)][string]$SqlString
        ,[Parameter(Mandatory=$false)][ValidateScript({if ($_ -is [System.Data.SqlClient.SqlParameter]) { return $true } 
                                                       if ($_ -is [System.Array]){ return ($_ | Where-Object { $_ -isnot [System.Data.SqlClient.SqlParameter] }) }
                                                       return $false
                                                      })]$SqlParameters
    )

    try {
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = $ConnectionString

        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.CommandText = $SqlString
        $SqlCmd.Connection = $SqlConnection

        if ($SqlParameters -is [System.Array] -and $null -ne $SqlParameters -and $SqlParameters.Count -gt 0) 
        {
            $SqlCmd.Parameters.AddRange($([System.Data.SqlClient.SqlParameter[]]$SqlParameters))
        }

        if ($SqlParameters -is [System.Data.SqlClient.SqlParameter] -and $null -ne $SqlParameters)
        {
            [void]$SqlCmd.Parameters.Add($SqlParameters)
        }

        $SqlCmd.Connection.Open()
        [void]$SqlCmd.ExecuteNonQuery()
        
    }
    catch {
        Write-Error $_
    }
    finally {
        $SqlCmd.Dispose()
        $SqlConnection.Close()
        $SqlConnection.Dispose()
        $ConnectionString = $null
    }
    <#
        .SYNOPSIS
        Cmdlet for executing DMLs & DDLs on SQL Server

        .DESCRIPTION
        This Cmdlet lets you execute DML & DDL statements on SQL Server, such as your UPDATES, INSERT, DELETE statements.
        Or execute stored procedures that does not return any data. 
        
        .PARAMETER ConnectionString
        You need to pass in the connection string to the SQL Server that you're connecting to. 
        E.g. Server=[SERVER];Database=[DATABASE];User Id=[USER_NAME];Password=[PASSWORD];TrustServerCertificate=True;

        .PARAMETER SqlString
        SqlString is the string you pass in for executing your DMLs & DDLs on SQL Server. Make it as complicated as your want :)

        .PARAMETER SqlParameters
        You can pass in one SQL parameter or many in an array. Provided the type is System.Data.SqlClient.SqlParameter.

        .INPUTS
        None. You can't pipe objects to Invoke-SqlNonQuery

        .OUTPUTS
        None. There are no outputs

    #>
}

function Copy-SqlBulk
{
    param(
        [Parameter(Mandatory = $true)][System.Data.DataTable]$SourceDataTable,
        [Parameter(Mandatory = $true)][string]$DestinationConnectionString,
        [Parameter(Mandatory = $true)][string]$DestinationTableName
    )

    try {
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = $DestinationConnectionString

        $SqlConnection.Open()

        $SqlBulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy -ArgumentList $SqlConnection
        $SqlBulkCopy.DestinationTableName = $DestinationTableName

        $SqlBulkCopy.WriteToServer($SourceDataTable)
    }
    catch {
        Write-Error $_
    }
    finally {
        $SqlBulkCopy.Close()
        $SqlBulkCopy.Dispose()
        $SqlConnection.Close()
        $SqlConnection.Dispose()
        $DestinationConnectionString = $null
    }

    <#
        .SYNOPSIS
        Cmdlet for Copying Bulk Copying Data from one database server to another.

        .DESCRIPTION
        This Cmdlet lets you bulk copy data from one database server to another. It is mandatory to have a object that is the type of System.Data.DataTable, otherwise it will not work.
        
        .PARAMETER DestinationConnectionString
        You need to pass in the destination connection string to the SQL Server that you want to copy the data to. 
        E.g. Server=[SERVER];Database=[DATABASE];User Id=[USER_NAME];Password=[PASSWORD];TrustServerCertificate=True;

        .PARAMETER DestinationTableName
        This is parameter for the destination table name that you're copying to on the destination server.

        .INPUTS
        None. You can't pipe objects to Copy-SqlBulk

        .OUTPUTS
        None. There are no outputs

    #>
}

<#
    .SYNOPSIS
    This file contains cmdlets for executing SQL queries, DML and DDL statements on SQL Server.

    .DESCRIPTION
    This file contains cmdlets for executing SQL queries and DML statements on SQL Server. 
    You can import this script with and call the cmdlets in your script execute SQL queries, DMLs and DDLs!.

    NOTE: This intended to be used with PowerShell 5.1 and below (Windows PowerShell) because it uses the
    System.Data.SqlClient namespace. If you're using PowerShell Core, you should 
    use the Microsoft.Data.SqlClient namespace.
    
    For executing any cmdlets you will need to pass in a connection string e.g.:
    Server=[SERVER];Database=[DATABASE];User Id=[USER_NAME];Password=[PASSWORD];TrustServerCertificate=True;
    
    .INPUTS
    None. You can't pipe objects.
#>