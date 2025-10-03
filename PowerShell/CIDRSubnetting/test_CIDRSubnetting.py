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
"""

import unittest
from ipaddress import IPv4Network
import subprocess
import os

class PSCommand:

    def __init__(self, psCmdLet: str):
        self.__psScriptCmdStr = ". " + os.path.dirname(__file__) + os.sep + "CIDRSubnetting.ps1; " + psCmdLet
        self.__psCmdLst = ["pwsh", "-Command", self.__psScriptCmdStr]

    def runPsCommand(self) -> str:
        results = subprocess.run(
            self.__psCmdLst,
            stdout=subprocess.PIPE,
            stderr= subprocess.PIPE,
            text=True
        )

        if results.returncode != 0:
            print("PowerShell Error: %s" % (results.stderr))

        return results.stdout


class TestCompareCIDR(unittest.TestCase):

    def __init__(self, methodName):
        self.cidrRangePy = IPv4Network("192.168.1.0/24")
        super().__init__(methodName)

    def test_totalAddressCount(self):
        totalAddressExpected = 256
        
        self.assertEqual(self.cidrRangePy.num_addresses, totalAddressExpected)

        psCmdActual = PSCommand("Get-TotalCountOfIPAddress -subnetSuffixNum 24").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), totalAddressExpected)

    def test_networkIPAddress(self):
        networkIpAddressNumExpected = 3232235776
        
        self.assertEqual(int(self.cidrRangePy.network_address), networkIpAddressNumExpected)

        psCmdActual = PSCommand("Get-NetworkIpAddress -IpPrefixNum 3232235776 -subnetMaskUInt 4294967040").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), networkIpAddressNumExpected)

    def test_broadcastIPAddress(self):
        broadcastIpAddressNumExpected = 3232236031

        self.assertEqual(int(self.cidrRangePy.broadcast_address), broadcastIpAddressNumExpected)

        psCmdActual = PSCommand("Get-BroadcastIpAddress -networkIpUInt 3232235776 -totalAddresses 256").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), broadcastIpAddressNumExpected)

    def test_subnetMaskUInt(self):
        subnetMaskNumExpected = 4294967040

        self.assertEqual(int(self.cidrRangePy.netmask), subnetMaskNumExpected)

        psCmdActual = PSCommand("Get-SubnetMaskUInt -SubnetSuffixInt 24").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), subnetMaskNumExpected)

    def test_HostMaskUInt(self):
        hostMaskNumExpected = 255

        self.assertEqual(int(self.cidrRangePy.hostmask), hostMaskNumExpected)

        psCmdActual = PSCommand("Get-HostMaskUInt -HostBits 8").runPsCommand().strip()
        self.assertEqual(int(psCmdActual), hostMaskNumExpected)

    def test_CompareSubnets(self):
        cidrRangePy2 = IPv4Network("192.168.1.128/25")
        self.assertTrue(self.cidrRangePy.overlaps(cidrRangePy2))

        psCmdActual = PSCommand('Compare-Subnets -CIDRAddressA "192.168.1.0/24" -CIDRAddressB "192.168.1.128/25"').runPsCommand().strip()
        self.assertTrue(bool(psCmdActual))


if __name__ == '__main__':
    unittest.main()