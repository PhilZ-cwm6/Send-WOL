<#
.SYNOPSIS
    Send-WOL v1.0.4 by PhilZ-cwm6 https://github.com/PhilZ-cwm6/Send-WOL


.DESCRIPTION
    Send Wake on Lan (WOL) packet via UDP to either :
        - this LAN Broadcast addresses (255.255.255.255) on default Port 9
        - a specified LAN brodcast address (exp. 192.168.10.255) on default Port 9
        - a user specified brodcast IP/Subnet and/or port number
    Edit the $StaticLookupTable entries to use a Host name alias instead of the MAC address
    Also sends a Notification in Windows if the optional BurnToast module is installed


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
    # History :
        - v1.0.0, 01 sept 2021 : initial release
        - v1.0.1, 02 sept 2021 : support WOL by calling the script, no need to source the Send-WOL function first
        - v1.0.2, 03 sept 2021 : fix Powershell v7 compatibility syntax in split. Do not use global context so that we can source from other scripts
        - v1.0.3, 04 sept 2021 : fix calling WOL by script name without sourcing it
        - v1.0.4, 06 sept 2021 : support optional BurnToast Notifications module, fix log message when using multiple mac entries
.LINK
    # Credits :
        - Chris Warwick, @cjwarwickps, January 2012 / Dr. Tobias Weltner, Apr 29, 2020
        - Aleksandar @Idera for the Get-BroadcastAddress Function
#>


# Parameters when calling the script through script file name and not by sourcing it as a module
Param (
    [Parameter(Position=1)]
    [string[]]$mac,
    [string]$ip="255.255.255.255",
    [string]$subnet="255.255.255.0",
    [int]$port=9,
    [string]$LocalDebugPreference="SilentlyContinue"
)

# BurnToast module notification custom icons path (edit to full path as needed)
$SendWOL_Success = ".\send_notification_logo_wol.png"
$SendWOL_Warn = ".\send_notification_logo_warn.png"
$SendWOL_Error = ".\send_notification_logo_error.png"

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
        Write-Debug -Message "Rceived: Send-WOL -mac $mac -ip $ip -subnet $subnet -port $port -LocalDebugPreference $LocalDebugPreference"

        # The following table contains aliases for hostnames to be resolved to a mac
        # - we can use -mac TrueNAS and it will resolve to the MAC we define here
        $StaticLookupTable=@{
            TrueNAS  = '00-01-02-03-04-AA'
            WORKSTATION = '02:23:45:67:89:AB'
            Computer1 = '01-02-03-04-05-AB'
        }

        # Create an UDP client $UdpClient Socket to connect to when sending the WOL packet
        $UdpClient = New-Object System.Net.Sockets.UdpClient

        # Set the debug preference to user option (Default is Continue to not prompt for entry when -Debug is used)
        $DebugPreference=$LocalDebugPreference
    }

    Process {
        Foreach ($MacString in $mac) {
            try
            {
                $MacAddress = $MacString

                # Check to see if a known MAC alias has been specified; if so, substitute the corresponding address
                If ($StaticLookupTable.ContainsKey($MacString)) {
                    $MacAddress = $StaticLookupTable[$MacString]
                    Write-Verbose -Message "Found '$MacString' MAC Address '$MacAddress' in lookup table"
                }

                # Validate the MAC address, 6 hex bytes separated by : or -
                If ($MacAddress -NotMatch '^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$') {
                    $log_msg = "Ignored invalid MAC address '$MacAddress'. MAC must be 6 hex bytes separated by : or -"
                    Write-Warning "$log_msg"
                    Write-Verbose ""
                    Send-BurnToasrNotification -UID "Send_WOL_$MacString" -Title "Send-WOL" -Text1 "Send-WOL to $MacString" -Text2 "$log_msg" -Logo "$SendWOL_Warn"
                    Continue
                } else {
                    Write-Verbose -Message "Using MAC '$MacAddress'"
                }

                # Split and convert the MAC address to an array of bytes
                $MacBytesArray = $MacAddress -split '[:-]' | ForEach-Object { [System.Convert]::ToByte($_, 16) }
                # $MacBytesArray = $MacAddress -split '[:-]' | ForEach-Object { [Byte] "0x$_"}

                # WOL Packet is a byte array with the first six bytes 0xFF, followed by 16 copies of the MAC address
                $Packet = [Byte[]](,0xFF * 6) + ($MacBytesArray * 16)
                
                Write-Debug "Broadcast packet: $([BitConverter]::ToString($Packet))"

                $targetIP = [System.Net.IPAddress]::Parse($ip)
                $broadcastIP = (Get-BroadcastAddress -IPAddress $targetIP -SubnetMask $subnet).Result
                Write-Debug "broadcastIP = $broadcastIP"

                # Send packets to the Broadcast address
                $UDPclient.Connect($broadcastIP, $port)
                [Void]$UdpClient.Send($Packet, $Packet.Length)

                $log_msg = "WOL Packet sent to $MacString at ${broadcastIP}:${port}"
                Write-Verbose "$log_msg"
                Send-BurnToasrNotification -UID "Send_WOL_$MacString" -Title "Send-WOL" -Text1 "Send-WOL to $MacString" -Text2 "$log_msg" -Logo "$SendWOL_Success"
            } catch {
                $ErrorMsg = $Error[0]
                $log_msg = "Failed to send WOL to $MacString at ${broadcastIP}:${port}"
                Write-Error "$log_msg"
                Write-Error "$ErrorMsg"
                Send-BurnToasrNotification -UID "Send_WOL_$MacString" -Title "Send-WOL" -Text1 "Send-WOL to $MacString" -Text2 "$ErrorMsg" -Text3 "$log_msg" -Logo "$SendWOL_Error"
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

# Function to send a BurnToast notification in Windows Notification Area
function Send-BurnToasrNotification {
    param (
        $UID="Send-WOL Notification",
        $Title="Send-WOL",
        $Text1="Log message",
        $Text2="",
        $Text3="",
        $Logo = "$SendWOL_Success"
    )

    # Do not error if BurntToast module is not installed
    if (Get-Module -ListAvailable -Name BurntToast) {
        $Header = New-BTHeader -ID 1 -Title "$Title"
        New-BurntToastNotification -UniqueIdentifier "$UID" -Header $Header -AppLogo "$Logo" -Text ("$Text1"), ("$Text2"), ("$Text3")
    }
}

# If script is started with args, always pass them to Script Scope Send-WOL function
# If script is started without args:
#  + if it was sourced to Global scope, only display module load success
#  + if it is not sourced to Global Scope, run Send-WOL function from Script Scope to display help

if ($PSBoundParameters.Count -gt 0) {
    Send-WOL -Verbose -mac $mac -ip $ip -subnet $subnet -port $port -LocalDebugPreference $LocalDebugPreference
} else {
    Write-Output "Send-WOL. Load module with:"
    Write-Output ". `"$PSCommandPath`""
    Write-Output "Then, use Send-WOL -? for help"
}
