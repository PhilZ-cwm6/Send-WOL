<#
.SYNOPSIS
    Send-WOL v1.0.0 - released 01 sept 2021 by PhilZ-cwm6 @github.com
    Send a WOL packet to a broadcast address / port


.Description
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


.PARAMETER mac
    [Mandatory]
    The MAC address or Host alias of the devices to wake up
    It can be a list of mac addresses in the format of "Send-WOL -mac MAC1,MAC2,MAC3"
    Or piped like "$mac = "MAC1", "HOST2", "HOST3" | Send-WOL"


.PARAMETER ip
    [Optional, Default 255.255.255.255]
    Needed for a Directed-Brodcast
    The IP address of the device where the WOL packet will be sent
    Default is "This LAN" broadcast IP 255.255.255.255


.PARAMETER subnet
    [Optional, Default 255.255.255.0]
    In conjunction with a specific ip for a Directed-Brodcast
    Will brodcast to the specified IP LAN brodcast address
    Exp: Send-WOL -ip 192.168.100.10 -subnet 255.255.255.0
         sends a WOL packet to 192.168.100.255


.PARAMETER port
    [Optional, Default 9]
    Specify a custom port to send the WOL packet


.PARAMETER Verbose
    be Verbose and print detailed logs

.PARAMETER Debug
    Prints debugging code in Write-Debug

.PARAMETER LocalDebugPreference
    In conjunction with -Debug, sets debug option to either "SilentlyContinue", "Stop", "Continue", "Inquire", "Ignore", "Suspend", or "Break"

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


.LINK
    # AUTHOR
    PhilZ-cwm6 - https://github.com/PhilZ-cwm6/Send-WOL

    # HISTORY
        - v1.0.0, 01 sept 2021 : initial release


    # CREDITS
        - Chris Warwick, @cjwarwickps, January 2012 for 
        - Dr. Tobias Weltner, Apr 29, 2020
        - Aleksandar @Idera for the Get-BroadcastAddress Function
#>

Function Send-WOL {
[OutputType()]

    # Funcion arguments
    # - ValueFromPipeline : allow multiple arguments to be added through pipeline, exp: MAC1 MAC2 MAC3 | Send-WOL
    # - Mandatory=$True,Position=1 : the first argument ($mac) is mandatory
    # - $ip, $subnet and and $port: optional arguments, if not specified they will default to ip=255.255.255.255/24 and port=9
    Param (
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True)]
        [string[]]$mac,
        [string]$ip="255.255.255.255",
        [string]$subnet="255.255.255.0",
        [int]$port=9,
        [string]$LocalDebugPreference="SilentlyContinue"
    )

    Begin {
        # The following table contains aliases for hostnames to be resolved to a mac
        # - we can use -mac TrueNAS and it will resolve to the MAC we define here
        $StaticLookupTable=@{
            TrueNAS  = '00-01-02-03-04-AA'
            READYNAS = '01-02-03-04-05-AB'
            WORKSTATION = '02:23:45:67:89:AB'
        }

        # Create an UDP client $UdpClient Socket to connect to when sending the WOL packet
        $UdpClient = New-Object System.Net.Sockets.UdpClient

        # Set the debug preference to user option (Default is Continue to not prompt for entry when -Debug is used)
        $DebugPreference=$LocalDebugPreference
    }

    Process {
        Foreach ($MacString in $mac) {
            try {
                # Check to see if a known MAC alias has been specified; if so, substitute the corresponding address
                If ($StaticLookupTable.ContainsKey($MacString)) {
                    Write-Verbose -Message "Found '$MacString' in lookup table"
                    $MacString = $StaticLookupTable[$MacString]
                }

                # Validate the MAC address, 6 hex bytes separated by : or -
                If ($MacString -NotMatch '^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$') {
                    Write-Warning "Mac address '$MacString' is invalid and was skipped. MAC must be 6 hex bytes separated by : or -"
                    Write-Verbose ""
                    Continue
                } else {
                    Write-Verbose -Message "Using argument '$MacString'"
                }

                # Split and convert the MAC address to an array of bytes
                $MacBytes= $MacString.Split('-:') | Foreach {[Byte]"0x$_"}

                # WOL Packet is a byte array with the first six bytes 0xFF, followed by 16 copies of the MAC address
                $Packet = [Byte[]](,0xFF * 6) + ($MacBytes* 16)
                
                Write-Debug "Broadcast packet: $([BitConverter]::ToString($Packet))"

                $targetIP = [System.Net.IPAddress]::Parse($ip)
                $broadcastIP = (Get-BroadcastAddress -IPAddress $targetIP -SubnetMask $subnet).Result
                Write-Verbose "broadcastIP = $broadcastIP"

                # Send packets to the Broadcast address
                $UDPclient.Connect($broadcastIP, $port)
                [Void]$UdpClient.Send($Packet, $Packet.Length)
                Write-Verbose "Wake-on-Lan Packet sent to $MacString at ${broadcastIP}:${port}"
            } catch {
                Write-Error "Packet could not be sent to $MacString at ${broadcastIP}:${port}"
            }

            Write-Verbose ""
        }
    }

    End {
        $UdpClient.Close()
        $UdpClient.Dispose()
    }
}

# Function to return the brodcast address from an IP/subnet
function Get-BroadcastAddress {
    param (
        [Parameter(Mandatory=$true)]
        $IPAddress,
        $SubnetMask='255.255.255.0'
    )

    filter Convert-IP2Decimal {
        ([IPAddress][String]([IPAddress]$_)).Address
    }

    filter Convert-Decimal2IP {
        ([System.Net.IPAddress]$_).IPAddressToString 
    }

    [UInt32]$ip = $IPAddress | Convert-IP2Decimal
    [UInt32]$subnet = $SubnetMask | Convert-IP2Decimal
    [UInt32]$broadcast = $ip -band $subnet 
    $broadcastIP = $broadcast -bor -bnot $subnet | Convert-Decimal2IP

    New-Object psobject -Property @{
        Message = ""# not used
        Result = $broadcastIP
    }
}
