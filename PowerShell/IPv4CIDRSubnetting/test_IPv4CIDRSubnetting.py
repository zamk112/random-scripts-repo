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

"""
Unit testing CIDRSubnetting.ps1 script and comparing outputs to the ipaddress module with the IPv4Network class. 
Just doing private class A & C since this is what I use at home and work 😜.
"""

import unittest
from ipaddress import IPv4Network, IPv4Address
import subprocess
import os


class PSCommand:
    """
    Created the PSCommand class to run my powershell commands with the subprocess module, the output and error pipes are all converted to text.
    So casting is needed to in order to test for correctness.
    """
    def __init__(self, psCmdLet: str):
        """
        Constructor is used to initialise the path to the PowerShell Script file. and also the PowerShell command to execute. 
        psCmdLet is the cmdLet that's going to be executed from the file.
        """
        self.__psScriptCmdStr = ". " + os.path.dirname(__file__) + os.sep + "IPv4CIDRSubnetting.ps1; " + psCmdLet
        self.__psCmdLst = ["pwsh", "-Command", self.__psScriptCmdStr]

    def runPsCommand(self) -> str:
        """
        Executing the PowerShell command using pipes where stdout and stderr back to results variable where the output is of type string.
        """
        results = subprocess.run(
            self.__psCmdLst,
            stdout=subprocess.PIPE,
            stderr= subprocess.PIPE,
            text=True
        )

        if results.returncode != 0:
            print("PowerShell Error: %s" % (results.stderr))

        return results.stdout

