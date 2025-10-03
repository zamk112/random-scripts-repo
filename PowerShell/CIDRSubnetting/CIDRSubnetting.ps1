
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

param([string][ValidateSet("Continue", "SilentlyContinue")]$DebugPreference = "SilentlyContinue")

function Convert-IPUIntToIpStr 
{    
    param([Parameter(Mandatory=$true)][ValidateScript({($_ -is [Int32] -or $_ -is [UInt32] -or $_ -is [Int64] -or $_ -is [UInt64])})]$IpPrefixNum)
    
    $stringBuilder = New-Object -TypeName System.Text.StringBuilder

    for ($i = 0; $i -lt 4; $i++) {
        [void]$stringBuilder.Append(($IpPrefixNum -shr (8 * (3 - $i)) -band 0xFF).ToString())

        if ($i -ne 3)
        {
            [void]$stringBuilder.Append(".")
        }
    }

    return $stringBuilder.ToString()

    <#
        .SYNOPSIS
        Converts integer value of IP address to string presentation of IP address.

        .DESCRIPTION
        Converts integer value presentation of IP address to string presentation of IPv4 address broken up into 4 set octets with dot notation.

        .PARAMETER IpPrefixNum
        Integer value presentation of IP address. Parameter value needs to be either int, uint or ulong

        .INPUTS
        None. You can't pipe objects to Convert-IPUIntToIpStr.

        .OUTPUTS
        Returns a string value of IPv4 address format (4 octets with dot notation).

        .EXAMPLE
        PS> Convert-IPUIntToIpStr -IpPrefixNum 3232235776
        192.168.1.1
    #>
}

function Convert-IPStrToIPUInt 
{
    param ([Parameter(Mandatory=$true)][string][ValidatePattern("^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$")]$IPStr)
    [byte[]]$splitIp = $IPStr -split "\."
    [uint]$IpPrefixNum = 0

    for ($i = 0; $i -lt $splitIp.Length; $i++) {
        [uint]$shifted = [uint]([int]::Parse($splitIp[$i])) -shl (8 * (3 - $i))
        Write-Debug "Octet $($i+1): $($splitIp[$i]) << $(8 * (3 - $i)) = $($shifted)"
        $IpPrefixNum += $shifted
    }

    return $IpPrefixNum

    <#
        .SYNOPSIS
        Converts string value of IP address to integer presentation of IP Address.

        .DESCRIPTION
        Converts string value presentation of IP address which presented by 4 octets of 8 bits to integer presentation.

        .PARAMETER IPStr
        String value presentation of IP Address.

        .INPUTS
        None. You can't pipe objects to Convert-IPStrToIPUInt.

        .OUTPUTS
        Returns a Unsinged Integer value of IPv4 addresss.

        .EXAMPLE
        PS> Convert-IPStrToIPUInt -IPStr "192.168.1.0"
        3232235776
    #>
}

function Get-HostBitsShort
{
    param([Parameter(Mandatory=$true)][int]$SubnetSuffixInt)

    [short]$hostBits = 32 - $SubnetSuffixInt 
    Write-Debug "Host Bits Integer Value: $($hostBits)"

    return $hostBits

    <#
        .SYNOPSIS
        Calculates the host bits from the CIDR Subnet Suffix.

        .DESCRIPTION
        Calculates the host bits from the CIDR Subnet Suffix and returns the difference after subtracting from 32.

        .PARAMETER SubnetSuffixInt
        CIDR suffix as a integer value.

        .INPUTS
        None. You can't pipe objects to Get-HostBitsShort.

        .EXAMPLE
        PS> Get-HostBitsShort -SubnetSuffixInt 24
        8

        .EXAMPLE
        PS> Get-HostBitsShort -SubnetSuffixInt 16
        16
    #>
}

function Get-HostMaskUInt
{
    param([Parameter(Mandatory=$true)][short]$HostBits)

    [uint]$hostMaskUInt = ([System.Math]::Pow(2, $HostBits)) - 1

    Write-Debug "Subnet Mask Integer Value: $($hostMaskUInt)"
    Write-Debug "Subnet Mask Binary Value: $([Convert]::ToString($hostMaskUInt, 2).PadLeft(32, '0'))"

    return $hostMaskUInt

    <#
        .SYNOPSIS
        Calculates the Host Mask from Host Bits
        
        .DESCRIPTION
        Calculates the Host Mask from Host Bits and returns a unsigned integer value.

        .PARAMETER hostBits
        Host bits as short type

        .INPUTS
        None. You can't pipe objects to Get-HostMaskUInt.

        .OUTPUTS
        Returns an unsigned integer value.

        .EXAMPLE
        PS> Get-HostMaskUInt -HostBits 8
        255

        .EXAMPLE
        PS> Get-HostMaskUInt -HostBits 16
        65535

    #>
}

