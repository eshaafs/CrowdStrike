$Humio = @{ Cloud = ''; Token = '' }
switch ($Humio) {
    { $_.Cloud -and $_.Cloud -notmatch '/$' } { $_.Cloud += '/' }
    { ($_.Cloud -and !$_.Token) -or ($_.Token -and !$_.Cloud) } {
        throw "Both 'Cloud' and 'Token' are required when sending results to Humio."
    }
    { $_.Cloud -and $_.Cloud -notmatch '^https://cloud(.(community|us))?.humio.com/$' } {
        throw "'$($_.Cloud)' is not a valid Humio cloud value."
    }
    { $_.Token -and $_.Token -notmatch '^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$' } {
        throw "'$($_.Token)' is not a valid Humio ingest token."
    }
    { $_.Cloud -and $_.Token -and [Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12' } {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        } catch {
            throw $_
        }
    }
}
function grk ([string]$Str) {
    $Obj = foreach ($N in (Get-ChildItem 'Registry::\').PSChildName) {
        if ($N -eq 'HKEY_USERS') {
            foreach ($V in (Get-ChildItem "Registry::\$N" -EA 0 | Where-Object { $_.Name -match
            'S-\d-\d+-(\d+-){1,14}\d+$' }).PSChildName) {
                if (Test-Path "Registry::\$N\$V\$Str") { Get-ChildItem "Registry::\$N\$V\$Str" -EA 0 }
            }
        } elseif (Test-Path "Registry::\$N\$Str") {
            Get-ChildItem "Registry::\$N\$Str" -EA 0
        }
    }
    $Obj | ForEach-Object {
        $I = [PSCustomObject]@{}
        foreach ($P in $_.Property) {
            $I.PSObject.Properties.Add((New-Object PSNoteProperty($P,($_.GetValue($P)))))
        }
        $I
    }
}
function shumio ([string]$Script,[object[]]$Object,[string]$Cloud,[string]$Token) {
    if ($Object -and $Cloud -and $Token) {
        $Iwr = @{ Uri = $Cloud,'api/v1/ingest/humio-structured/' -join $null; Method = 'post';
            Headers = @{ Authorization = 'Bearer',$Token -join ' '; ContentType = 'application/json' }}
        $Att = @{ host = [System.Net.Dns]::GetHostName(); script = $Script }
        $Reg = reg query 'HKLM\SYSTEM\CurrentControlSet\Services\CSAgent\Sim' 2>$null
        if ($Reg) {
            $Att['cid'] = (($Reg -match 'CU ') -split 'REG_BINARY')[-1].Trim().ToLower()
            $Att['aid'] = (($Reg -match 'AG ') -split 'REG_BINARY')[-1].Trim().ToLower()
        }
        [object[]]$Event = @($Object).foreach{
            if ($_ -is [PSCustomObject]) {
                $Clone = $Att.Clone()
                @($_.PSObject.Properties).foreach{ $Clone[$_.Name]=$_.Value }
                ,@{ timestamp = Get-Date -Format o; attributes = $Clone }
            } else {
                ,@{ timestamp = Get-Date -Format o; attributes = $Att; rawstring = [string]$_ }
            }
        }
        if ($Event) {
            $Body = @{ tags = @{ source = 'crowdstrike-rtr_script' }; events = @($Event) }
            $Req = try {
                Invoke-WebRequest @Iwr -Body (ConvertTo-Json @($Body) -Depth 8) -UseBasicParsing
            } catch {}
            if (!$Req -or $Req.StatusCode -ne 200) {
                $Rtr = Join-Path $env:SystemRoot 'system32\drivers\CrowdStrike\Rtr'
                $Json = $Script -replace '\.ps1',"_$((Get-Date).ToFileTimeUtc()).json"
                if ((Test-Path $Rtr -PathType Container) -eq $false) {
                    [void](New-Item $Rtr -ItemType Directory)
                }
                ConvertTo-Json @($Object) -Depth 8 >> (Join-Path $Rtr $Json)
            }
        }
    }
}
$Out = @('Microsoft\Windows\CurrentVersion\Uninstall',
'Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall').foreach{
    grk "Software\$_" | Where-Object { $_.DisplayName -and $_.DisplayVersion -and $_.Publisher } |
        Select-Object DisplayName,DisplayVersion,Publisher,InstallLocation
}
shumio 'list_application.ps1' $Out $Humio.Cloud $Humio.Token
$Out | ConvertTo-Json -Compress
