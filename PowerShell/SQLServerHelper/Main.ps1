
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

try {
    Push-Location $PSScriptRoot
    #Start-Transcript -Path ".\Logs\$(Get-Date -Format "yyyyMMdd_HHmmss")_Log.txt" -Append

    . .\MSSqlServerHelpers.ps1

    $credential = $null
    $ConnectionStrings = $null

    if (Test-Path -Path "..\CredentialManager\GetCredentialsDLL\GetCredentials\bin\Release\GetCredentials.dll" -PathType Leaf)
    {
        Add-Type -Path "..\CredentialManager\GetCredentialsDLL\GetCredentials\bin\Release\GetCredentials.dll"
        $credential = [GetCredentials]::GetCredential("SQLServerHelperDemo")
        $ConnectionStrings = @{
            SourceConnectionString      = "Server=MacBookAir.lan;Database=AdventureWorks;User Id=$($credential.UserName);Password=$($credential.Password);TrustServerCertificate=True;"
            DestinationConnectionString = "Server=MacBookAir.lan;Database=AdventureWorksDest;User Id=$($credential.UserName);Password=$($credential.Password);TrustServerCertificate=True;"
        }
    }
    elseif (Test-Path -Path "..\CredentialManager\GetCredentialsDLL\GetCredentials\bin\Debug\GetCredentials.dll" -PathType Leaf) {
        Add-Type -Path "..\CredentialManager\GetCredentialsDLL\GetCredentials\bin\Debug\GetCredentials.dll"
        $credential = [GetCredentials]::GetCredential("SQLServerHelperDemo")
        $ConnectionStrings = @{
            SourceConnectionString      = "Server=MacBookAir.lan;Database=AdventureWorks;User Id=$($credential.UserName);Password=$($credential.Password);TrustServerCertificate=True;"
            DestinationConnectionString = "Server=MacBookAir.lan;Database=AdventureWorksDest;User Id=$($credential.UserName);Password=$($credential.Password);TrustServerCertificate=True;"
        }
    }
    else {
        $ConnectionStrings = Get-Content -Path ./config.json -Raw | ConvertFrom-Json
    }

    Write-Host "Create Database, Schema & Table in Destination Database" -ForegroundColor Yellow
    Invoke-SqlNonQuery -ConnectionString $ConnectionStrings.DestinationConnectionString -SqlString "CREATE SCHEMA Production AUTHORIZATION dbo"
    
    $createProductionProductScript = Get-Content -Path '.\SqlScripts\CREATE TABLE Production.Product Script.sql' -Raw
    Invoke-SqlNonQuery -ConnectionString $ConnectionStrings.DestinationConnectionString -SqlString $createProductionProductScript

    Write-Host "Getting Data From Source Data Table" -ForegroundColor Yellow
    $SourceDataTable = New-Object System.Data.DataTable

    $sqlSelectQuery = "SELECT * FROM Production.Product WHERE ProductID = @ID AND Size = @Size AND ProductLine = @ProductLine";
    
    # First way to create a SQL Parameter
    $idParameter = New-Object System.Data.SqlClient.SqlParameter
    $idParameter.ParameterName = "@ID"
    $idParameter.SqlDbType = [System.Data.SqlDbType]::Int
    $idParameter.Value = 999

    # Second way to create a parameter
    $sizeParameter = New-Object System.Data.SqlClient.SqlParameter("@Size", 52)

    # Third way to create a parameter
    $productLineParameter = New-Object System.Data.SqlClient.SqlParameter -ArgumentList "@ProductLine", [System.Data.SqlDbType]::VarChar
    $productLineParameter.Value = "R";

    $parametersArray = @($idParameter, $sizeParameter, $productLineParameter)

    Get-SqlData -ConnectionString $ConnectionStrings.SourceConnectionString -SqlString $sqlSelectQuery -OutDataTable $SourceDataTable -SqlParameters $parametersArray
    $SourceDataTable

    # SQL Copy
    Write-Host "Writing Data from Source Data Table to another Database" -ForegroundColor Yellow
    Copy-SqlBulk -SourceDataTable $SourceDataTable -DestinationConnectionString $ConnectionStrings.DestinationConnectionString -DestinationTableName "Production.Product"
    Get-SqlData -ConnectionString $ConnectionStrings.DestinationConnectionString -SqlString "SELECT * FROM Production.Product"

    # Execute Non Queries
    Write-Host "Updating Measure Code in Destination Database Table" -ForegroundColor Yellow
    $updateIdParameter = New-Object System.Data.SqlClient.SqlParameter("@ID", 1)
    $measureCodeParameter = New-Object System.Data.SqlClient.SqlParameter("@MeasureCode", "M")

    $sqlUpdateQuery = "UPDATE Production.Product SET SizeUnitMeasureCode = @MeasureCode WHERE ProductID = @ID"
    Invoke-SqlNonQuery -ConnectionString $ConnectionStrings.DestinationConnectionString -SqlString $sqlUpdateQuery -SqlParameters @($updateIdParameter, $measureCodeParameter)
    Get-SqlData -ConnectionString $ConnectionStrings.DestinationConnectionString -SqlString "SELECT * FROM Production.Product"
    
    Write-Host "Deleting Row from Destination Database Table" -ForegroundColor Yellow
    $deleteIdParameter = New-Object System.Data.SqlClient.SqlParameter("@ID", 1)
    $sqlDeleteQuery = "DELETE Production.Product WHERE ProductID = @ID";

    Invoke-SqlNonQuery -ConnectionString $ConnectionStrings.DestinationConnectionString -SqlString $sqlDeleteQuery -SqlParameters $deleteIdParameter
    Get-SqlData -ConnectionString $ConnectionStrings.DestinationConnectionString -SqlString "SELECT * FROM Production.Product"

    # Drop Table & Schema Commands
    Write-Host "`nDropping Schema and Table in Destination Database" -ForegroundColor Yellow
    Invoke-SqlNonQuery -ConnectionString $ConnectionStrings.DestinationConnectionString -SqlString "DROP TABLE Production.Product"
    Invoke-SqlNonQuery -ConnectionString $ConnectionStrings.DestinationConnectionString -SqlString "DROP SCHEMA Production"
}
catch
{
    Write-Error $_
}
finally {
    $credential = $null
    $ConnectionStrings = $null    
    #Stop-Transcript
    Pop-Location
}

<#
    .SYNOPSIS
    This is just a demonstration file.

    .DESCRIPTION
    This is just demonstration of file of how to import the SqlHelpers.ps1 script and execute the cmdlets. 
    The database that I am using for this demonstration is the AdventureWorks2019 database. And I created a destination database 
    called AdventureWorksDest to test the Copy-SqlBulk cmdlet.
    See: https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver17&tabs=ssms

    Also incorporating Credential Manager DLL to fetch the credentials securely.
    See: ..\CredentialManager\README.md for more details.
    
    .INPUTS
    None. You can't pipe objects.
#>

