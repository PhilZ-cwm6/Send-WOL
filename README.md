# .SYNOPSIS
    Send-WOL v1.0.3 by PhilZ-cwm6 https://github.com/PhilZ-cwm6/Send-WOL


# .DESCRIPTION
    Send Wake on Lan (WOL) packet via UDP to either :
        - this LAN Broadcast addresses (255.255.255.255) on default Port 9
        - a specified LAN brodcast address (exp. 192.168.10.255) on default Port 9
        - a user specified brodcast IP/Subnet and/or port number

    Edit the $StaticLookupTable entries to use a Host name alias instead of the MAC address


# .PARAMETER mac
    [Mandatory]
    The MAC address or Host alias of the devices to wake up
    It can be a list of mac addresses in the format of "Send-WOL -mac MAC1,MAC2,MAC3"
    Or piped like "$mac = "MAC1", "HOST2", "HOST3" | Send-WOL"


# .PARAMETER ip
    [Optional, Default 255.255.255.255]
    Needed for a Directed-Brodcast
    The IP address of the device where the WOL packet will be sent
    Default is "This LAN" broadcast IP 255.255.255.255


# .PARAMETER subnet
    [Optional, Default 255.255.255.0]
    In conjunction with a specific ip for a Directed-Brodcast
    Will brodcast to the specified IP LAN brodcast address
    Exp: Send-WOL -ip 192.168.100.10 -subnet 255.255.255.0
         sends a WOL packet to 192.168.100.255


# .PARAMETER port
    [Optional, Default 9]
    Specify a custom port to send the WOL packet


# .PARAMETER Verbose
    be Verbose and print detailed logs

# .PARAMETER Debug
    Prints debugging code in Write-Debug

# .PARAMETER LocalDebugPreference
    In conjunction with -Debug, sets debug option to either "SilentlyContinue", "Stop", "Continue", "Inquire", "Ignore", "Suspend", or "Break"

# .EXAMPLE
    Get-Help -Name Send-WOL -Full
    # print full help

# .EXAMPLE
    Send-WOL -Verbose 01:23:45:67:89:AB, AA:23:45:67:89:AB, CD:23:45:67:89:AB
    # sends a WOL packet to "This LAN" brodcast address 255.255.255.255 on default port 9, destined to devices with MAC 01:23:45:67:89:AB AA:23:45:67:89:AB and CD:23:45:67:89:AB
    # in addition, it verbosely prints detailed logs

# .EXAMPLE
    Send-WOL 01:23:45:67:89:AB, AA:23:45:67:89:AB, CD:23:45:67:89:AB -port 7
    # sends a WOL packet to "This LAN" brodcast address 255.255.255.255 on port 7, destined to devices with MAC 01:23:45:67:89:AB AA:23:45:67:89:AB and CD:23:45:67:89:AB

# .EXAMPLE
    Send-WOL -mac 01:23:45:67:89:AB -ip 192.168.8.3
    # sends a WOL packet to 192.168.8.255 brodcast address on default port 9, destined to device with MAC 01:23:45:67:89:AB

# .EXAMPLE
    Send-WOL -mac TrueNAS,WORKSTATION -ip 192.168.8.3 -subnet 255.255.255.0 -port 7
    # sends a WOL packet to 192.168.8.255 brodcast address on port 7, destined to hosts with name aliases TrueNAS and WORKSTATION
    # !! TrueNAS and WORKSTATION MAC addresses must be hardcoded in script !!

# .EXAMPLE
    $mac = "TrueNAS", "Workstation" | Send-WOL -Verbose -port 7 -ip 10.20.30.0
    # sends a WOL packet to 10.20.30.255 brodcast address on port 7, destined to hosts with name aliases TrueNAS and WORKSTATION
    # be Verbose and print detailed logs

# .EXAMPLE
    Send-WOL -Verbose -Debug -LocalDebugPreference Inquire -mac TrueNAS, Workstation -ip 10.20.30.1 -subnet 255.255.255.0 -port 9
    # sends a WOL packet to 10.20.30.255 brodcast address on port 7, destined to hosts with name aliases TrueNAS and WORKSTATION
    # be Verbose and print detailed logs
    # print debug code and prompt after each debug line

# .History :
    - v1.0.0, 01 sept 2021 : initial release
    - v1.0.1, 02 sept 2021 : support WOL by calling the script, no need to source the Send-WOL function first
    - v1.0.2, 03 sept 2021 : fix Powershell v7 compatibility syntax in split. Do not use global context so that we can source from other scripts
    - v1.0.3, 04 sept 2021 : fix calling WOL by script name without sourcing it

# .Credits :
    - Chris Warwick, @cjwarwickps, January 2012 / Dr. Tobias Weltner, Apr 29, 2020
    - Aleksandar @Idera for the Get-BroadcastAddress Function