function Get-SubnetMaskUInt
{
    param([Parameter(Mandatory=$true)][int][ValidateRange(0, 32)]$SubnetSuffixInt)

    # This is still correct in binary representation even though it's a negative integer value.
    # [short]$hostBits = 32 - $SubnetSuffixInt 
    # Write-Debug "Host Bits Integer Value: $($hostBits)"
    # [int]$subnetMaskInt = (0xFFFFFFFF -shl $hostBits) -band 0xFFFFFFFF

    # But will make it as a Unsigned Integer value it makes a bit more sense.
    [short]$hostBits = Get-HostBitsShort -SubnetSuffixInt $SubnetSuffixInt
    [uint]$hostMaskUInt = Get-HostMaskUInt -HostBits $hostBits
    [uint]$subnetMaskUint = -bnot $hostMaskUInt

    Write-Debug "Subnet Mask Integer Value: $($subnetMaskUint)"
    Write-Debug "Subnet Mask Binary Value: $([Convert]::ToString($subnetMaskUint, 2).PadLeft(32, '0'))"

    return $subnetMaskUint

    <#
        .SYNOPSIS
        Converts CIDR suffix to subnet mask.

        .DESCRIPTION
        Convert CIDR suffix to subnet mask for bitwise manipulation.

        .PARAMETER SubnetSuffixInt
        CIDR suffix as a integer value.

        .INPUTS
        None. You can't pipe objects to Get-SubnetMaskUInt.

        .OUTPUTS
        Outputs returns an Unsigned Integer value.
        
        .EXAMPLE
        PS> Get-SubnetMaskUInt -SubnetSuffixInt 24
        4294967040

        .EXAMPLE
        PS> Get-SubnetMaskUInt -SubnetSuffixInt 16
        4294901760

    #>
}

function Get-NetworkIpAddress 
{
    param([Parameter(Mandatory=$true)][uint]$IpPrefixNum,
          [Parameter(Mandatory=$true)][uint]$subnetMaskUInt
         )

    [uint]$networkIpUInt = $IpPrefixNum -band $subnetMaskUInt
    Write-Debug "Network Integer Value: $($networkIpUInt)"
    Write-Debug "Network Binary Value: $([Convert]::ToString($networkIpUInt, 2).PadLeft(32, '0'))"

    return $networkIpUInt

    <#
        .SYNOPSIS
        Calculates network IP address from IP address prefix and the subnet suffix

        .DESCRIPTION
        Calculates network IP address from address prefix as a unsigned integer value and the subnet suffix as an integer value with the bitwise AND operation.

        .PARAMETER IpPrefixNum
        IP Address prefix as a unsigned integer value

        .PARAMETER subnetMaskUInt
        Subnet Mask suffice as a unsigned integer value.

        .INPUTS
        None. You can't pipe objects to Get-NetworkIpAddress.

        .OUTPUTS
        Returns an unsigned integer value that presents the network Ip Address

        .EXAMPLE
        PS> Get-NetworkIpAddress -IpPrefixNum 167772416 -subnetMaskUInt 4294901760 # For CIDR '10.0.1.0/16'
        167772160

        .EXAMPLE
        PS> Get-NetworkIpAddress -IpPrefixNum 3232235776 -subnetMaskUInt 4294967040 # '192.168.1.0/24'
        3232235776

    #>
}

function Get-BroadcastIpAddress
{
    param([Parameter(Mandatory=$true)][uint]$networkIpUInt,
          [Parameter(Mandatory=$true)][long]$totalAddresses
         )

    [uint]$broadcastUInt = $networkIpUInt -bor ($totalAddresses - 1)
    Write-Debug "Broadcast Integer Value: $($broadcastUInt)"
    Write-Debug "Broadcast Mask Binary Value: $([Convert]::ToString($broadcastUInt, 2).PadLeft(32, '0'))"
    
    return $broadcastUInt

    <#
        .SYNOPSIS
        Calculates the broadcast IP address.

        .DESCRIPTION
        Calculates the broadcast IP address from the network IP unsigned integer value and the total number of ip address calculated from the CIDR suffix
        with Bitwise OR operation.

        .PARAMETER networkIpUInt
        Network IP address as a unsigned integer value

        .PARAMETER totalAddresses
        Total number of IP Addresses

        .INPUTS
        None. You can't pipe objects to Get-BroadcastIpAddress

        .OUTPUTS
        Returns a unsigned integer value

        .EXAMPLE
        PS> Get-BroadcastIpAddress -networkIpUInt 3232235776 -totalAddresses 256 # For '192.168.1.0/24'
        3232236031

        .EXAMPLE
        PS> Get-BroadcastIpAddress -networkIpUInt 169607168 -totalAddresses 512 # For '10.28.0.0/23'
        169607679

    #>
}

