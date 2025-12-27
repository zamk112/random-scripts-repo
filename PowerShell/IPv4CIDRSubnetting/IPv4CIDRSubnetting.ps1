
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

function Convert-IPNumToIpStr 
{    
    param([Parameter(Mandatory=$true)][uint]$IpPrefixUInt)
    
    $stringBuilder = New-Object -TypeName System.Text.StringBuilder

    for ($i = 0; $i -lt 4; $i++) {
        [void]$stringBuilder.Append(($IpPrefixUInt -shr (8 * (3 - $i)) -band 0xFF).ToString())

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
        E.g: 3232235776 to 192.168.1.0

        Mathematically:
        1st octet = ⌊3232235776 / 2^24⌋ = 192
        2nd octet = ⌊(3232235776 - (192 * 2^24)) / 2^16⌋ = 168
        3rd octet = ⌊(3232235776 - ((192 * 2^24) + (168 * 2^16))) / 2^8⌋ = 1
        4th octet = ⌊(3232235776 - ((192 * 2^24) + (168 * 2^16) + (1 * 2^8))) / 2^0⌋ = 0

        Bitwise Operation:
        1st Octet = (3232235776 >> 24) & 0xFF = 192
            First operation '(3232235776 >> 24)':
            11000000 10101000 00000001 00000000 >> 24 = 00000000 00000000 00000000 11000000

            Second operation '& 0xFF':
            00000000 00000000 00000000 11000000
            00000000 00000000 00000000 11111111 &
            -----------------------------------
            00000000 00000000 00000000 11000000

            |2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|
            |128|64 |32 |16 |8  |4  |2  |1  |
            | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |

            168 + 64 = 192

        2nd Octet = (3232235776 >> 16) & 0xFF = 168
            First operation '(3232235776 >> 16)':
            11000000 10101000 00000001 00000000 >> 16 = 00000000 00000000 11000000 10101000

            Second operation '& 0xFF':
            00000000 00000000 11000000 10101000
            00000000 00000000 00000000 11111111 &
            -----------------------------------
            00000000 00000000 00000000 10101000

            |2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|
            |128|64 |32 |16 |8  |4  |2  |1  |
            | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 0 |

            168 + 32 + 8 = 168

        3rd Octet = (3232235776 >> 8) & 0xFF = 1
            First operation '(3232235776 >> 8)':
            11000000 10101000 00000001 00000000 >> 8 = 00000000 11000000 10101000 00000001

            Second operation '& 0xFF':
            00000000 11000000 10101000 00000001
            00000000 00000000 00000000 11111111 &
            -----------------------------------
            00000000 00000000 00000000 00000001
            
            |2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|
            |128|64 |32 |16 |8  |4  |2  |1  |
            | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |            

            2^0 = 1 = 1

        4th Octet = (3232235776 >> 0) & 0xFF = 0
            First operation '(3232235776 >> 0)':
            11000000 10101000 00000001 00000000 >> 0 = 11000000 10101000 00000001 00000000

            Second operation '& 0xFF':
            11000000 10101000 00000001 00000000
            00000000 00000000 00000000 11111111 &
            -----------------------------------
            00000000 00000000 00000000 00000000

            |2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|
            |128|64 |32 |16 |8  |4  |2  |1  |
            | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |     

            0 = 0

        Final Value:
            192.168.1.0

        .PARAMETER IpPrefixUInt
        Integer value presentation of IP address. Parameter value needs to be either int, uint or ulong

        .INPUTS
        None. You can't pipe objects to Convert-IPNumToIpStr.

        .OUTPUTS
        Returns a string value of IPv4 address format (4 octets with dot notation).

        .EXAMPLE
        PS> Convert-IPNumToIpStr -IpPrefixUInt 3232235776
        192.168.1.0
    #>
}

function Convert-IPStrToIPUInt 
{
    param ([Parameter(Mandatory=$true)][string][ValidatePattern("^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$")]$IPStr)
    [byte[]]$splitIp = $IPStr -split "\."
    [uint]$IpPrefixUInt = 0

    for ($i = 0; $i -lt $splitIp.Length; $i++) {
        [uint]$shifted = ([uint]::Parse($splitIp[$i])) -shl (8 * (3 - $i))
        Write-Debug "Octet $($i+1): $($splitIp[$i]) << $(8 * (3 - $i)) = $($shifted)"
        $IpPrefixUInt += $shifted
    }

    Write-Debug "IP Unsigned Integer Value: $($IpPrefixUInt)"
    Write-Debug "IP Binary Value: $([Convert]::ToString($IpPrefixUInt, 2).PadLeft(32, '0'))"

    return $IpPrefixUInt

    <#
        .SYNOPSIS
        Converts string value of IP address to integer presentation of IP Address.

        .DESCRIPTION
        Converts string value presentation of IP address which presented by 4 octets of 8 bits to integer presentation.
        E.g. 192.168.1.0 = 3232235776

        |          |   |1st       |   |2nd       |   |3rd    |   |4th    |
        |3232235776| = |192 * 2^24| + |168 * 2^16| + |1 * 2^8| + |0 * 2^0|
        |3232235776| = |192 << 24 | + |168 << 16 | + |1 << 8 | + |0 << 0 |
        |----------| = |----------| + |----------| + |-------| + |-------|
        |3232235776| = |3221225472| + |  11010048| + |    256| + |      0|

        Bitwise operation:
        1st Octet: 192 << 24
            First operation:
                192 << 24 = 11000000 00000000 00000000 00000000
        
        2nd Octet: 168 << 16
            First operation:
                168 << 16 = 00000000 10101000 00000000 00000000

            Second operation:
            11000000 00000000 00000000 00000000
            00000000 10101000 00000000 00000000 +
            -----------------------------------
            11000000 10101000 00000000 00000000

        3rd Octet: 1 << 8
            First operation:
            00000000 00000000 00000001 00000000

            Second operation:
            00000000 00000000 00000001 00000000
            11000000 10101000 00000000 00000000 +
            -----------------------------------
            11000000 10101000 00000001 00000000

        4th Octet: 0 << 0
            First operation:
            00000000 00000000 00000000 00000000
            
            Second operation:
            00000000 00000000 00000000 00000000
            11000000 10101000 00000001 00000000 +
            -----------------------------------
            11000000 10101000 00000001 00000000

        Final Binary Form:
            11000000 10101000 00000001 00000000
        
        Calculation:
            |First Octet                                                                   |Second Octet                                              |Third Octet                            |Fourth Octet                   |
            |2^31      |2^30      |2^29     |2^28     |2^27     |2^26    |2^25    |2^24    |2^23   |2^22   |2^21   |2^20   |2^19  |2^18  |2^17  |2^16 |2^15 |2^14 |2^13|2^12|2^11|2^10|2^9|2^8|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|
            |2147483648|1073741824|536870912|268435456|134217728|67108864|33554432|16777216|8388608|4194304|2097152|1048576|524288|262144|131072|65536|32768|16384|8192|4096|2048|1024|512|256|128|64 |32 |16 |8  |4  |2  |1  |
            |     1    |     1    |    0    |    0    |    0    |    0   |    0   |    0   |   1   |   0   |   1   |   0   |   1  |   0  |   0  |  0  |  0  |  0  |  0 |  0 |  0 |  0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

            3232235776 = 2147483648 + 1073741824 + 8388608 + 2097152 + 524288 + 256


        .PARAMETER IPStr
        String value presentation of IP Address.

        .INPUTS
        None. You can't pipe objects to Convert-IPStrToIPUInt.

        .OUTPUTS
        Returns a Unsigned Integer value of IPv4 addresses.

        .EXAMPLE
        PS> Convert-IPStrToIPUInt -IPStr "192.168.1.0"
        3232235776
    #>
}

function Get-HostBitsByte
{
    param([Parameter(Mandatory=$true)][byte][ValidateRange(0, 32)]$SubnetSuffixNum)

    [byte]$hostBitsByte = 32 - $SubnetSuffixNum
    Write-Debug "Host Bits Integer Value: $($hostBitsByte)"

    return $hostBitsByte

    <#
        .SYNOPSIS
        Calculates the host bits from the CIDR Subnet Suffix.

        .DESCRIPTION
        Calculates the host bits from the CIDR Subnet Suffix and returns the difference after subtracting from 32.
        E.g:
        Host Bits = 32 - 16 = 16

        .PARAMETER SubnetSuffixNum
        CIDR suffix as a integer value.

        .INPUTS
        None. You can't pipe objects to Get-HostBitsByte.

        .EXAMPLE
        PS> Get-HostBitsByte -SubnetSuffixNum 24
        8

        .EXAMPLE
        PS> Get-HostBitsByte -SubnetSuffixNum 16
        16
    #>
}

function Get-HostMaskUInt
{
    param([Parameter(Mandatory=$true)][byte][ValidateRange(0, 32)]$HostBitsByte)

    [uint]$hostMaskUInt = ([System.Math]::Pow(2, $HostBitsByte)) - 1
    Write-Debug "Subnet Mask Integer Value: $($hostMaskUInt)"
    Write-Debug "Subnet Mask Binary Value: $([Convert]::ToString($hostMaskUInt, 2).PadLeft(32, '0'))"

    return $hostMaskUInt

    <#
        .SYNOPSIS
        Calculates the Host Mask from Host Bits
        
        .DESCRIPTION
        Calculates the Host Mask from Host Bits and returns a unsigned integer value.

        Host Bit Mask Integer value = 2^16-1 = 65535

        Host Bit Mask Binary Form:
            |First Octet                                                                   |Second Octet                                              |Third Octet                            |Fourth Octet                   |
            |2^31      |2^30      |2^29     |2^28     |2^27     |2^26    |2^25    |2^24    |2^23   |2^22   |2^21   |2^20   |2^19  |2^18  |2^17  |2^16 |2^15 |2^14 |2^13|2^12|2^11|2^10|2^9|2^8|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|
            |2147483648|1073741824|536870912|268435456|134217728|67108864|33554432|16777216|8388608|4194304|2097152|1048576|524288|262144|131072|65536|32768|16384|8192|4096|2048|1024|512|256|128|64 |32 |16 |8  |4  |2  |1  |
            |     0    |     0    |    0    |    0    |    0    |    0   |    0   |    0   |   0   |   0   |   0   |   0   |   0  |   0  |   0  |  0  |  1  |  1  |  1 |  1 |  1 |  1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

            Final Binary Form:
            00000000 00000000 11111111 11111111

            Binary to Numeric Conversion Check:
            32768 + 16384 + 8192 + 4096 + 2048 + 1024 + 512 + 256 + 128 + 64 + 32 + 16 + 8 + 4 + 2 + 1 = 65535

        .PARAMETER HostBitsByte
        Host bits as byte type

        .INPUTS
        None. You can't pipe objects to Get-HostMaskUInt.

        .OUTPUTS
        Returns an unsigned integer value.

        .EXAMPLE
        PS> Get-HostMaskUInt -HostBitsByte 8
        255

        .EXAMPLE
        PS> Get-HostMaskUInt -HostBitsByte 16
        65535

    #>
}

function Get-SubnetMaskUInt
{
    param([Parameter(Mandatory=$true)][byte][ValidateRange(0, 32)]$SubnetSuffixNum)

    # This is still correct in binary representation even though it's a negative integer value.
    # [short]$hostBits = 32 - $SubnetSuffixInt 
    # Write-Debug "Host Bits Integer Value: $($hostBits)"
    # [int]$subnetMaskInt = (0xFFFFFFFF -shl $hostBits) -band 0xFFFFFFFF

    # But will make it as a Unsigned Integer value it makes a bit more sense.
    [byte]$hostBitsByte = Get-HostBitsByte -SubnetSuffixNum $SubnetSuffixNum
    [uint]$hostMaskUInt = Get-HostMaskUInt -HostBitsByte $hostBitsByte
    [uint]$subnetMaskUint = -bnot $hostMaskUInt
    Write-Debug "Subnet Mask Integer Value: $($subnetMaskUint)"
    Write-Debug "Subnet Mask Binary Value: $([Convert]::ToString($subnetMaskUint, 2).PadLeft(32, '0'))"

    return $subnetMaskUint

    <#
        .SYNOPSIS
        Converts CIDR suffix to subnet mask.

        .DESCRIPTION
        Convert CIDR suffix to subnet mask for bitwise manipulation. See below:
        E.g. CIDR Suffix /16

        Host bit mask = 00000000 00000000 11111111 11111111

        Subnet NOT Host Bit Mask:
            00000000 00000000 11111111 11111111 !
            -----------------------------------
            11111111 11111111 00000000 00000000 

            Binary to Number Conversion:
            |First Octet                                                                   |Second Octet                                              |Third Octet                            |Fourth Octet                   |
            |2^31      |2^30      |2^29     |2^28     |2^27     |2^26    |2^25    |2^24    |2^23   |2^22   |2^21   |2^20   |2^19  |2^18  |2^17  |2^16 |2^15 |2^14 |2^13|2^12|2^11|2^10|2^9|2^8|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|
            |2147483648|1073741824|536870912|268435456|134217728|67108864|33554432|16777216|8388608|4194304|2097152|1048576|524288|262144|131072|65536|32768|16384|8192|4096|2048|1024|512|256|128|64 |32 |16 |8  |4  |2  |1  |
            |     1    |     1    |    1    |    1    |    1    |    1   |    1   |    1   |   1   |   1   |   1   |   1   |   1  |   1  |   1  |  1  |  0  |  0  |  0 |  0 |  0 |  0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

            2147483648 + 1073741824 + 536870912 + 268435456 + 134217728 + 67108864 + 33554432 + 16777216 + 8388608 + 4194304 + 2097152 + 1048576 + 524288 + 262144 + 131072 + 65536 = 4294901760           

        .PARAMETER SubnetSuffixNum
        CIDR suffix as a integer value.

        .INPUTS
        None. You can't pipe objects to Get-SubnetMaskUInt.

        .OUTPUTS
        Outputs returns an Unsigned Integer value.
        
        .EXAMPLE
        PS> Get-SubnetMaskUInt -SubnetSuffixNum 24
        4294967040

        .EXAMPLE
        PS> Get-SubnetMaskUInt -SubnetSuffixNum 16
        4294901760

    #>
}

function Get-NetworkIpAddressUInt 
{
    param([Parameter(Mandatory=$true)][uint]$IpPrefixUInt,
          [Parameter(Mandatory=$true)][uint]$subnetMaskUInt
         )

    [uint]$networkIpUInt = $IpPrefixUInt -band $subnetMaskUInt
    Write-Debug "Network Integer Value: $($networkIpUInt)"
    Write-Debug "Network Binary Value: $([Convert]::ToString($networkIpUInt, 2).PadLeft(32, '0'))"

    return $networkIpUInt

    <#
        .SYNOPSIS
        Calculates network IP address from IP address prefix and the subnet suffix

        .DESCRIPTION
        Calculates network IP address from address prefix as a unsigned integer value and the subnet suffix as an integer value with the bitwise AND operation. See below:
        E.g. 192.168.1.0/24
        Ip Prefix Number = 3232235776 = 11000000 10101000 00000001 00000000
        Subnet Prefix Mask = 4294967040 = 11111111 11111111 11111111 00000000
        
        Bitwise AND Operation:
            11000000 10101000 00000001 00000000
            11111111 11111111 11111111 00000000 &
            -----------------------------------
            11000000 10101000 00000001 00000000

            |First Octet                                                                   |Second Octet                                              |Third Octet                            |Fourth Octet                   |
            |2^31      |2^30      |2^29     |2^28     |2^27     |2^26    |2^25    |2^24    |2^23   |2^22   |2^21   |2^20   |2^19  |2^18  |2^17  |2^16 |2^15 |2^14 |2^13|2^12|2^11|2^10|2^9|2^8|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|
            |2147483648|1073741824|536870912|268435456|134217728|67108864|33554432|16777216|8388608|4194304|2097152|1048576|524288|262144|131072|65536|32768|16384|8192|4096|2048|1024|512|256|128|64 |32 |16 |8  |4  |2  |1  |
            |     1    |     1    |    0    |    0    |    0    |    0   |    0   |    0   |   1   |   0   |   1   |   0   |   1  |   0  |   0  |  0  |  0  |  0  |  0 |  0 |  0 |  0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
        
            2147483648 + 1073741824 + 8388608 + 2097152 + 524288 + 256 = 3232235776

        .PARAMETER IpPrefixUInt
        IP Address prefix as a unsigned integer value

        .PARAMETER subnetMaskUInt
        Subnet Mask suffice as a unsigned integer value.

        .INPUTS
        None. You can't pipe objects to Get-NetworkIpAddressUInt.

        .OUTPUTS
        Returns an unsigned integer value that presents the network Ip Address

        .EXAMPLE
        PS> Get-NetworkIpAddressUInt -IpPrefixUInt 167772416 -subnetMaskUInt 4294901760 # For CIDR '10.0.1.0/16'
        167772160

        .EXAMPLE
        PS> Get-NetworkIpAddressUInt -IpPrefixUInt 3232235776 -subnetMaskUInt 4294967040 # '192.168.1.0/24'
        3232235776

    #>
}

function Get-BroadcastIpAddressUInt
{
    param([Parameter(Mandatory=$true)][uint]$networkIpUInt,
          [Parameter(Mandatory=$true)][uint]$hostMaskUInt
         )

    # This is correct but using host mask is better
    # [uint]$broadcastUInt = $networkIpUInt -bor ($totalAddresses - 1) 
    [uint]$broadcastUInt = $networkIpUInt -bor $hostMaskUInt
    Write-Debug "Broadcast Integer Value: $($broadcastUInt)"
    Write-Debug "Broadcast Mask Binary Value: $([Convert]::ToString($broadcastUInt, 2).PadLeft(32, '0'))"
    
    return $broadcastUInt

    <#
        .SYNOPSIS
        Calculates the broadcast IP address.

        .DESCRIPTION
        Calculates the broadcast IP address from the network IP unsigned integer value and the total number of ip address calculated from the CIDR suffix
        with Bitwise OR operation. See below:
        E.g. 192.168.1.0/24

        Network IP Address = 3232235776 = 11000000 10101000 00000001 00000000
        Host mask = 255 = 00000000 00000000 00000000 11111111

        Bitwise Operation:
            11000000 10101000 00000001 00000000
            00000000 00000000 00000000 11111111 |
            -----------------------------------
            11000000 10101000 00000001 11111111    

            |First Octet                                                                   |Second Octet                                              |Third Octet                            |Fourth Octet                   |
            |2^31      |2^30      |2^29     |2^28     |2^27     |2^26    |2^25    |2^24    |2^23   |2^22   |2^21   |2^20   |2^19  |2^18  |2^17  |2^16 |2^15 |2^14 |2^13|2^12|2^11|2^10|2^9|2^8|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|
            |2147483648|1073741824|536870912|268435456|134217728|67108864|33554432|16777216|8388608|4194304|2097152|1048576|524288|262144|131072|65536|32768|16384|8192|4096|2048|1024|512|256|128|64 |32 |16 |8  |4  |2  |1  |
            |     1    |     1    |    0    |    0    |    0    |    0   |    0   |    0   |   1   |   0   |   1   |   0   |   1  |   0  |   0  |  0  |  0  |  0  |  0 |  0 |  0 |  0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

            2147483648 + 1073741824 + 8388608 + 2097152 + 524288 + 256 + 128 + 64 + 32 + 16 + 8 + 4 + 2 + 1 = 3232236031


        .PARAMETER networkIpUInt
        Network IP address as a unsigned integer value

        .PARAMETER hostMaskUInt
        Total number of IP Addresses

        .INPUTS
        None. You can't pipe objects to Get-BroadcastIpAddressUInt

        .OUTPUTS
        Returns a unsigned integer value

        .EXAMPLE
        PS> Get-BroadcastIpAddressUInt -networkIpUInt 3232235776 -hostMaskUInt 255 # For '192.168.1.0/24'
        3232236031

        .EXAMPLE
        PS> Get-BroadcastIpAddressUInt -networkIpUInt 169607168 -hostMaskUInt 511 # For '10.28.0.0/23'
        169607679

    #>
}

function Get-TotalCountOfIPAddress
{
    param([Parameter(Mandatory=$true)][byte][ValidateRange(0, 32)]$subnetSuffixNum)

    [uint]$totalAddresses = [Math]::Pow(2, 32 - $subnetSuffixNum)
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

function Get-IPv4CIDRTranslation 
{
    param([Parameter(Mandatory=$true)][string][ValidatePattern("^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\/(?:3[0-2]|[1-2]?[0-9])$")]$CIDRAddress)
    
    [uint]$IpPrefixUInt = Convert-IPStrToIPUInt -IPStr $($CIDRAddress -split "\/")[0]
    $subnetSuffixNum = [byte]::Parse($($CIDRAddress -split "\/")[1])
    Write-Debug "Subnet suffix: $($subnetSuffixNum)"
    [byte]$hostBitsByte = Get-HostBitsByte -SubnetSuffixNum $subnetSuffixNum
    [uint]$hostMaskUInt = Get-HostMaskUInt -HostBitsByte $hostBitsByte
    [uint]$subnetMaskUInt = Get-SubnetMaskUInt -SubnetSuffixNum $subnetSuffixNum 
    [uint]$networkIpUInt = Get-NetworkIpAddressUInt -IpPrefixUInt $IpPrefixUInt -subnetMaskUInt $subnetMaskUInt
    [uint]$broadcastUInt = Get-BroadcastIpAddressUInt -networkIpUInt $networkIpUInt -hostMaskUInt $hostMaskUInt
    [uint]$hostMaskUInt = -bnot $subnetMaskUInt
    Write-Debug "Host Integer Value: $($hostMaskUInt)"
    Write-Debug "Host Binary Value: $([Convert]::ToString($hostMaskUInt, 2).PadLeft(32, '0'))"
    
    if (($IpPrefixUInt -band $hostMaskUInt) -ne 0)
    {
        Write-Warning "Host bit(s) is not valid when comparing to subnet mask, host bit(s) will be zero!"
    }

    return @{
        NetworkIP = @{
            Numerical = $networkIpUInt;
            Octets = Convert-IPNumToIpStr -IpPrefixUInt $networkIpUInt;
            Binary = [Convert]::ToString($networkIpUInt, 2).PadLeft(32, '0');
        };
        BroadcastIP = @{
            Numerical = $broadcastUInt;
            Octets = Convert-IPNumToIpStr -IpPrefixUInt $broadcastUInt;
            Binary = [Convert]::ToString($broadcastUInt, 2).PadLeft(32, '0');
        };
        SubnetMask = @{
            Numerical = $subnetMaskUInt;
            Octets = Convert-IPNumToIpStr -IpPrefixUInt $subnetMaskUInt;
            Binary = [Convert]::ToString($subnetMaskUInt, 2).PadLeft(32, '0');
        };
        HostMask = @{
            Numerical = $hostMaskUInt;
            Octets = Convert-IPNumToIpStr -IpPrefixUInt $hostMaskUInt;
            Binary = [Convert]::ToString($hostMaskUInt, 2).PadLeft(32, '0');            
        }
        FirstHost = @{
            Numerical = ($networkIpUInt + 1);
            Octets = Convert-IPNumToIpStr -IpPrefixUInt ($networkIpUInt + 1);
            Binary = [Convert]::ToString(($networkIpUInt + 1), 2).PadLeft(32, '0');
        };
        LastHost = @{
            Numerical = ($broadcastUInt - 1);
            Octets = Convert-IPNumToIpStr -IpPrefixUInt ($broadcastUInt - 1);
            Binary = [Convert]::ToString(($broadcastUInt - 1), 2).PadLeft(32, '0');
        };
        TotalAddresses = Get-TotalCountOfIPAddress -subnetSuffixNum $subnetSuffixNum;
        
        
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
        PS> Get-IPv4CIDRTranslation -CIDRAddress "192.168.1.0/24"
        Name                           Value
        ----                           -----
        FirstHost                      {[Octets, 192.168.1.1], [Numerical, 3232235777], [Binary, 11000000101010000000000100000001]}
        LastHost                       {[Octets, 192.168.1.254], [Numerical, 3232236030], [Binary, 11000000101010000000000111111110]}
        HostMask                       {[Octets, 0.0.0.255], [Numerical, 255], [Binary, 00000000000000000000000011111111]}
        SubnetMask                     {[Octets, 255.255.255.0], [Numerical, 4294967040], [Binary, 11111111111111111111111100000000]}
        BroadcastIP                    {[Octets, 192.168.1.255], [Numerical, 3232236031], [Binary, 11000000101010000000000111111111]}
        TotalAddresses                 256
        NetworkIP                      {[Octets, 192.168.1.0], [Numerical, 3232235776], [Binary, 11000000101010000000000100000000]}

        .EXAMPLE
        PS> Get-IPv4CIDRTranslation -CIDRAddress "10.0.1.0/16"
        WARNING: Host bit(s) is not valid when comparing to subnet mask, host bit(s) will be zero!

        Name                           Value
        ----                           -----
        FirstHost                      {[Octets, 10.28.0.1], [Numerical, 169607169], [Binary, 00001010000111000000000000000001]}
        LastHost                       {[Octets, 10.28.255.254], [Numerical, 169672702], [Binary, 00001010000111001111111111111110]}
        HostMask                       {[Octets, 0.0.255.255], [Numerical, 65535], [Binary, 00000000000000001111111111111111]}
        SubnetMask                     {[Octets, 255.255.0.0], [Numerical, 4294901760], [Binary, 11111111111111110000000000000000]}
        BroadcastIP                    {[Octets, 10.28.255.255], [Numerical, 169672703], [Binary, 00001010000111001111111111111111]}
        TotalAddresses                 65536
        NetworkIP                      {[Octets, 10.28.0.0], [Numerical, 169607168], [Binary, 00001010000111000000000000000000]}
    #>
}

function Compare-Subnets
{
    param ([Parameter(Mandatory=$true)][string][ValidatePattern("^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\/(?:3[0-2]|[1-2]?[0-9])$")]$CIDRAddressA,
           [Parameter(Mandatory=$true)][string][ValidatePattern("^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\/(?:3[0-2]|[1-2]?[0-9])$")]$CIDRAddressB
          )
    
    [uint]$ipPrefixUIntA = Convert-IPStrToIPUInt -IPStr ($CIDRAddressA -split "\/")[0]
    $subnetSuffixNumA = [byte]::Parse($($CIDRAddressA -split "\/")[1])
    [byte]$hostbitsByteA = Get-HostBitsByte -SubnetSuffixNum $subnetSuffixNumA
    [uint]$subnetMaskUIntA = Get-SubnetMaskUInt -SubnetSuffixNum $subnetSuffixNumA
    [uint]$networkIpUIntA = Get-NetworkIpAddressUInt -IpPrefixUInt $ipPrefixUIntA -subnetMaskUInt $subnetMaskUIntA
    [uint]$hostMaskUIntA = Get-HostMaskUInt -HostBitsByte $hostbitsByteA
    [uint]$broadcastIpUIntA = Get-BroadcastIpAddressUInt -networkIpUInt $networkIpUIntA -hostMaskUInt $hostMaskUIntA
    [uint]$ipPrefixUIntB = Convert-IPStrToIPUInt -IPStr ($CIDRAddressB -split "\/")[0]

    $subnetSuffixNumB = [byte]::Parse($($CIDRAddressB -split "\/")[1])
    [byte]$hostbitsByteB = Get-HostBitsByte -SubnetSuffixNum $subnetSuffixNumA
    [uint]$subnetMaskUIntB = Get-SubnetMaskUInt -SubnetSuffixNum $subnetSuffixNumB
    [uint]$networkIpUIntB = Get-NetworkIpAddressUInt -IpPrefixUInt $ipPrefixUIntB -subnetMaskUInt $subnetMaskUIntB
    [uint]$hostMaskByteB = Get-HostMaskUInt -HostBitsByte $hostbitsByteB
    [uint]$broadcastIpUIntB = Get-BroadcastIpAddressUInt -networkIpUInt $networkIpUIntB -hostMaskUInt $hostMaskByteB

    return ($networkIpUIntA -le $broadcastIpUIntB) -and ($broadcastIpUIntA -ge $networkIpUIntB)

    <#
        .SYNOPSIS
        Compares two subnets for overlaps or if subnet is within IP Address Space.

        .DESCRIPTION
        Compares two subnets for overlaps or if subnet is within the IP Address Space with IP CIDR values, first by taking the max value of the prefix and then comparing the network IP values.
        If network IP comparison returns false then it will take the minimum prefix value if the prefixes do not match and then compare the new network IP values. See below:
        E.g.
        Network Address A = 192.168.1.0 = 3232235776
        Broadcast Address A = 192.168.1.255 = 3232236031

        Network Address B = 192.168.1.0 = 3232235776
        Broadcast Address B = 192.168.1.127 = 3232235903

        Network Address A <= Broadcast Address B && Broadcast Address A >= Network Address B
        3232235776 <= 3232235903 && 3232236031 >= 3232235776
                  TRUE           &&           TRUE            = TRUE !!           

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

function Test-IPInSubnet
{
    param([Parameter(Mandatory=$true)][string][ValidatePattern("^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$")]$IPStr,
          [Parameter(Mandatory=$true)][string][ValidatePattern("^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\/(?:3[0-2]|[1-2]?[0-9])$")]$CIDRAddress
         )

    [uint]$ipNum = Convert-IPStrToIPUInt -IPStr $IPStr
    [uint]$ipPrefixUInt = Convert-IPStrToIPUInt -IPStr ($CIDRAddress -split "\/")[0]
    $subnetSuffixNum = [byte]::Parse($($CIDRAddress -split "\/")[1])
    [byte]$hostbitsByte = Get-HostBitsByte -SubnetSuffixNum $subnetSuffixNum
    [uint]$subnetMaskUInt = Get-SubnetMaskUInt -SubnetSuffixNum $subnetSuffixNum
    [uint]$networkIpUInt = Get-NetworkIpAddressUInt -IpPrefixUInt $ipPrefixUInt -subnetMaskUInt $subnetMaskUInt
    [uint]$hostMaskUInt = Get-HostMaskUInt -HostBitsByte $hostbitsByte
    [uint]$broadcastIpUInt = Get-BroadcastIpAddressUInt -networkIpUInt $networkIpUInt -hostMaskUInt $hostMaskUInt

    return $ipNum -ge $networkIpUInt -and $ipNum -le $broadcastIpUInt

    <#
        .SYNOPSIS
        Test Ip address on a given subnet.

        .DESCRIPTION
        Test an ip address on a given subnet. As long as IP Number is greater than network IP number and it is less than broadcast IP number, the IP address is within the subnet range.

        .PARAMETER IPStr
        String version of the IP address.

        .PARAMETER CIDRAddress
        String version of the CIDR address.

        .INPUTS
        None. You can't pipe objects to Test-IPInSubnet

        .EXAMPLE
        PS> Test-IPInSubnet -IPStr "10.28.0.128" -CIDRAddress "10.28.0.0/16"
        True

        .EXAMPLE
        PS> Test-IPInSubnet -IPStr "192.168.1.0" -CIDRAddress "192.168.1.0/24"
        True

        .EXAMPLE
        PS> Test-IPInSubnet -IPStr "192.168.2.254" -CIDRAddress "192.168.1.0/24"
        False
    #>
}

<#
    .SYNOPSIS
    This script is for using creating subnets from an IP address space using the CIDR notation. And also troubleshooting subnets.

    .DESCRIPTION
    This script was written to help creating creating an from IP address space using the CIDR notation. This script can also be used for troubleshooting subnets as well.
    Detailed explanation are in the function comments. But will generalise a few items that are used frequently through the code.

    # Regex Validation patterns
    The beginning (^) and end ($) anchors are added to exactly match the string IP address or CIDR subnet address parameters. This is so that you do not enter a value like 'hello192.168.1.0hello' as an example. And also using non capturing groups for regex performance optimization. 

    ## Validation pattern for string version of IP address. 
    Regex Pattern: "^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$"

    The first part: (?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3} matches numbers from 0 to 255:
    1. 25[0-5] - matches numbers from 250 to 255 or,
    2. 2[0-4][0-9] - matches numbers from 200 to 249 or,
    3. 1[0-9]{2} - matches numbers 100 to 109 (same thing as 1[0-9][0-9], exactly 2 occurrence needs to occur) or,
    4. [1-9]?[0-9] - matches numbers 0 - 99 ([1-9]? means the occurrence can happen 0 or 1 time)
    5. \. - the dot must be in the address for the first 3 occurrence.
    6. {3} - represents the first 3 octets where the above logic (1 to 5) must exactly occur 3 times.
    
    The second part: (?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])
    This is the last or fourth octet. Exactly the same logic steps from 1 to 4 in the first part, however there is no occurrence of the \. and the no exact repetition occurrence needs to happen as per step 6 
    (only needs to happen once).

    ## Validation pattern for string version of CIDR Subnet Address
    Regex pattern: "^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\/(3[0-2]|[1-2]?[0-9])$"

    The first part: (?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])
    This is the same as ip address validation in the Validation pattern for string version of IP address section.

    The second part: \/(?:3[0-2]|[1-2]?[0-9]):
    1. \/ - expects "/" after the ip address portion
    2. 3[0-2] values can be 30, 31, 32 or,
    3. [1-2]?[0-9] values can be from 0 to 29

    # Numerical considerations. 
    Explicit type enforcement was used to explicitly cast the numeric values to 2 numeric types are used throughout the script. 
    
    ## byte variable type
    The first one is byte since the CIDR subnet suffix has a range from 0 to 32, it is the smallest unsigned numerical type is that can be used and then for parameters a ValidateRange attribute is used 
    to restrict the input between 0 and 32.

    The second one is unsigned integer where the max value is 4294967295 which is also a geometric sequence that follows 2^0 + 2^1 + 2^2 + ... + 2^31 = 2^32 - 1 (so 2^n - 1) which represents 
    the highest value that an ip address can have.
        a = first term
        r = common ratio
        n = number of terms
        S_n = a ((r^n-1) / (r - 1))
        S_32 = 1*((2^32 - 1)/(2 - 1)) = 2^32 - 1
        S_32 = 4294967295

    For explicitly casting ip address string to a unsigned integers ensure accuracy and consistency when comparing values. When converting the ip octet to a base 10 value and vice versa, it is easy to visualise 
    in a binary-to-numeric table for converting and performing arithmetic and bitwise operations for calculating the network IP, broadcast IP, subnet mask, host mask and so on:

    |First Octet                                                                   |Second Octet                                              |Third Octet                            |Fourth Octet                   |
    |2^31      |2^30      |2^29     |2^28     |2^27     |2^26    |2^25    |2^24    |2^23   |2^22   |2^21   |2^20   |2^19  |2^18  |2^17  |2^16 |2^15 |2^14 |2^13|2^12|2^11|2^10|2^9|2^8|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|
    |2147483648|1073741824|536870912|268435456|134217728|67108864|33554432|16777216|8388608|4194304|2097152|1048576|524288|262144|131072|65536|32768|16384|8192|4096|2048|1024|512|256|128|64 |32 |16 |8  |4  |2  |1  |
    
    4294967295 = 2147483648 + 1073741824 + 536870912 + 268435456 + 134217728 + 67108864 + 33554432 + 16777216 + 8388608 + 4194304 + 2097152 + 1048576 + 524288 + 262144 + 131072 + 65536 + 32768 + 16384 + 8192 
                + 4096 + 2048 + 1024 + 512 + 256 + 128 + 64 + 32 + 16 + 8 + 4 + 2 + 1

    For each octet, 1 byte represent by 8 bits where the values can range from 0 to 255 (or 2^8 = 256 possible values). However, when doing comparisons and bitwise operations, it becomes easy when you consider 
    all 4 octets as one value.

    .PARAMETER DebugPreference
    This parameter is used for PowerShell Debugging and also for setting breakpoints if you're using VS Code.

    .INPUTS
    There are no inputs for CIDRSubnetting
#>