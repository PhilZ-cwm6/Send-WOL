# .SYNOPSIS
    Send-WOL v1.0.5 by PhilZ-cwm6 https://github.com/PhilZ-cwm6/Send-WOL


# .DESCRIPTION
    Send Wake on Lan (WOL) packet via UDP to either :
        - default: this LAN Broadcast addresses (255.255.255.255) on Port 9
        - a user specified brodcast IP/Subnet and/or port number
    Edit the $StaticLookupTable entries to use a Host name alias instead of the MAC address
    Also sends a Notification in Windows if the optional BurnToast module is installed


# .PARAMETER mac
    [Mandatory], The MAC address or Host alias of the devices to wake up
    It can be a list of mac addresses in the format of "Send-WOL -mac MAC1,MAC2,MAC3"
    Or piped like "$mac = "MAC1", "HOST2", "HOST3" | Send-WOL"

# .PARAMETER ip
    Needed for a Directed-Brodcast to a device IP address. Default is "This LAN" broadcast address 255.255.255.255

# .PARAMETER subnet
    Use in conjunction with a specific ip for a Directed-Brodcast. Default is 255.255.255.0
    Exp: Send-WOL Workstation -ip 192.168.100.10 -subnet 255.255.255.0
         sends a WOL packet for Workstation MAC address to 192.168.100.255:9

# .PARAMETER port
    Specify a custom port to send the WOL packet. Default is port 9

# .PARAMETER InformationPreference
    [SilentlyContinue|Stop|Continue|Inquire|Ignore|Suspend|Break]
    Default=Continue ; Dispplay informational messages to stdout and console (Write-Information)

# .PARAMETER VerbosePreference
    [SilentlyContinue|Stop|Continue|Inquire|Ignore|Suspend|Break]
    -Verbose = -VerbosePreference "Continue". Print Write-Verbose logs. Default=SilentlyContinue

# .PARAMETER DebugPreference
    [SilentlyContinue|Stop|Continue|Inquire|Ignore|Suspend|Break]
    -Debug = -DebugPreference "Continue". Print Write-Debug logs. Default=SilentlyContinue


# .EXAMPLE
    Get-Help -Name Send-WOL -Full | Send-WOL -?
    # print full help

# .EXAMPLE
    Send-WOL 01:23:45:67:89:AB, AA:23:45:67:89:AB, CD:23:45:67:89:AB
    # send WOL to "This LAN" brodcast address 255.255.255.255 on default port 9, destined to the 3 specified MAC addresses

# .EXAMPLE
    Send-WOL -mac 01:23:45:67:89:AB -ip 192.168.8.3 -port 7
    # send WOL to 192.168.8.255 brodcast address on port 7, destined to specified MAC

# .EXAMPLE
    Send-WOL -mac Computer1,WORKSTATION -ip 192.168.8.3 -subnet 255.255.255.0 -port 7
    # send WOL to 192.168.8.255 brodcast address on port 7, destined to hosts with name aliases Computer1 and WORKSTATION
    # !! Computer1 and WORKSTATION MAC addresses must be hardcoded in script !!

# .EXAMPLE
    $mac = "Computer1", "WORKSTATION" | Send-WOL -Verbose -port 7 -ip 10.20.30.0
    # sends a WOL packet to 10.20.30.255 brodcast address on port 7, destined to hosts with name aliases Computer1 and WORKSTATION
    # be verbose and print detailed logs

# .EXAMPLE
    Send-WOL -Verbose -DebugPreference Inquire -mac Computer1, WORKSTATION -ip 10.20.30.1 -subnet 255.255.255.0 -port 9
    # sends a WOL packet to 10.20.30.255 brodcast address on port 7, destined to hosts with name aliases Computer1 and WORKSTATION
    # be verbose to print detailed logs. Print debug code and prompt after each debug line

# .LINK
    # History :
        - v1.0.0, 01 sept 2021 : initial release
        - v1.0.1, 02 sept 2021 : support WOL by calling the script, no need to source the Send-WOL function first
        - v1.0.2, 03 sept 2021 : fix Powershell v7 compatibility syntax in split. Do not use global context so that we can source from other scripts
        - v1.0.3, 04 sept 2021 : fix calling WOL by script name without sourcing it
        - v1.0.4, 06 sept 2021 : support optional BurnToast Notifications module, fix log message when using multiple mac entries
        - v1.0.5, 09 sept 2021 : optimize logging output and fix help display when sourcing the Send-WOL function
# .LINK
    # Credits :
        - Chris Warwick, @cjwarwickps, January 2012 / Dr. Tobias Weltner, Apr 29, 2020
        - Aleksandar @Idera for the Get-BroadcastAddress Function