function Get-TotalCountOfIPAddress
{
    param([Parameter(Mandatory=$true)][short]$subnetSuffixNum)

    [long]$totalAddresses = [Math]::Pow(2, 32 - $subnetSuffixNum)
    Write-Debug "Total Number of IP address $($totalAddresses)"

    return $totalAddresses

    <#
        .SYNOPSIS
        Calculates total the number of IP addresses for the CIDR range.

        .DESCRIPTION
        Calculates total the number of IP Addresses for the CIDR range. 

        .PARAMETER subnetSuffixNum
        Subnet suffix value from the CIDR range.

        .INPUTS
        None. You can't pipe objects to Get-TotalCountOfIPAddress

        .OUTPUTS
        Returns the total count of ip address as a long type

        .EXAMPLE
        PS> Get-TotalCountOfIPAddress -subnetSuffixNum 18                             
        16384

        .EXAMPLE
        PS>  Get-TotalCountOfIPAddress -subnetSuffixNum 24
        256
    #>    
}

function Get-IPCIDRTranslation 
{
    param([Parameter(Mandatory=$true)][string][ValidatePattern("^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$")]$CIDRAddress)
    
    [uint]$IpPrefixNum = Convert-IPStrToIPUInt -IPStr $($CIDRAddress -split "\/")[0]
    Write-Debug "IP Binary Value: $([Convert]::ToString($IpPrefixNum, 2).PadLeft(32, '0'))"

    $subnetSuffixNum = [short]::Parse($($CIDRAddress -split "\/")[1])
    Write-Debug "Subnet suffix: $($subnetSuffixNum)"
    
    [long]$totalAddresses = Get-TotalCountOfIPAddress -subnetSuffixNum $subnetSuffixNum
    [int]$subnetMaskUInt = Get-SubnetMaskUInt -SubnetSuffixInt $subnetSuffixNum
    [uint]$networkIpUInt = Get-NetworkIpAddress -IpPrefixNum $IpPrefixNum -subnetMaskUInt $subnetMaskUInt
    [uint]$broadcastUInt = Get-BroadcastIpAddress -networkIpUInt $networkIpUInt -totalAddresses $totalAddresses

    [int]$hostMaskInt = -bnot $subnetMaskUInt
    Write-Debug "Host Integer Value: $($hostMaskInt)"
    Write-Debug "Host Binary Value: $([Convert]::ToString($hostMaskInt, 2).PadLeft(32, '0'))"
    
    if (($IpPrefixNum -band $hostMaskInt) -ne 0)
    {
        Write-Warning "Host bit(s) is not valid when comparing to subnet mask, host bit(s) will be zero!"
    }

    return @{
        Network_IP = Convert-IPUIntToIpStr -IpPrefixNum $networkIpUInt
        Broadcast_IP = Convert-IPUIntToIpStr -IpPrefixNum $broadcastUInt
        Subnet_Mask = Convert-IPUIntToIpStr -IpPrefixNum $subnetMaskUInt
        Total_Addresses = $totalAddresses
        First_Host = Convert-IPUIntToIpStr -IpPrefixNum ($networkIpUInt + 1)
        Last_Host = Convert-IPUIntToIpStr -IpPrefixNum ($broadcastUInt - 1)
    }

    <#
        .SYNOPSIS
        Translates the IPv4 CIDR address range and breakdowns of IPv4 ranges and Subnets

        .DESCRIPTION
        Translates the IPv4 CIDR address range and breakdowns the CIDR ranges and finds:
        - Subnet Mask
        - Network IP
        - Broadcast IP
        - Total count of IPv4 Addresses
        - First IPv4 Address
        - Last IPv4 Address

        .PARAMETER CIDRAddress
        Input is IPv4 CIDR Address

        .INPUTS
        None. You can't pipe objects to Get-IPCIDRTranslation.

        .OUTPUTS
        Hashtable. Get-IPCIDRTranslation returns a hashtable with the following key-pair values:
        - Subnet Mask
        - Network IP
        - Broadcast IP
        - Total count of IPv4 Addresses
        - First IPv4 Address
        - Last IPv4 Address

        .EXAMPLE
        PS> Get-IPCIDRTranslation -CIDRAddress "192.168.1.0/24"
        Name                           Value
        ----                           -----
        Subnet_Mask                    255.255.255.0
        Network_IP                     192.168.1.0
        Broadcast_IP                   192.168.1.255
        Total_Addresses                256
        Last_Host                      192.168.1.254
        First_Host                     192.168.1.1

        .EXAMPLE
        PS> Get-IPCIDRTranslation -CIDRAddress "10.0.1.0/16"
        WARNING: Host bit(s) is not valid when comparing to subnet mask, host bit(s) will be zero!

        Name                           Value
        ----                           -----
        Subnet_Mask                    255.255.0.0
        First_Host                     10.0.0.1
        Last_Host                      10.0.255.254
        Broadcast_IP                   10.0.255.255
        Network_IP                     10.0.0.0
        Total_Addresses                65536
    #>
}