class TestCompareCIDRPrivateClassA(unittest.TestCase):
    """
    Testing Private Class A IPv4 Addresses with a subnet range of 10.28.0.0 to 10.28.255.255
    Subnet setup as per https://learn.microsoft.com/en-us/azure/databricks/security/network/classic/private-link-standard#create-vnet
    """
    def __init__(self, methodName):
        self.ipAddressSpace = IPv4Network("10.28.0.0/16")
        self.publicSubnet = IPv4Network("10.28.0.0/25")
        self.privateSubnet = IPv4Network("10.28.0.128/25")
        self.privateLink = IPv4Network("10.28.1.0/27")
        super().__init__(methodName)

    def test_totalAddressCount(self):
        # Testing IP Address Space
        totalAddressExpected = 65536
        
        self.assertEqual(self.ipAddressSpace.num_addresses, totalAddressExpected)

        psCmdActual = PSCommand("Get-TotalCountOfIPAddress -subnetSuffixNum 16").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), totalAddressExpected)

        # Testing public subnet
        totalAddressExpected = 128

        self.assertEqual(self.publicSubnet.num_addresses, totalAddressExpected)

        psCmdActual = PSCommand("Get-TotalCountOfIPAddress -subnetSuffixNum 25").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), totalAddressExpected)

        # Testing private subnet
        self.assertEqual(self.privateSubnet.num_addresses, totalAddressExpected)

        psCmdActual = PSCommand("Get-TotalCountOfIPAddress -subnetSuffixNum 25").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), totalAddressExpected)

        # Testing private link
        totalAddressExpected = 32

        self.assertEqual(self.privateLink.num_addresses, totalAddressExpected)

        psCmdActual = PSCommand("Get-TotalCountOfIPAddress -subnetSuffixNum 27").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), totalAddressExpected)        


    def test_networkIPAddressUInt(self):
        # Testing IP Address space
        networkIpAddressNumExpected = 169607168
        
        self.assertEqual(int(self.ipAddressSpace.network_address), networkIpAddressNumExpected)

        psCmdActual = PSCommand("Get-NetworkIpAddressUInt -IpPrefixUInt 169607169 -subnetMaskUInt 4294901760").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), networkIpAddressNumExpected)

        # Testing public subnet
        self.assertEqual(int(self.publicSubnet.network_address), networkIpAddressNumExpected)

        psCmdActual = PSCommand("Get-NetworkIpAddressUInt -IpPrefixUInt 169607169 -subnetMaskUInt 4294967168").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), networkIpAddressNumExpected)

        # Testing private subnet
        networkIpAddressNumExpected = 169607296

        self.assertEqual(int(self.privateSubnet.network_address), networkIpAddressNumExpected)

        psCmdActual = PSCommand("Get-NetworkIpAddressUInt -IpPrefixUInt 169607296 -subnetMaskUInt 4294967168").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), networkIpAddressNumExpected)

        # Testing Private Link Subnet
        networkIpAddressNumExpected = 169607424

        self.assertEqual(int(self.privateLink.network_address), networkIpAddressNumExpected)

        psCmdActual = PSCommand("Get-NetworkIpAddressUInt -IpPrefixUInt 169607424 -subnetMaskUInt 4294967264").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), networkIpAddressNumExpected)        

    def test_broadcastIPAddressUInt(self):
        # Testing IP Address Space
        broadcastIpAddressNumExpected = 169672703

        self.assertEqual(int(self.ipAddressSpace.broadcast_address), broadcastIpAddressNumExpected)

        psCmdActual = PSCommand("Get-BroadcastIpAddressUInt -networkIpUInt 169607168 -hostMaskUInt 65535").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), broadcastIpAddressNumExpected)

        # Testing public subnet
        broadcastIpAddressNumExpected = 169607295

        self.assertEqual(int(self.publicSubnet.broadcast_address), broadcastIpAddressNumExpected)

        psCmdActual = PSCommand("Get-BroadcastIpAddressUInt -networkIpUInt 169607168 -hostMaskUInt 127").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), broadcastIpAddressNumExpected)

        # Testing private subnet
        broadcastIpAddressNumExpected = 169607423

        self.assertEqual(int(self.privateSubnet.broadcast_address), broadcastIpAddressNumExpected)

        psCmdActual = PSCommand("Get-BroadcastIpAddressUInt -networkIpUInt 169607296 -hostMaskUInt 127").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), broadcastIpAddressNumExpected)   

        # Testing private link
        broadcastIpAddressNumExpected = 169607455

        self.assertEqual(int(self.privateLink.broadcast_address), broadcastIpAddressNumExpected)

        psCmdActual = PSCommand("Get-BroadcastIpAddressUInt -networkIpUInt 169607424 -hostMaskUInt 31").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), broadcastIpAddressNumExpected)   

    def test_subnetMaskUInt(self):
        # Testing IP Address Space
        subnetMaskNumExpected = 4294901760

        self.assertEqual(int(self.ipAddressSpace.netmask), subnetMaskNumExpected)

        psCmdActual = PSCommand("Get-SubnetMaskUInt -SubnetSuffixNum 16").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), subnetMaskNumExpected)

        # Testing Public & Private Subnets
        subnetMaskNumExpected = 4294967168
        self.assertEqual(int(self.publicSubnet.netmask), subnetMaskNumExpected)
        self.assertEqual(int(self.privateSubnet.netmask), subnetMaskNumExpected)

        psCmdActual = PSCommand("Get-SubnetMaskUInt -SubnetSuffixNum 25").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), subnetMaskNumExpected)

        # Testing private link
        subnetMaskNumExpected = 4294967264
        self.assertEqual(int(self.privateLink.netmask), subnetMaskNumExpected)

        psCmdActual = PSCommand("Get-SubnetMaskUInt -SubnetSuffixNum 27").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), subnetMaskNumExpected)


    def test_HostMaskUInt(self):
        # Testing IP Address Space
        hostMaskNumExpected = 65535

        self.assertEqual(int(self.ipAddressSpace.hostmask), hostMaskNumExpected)

        psCmdActual = PSCommand("Get-HostMaskUInt -HostBits 16").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), hostMaskNumExpected)

        # Testing public and private subnet
        hostMaskNumExpected = 127

        self.assertEqual(int(self.publicSubnet.hostmask), hostMaskNumExpected)

        psCmdActual = PSCommand("Get-HostMaskUInt -HostBits 7").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), hostMaskNumExpected)   

        # Testing private link
        hostMaskNumExpected = 31

        self.assertEqual(int(self.privateLink.hostmask), hostMaskNumExpected)

        psCmdActual = PSCommand("Get-HostMaskUInt -HostBits 5").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), hostMaskNumExpected)   

    def test_CompareSubnets(self):
        # Test if subnets are in IP Address Space
        self.assertTrue(self.ipAddressSpace.overlaps(self.publicSubnet))

        psCmdActual = PSCommand('Compare-Subnets -CIDRAddressA "10.28.0.0/16" -CIDRAddressB "10.28.0.0/25"').runPsCommand().strip().lower() == "true"
        self.assertTrue(psCmdActual)

        self.assertTrue(self.ipAddressSpace.overlaps(self.privateSubnet))

        psCmdActual = PSCommand('Compare-Subnets -CIDRAddressA "10.28.0.0/16" -CIDRAddressB "10.28.0.128/25"').runPsCommand().strip().lower() == "true"
        self.assertTrue(psCmdActual)        

        self.assertTrue(self.ipAddressSpace.overlaps(self.privateLink))

        psCmdActual = PSCommand('Compare-Subnets -CIDRAddressA "10.28.0.0/16" -CIDRAddressB "10.28.1.0/27"').runPsCommand().strip().lower() == "true"
        self.assertTrue(psCmdActual)      

        # Test if public subnet overlaps private subnet or private link
        self.assertFalse(self.publicSubnet.overlaps(self.privateSubnet))

        psCmdActual = PSCommand('Compare-Subnets -CIDRAddressA "10.28.0.0/25" -CIDRAddressB "10.28.0.128/25"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual) 

        self.assertFalse(self.publicSubnet.overlaps(self.privateLink))

        psCmdActual = PSCommand('Compare-Subnets -CIDRAddressA "10.28.0.0/25" -CIDRAddressB "10.28.1.0/27"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual)                         

    def test_TestIPInSubnet(self):
        # Check IP address in IP Address Space
        ipAddress = IPv4Address('10.28.0.23')
        self.assertTrue(ipAddress in self.ipAddressSpace)

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.23" -CIDRAddress "10.28.0.0/16"').runPsCommand().strip().lower() == "true"
        self.assertTrue(psCmdActual)

        ipAddress = IPv4Address('10.29.2.128')
        self.assertFalse(ipAddress in self.ipAddressSpace)

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.29.2.128" -CIDRAddress "10.28.0.0/16"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual)

        ipAddress = IPv4Address('10.28.1.200')
        self.assertTrue(ipAddress in self.ipAddressSpace)

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.200" -CIDRAddress "10.28.0.0/16"').runPsCommand().strip().lower() == "true"
        self.assertTrue(psCmdActual)

        # Check IP address in Public Subnet
        ipAddress = IPv4Address('10.28.0.23')
        self.assertTrue(ipAddress in self.publicSubnet)

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.23" -CIDRAddress "10.28.0.0/25"').runPsCommand().strip().lower() == "true"
        self.assertTrue(psCmdActual)

        ipAddress = IPv4Address('10.28.0.129')
        self.assertFalse(ipAddress in self.publicSubnet)    

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.129" -CIDRAddress "10.28.0.0/25"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual)

        ipAddress = IPv4Address('10.28.1.36')
        self.assertFalse(ipAddress in self.publicSubnet)    

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.1.36" -CIDRAddress "10.28.0.0/25"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual)        

        # Check IP in Private Subnet
        ipAddress = IPv4Address('10.28.0.23')
        self.assertFalse(ipAddress in self.privateLink)

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.23" -CIDRAddress "10.28.0.128/25"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual)

        ipAddress = IPv4Address('10.28.0.129')
        self.assertFalse(ipAddress in self.privateLink)    

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.129" -CIDRAddress "10.28.0.128/25"').runPsCommand().strip().lower() == "true"
        self.assertTrue(psCmdActual)

        ipAddress = IPv4Address('10.28.1.36')
        self.assertFalse(ipAddress in self.privateLink)    

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.1.36" -CIDRAddress "10.28.0.128/25"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual)

        # Test IP in Private Link subnet
        ipAddress = IPv4Address('10.28.0.23')
        self.assertFalse(ipAddress in self.privateLink)

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.23" -CIDRAddress "10.28.1.0/27"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual)

        ipAddress = IPv4Address('10.28.0.129')
        self.assertFalse(ipAddress in self.privateLink)    

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.129" -CIDRAddress "10.28.1.0/27"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual)

        ipAddress = IPv4Address('10.28.1.36')
        self.assertFalse(ipAddress in self.privateLink)    

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.1.36" -CIDRAddress "10.28.1.0/27"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual)     

        ipAddress = IPv4Address('10.28.1.5') 
        self.assertTrue(ipAddress in self.privateLink)

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "10.28.1.5" -CIDRAddress "10.28.1.0/27"').runPsCommand().strip().lower() == "true"
        self.assertTrue(psCmdActual)

class TestCompareCIDRPrivateClassC(unittest.TestCase):
    """
    Testing Private Class C IPv4 Addresses with a subnet range of 192.168.1.0 to 192.168.1.255
    """
    def __init__(self, methodName):
        self.cidrRangePy = IPv4Network("192.168.1.0/24")
        super().__init__(methodName)

    def test_totalAddressCount(self):
        totalAddressExpected = 256
        
        self.assertEqual(self.cidrRangePy.num_addresses, totalAddressExpected)

        psCmdActual = PSCommand("Get-TotalCountOfIPAddress -subnetSuffixNum 24").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), totalAddressExpected)

    def test_networkIPAddressUInt(self):
        networkIpAddressNumExpected = 3232235776
        
        self.assertEqual(int(self.cidrRangePy.network_address), networkIpAddressNumExpected)

        psCmdActual = PSCommand("Get-NetworkIpAddressUInt -IpPrefixUInt 3232235776 -subnetMaskUInt 4294967040").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), networkIpAddressNumExpected)

    def test_broadcastIPAddressUInt(self):
        broadcastIpAddressNumExpected = 3232236031

        self.assertEqual(int(self.cidrRangePy.broadcast_address), broadcastIpAddressNumExpected)

        psCmdActual = PSCommand("Get-BroadcastIpAddressUInt -networkIpUInt 3232235776 -hostMaskUInt 255").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), broadcastIpAddressNumExpected)

    def test_subnetMaskUInt(self):
        subnetMaskNumExpected = 4294967040

        self.assertEqual(int(self.cidrRangePy.netmask), subnetMaskNumExpected)

        psCmdActual = PSCommand("Get-SubnetMaskUInt -SubnetSuffixNum 24").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), subnetMaskNumExpected)

    def test_HostMaskUInt(self):
        hostMaskNumExpected = 255

        self.assertEqual(int(self.cidrRangePy.hostmask), hostMaskNumExpected)

        psCmdActual = PSCommand("Get-HostMaskUInt -HostBits 8").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), hostMaskNumExpected)

    def test_CompareSubnets(self):
        cidrRangePy2 = IPv4Network("192.168.1.128/25")
        self.assertTrue(self.cidrRangePy.overlaps(cidrRangePy2))

        psCmdActual = PSCommand('Compare-Subnets -CIDRAddressA "192.168.1.0/24" -CIDRAddressB "192.168.1.128/25"').runPsCommand().strip().lower() == "true"
        self.assertTrue(psCmdActual)

        cidrRangePy3 = IPv4Network("192.168.1.0/25")
        self.assertFalse(cidrRangePy3.overlaps(cidrRangePy2))

        psCmdActual = PSCommand('Compare-Subnets -CIDRAddressA "192.168.1.0/25" -CIDRAddressB "192.168.1.128/25"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual)

    def test_TestIPInSubnet(self):
        ipAddress = IPv4Address('192.168.1.0')
        self.assertTrue(ipAddress in self.cidrRangePy)

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "192.168.1.0" -CIDRAddress "192.168.1.0/24"').runPsCommand().strip().lower() == "true"
        self.assertTrue(psCmdActual)

        ipAddress = IPv4Address('192.168.2.254')
        self.assertFalse(ipAddress in self.cidrRangePy)

        psCmdActual = PSCommand('Test-IPInSubnet -IPStr "192.168.2.254" -CIDRAddress "192.168.1.0/24"').runPsCommand().strip().lower() == "true"
        self.assertFalse(psCmdActual)

class TestSubnets(unittest.TestCase):
    """
    Performing some min and max values of CIDR Subnet Prefix
    """
    def __init__(self, methodName):
        self.cidrRangePy = None
        self.subnetMaskNumExpected = None
        super().__init__(methodName)

    def test_zeroSuffix(self):
        self.subnetMaskNumExpected = 0

        self.cidrRangePy = IPv4Network("0.0.0.0/0")
        self.assertEqual(int(self.cidrRangePy.netmask), self.subnetMaskNumExpected)

        psCmdActual = PSCommand('Get-SubnetMaskUInt -SubnetSuffixNum 0').runPsCommand().strip()
        self.assertEqual(int(psCmdActual), self.subnetMaskNumExpected)

    def test_MaxSuffix(self):
        self.subnetMaskNumExpected = 4294967295
        
        self.cidrRangePy = IPv4Network("192.168.1.0/32")
        self.assertEqual(int(self.cidrRangePy.netmask), self.subnetMaskNumExpected)

        psCmdActual = PSCommand('Get-SubnetMaskUInt -SubnetSuffixNum 32').runPsCommand().strip()
        self.assertEqual(int(psCmdActual), self.subnetMaskNumExpected)


if __name__ == '__main__':
    unittest.main()