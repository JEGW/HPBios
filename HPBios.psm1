function Set-HPBiosPassword {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [string[]] $ComputerName,

        [Parameter(Mandatory)]
        [string] $CurrentPassword,

        [Parameter(Mandatory)]
        [string] $NewPassword
    )

    begin {
        $arguments = @{
            Name = 'Setup Password'
            Password = "<utf-16/>$CurrentPassword"
            Value = "<utf-16/>$NewPassword"
        }

        if (-not $PSBoundParameters.ContainsKey('ComputerName')) {
            $ComputerName = $env:COMPUTERNAME
        }
    }

    process {
        foreach ($computer in $ComputerName) {
            do {
                Write-Verbose "Connecting to $computer on Wsman"
                $protocol = 'Wsman'

                try {
                    $option = New-CimSessionOption -Protocol $protocol
                    $sessionParams = @{
                        ComputerName = $computer
                        SessionOption = $option
                        ErrorAction = 'Stop'
                    }
                    $session = New-CimSession @sessionParams

                    $gcimParams = @{
                        Namespace = 'root/HP/InstrumentedBIOS'
                        ClassName = 'HP_BIOSSettingInterface'
                        CimSession = $session
                    }
                    $biosClass = Get-CimInstance @gcimParams

                    Write-Verbose "Setting password on $computer"
                    $icimParams = @{
                        InputObject = $biosClass
                        Arguments = $arguments
                        MethodName = 'SetBIOSSetting'
                    }
                    $return = Invoke-CimMethod @icimParams

                    switch ($return.return) {
                        0 {$status = 'Success'}
                        1 {$status = 'Not Supported'}
                        2 {$status = 'Unspecified Error'}
                        3 {$status = 'Timeout'}
                        4 {$status = 'Failed'}
                        5 {$status = 'Invalid Parameter'}
                        6 {$status = 'Access Denied'}
                        default {$status = "Failed: $($return.return)"}
                    }

                    $obj = [pscustomobject] @{
                        ComputerName = $computer
                        Status = $status
                    }
                    Write-Output $obj

                    Write-Verbose "Closing connection to $computer"
                    $session | Remove-CimSession
                    $protocol = 'Stop'
                }
                catch {
                    switch ($protocol) {
                        'Wsman' {$protocol = 'Dcom'}
                        'Dcom'  {$protocol = 'Stop'}
                    }
                }
            }
            until ($protocol = 'Stop')
        }
    }
}

function Get-HPBiosSecureBoot {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [string[]] $ComputerName
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ComputerName')) {
            $ComputerName = $env:COMPUTERNAME
        }
    }

    process {
        foreach ($computer in $ComputerName) {
            do {
                Write-Verbose "Connecting to $computer on Wsman"
                $protocol = 'Wsman'

                try {
                    $option = New-CimSessionOption -Protocol $protocol
                    $sessionParams = @{
                        ComputerName = $computer
                        SessionOption = $option
                        ErrorAction = 'Stop'
                    }
                    $session = New-CimSession @sessionParams

                    $gcimParams = @{
                        Namespace = 'root/HP/InstrumentedBIOS'
                        ClassName = 'HP_BIOSSetting'
                        CimSession = $session
                        Filter = "Name = 'Configure Legacy Support and Secure Boot'"
                    }
                    $secureBoot = Get-CimInstance @gcimParams

                    $obj = [pscustomobject] @{
                        'Name' = $secureBoot.Name
                        'CurrentValue' = $secureBoot.currentValue
                        'PossibleValues' = $secureBoot.possibleValues
                        'ComputerName' = $secureBoot.PSComputerName
                    }
                    Write-Output $obj

                    Write-Verbose "Closing connection to $computer"
                    $session | Remove-CimSession
                    $protocol = 'Stop'
                }
                catch {
                    switch ($protocol) {
                        'Wsman' {$protocol = 'Dcom'}
                        'Dcom'  {$protocol = 'Stop'}
                    }
                }
            }
            until ($protocol = 'Stop')
        }
    }
}

function Get-HPBiosVirtualization {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [string[]] $ComputerName
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('ComputerName')) {
            $ComputerName = $env:COMPUTERNAME
        }
    }

    process {
        foreach ($computer in $ComputerName) {
            do {
                Write-Verbose "Connecting to $computer on Wsman"
                $protocol = 'Wsman'

                try {
                    $option = New-CimSessionOption -Protocol $protocol
                    $sessionParams = @{
                        ComputerName = $computer
                        SessionOption = $option
                        ErrorAction = 'Stop'
                    }
                    $session = New-CimSession @sessionParams

                    $gcimParams = @{
                        Namespace = 'root/HP/InstrumentedBIOS'
                        ClassName = 'HP_BIOSSetting'
                        CimSession = $session
                        Filter = "Name LIKE '%virtual%'"
                    }
                    $virtual = Get-CimInstance @gcimParams
                    
                    foreach ($v in $virtual) {
                        $obj = [pscustomobject] @{
                            'Name' = $v.Name
                            'CurrentValue' = $v.currentValue
                            'PossibleValues' = $v.possibleValues
                            'ComputerName' = $v.PSComputerName
                        }
                        Write-Output $obj
                    }

                    Write-Verbose "Closing connection to $computer"
                    $session | Remove-CimSession
                    $protocol = 'Stop'
                }
                catch {
                    switch ($protocol) {
                        'Wsman' {$protocol = 'Dcom'}
                        'Dcom'  {$protocol = 'Stop'}
                    }
                }
            }
            until ($protocol = 'Stop')
        }
    }
}

function Get-HPComputer {
    [cmdletbinding()]
    param ()

    $searchBase = 'OU=Gowen Field,OU=AFCONUSCENTRAL,OU=Bases,DC=AREA52,DC=AFNOAPPS,DC=USAF,DC=MIL'
    $computers = (Get-ADComputer -Filter * -SearchBase $searchBase).Name

    foreach ($computer in $computers) {
        do {
            Write-Verbose "Connecting to $computer on Wsman"
            $protocol = 'Wsman'

            try {
                $option = New-CimSessionOption -Protocol $protocol
                $sessionParams = @{
                    ComputerName = $computer
                    SessionOption = $option
                    ErrorAction = 'Stop'
                }
                $session = New-CimSession @sessionParams

                $gcimParams = @{
                    ClassName = 'Win32_ComputerSystem'
                    CimSession = $session
                    Filter = "Manufacturer = 'HP'"
                    Property = 'Manufacturer'
                }
                $gcim = Get-CimInstance @gcimParams

                $obj = [pscustomobject] @{
                    'ComputerName' = $gcim.psComputerName
                    'Manufacturer' = $gcim.Manufacturer
                }
                Write-Output $obj

                Write-Verbose "Closing connection to $computer"
                $session | Remove-CimSession
                $protocol = 'Stop'
            }
            catch {
                switch ($protocol) {
                    'Wsman' {$protocol = 'Dcom'}
                    'Dcom'  {$protocol = 'Stop'}
                }
            }
        }
        until ($protocol = 'Stop')
    }
}
