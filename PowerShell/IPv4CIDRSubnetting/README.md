# Motivation
Since I started my new role at Microsoft as a Databricks Support Engineer, cloud networking is an essential part of Databricks and how customers customise their networking (using VNets, Private Link, Service Endpoints, etc.) to ingress and egress data. Most of my career has been focused on application support and development. Networking was not a really prerequisite for my work (well not a lot anyways). 

Now it is 😁, so I decided to re-learn how to do subnetting with CIDR addresses. So I decided to write a PowerShell script to relearn how to create subnets from an IP Address space. 

Later on, I discovered that Python has the `ipaddress` module, which performs all the tasks that my script [IPv4CIDRSubnetting.ps1](./IPv4CIDRSubnetting.ps1) does 🤦🏽‍♂️. But the good thing is I can do some unit tests (see [test_ip_v4_cidr_subnetting.py](./test_ip_v4_cidr_subnetting.py)) to compare with the `IPv4Network` class found in `ipaddress` module using the `subprocess` module to execute my PowerShell CmdLets. 

I know explicitly casting and/or parsing all my variables and parameters is overkill but it's a good reminder of what the types are especially when it comes to bitwise operations. Either way, good fun doing bitwise operations to get the blood flowing!

# Introduction
Honestly, I should have done the bitwise operations by hand first before writing code but anyways when I did do it by hand this is the process that I came up with:  
1. Work out the host bits from subnet suffix number (`Get-HostBitsByte`).
2. Calculate the host mask unsigned integer value (`Get-HostMaskUInt`).
3. Calculate the subnet mask unsigned integer value (inverse of host mask with ! operation) (`Get-SubnetMaskUInt`, calls `Get-HostBitsByte` & `Get-HostMaskUInt` internally).
4. Convert IP address prefix octets into an unsigned integer value (`Convert-IPStrToIPUInt`).
5. Calculate the network IP address with IP unsigned integer value and subnet mask (`Get-NetworkIpAddressUInt`).
6. Calculate the broadcast IP address with network IP address and the host mask unsigned integer value (`Get-BroadcastIpAddressUInt`).
7. Calculate first IP address (unsigned integer network IP address value + 1).
8. Calculate last IP address (unsigned integer broadcast IP address value - 1).

Lastly, to get the IPv4 CIDR Translation (when calling `Get-IPv4CIDRTranslation`), all the unsigned integer and byte values are then converted back to 4 octet based strings with `Convert-IPNumToIpStr`.

I also did add two more cmdlet for comparing subnets (`Compare-Subnets`, checking subnets for overlaps) and also testing IP addresses in subnets (`Test-IPInSubnet`).

Each CmdLet has detailed comments explaining how the function works in terms of bitwise operations and mathematical approach (if applicable). 

This is just an overview and how I came to my solution or what I needed to understand subnets.

# Understanding Octets & Bitwise operations
There's a few important elements that I had remember in order to perform bitwise operations. This is why you will predominantly see all variables and parameter variables explicitly casted to a byte (predominantly for subnet suffix and host bits) and unsigned integer (and I wanted to make sure and understand that I am using the right variables types throughout the script).

## IPv4 CIDR subnet suffix and host bits
For the CIDR subnet suffix and host bits, I've decided to explicitly cast these to a `byte` type. In IPv4 CIDR notation the maximum value of the suffix is `/32`. Meaning:  
  * Each octet can have the maximum value of 255 or,
  * IPv4 address has a maximum bit value is 32 bits (or 4 bytes). 

You can run the following in the PowerShell REPL to verify:  
|Command           |Value|
|------------------|-----|
|`[byte]::MinValue`|0    |
|`[byte]::MaxValue`|255  |

Although a bytes value ranges from 0 to 255, you will see on parameter where it is asking for a subnet suffix number of the host bit number, I have added a `ValidateRange` attribute to restrict the parameter values from 0 to 32. *These values are not used for bitwise operations*. When do I do use them bitwise operation? When the host bits converted a host mask and then taking the inverse of the host mask with the bitwise NOT (`!`) operation to calculate the subnet mask.

### When octet in subnet mask is 255
When an octet in the subnet mask is 255, this means that the octet of the IP address cannot change. These are known as **Network bits** in the IP address. The rest are known as **Host bits**, which can vary. But as an FYI, traditional rules says for usable host addresses you need to leave 2 host bits, which is 30 or less bits due to:  
  * `/31` - Special use for point-to-point links (RFC 3021)
  * `/32` - Single host address (i.e 127.0.0.1/32 used for host routes, loopback)

