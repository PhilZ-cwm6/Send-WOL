# SYNOPSIS
    Send-WOL v1.0.0 - released 01 sept 2021 by PhilZ-cwm6 @github.com
    Send a WOL packet to a broadcast address / port


# Description
    Wake on Lan (WOL) uses a “Magic Packet” that consists of six bytes of 0xFF (the physical layer broadcast address),
    followed by 16 copies of the 6-byte (48-bit) target MAC address (see http://en.wikipedia.org/wiki/Wake-on-LAN).

    This packet is sent via UDP to either :
        + this LAN Broadcast addresses (255.255.255.255) on arbitrary Port 9
        + the specified LAN brodcast address (exp. 192.168.10.255) on default Port 9
        + a user specified brodcast IP/Subnet and/or port number

    Construction of this packet in PowerShell is very straight-forward: (“$Packet = [Byte[]](,0xFF*6)+($Mac*16)”).

    This script has a user editable table of saved MAC addresses to allow machine aliases to be specified as parameters to the
    function the real addresses have been obfuscated here) and uses a regex to validate MAC address strings.  The address
    aliases are contained in a hash table in the script - but they could very easily be obtained from an external source such as
    a text file or a CSV file (this is left as an exercise for the reader).


# Parameters
-mac
    [Mandatory]
    The MAC address or Host alias of the devices to wake up
    It can be a list of mac addresses in the format of "Send-WOL -mac MAC1,MAC2,MAC3"
    Or piped like "$mac = "MAC1", "HOST2", "HOST3" | Send-WOL"


-ip
    [Optional, Default 255.255.255.255]
    Needed for a Directed-Brodcast
    The IP address of the device where the WOL packet will be sent
    Default is "This LAN" broadcast IP 255.255.255.255


-subnet
    [Optional, Default 255.255.255.0]
    In conjunction with a specific ip for a Directed-Brodcast
    Will brodcast to the specified IP LAN brodcast address
    Exp: Send-WOL -ip 192.168.100.10 -subnet 255.255.255.0
         sends a WOL packet to 192.168.100.255


-port
    [Optional, Default 9]
    Specify a custom port to send the WOL packet


-Verbose
    be Verbose and print detailed logs

-Debug
    Prints debugging code in Write-Debug

-LocalDebugPreference
    In conjunction with -Debug, sets debug option to either "SilentlyContinue", "Stop", "Continue", "Inquire", "Ignore", "Suspend", or "Break"

# Examples
.EXAMPLE

    Get-Help -Name Send-WOL -Full
    # print full help

.EXAMPLE

    Send-WOL -Verbose 01:23:45:67:89:AB, AA:23:45:67:89:AB, CD:23:45:67:89:AB
    # sends a WOL packet to "This LAN" brodcast address 255.255.255.255 on default port 9, destined to devices with MAC 01:23:45:67:89:AB AA:23:45:67:89:AB and CD:23:45:67:89:AB
    # in addition, it verbosely prints detailed logs

.EXAMPLE

    Send-WOL 01:23:45:67:89:AB, AA:23:45:67:89:AB, CD:23:45:67:89:AB -port 7
    # sends a WOL packet to "This LAN" brodcast address 255.255.255.255 on port 7, destined to devices with MAC 01:23:45:67:89:AB AA:23:45:67:89:AB and CD:23:45:67:89:AB

.EXAMPLE

    Send-WOL -mac 01:23:45:67:89:AB -ip 192.168.8.3
    # sends a WOL packet to 192.168.8.255 brodcast address on default port 9, destined to device with MAC 01:23:45:67:89:AB

.EXAMPLE

    Send-WOL -mac TrueNAS,WORKSTATION -ip 192.168.8.3 -subnet 255.255.255.0 -port 7
    # sends a WOL packet to 192.168.8.255 brodcast address on port 7, destined to hosts with name aliases TrueNAS and WORKSTATION
    # !! TrueNAS and WORKSTATION MAC addresses must be hardcoded in script !!

.EXAMPLE
    $mac = "TrueNAS", "Workstation" | Send-WOL -Verbose -port 7 -ip 10.20.30.0
    # sends a WOL packet to 10.20.30.255 brodcast address on port 7, destined to hosts with name aliases TrueNAS and WORKSTATION
    # be Verbose and print detailed logs

.EXAMPLE

    Send-WOL -Verbose -Debug -LocalDebugPreference Inquire -mac TrueNAS, Workstation -ip 10.20.30.1 -subnet 255.255.255.0 -port 9
    # sends a WOL packet to 10.20.30.255 brodcast address on port 7, destined to hosts with name aliases TrueNAS and WORKSTATION
    # be Verbose and print detailed logs
    # print debug code and prompt after each debug line


# AUTHOR
    PhilZ-cwm6 - https://github.com/PhilZ-cwm6/Send-WOL

# HISTORY
    - v1.0.0, 01 sept 2021 : initial release

# CREDITS
    - Chris Warwick, @cjwarwickps, January 2012 for 
    - Dr. Tobias Weltner, Apr 29, 2020
    - Aleksandar @Idera for the Get-BroadcastAddress Function