function Compare-Subnets 
{
    param ([Parameter(Mandatory=$true)][string][ValidatePattern("^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$")]$CIDRAddressA,
           [Parameter(Mandatory=$true)][string][ValidatePattern("^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$")]$CIDRAddressB
          )
    
    [uint]$ipPrefixNumA = Convert-IPStrToIPUInt -IPStr ($CIDRAddressA -split "\/")[0]
    Write-Debug "A: IP Integer Value: $($IpPrefixNumA)"
    Write-Debug "A: IP Binary Value: $([Convert]::ToString($IpPrefixNumA, 2).PadLeft(32, '0'))"
    
    [short]$subnetSuffixNumA = [short]::Parse($($CIDRAddressA -split "\/")[1])
    [int]$subnetMaskUIntA = Get-SubnetMaskUInt -SubnetSuffixInt $subnetSuffixNumA
    [uint]$networkIpNumA = Get-NetworkIpAddress -IpPrefixNum $ipPrefixNumA -subnetMaskUInt $subnetMaskUIntA
    [long]$totalAddressesA = Get-TotalCountOfIPAddress -subnetSuffixNum $subnetSuffixNumA
    [uint]$broadcastIpNumA = Get-BroadcastIpAddress -networkIpUInt $networkIpNumA -totalAddresses $totalAddressesA


    [uint]$ipPrefixNumB = Convert-IPStrToIPUInt -IPStr ($CIDRAddressB -split "\/")[0]
    Write-Debug "B: IP Integer Value: $($IpPrefixNumB)"
    Write-Debug "B: IP Binary Value: $([Convert]::ToString($IpPrefixNumB, 2).PadLeft(32, '0'))"

    [short]$subnetSuffixNumB = [short]::Parse($($CIDRAddressB -split "\/")[1])
    [int]$subnetMaskUIntB = Get-SubnetMaskUInt -SubnetSuffixInt $subnetSuffixNumB
    [uint]$networkIpNumB = Get-NetworkIpAddress -IpPrefixNum $ipPrefixNumB -subnetMaskUInt $subnetMaskUIntB
    [long]$totalAddressesB = Get-TotalCountOfIPAddress -subnetSuffixNum $subnetSuffixNumB
    [uint]$broadcastIpNumB = Get-BroadcastIpAddress -networkIpUInt $networkIpNumB -totalAddresses $totalAddressesB

    return ($networkIpNumA -le $broadcastIpNumB) -and ($broadcastIpNumA -ge $networkIpNumB)

    <#
        .SYNOPSIS
        Compares two subnets for overlaps or if subnet is within IP Address Space.

        .DESCRIPTION
        Compares two subnets for overlaps or if subnet is within the IP Address Space with IP CIDR values, first by taking the max value of the prefix and then comparing the network IP values.
        If network IP comparison returns false then it will take the minimum prefix value if the prefixes do not match and then compare the new network IP values.

        .PARAMETER CIDRAddressA
        Input is IPv4 CIDR Address

        .PARAMETER CIDRAddressB
        Input is IPv4 CIDR Address        

        .INPUTS
        None. You can't pipe objects to Compare-Subnets.

        .OUTPUTS
        Returns a Boolean value.

        .EXAMPLE
        PS> Compare-Subnets -CIDRAddressA "192.168.1.0/24" -CIDRAddressB "192.168.1.128/25"
        True

        .EXAMPLE
        PS> Compare-Subnets -CIDRAddressA "192.168.1.0/25" -CIDRAddressB "192.168.1.128/25"
        False

        .EXAMPLE
        PS> Compare-Subnets -CIDRAddressA "10.0.0.0/24" -CIDRAddressB "10.0.5.0/24"
        False        
        
    #>    
}