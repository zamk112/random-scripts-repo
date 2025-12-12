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
Unit testing CIDRSubnetting.ps1 script and comparing outputs to the ipaddress 
module with the IPv4Network class. Just doing private class A & C since this 
is what I use at home and work 😜.
"""

import unittest
from ipaddress import IPv4Network, IPv4Address
import subprocess
import os


class PSCommand:
    """
    Created the PSCommand class to run my powershell commands with the subprocess module, 
    the output and error pipes are all converted to text. So casting is needed to in order 
    to test for correctness.
    """
    def __init__(self, ps_cmd_let: str):
        """
        Constructor is used to initialise the path to the PowerShell Script file. and also 
        the PowerShell command to execute. psCmdLet is the cmdLet that's going to be 
        executed from the file.
        """
        # pylint: disable=line-too-long
        self.__ps_script_cmd_str = ". " + os.path.dirname(__file__) + os.sep + "IPv4CIDRSubnetting.ps1; " + ps_cmd_let
        self.__ps_cmd_lst = ["pwsh", "-Command", self.__ps_script_cmd_str]

    def run_ps_command(self) -> str:
        """
        Executing the PowerShell command using pipes where stdout and stderr back to results 
        variable where the output is of type string.
        """
        results = subprocess.run(
            self.__ps_cmd_lst,
            stdout=subprocess.PIPE,
            stderr= subprocess.PIPE,
            text=True,
            check=False
        )

        if results.returncode != 0:
            print(f"PowerShell Error: {results.stderr}")

        return results.stdout

class TestCompareCIDRPrivateClassA(unittest.TestCase):

    # pylint: disable=line-too-long
    """
    Testing Private Class A IPv4 Addresses with a subnet range of 10.28.0.0 to 10.28.255.255
    Subnet setup as per https://learn.microsoft.com/en-us/azure/databricks/security/network/classic/private-link-standard#create-vnet
    """
    def __init__(self, methodName):
        self.ip_address_space = IPv4Network("10.28.0.0/16")
        self.public_subnet = IPv4Network("10.28.0.0/25")
        self.private_subnet = IPv4Network("10.28.0.128/25")
        self.private_link = IPv4Network("10.28.1.0/27")
        super().__init__(methodName)

    def test_total_address_count(self):
        """Testing total address count"""
        # Testing IP Address Space
        total_address_expected = 65536

        self.assertEqual(self.ip_address_space.num_addresses, total_address_expected)

        ps_cmd_actual = PSCommand("Get-TotalCountOfIPAddress -subnetSuffixNum 16").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), total_address_expected)

        # Testing public subnet
        total_address_expected = 128

        self.assertEqual(self.public_subnet.num_addresses, total_address_expected)

        ps_cmd_actual = PSCommand("Get-TotalCountOfIPAddress -subnetSuffixNum 25").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), total_address_expected)

        # Testing private subnet
        self.assertEqual(self.private_subnet.num_addresses, total_address_expected)

        ps_cmd_actual = PSCommand("Get-TotalCountOfIPAddress -subnetSuffixNum 25").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), total_address_expected)

        # Testing private link
        total_address_expected = 32

        self.assertEqual(self.private_link.num_addresses, total_address_expected)

        ps_cmd_actual = PSCommand("Get-TotalCountOfIPAddress -subnetSuffixNum 27").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), total_address_expected)

    def test_network_ip_address_uint(self):
        """Testing network ip address as a numeric value"""
        # Testing IP Address space
        network_ip_address_num_expected = 169607168

        self.assertEqual(int(self.ip_address_space.network_address), network_ip_address_num_expected)

        ps_cmd_actual = PSCommand("Get-NetworkIpAddressUInt -IpPrefixUInt 169607169 -subnetMaskUInt 4294901760").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), network_ip_address_num_expected)

        # Testing public subnet
        self.assertEqual(int(self.public_subnet.network_address), network_ip_address_num_expected)

        ps_cmd_actual = PSCommand("Get-NetworkIpAddressUInt -IpPrefixUInt 169607169 -subnetMaskUInt 4294967168").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), network_ip_address_num_expected)

        # Testing private subnet
        network_ip_address_num_expected = 169607296

        self.assertEqual(int(self.private_subnet.network_address), network_ip_address_num_expected)

        ps_cmd_actual = PSCommand("Get-NetworkIpAddressUInt -IpPrefixUInt 169607296 -subnetMaskUInt 4294967168").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), network_ip_address_num_expected)

        # Testing Private Link Subnet
        network_ip_address_num_expected = 169607424

        self.assertEqual(int(self.private_link.network_address), network_ip_address_num_expected)

        ps_cmd_actual = PSCommand("Get-NetworkIpAddressUInt -IpPrefixUInt 169607424 -subnetMaskUInt 4294967264").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), network_ip_address_num_expected)

    def test_broadcast_ip_address_uint(self):
        """Testing broadcast ip address as a numeric value"""
        # Testing IP Address Space
        broadcast_ip_address_num_expected = 169672703

        self.assertEqual(int(self.ip_address_space.broadcast_address), broadcast_ip_address_num_expected)

        ps_cmd_actual = PSCommand("Get-BroadcastIpAddressUInt -networkIpUInt 169607168 -hostMaskUInt 65535").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), broadcast_ip_address_num_expected)

        # Testing public subnet
        broadcast_ip_address_num_expected = 169607295

        self.assertEqual(int(self.public_subnet.broadcast_address), broadcast_ip_address_num_expected)

        ps_cmd_actual = PSCommand("Get-BroadcastIpAddressUInt -networkIpUInt 169607168 -hostMaskUInt 127").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), broadcast_ip_address_num_expected)

        # Testing private subnet
        broadcast_ip_address_num_expected = 169607423

        self.assertEqual(int(self.private_subnet.broadcast_address), broadcast_ip_address_num_expected)

        ps_cmd_actual = PSCommand("Get-BroadcastIpAddressUInt -networkIpUInt 169607296 -hostMaskUInt 127").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), broadcast_ip_address_num_expected)

        # Testing private link
        broadcast_ip_address_num_expected = 169607455

        self.assertEqual(int(self.private_link.broadcast_address), broadcast_ip_address_num_expected)

        ps_cmd_actual = PSCommand("Get-BroadcastIpAddressUInt -networkIpUInt 169607424 -hostMaskUInt 31").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), broadcast_ip_address_num_expected)

    def test_subnet_mask_uint(self):
        """Testing subnet mask as a numeric value"""
        # Testing IP Address Space
        subnet_mask_num_expected = 4294901760

        self.assertEqual(int(self.ip_address_space.netmask), subnet_mask_num_expected)

        ps_cmd_actual = PSCommand("Get-SubnetMaskUInt -SubnetSuffixNum 16").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), subnet_mask_num_expected)

        # Testing Public & Private Subnets
        subnet_mask_num_expected = 4294967168
        self.assertEqual(int(self.public_subnet.netmask), subnet_mask_num_expected)
        self.assertEqual(int(self.private_subnet.netmask), subnet_mask_num_expected)

        ps_cmd_actual = PSCommand("Get-SubnetMaskUInt -SubnetSuffixNum 25").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), subnet_mask_num_expected)

        # Testing private link
        subnet_mask_num_expected = 4294967264
        self.assertEqual(int(self.private_link.netmask), subnet_mask_num_expected)

        ps_cmd_actual = PSCommand("Get-SubnetMaskUInt -SubnetSuffixNum 27").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), subnet_mask_num_expected)


    def test_host_mask_uint(self):
        """Testing host mask value as a numeric value"""
        # Testing IP Address Space
        host_mask_num_expected = 65535

        self.assertEqual(int(self.ip_address_space.hostmask), host_mask_num_expected)

        ps_cmd_actual = PSCommand("Get-HostMaskUInt -HostBits 16").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), host_mask_num_expected)

        # Testing public and private subnet
        host_mask_num_expected = 127

        self.assertEqual(int(self.public_subnet.hostmask), host_mask_num_expected)

        ps_cmd_actual = PSCommand("Get-HostMaskUInt -HostBits 7").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), host_mask_num_expected)

        # Testing private link
        host_mask_num_expected = 31

        self.assertEqual(int(self.private_link.hostmask), host_mask_num_expected)

        ps_cmd_actual = PSCommand("Get-HostMaskUInt -HostBits 5").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), host_mask_num_expected)

    def test_compare_subnets(self):
        """Testing subnet overlaps and comparison"""
        # Test if subnets are in IP Address Space
        self.assertTrue(self.ip_address_space.overlaps(self.public_subnet))

        ps_cmd_actual = PSCommand('Compare-Subnets -CIDRAddressA "10.28.0.0/16" -CIDRAddressB "10.28.0.0/25"').run_ps_command().strip().lower() == "true"
        self.assertTrue(ps_cmd_actual)

        self.assertTrue(self.ip_address_space.overlaps(self.private_subnet))

        ps_cmd_actual = PSCommand('Compare-Subnets -CIDRAddressA "10.28.0.0/16" -CIDRAddressB "10.28.0.128/25"').run_ps_command().strip().lower() == "true"
        self.assertTrue(ps_cmd_actual)

        self.assertTrue(self.ip_address_space.overlaps(self.private_link))

        ps_cmd_actual = PSCommand('Compare-Subnets -CIDRAddressA "10.28.0.0/16" -CIDRAddressB "10.28.1.0/27"').run_ps_command().strip().lower() == "true"
        self.assertTrue(ps_cmd_actual)

        # Test if public subnet overlaps private subnet or private link
        self.assertFalse(self.public_subnet.overlaps(self.private_subnet))

        ps_cmd_actual = PSCommand('Compare-Subnets -CIDRAddressA "10.28.0.0/25" -CIDRAddressB "10.28.0.128/25"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

        self.assertFalse(self.public_subnet.overlaps(self.private_link))

        ps_cmd_actual = PSCommand('Compare-Subnets -CIDRAddressA "10.28.0.0/25" -CIDRAddressB "10.28.1.0/27"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

    def test_ip_in_subnet(self):
        """Testing if IP Address is in a given subnet"""
        # Check IP address in IP Address Space
        ip_address = IPv4Address('10.28.0.23')
        self.assertTrue(ip_address in self.ip_address_space)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.23" -CIDRAddress "10.28.0.0/16"').run_ps_command().strip().lower() == "true"
        self.assertTrue(ps_cmd_actual)

        ip_address = IPv4Address('10.29.2.128')
        self.assertFalse(ip_address in self.ip_address_space)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.29.2.128" -CIDRAddress "10.28.0.0/16"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

        ip_address = IPv4Address('10.28.1.200')
        self.assertTrue(ip_address in self.ip_address_space)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.200" -CIDRAddress "10.28.0.0/16"').run_ps_command().strip().lower() == "true"
        self.assertTrue(ps_cmd_actual)

        # Check IP address in Public Subnet
        ip_address = IPv4Address('10.28.0.23')
        self.assertTrue(ip_address in self.public_subnet)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.23" -CIDRAddress "10.28.0.0/25"').run_ps_command().strip().lower() == "true"
        self.assertTrue(ps_cmd_actual)

        ip_address = IPv4Address('10.28.0.129')
        self.assertFalse(ip_address in self.public_subnet)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.129" -CIDRAddress "10.28.0.0/25"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

        ip_address = IPv4Address('10.28.1.36')
        self.assertFalse(ip_address in self.public_subnet)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.1.36" -CIDRAddress "10.28.0.0/25"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

        # Check IP in Private Subnet
        ip_address = IPv4Address('10.28.0.23')
        self.assertFalse(ip_address in self.private_link)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.23" -CIDRAddress "10.28.0.128/25"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

        ip_address = IPv4Address('10.28.0.129')
        self.assertFalse(ip_address in self.private_link)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.129" -CIDRAddress "10.28.0.128/25"').run_ps_command().strip().lower() == "true"
        self.assertTrue(ps_cmd_actual)

        ip_address = IPv4Address('10.28.1.36')
        self.assertFalse(ip_address in self.private_link)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.1.36" -CIDRAddress "10.28.0.128/25"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

        # Test IP in Private Link subnet
        ip_address = IPv4Address('10.28.0.23')
        self.assertFalse(ip_address in self.private_link)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.23" -CIDRAddress "10.28.1.0/27"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

        ip_address = IPv4Address('10.28.0.129')
        self.assertFalse(ip_address in self.private_link)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.0.129" -CIDRAddress "10.28.1.0/27"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

        ip_address = IPv4Address('10.28.1.36')
        self.assertFalse(ip_address in self.private_link)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.1.36" -CIDRAddress "10.28.1.0/27"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

        ip_address = IPv4Address('10.28.1.5')
        self.assertTrue(ip_address in self.private_link)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "10.28.1.5" -CIDRAddress "10.28.1.0/27"').run_ps_command().strip().lower() == "true"
        self.assertTrue(ps_cmd_actual)

class TestCompareCIDRPrivateClassC(unittest.TestCase):
    """
    Testing Private Class C IPv4 Addresses with a subnet range of 192.168.1.0 to 192.168.1.255
    """
    def __init__(self, methodName):
        self.cidr_range_py = IPv4Network("192.168.1.0/24")
        super().__init__(methodName)

    def test_total_address_count(self):
        """Testing total address count"""
        total_address_expected = 256

        self.assertEqual(self.cidr_range_py.num_addresses, total_address_expected)

        # pylint: disable=line-too-long
        ps_cmd_actual = PSCommand("Get-TotalCountOfIPAddress -subnetSuffixNum 24").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), total_address_expected)

    def test_network_ip_address_uint(self):
        """Testing network ip address as a numeric value"""
        network_ip_address_num_expected = 3232235776
        self.assertEqual(int(self.cidr_range_py.network_address), network_ip_address_num_expected)

        # pylint: disable=line-too-long
        ps_cmd_actual = PSCommand("Get-NetworkIpAddressUInt -IpPrefixUInt 3232235776 -subnetMaskUInt 4294967040").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), network_ip_address_num_expected)

    def test_broadcast_ip_address_uint(self):
        """Testing broadcast up address as a numeric value"""
        broadcast_ip_address_num_expected = 3232236031

        # pylint: disable=line-too-long
        self.assertEqual(int(self.cidr_range_py.broadcast_address), broadcast_ip_address_num_expected)

        ps_cmd_actual = PSCommand("Get-BroadcastIpAddressUInt -networkIpUInt 3232235776 -hostMaskUInt 255").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), broadcast_ip_address_num_expected)

    def test_subnet_mask_uint(self):
        """Testing subnet mask as a numeric value"""
        subnet_mask_num_expected = 4294967040

        self.assertEqual(int(self.cidr_range_py.netmask), subnet_mask_num_expected)

        ps_cmd_actual = PSCommand("Get-SubnetMaskUInt -SubnetSuffixNum 24").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), subnet_mask_num_expected)

    def test_host_mask_uint(self):
        """Testing host mast as a numeric value"""
        host_mask_num_expected = 255

        self.assertEqual(int(self.cidr_range_py.hostmask), host_mask_num_expected)

        ps_cmd_actual = PSCommand("Get-HostMaskUInt -HostBits 8").run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), host_mask_num_expected)

    def test_compare_subnets(self):
        """Testing for subnet overlap and comparison"""
        cidr_range_py2 = IPv4Network("192.168.1.128/25")
        self.assertTrue(self.cidr_range_py.overlaps(cidr_range_py2))

        # pylint: disable=line-too-long
        ps_cmd_actual = PSCommand('Compare-Subnets -CIDRAddressA "192.168.1.0/24" -CIDRAddressB "192.168.1.128/25"').run_ps_command().strip().lower() == "true"
        self.assertTrue(ps_cmd_actual)

        cidr_range_py3 = IPv4Network("192.168.1.0/25")
        self.assertFalse(cidr_range_py3.overlaps(cidr_range_py2))

        ps_cmd_actual = PSCommand('Compare-Subnets -CIDRAddressA "192.168.1.0/25" -CIDRAddressB "192.168.1.128/25"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

    def test_ip_in_subnet(self):
        """Testing IP address in subnet"""
        ip_address = IPv4Address('192.168.1.0')
        self.assertTrue(ip_address in self.cidr_range_py)

        # pylint: disable=line-too-long
        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "192.168.1.0" -CIDRAddress "192.168.1.0/24"').run_ps_command().strip().lower() == "true"
        self.assertTrue(ps_cmd_actual)

        ip_address = IPv4Address('192.168.2.254')
        self.assertFalse(ip_address in self.cidr_range_py)

        ps_cmd_actual = PSCommand('Test-IPInSubnet -IPStr "192.168.2.254" -CIDRAddress "192.168.1.0/24"').run_ps_command().strip().lower() == "true"
        self.assertFalse(ps_cmd_actual)

class TestSubnets(unittest.TestCase):
    """
    Performing some min and max values of CIDR Subnet Prefix
    """
    def __init__(self, methodName):
        self.cidr_range_py = None
        self.subnet_mask_num_expected = None
        super().__init__(methodName)

    def test_zero_suffix(self):
        """Testing IP address CIDR with 0 suffix"""
        self.subnet_mask_num_expected = 0

        self.cidr_range_py = IPv4Network("0.0.0.0/0")
        self.assertEqual(int(self.cidr_range_py.netmask), self.subnet_mask_num_expected)

        ps_cmd_actual = PSCommand('Get-SubnetMaskUInt -SubnetSuffixNum 0').run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), self.subnet_mask_num_expected)

    def test_max_suffix(self):
        """Testing IP address CIDR with max suffix value"""
        self.subnet_mask_num_expected = 4294967295

        self.cidr_range_py = IPv4Network("192.168.1.0/32")
        self.assertEqual(int(self.cidr_range_py.netmask), self.subnet_mask_num_expected)

        ps_cmd_actual = PSCommand('Get-SubnetMaskUInt -SubnetSuffixNum 32').run_ps_command().strip()
        self.assertEqual(int(ps_cmd_actual), self.subnet_mask_num_expected)


if __name__ == '__main__':
    unittest.main()
