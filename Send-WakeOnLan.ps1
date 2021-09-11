<#
.SYNOPSIS
    Send-WOL by PhilZ-cwm6 https://github.com/PhilZ-cwm6/Send-WOL


.DESCRIPTION
    For a full help, first source the script by typing '. ./path/to/script.ps1'
    Then type: 'Get-Help Send-WOL -Full'


.LINK
    # History :
        - v1.0.0, 01 sept 2021 : initial release
        - v1.0.1, 02 sept 2021 : support WOL by calling the script, no need to source the Send-WOL function first
        - v1.0.2, 03 sept 2021 : fix Powershell v7 compatibility syntax in split. Do not use global context so that we can source from other scripts
        - v1.0.3, 04 sept 2021 : fix calling WOL by script name without sourcing it
        - v1.0.4, 06 sept 2021 : support optional BurnToast Notifications module, fix log message when using multiple mac entries
        - v1.0.5, 09 sept 2021 : optimize logging output and fix help display when sourcing the Send-WOL function
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
    [string]$InformationPreference="Continue",
    [string]$VerbosePreference="SilentlyContinue",
    [string]$DebugPreference="SilentlyContinue"
)

# BurnToast module notification custom icons path (edit to full path as needed)
$SendWOL_Success = "D:\My Docs\FreeFileSync Job\send_notification_logo_wol.png"
$SendWOL_Warn = "D:\My Docs\FreeFileSync Job\send_notification_logo_warn.png"
$SendWOL_Error = "D:\My Docs\FreeFileSync Job\send_notification_logo_error.png"