Although if you do have a CIDR notation with `/32`, this just means you have have 1 IP address, which is still valid (confirmed in my testing in see [test_ip_v4_cidr_subnetting.py](./test_ip_v4_cidr_subnetting.py), `TestSubnets` class). 

Maybe I should also add a warning for these 🤔 and also for `\0` too.

## Bitwise operations
Before I start discussing bitwise operations, the first thing I need to discuss is conversion from a decimal value to a unsigned integer value for bitwise operation and then the binary representation of the unsigned integer value, which both applies to octets of the IP address prefix and subnet suffix of the IPv4 CIDR notation.

## Decimal to unsigned integer conversion
## 8 bits/1 byte/1 octet representation
First and foremost, we know that 1 byte is 8 bits and 1 byte represents an octet in the IP address. And we know that the maximum value 1 byte (or 8 bits) can store is 255. What does this look like?  

|             |   |   |   |   |   |   |   |   |  
|-------------|---|---|---|---|---|---|---|---|   
|Bit Position |8th|7th|6th|5th|4th|3rd|2nd|1st|   
|Powers of 2^x|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|  
|Total        |128|64 |32 |16 |8  |4  |2  |1  |  

If you add up the *Total* it will equal to 255.

$255 = 128 + 64 + 32 + 16 + 8 + 4 + 2 + 1$

What's the binary representation of 255?

|             |   |   |   |   |   |   |   |   |  
|-------------|---|---|---|---|---|---|---|---|   
|Bit Position |8th|7th|6th|5th|4th|3rd|2nd|1st|   
|Powers of 2^x|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|  
|Total        |128|64 |32 |16 |8  |4  |2  |1  |  
|Binary       | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

In the last row is the binary representation meaning $11111111 = 255$. If you wanted to represent a value of $203$, it would be $110010110$. Using our handy dandy table, it would look like:   

|             |   |   |   |   |   |   |   |   |  
|-------------|---|---|---|---|---|---|---|---|   
|Bit Position |8th|7th|6th|5th|4th|3rd|2nd|1st|   
|Powers of 2^x|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|  
|Total        |128|64 |32 |16 |8  |4  |2  |1  |  
|Binary       | 1 | 1 | 0 | 0 | 1 | 0 | 1 | 1 |

$203 = 128 + 64 + 8 + 2 + 1$

**203 is not a valid numerical value that represents the network or the host bits (subnet mask or host mask)**. Just want to show you how the decimal to binary conversion works. Anything that is a $0$, we ignore and do not add; anything that is a $1$ we add.

For documentation purposes, see table below for valid values for IPv4 network and host bits (subnet mask and host mask):  

|Decimal Value|Binary Value|
|-------------|------------|
|0            |00000000    |
|128          |10000000    |
|192          |11000000    |
|224          |11100000    |
|240          |11110000    |
|248          |11111000    |
|252          |11111100    |
|255          |11111111    |

Sure that same can be applied to an private class C IP Address space $192.168.1.0$. First octet $192$ the binary value is $11000000$, from our table above. But what about for $168$? Let's work it out using our handy dandy table.

|             |   |   |   |   |   |   |   |   |  
|-------------|---|---|---|---|---|---|---|---|   
|Bit Position |8th|7th|6th|5th|4th|3rd|2nd|1st|   
|Powers of 2^x|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|  
|Total        |128|64 |32 |16 |8  |4  |2  |1  |  
|Binary       | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 0 |

$168 = 128 + 32 + 8 = 10101000$

But this is only for **1 octet**, we need to do this **3 more times**. By hand it might not be a problem, but programmatically, it's a bit of an overhead if we try to replicate by hand approach.

## 32 bits/4 bytes/4 octet representation
Since the by hand approach is a bit of an overhead programmatically and I wanted to take the path of least work 😜. An IPv4 address is 32 bits which is comprised of 4 octets of 8 bits. So we need a bigger handy (not so) dandy table.  

