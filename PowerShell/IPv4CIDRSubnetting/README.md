# Motivation
Since I started my new role at Microsoft as a Databricks Support Engineer, cloud networking is an essential part of Databricks and how customers customise their networking (using VNets, Private Link, Service Endpoints, etc.) to ingress and egress data. Most of my career has been focused on application support and development. Networking was not a really prerequisite for my work (well not a lot anyways). 

Now it is 😁, so I decided to re-learn how to do subnetting with CIDR addresses. So I decided to write a PowerShell script to relearn how to create subnets from an IP Address space. 

Later on, I discovered that Python has the `ipaddress` module, which performs all the tasks that my script `CIDRSubnetting.ps1` does 🤦🏽‍♂️. But the good thing is I can do some unit tests (see `test_CIDRSubnetting.py`) to compare with the `IPv4Network` class found in `ipaddress` module using the `subprocess` module to execute my PowerShell CmdLets. 

I know explicitly casting and/or parsing all my variables and parameters is overkill but it's a good remainder of what the types are especially when it comes to bitwise operations. Either way, good fun doing bitwise operations to get the blood flowing!