Function Send-WOL {
<#
.SYNOPSIS
    Send-WOL v1.0.5 by PhilZ-cwm6 https://github.com/PhilZ-cwm6/Send-WOL


.DESCRIPTION
    Send Wake on Lan (WOL) packet via UDP to either :
        - default: this LAN Broadcast addresses (255.255.255.255) on Port 9
        - a user specified brodcast IP/Subnet and/or port number
    Edit the $StaticLookupTable entries to use a Host name alias instead of the MAC address
    Also sends a Notification in Windows if the optional BurnToast module is installed


.PARAMETER mac
    [Mandatory], The MAC address or Host alias of the devices to wake up
    It can be a list of mac addresses in the format of "Send-WOL -mac MAC1,MAC2,MAC3"
    Or piped like "$mac = "MAC1", "HOST2", "HOST3" | Send-WOL"

.PARAMETER ip
    Needed for a Directed-Brodcast to a device IP address. Default is "This LAN" broadcast address 255.255.255.255

.PARAMETER subnet
    Use in conjunction with a specific ip for a Directed-Brodcast. Default is 255.255.255.0
    Exp: Send-WOL Workstation -ip 192.168.100.10 -subnet 255.255.255.0
         sends a WOL packet for Workstation MAC address to 192.168.100.255:9

.PARAMETER port
    Specify a custom port to send the WOL packet. Default is port 9

.PARAMETER InformationPreference
    [SilentlyContinue|Stop|Continue|Inquire|Ignore|Suspend|Break]
    Default=Continue ; Dispplay informational messages to stdout and console (Write-Information)

.PARAMETER VerbosePreference
    [SilentlyContinue|Stop|Continue|Inquire|Ignore|Suspend|Break]
    -Verbose = -VerbosePreference "Continue". Print Write-Verbose logs. Default=SilentlyContinue

.PARAMETER DebugPreference
    [SilentlyContinue|Stop|Continue|Inquire|Ignore|Suspend|Break]
    -Debug = -DebugPreference "Continue". Print Write-Debug logs. Default=SilentlyContinue


.EXAMPLE
    Get-Help -Name Send-WOL -Full | Send-WOL -?
    # print full help

.EXAMPLE
    Send-WOL 01:23:45:67:89:AB, AA:23:45:67:89:AB, CD:23:45:67:89:AB
    # send WOL to "This LAN" brodcast address 255.255.255.255 on default port 9, destined to the 3 specified MAC addresses

.EXAMPLE
    Send-WOL -mac 01:23:45:67:89:AB -ip 192.168.8.3 -port 7
    # send WOL to 192.168.8.255 brodcast address on port 7, destined to specified MAC

.EXAMPLE
    Send-WOL -mac Computer1,WORKSTATION -ip 192.168.8.3 -subnet 255.255.255.0 -port 7
    # send WOL to 192.168.8.255 brodcast address on port 7, destined to hosts with name aliases Computer1 and WORKSTATION
    # !! Computer1 and WORKSTATION MAC addresses must be hardcoded in script !!

.EXAMPLE
    $mac = "Computer1", "WORKSTATION" | Send-WOL -Verbose -port 7 -ip 10.20.30.0
    # sends a WOL packet to 10.20.30.255 brodcast address on port 7, destined to hosts with name aliases Computer1 and WORKSTATION
    # be verbose and print detailed logs

.EXAMPLE
    Send-WOL -Verbose -DebugPreference Inquire -mac Computer1, WORKSTATION -ip 10.20.30.1 -subnet 255.255.255.0 -port 9
    # sends a WOL packet to 10.20.30.255 brodcast address on port 7, destined to hosts with name aliases Computer1 and WORKSTATION
    # be verbose to print detailed logs. Print debug code and prompt after each debug line
#>

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
        [string]$InformationPreference="Continue",
        [string]$VerbosePreference="SilentlyContinue",
        [string]$DebugPreference="SilentlyContinue"
    )

    Begin {
        Write-Debug -Message "Rceived: Send-WOL -mac $mac -ip $ip -subnet $subnet -port $port -InformationPreference $InformationPreference -VerbosePreference $VerbosePreference -DebugPreference $DebugPreference"

        # The following table contains aliases for hostnames to be resolved to a mac
        # - we can use -mac WORKSTATION and it will resolve to the MAC we define here
        $StaticLookupTable=@{
            WORKSTATION = '02:23:45:67:89:AB'
            Computer1 = '01-02-03-04-05-AB'
        }

        # Create an UDP client $UdpClient Socket to connect to when sending the WOL packet
        $UdpClient = New-Object System.Net.Sockets.UdpClient

    }

    Process {
        Foreach ($MacString in $mac) {
            try
            {
                $MacAddress = $MacString

                # Check to see if a known MAC alias has been specified; if so, substitute the corresponding address
                If ($StaticLookupTable.ContainsKey($MacString)) {
                    $MacAddress = $StaticLookupTable[$MacString]
                    Write-Information "Found '$MacString' MAC Address: '$MacAddress'"
                }

                # Validate the MAC address, 6 hex bytes separated by : or -
                If ($MacAddress -NotMatch '^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$') {
                    $log_msg = "Ignored invalid MAC address '$MacAddress'. MAC must be 6 hex bytes separated by : or -"
                    Write-Warning "$log_msg"
                    Write-Information ""
                    Send-BurnToasrNotification -UID "Send_WOL_$MacString" -Title "Send-WOL" -Text1 "Send-WOL to $MacString" -Text2 "$log_msg" -Logo "$SendWOL_Warn"
                    Continue
                } elseif ($MacString -eq $MacAddress) {
                    Write-Information "Sending WOL to MAC address '$MacAddress'"
                }

                # Split and convert the MAC address to an array of bytes
                $MacBytesArray = $MacAddress -split '[:-]' | ForEach-Object { [System.Convert]::ToByte($_, 16) }
                # $MacBytesArray = $MacAddress -split '[:-]' | ForEach-Object { [Byte] "0x$_"}

                # WOL Packet is a byte array with the first six bytes 0xFF, followed by 16 copies of the MAC address
                $Packet = [Byte[]](,0xFF * 6) + ($MacBytesArray * 16)
                
                Write-Debug "Broadcast packet: $([BitConverter]::ToString($Packet))"

                $targetIP = [System.Net.IPAddress]::Parse($ip)
                $broadcastIP = (Get-BroadcastAddress -IPAddress $targetIP -SubnetMask $subnet).Result
                Write-Verbose "Using broadcastIP '$broadcastIP' and port number $port"

                # Send packets to the Broadcast address
                $UDPclient.Connect($broadcastIP, $port)
                [Void]$UdpClient.Send($Packet, $Packet.Length)

                $log_msg = "WOL Packet sent to $MacString at ${broadcastIP}:${port}"
                Write-Information "$log_msg"
                Send-BurnToasrNotification -UID "Send_WOL_$MacString" -Title "Send-WOL" -Text1 "Send-WOL to $MacString" -Text2 "$log_msg" -Logo "$SendWOL_Success"
            } catch {
                $ErrorMsg = $Error[0]
                $log_msg = "Failed to send WOL to $MacString at ${broadcastIP}:${port}"
                Write-Error "$log_msg"
                Write-Error "$ErrorMsg"
                Send-BurnToasrNotification -UID "Send_WOL_$MacString" -Title "Send-WOL" -Text1 "Send-WOL to $MacString" -Text2 "$ErrorMsg" -Text3 "$log_msg" -Logo "$SendWOL_Error"
            }

            Write-Information ""
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
    Send-WOL -mac $mac -ip $ip -subnet $subnet -port $port -InformationPreference $InformationPreference -VerbosePreference $VerbosePreference -DebugPreference $DebugPreference
} else {
    Write-Output "Send-WOL. Load module with:"
    Write-Output ". `"$PSCommandPath`""
    Write-Output "Then, use Send-WOL -? for help"
}