|Octet         |1st       |          |         |         |         |        |        |        |2nd    |       |       |       |      |      |      |3rd  |     |     |    |    |    |    |    |4th|   |   |   |   |   |   |   |   |
|--------------|----------|----------|---------|---------|---------|--------|--------|--------|-------|-------|-------|-------|------|------|------|-----|-----|-----|----|----|----|----|----|---|---|---|---|---|---|---|---|---|  
|Bit Position  |32th      |31th      |30th     |29th     |28th     |27th    |26th    |25th    |24th   |23rd   |22nd   |21st   |20th  |19th  |18th  |17th |16th |15th |14th|13th|12th|11th|10th|9th|8th|7th|6th|5th|4th|3rd|2nd|1st| 
|Powers of 2^x |2^31      |2^30      |2^29     |2^28     |2^27     |2^26    |2^25    |2^24    |2^23   |2^22   |2^21   |2^20   |2^19  |2^18  |2^17  |2^16 |2^15 |2^14 |2^13|2^12|2^11|2^10|2^9 |2^8|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|  
|Total         |2147483648|1073741824|536870912|268435456|134217728|67108864|33554432|16777216|8388608|4194304|2097152|1048576|524288|262144|131072|65536|32768|16384|8192|4096|2048|1024|512 |256|128|64 |32 |16 |8  |4  |2  |1  |  

Now this does not look nice to work with by hand. But I can assure you many (if not all) scripting and program languages can do it in this matter. But if I go on any further, let's add the last row (*Total*) and see what we get:

$4294967295 = 2147483648 + 1073741824 + 536870912 + 268435456 + 134217728 + 67108864 + 33554432 + 16777216 + 8388608 + 4194304 + 2097152 + 1048576 + 524288 + 262144 + 131072 + 65536 + 32768 + 16384 + 8192 + 4096 + 2048 + 1024 + 512 + 256 + 128 + 64 + 32 + 16 + 8 + 4 + 2 + 1$

We get 4294967295, which also the same as the maximum value of an unsigned integer. You can run the following in the PowerShell REPL to verify:  
|Command           |Value     |
|------------------|----------|
|`[uint]::MinValue`|0         |
|`[uint]::MaxValue`|4294967295|

So we know that with the CIDR suffix of `/32` would be $11111111111111111111111111111111$. But what a Private Class C address would look like in our handy (not so dandy table).

|Octet         |1st       |          |         |         |         |        |        |        |2nd    |       |       |       |      |      |      |3rd  |     |     |    |    |    |    |    |4th|   |   |   |   |   |   |   |   |
|--------------|----------|----------|---------|---------|---------|--------|--------|--------|-------|-------|-------|-------|------|------|------|-----|-----|-----|----|----|----|----|----|---|---|---|---|---|---|---|---|---|  
|Bit Position  |32th      |31th      |30th     |29th     |28th     |27th    |26th    |25th    |24th   |23rd   |22nd   |21st   |20th  |19th  |18th  |17th |16th |15th |14th|13th|12th|11th|10th|9th|8th|7th|6th|5th|4th|3rd|2nd|1st| 
|Powers of 2^x |2^31      |2^30      |2^29     |2^28     |2^27     |2^26    |2^25    |2^24    |2^23   |2^22   |2^21   |2^20   |2^19  |2^18  |2^17  |2^16 |2^15 |2^14 |2^13|2^12|2^11|2^10|2^9 |2^8|2^7|2^6|2^5|2^4|2^3|2^2|2^1|2^0|  
|Total         |2147483648|1073741824|536870912|268435456|134217728|67108864|33554432|16777216|8388608|4194304|2097152|1048576|524288|262144|131072|65536|32768|16384|8192|4096|2048|1024|512 |256|128|64 |32 |16 |8  |4  |2  |1  |  
|Binary        |1         |1         |0        |0        |0        |0       |0       |0       |1      |0      |1      |0      |1     |0     |0     |0    |0    |0    |0   |0   |0   |0   |0   |1  |0  |0  |0  |0  |0  |0  |0  |0  |


So `192.168.1.0` in binary form is `11000000101010000000000100000000` but if we add the values together and store it in a unsigned integer variable then bitwise operations are much easier to perform.

$3232235776 = 2147483648 + 1073741824 + 8388608 + 2097152 + 524288 + 256$

Just formatting the binary value by adding a dot after every 8th bit.

`11000000.10101000.00000001.00000000` = $3232235776$ = `192.168.1.0`

# Conclusion
If I was to implement by hand operation as code, it would have had more code, but converting the values an unsigned integer made me write less code and also help me to relearn and have a better understanding from a developers perspective.  


# References
* https://www.freecodecamp.org/news/subnet-cheat-sheet-24-subnet-mask-30-26-27-29-and-other-ip-address-cidr-network-references/
* https://i-bit-therefore-i-byte.com/2020/05/11/point-to-point-links-with-31-rfc-3021/ 
* https://superuser.com/questions/1473252/what-does-it-mean-to-have-a-subnet-mask-32
* https://stackoverflow.com/questions/61887670/how-to-specify-a-cidr-block-that-covers-only-one-address