<#
.SYNOPSIS
  Collection of functions to for GXA
.DESCRIPTION
  Developed for GXA 
  .PARAMETER Verbose
  Provides additional detail to console during execution
.INPUTS None
.OUTPUTS None
.NOTES
  Version:        1.0
  Author:         Rusty Franks
  Creation Date:  2018-05-18
  Purpose/Change: Initial script development
.EXAMPLE
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

param (
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Any Global Declarations go here

#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function Set-GxaPaths {
    <#
    .SYNOPSIS
      Gets current status for Webroot SecureAnywhere
    .DESCRIPTION
      Checks if Webroot SecureAnywhere is installed and gets status from the registry

    .INPUTS None
    .OUTPUTS Array
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  2018-03-08
      Purpose/Change: Initial script development
    .EXAMPLE
    #>

    [CmdletBinding()]  
    param (
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"

        $gxaPaths = @(
            "$env:systemdrive\GXA",
            "$env:systemdrive\GXA\Utilities",
            "$env:systemdrive\GXA\Temp",
            "$env:systemdrive\GXA\Scripts",
            "$env:systemdrive\GXA\Software",
            "$env:systemdrive\GXA\Software\CryptoPrevent",
            "$env:systemdrive\GXA\Software\Webroot",
            "$env:systemdrive\GXA\Software\OpenDNS",
            "$env:systemdrive\GXA\Logs"
        )

    }

    process {
        try {
            Foreach ( $path in $gxaPaths ) {
                New-Item -ItemType Directory -Force -Path "$path" | Out-Null
            }
        }

        catch {
            $errorMessage = $_.Exception.Message
            Write-Error -Message "$(Get-Date -Format u) : Error: [$errorMessage]"
        }

    }

    end {
        Write-Verbose -Message "$(Get-Date -Format u) : Ending $($MyInvocation.InvocationName)..."
        return 0    
    }
}
Function Get-GxaModules {
    <#
    .SYNOPSIS
      Download latest modules from GitHub
    .DESCRIPTION
      Download latest modules from GitHub

    .INPUTS None
    .OUTPUTS Array
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  20180518
      Purpose/Change: Initial script development
    .EXAMPLE
    #>

    [CmdletBinding()]  
    param (
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"


    }

    process {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $response = Invoke-WebRequest "https://github.com/GXANetworks/GXA_Managed_Tools/releases/latest" -UseBasicParsing
            $url = "https://github.com/$(($response.links | Where-Object href -match 'dist.zip').href)"
            
            $installerName = "GXA_Managed_Tools.zip"            
            $output = "$env:temp\$installerName"

            Write-Verbose "$(Get-Date -Format u) : Downloading $url"

            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile("$url", $output)   

            Write-Verbose "$(Get-Date -Format u) : Extracting $output to $env:systemdrive\GXA\Scripts"

            New-Item -ItemType Directory -Force -Path "$env:systemdrive\GXA\Scripts" | Out-Null
            $shell_app = new-object -com shell.application
            $zip_file = $shell_app.namespace($output)
            $destination = $shell_app.namespace("$env:systemdrive\GXA\Scripts")
            $destination.Copyhere($zip_file.items(), 0x14)

            Write-Verbose "$(Get-Date -Format u) : Fixing folder name"
            $url -Match "https://github.com//GXANetworks/GXA_Managed_Tools/archive/v(?<version>.*).zip" | Out-Null
            $version = $Matches['version']
            Get-Item -Path "$env:systemdrive\GXA\Scripts\GXA_Managed_Tools" | Remove-Item -Recurse -Force
            Rename-Item -Path "$env:systemdrive\GXA\Scripts\GXA_Managed_Tools-$version" -NewName "GXA_Managed_Tools"

            Write-Verbose "$(Get-Date -Format u) : Removing $output"
            Remove-Item -Path $output -Force

        }

        catch {
            $errorMessage = $_.Exception.Message
            Write-Error -Message "$(Get-Date -Format u) : Error: [$errorMessage]"
        }

    }

    end {
        Write-Verbose -Message "$(Get-Date -Format u) : Ending $($MyInvocation.InvocationName)..."
        return 0    
    }
}

Function Set-TrustedPublisher {
    <#
    .SYNOPSIS
      Pull certificate from signed file and add to Trusted Publishers
    .DESCRIPTION
      Pull certificate from signed file and add to Trusted Publishers

    .INPUTS None
    .OUTPUTS Array
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  20180513
      Purpose/Change: Initial script development
    .EXAMPLE
    #>

    [CmdletBinding()]  
    param (
        [Parameter(Mandatory = $true)][String]$FilePath = ""
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"
        $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $Cert.Import((((Get-AuthenticodeSignature "$FilePath").SignerCertificate).Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)))
        $store = Get-Item "cert:\LocalMachine\TrustedPublisher"


    }

    process {
        try {
            $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]"ReadWrite")
            $store.Add($Cert)
            $store.Close()
        }

        catch {
            $errorMessage = $_.Exception.Message
            Write-Error -Message "$(Get-Date -Format u) : Error: [$errorMessage]"
        }

    }

    end {
        Write-Verbose -Message "$(Get-Date -Format u) : Ending $($MyInvocation.InvocationName)..."
        return 0    
    } 
}
#-----------------------------------------------------------[Execution]------------------------------------------------------------
# SIG # Begin signature block
# MIIa6QYJKoZIhvcNAQcCoIIa2jCCGtYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDOdfzFUzi2Gh5Z
# FZfcfXRM3QmT+rECSXFSlXYPKuAGwqCCCgkwggTQMIIDuKADAgECAgEHMA0GCSqG
# SIb3DQEBCwUAMIGDMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEG
# A1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMRR29EYWRkeS5jb20sIEluYy4xMTAv
# BgNVBAMTKEdvIERhZGR5IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIw
# HhcNMTEwNTAzMDcwMDAwWhcNMzEwNTAzMDcwMDAwWjCBtDELMAkGA1UEBhMCVVMx
# EDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoT
# EUdvRGFkZHkuY29tLCBJbmMuMS0wKwYDVQQLEyRodHRwOi8vY2VydHMuZ29kYWRk
# eS5jb20vcmVwb3NpdG9yeS8xMzAxBgNVBAMTKkdvIERhZGR5IFNlY3VyZSBDZXJ0
# aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBALngyxDUr3a91JNi6zBkuIEIbMME2WIXji//PmXPj85i5jxSHNoWRUtV
# q3hrY4NikM4PaWyZyBoUi0zMRTPqiNyeo68r/oBhnXlXxM8u9D8wPF1H/JoWvMM3
# lkFRjhFLVPgovtCMvvAwOB7zsCb4Zkdjbd5xJkePOEdT0UYdtOPcAOpFrL28cdmq
# bwDb280wOnlPX0xH+B3vW8LEnWA7sbJDkdikM07qs9YnT60liqXG9NXQpq50BWRX
# iLVEVdQtKjo++Li96TIKApRkxBY6UPFKrud5M68MIAd/6N8EOcJpAmxjUvp3wRvI
# dIfIuZMYUFQ1S2lOvDvTSS4f3MHSUvsCAwEAAaOCARowggEWMA8GA1UdEwEB/wQF
# MAMBAf8wDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBRAwr0njsw0gzCiM9f7bLPw
# tCyAzjAfBgNVHSMEGDAWgBQ6moUHEGcotu/2vQVBbiDBlNoP3jA0BggrBgEFBQcB
# AQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmdvZGFkZHkuY29tLzA1BgNV
# HR8ELjAsMCqgKKAmhiRodHRwOi8vY3JsLmdvZGFkZHkuY29tL2dkcm9vdC1nMi5j
# cmwwRgYDVR0gBD8wPTA7BgRVHSAAMDMwMQYIKwYBBQUHAgEWJWh0dHBzOi8vY2Vy
# dHMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8wDQYJKoZIhvcNAQELBQADggEBAAh+
# bJMQyDi4lqmQS/+hX08E72w+nIgGyVCPpnP3VzEbvrzkL9v4utNb4LTn5nliDgyi
# 12pjczG19ahIpDsILaJdkNe0fCVPEVYwxLZEnXssneVe5u8MYaq/5Cob7oSeuIN9
# wUPORKcTcA2RH/TIE62DYNnYcqhzJB61rCIOyheJYlhEG6uJJQEAD83EG2LbUbTT
# D1Eqm/S8c/x2zjakzdnYLOqum/UqspDRTXUYij+KQZAjfVtL/qQDWJtGssNgYIP4
# fVBBzsKhkMO77wIv0hVU7kQV2Qqup4oz7bEtdjYm3ATrn/dhHxXch2/uRpYoraEm
# fQoJpy4Eo428+LwEMAEwggUxMIIEGaADAgECAgkAiFyeSI8LjP4wDQYJKoZIhvcN
# AQELBQAwgbQxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQH
# EwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjEtMCsGA1UE
# CxMkaHR0cDovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMTMwMQYDVQQD
# EypHbyBEYWRkeSBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIwHhcN
# MTgwNTMxMTM1OTE4WhcNMTkwNTMxMTM1OTE4WjByMQswCQYDVQQGEwJVUzEOMAwG
# A1UECBMFVGV4YXMxEzARBgNVBAcTClJpY2hhcmRzb24xHjAcBgNVBAoTFUdYQSBO
# ZXR3b3JrIFNvbHV0aW9uczEeMBwGA1UEAxMVR1hBIE5ldHdvcmsgU29sdXRpb25z
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoAQOfPOJzG7DRk0XUg+t
# 1dTLa96nnAjNE07AGqPKBEOMqc68Vs2VXc5FI85OwOZhVZiemKN/heve6rPVYMor
# 7di6sJp/ksxBIvgoaCqszXO6Z4OzglA/F325w+YdEcOmwVQQHTE7XGeCTVyUqrpn
# woHEnX9Xd89TzKtaAJGWOucIR73D/hs20uwDOdarfDxCRUp0b71MTK9M71kP3OEl
# sDW7e/Jq2x2BFVa8O1HSen3Om3DacMUhGg/IrmK8y0O9gyyOTGWwqGd6/5DxwZ5Q
# 3sz04ounG70dUE2G0KDqAKFFUwf9oEbeR/NWkGRooJLkF/dxK6t/3X3o5TQHWtLx
# yQIDAQABo4IBhTCCAYEwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcD
# AzAOBgNVHQ8BAf8EBAMCB4AwNQYDVR0fBC4wLDAqoCigJoYkaHR0cDovL2NybC5n
# b2RhZGR5LmNvbS9nZGlnMnM1LTQuY3JsMF0GA1UdIARWMFQwSAYLYIZIAYb9bQEH
# FwIwOTA3BggrBgEFBQcCARYraHR0cDovL2NlcnRpZmljYXRlcy5nb2RhZGR5LmNv
# bS9yZXBvc2l0b3J5LzAIBgZngQwBBAEwdgYIKwYBBQUHAQEEajBoMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5nb2RhZGR5LmNvbS8wQAYIKwYBBQUHMAKGNGh0dHA6
# Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS9nZGlnMi5jcnQw
# HwYDVR0jBBgwFoAUQMK9J47MNIMwojPX+2yz8LQsgM4wHQYDVR0OBBYEFFZ7BHvd
# DxR1o16OTX0wlq9Eo60sMA0GCSqGSIb3DQEBCwUAA4IBAQBQQHeXCgHf0rUZpYuH
# mzwokWoePb4eCEZCk5HRIUJJKX6Ue32YNlltcT1y3SFguE20XZNEELyCWpLUM7kB
# ThSHnF1s7e77BLR2FmWm5v7O0i/R/SpSxHxK79gO+xpph0xFvXLCzF+mJr/rc1mX
# /u2WMpFloDPpG6ETKUQYKzGOD+4D/1Dpnnv4wb0FFy0Y037u/KgqhVPYRJX/hX3U
# 2lqgf2YmkrJPLxw3OYWg9SUbHStpQuBwt4ghQRcQ4KI1559Z5FLHty4zkNHMQ7Om
# wCcfyG06Gtdiqwacp4MujukKVjRM/zcG7NtVu4BOidcqwSaGPYkzhcXJCSbHQblP
# Eu3RMYIQNjCCEDICAQEwgcIwgbQxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6
# b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwg
# SW5jLjEtMCsGA1UECxMkaHR0cDovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9zaXRv
# cnkvMTMwMQYDVQQDEypHbyBEYWRkeSBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5IC0gRzICCQCIXJ5IjwuM/jANBglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcC
# AQwxAjAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsx
# DjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCD4VxQj4nfEP5+HyBv/JLl4
# 5S0EOrj3XZzFhbM9hkEQ6jANBgkqhkiG9w0BAQEFAASCAQAS59njKRhW/9ouORuZ
# uGQ2Xy5+DVTXD4a5D5Cbz05GjrqH0LO2T9bye0Hh8Co+rqd3WzYxepz6Rl9KDgL5
# qZIYi4OJ8sBQUJlwm1ado14gc9uS4Scehs+zOXLTXC1u+k/w9JuQLQoM85DdMN12
# 6rxyjo6LuEkXMyOytqtC7wQ/dSiRog6Uibnu1sAQxZzgBw7s85IQqA/oUdSzGQpw
# bIuANzhxRUzNs6OeHCzJAI4TqQgRjcFjNeR+34eJRQ/cREaUsOhBs5QvrpfrMk5z
# qVTgqA1b6xphY5vj+weUVsaZnqjyF/EIFhcjGM1G4Mcr85x3ijyiFP1/FHQAKOFL
# rEXWoYINxjCCDcIGCisGAQQBgjcDAwExgg2yMIINrgYJKoZIhvcNAQcCoIINnzCC
# DZsCAQMxDzANBglghkgBZQMEAgEFADBdBgsqhkiG9w0BCRABBKBOBEwwSgIBAQYK
# YIZIAYb9bgEHGDAhMAkGBSsOAwIaBQAEFDcs0BxItLKhPjh3xqWMRgmf11TOAgUx
# LjOsbhgPMjAxODA2MDYxNjA2MDNaoIIKhTCCBQAwggPooAMCAQICAQcwDQYJKoZI
# hvcNAQELBQAwgY8xCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYD
# VQQHEwpTY290dHNkYWxlMSUwIwYDVQQKExxTdGFyZmllbGQgVGVjaG5vbG9naWVz
# LCBJbmMuMTIwMAYDVQQDEylTdGFyZmllbGQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkgLSBHMjAeFw0xMTA1MDMwNzAwMDBaFw0zMTA1MDMwNzAwMDBaMIHGMQsw
# CQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFs
# ZTElMCMGA1UEChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjEzMDEGA1UE
# CxMqaHR0cDovL2NlcnRzLnN0YXJmaWVsZHRlY2guY29tL3JlcG9zaXRvcnkvMTQw
# MgYDVQQDEytTdGFyZmllbGQgU2VjdXJlIENlcnRpZmljYXRlIEF1dGhvcml0eSAt
# IEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5ZBmS+z5RnGpIIO+
# 6Wy/SslIaYF1Tm0k9ssXE/iwcVmEemsrhaQ0tRbly8zpQXAspC7W+jJ94ajelBCs
# McHA2Gr/WSerdtb8C3RruKeuP8RU9LQxRN2TVoykTF6bicskg5viV3232BIfyYVt
# 9NGA8VCbh67UCxAF+ye6KG0X6Q7WTbk5VQb/CiQFfi/GHXJs1IspjFd92tnrZhrT
# T6fff1LEMMWlyQ4CxVO/dzhoBiTDZsg3fjAeRXEjNf+Q2Cqdjeewkk08fyoKk9zN
# FkZl92CEi3ZLkSdzFJLg6u6PFuqNDj52F799iYCAREPnLeBDCXXaNuit24k69V0S
# jiMEgwIDAQABo4IBLDCCASgwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC
# AQYwHQYDVR0OBBYEFCVFgWhQJjg9Oy0svs1q2bY9s2ZjMB8GA1UdIwQYMBaAFHwM
# Mh+n2TB/xH1oo2Kooc6rB1snMDoGCCsGAQUFBwEBBC4wLDAqBggrBgEFBQcwAYYe
# aHR0cDovL29jc3Auc3RhcmZpZWxkdGVjaC5jb20vMDsGA1UdHwQ0MDIwMKAuoCyG
# Kmh0dHA6Ly9jcmwuc3RhcmZpZWxkdGVjaC5jb20vc2Zyb290LWcyLmNybDBMBgNV
# HSAERTBDMEEGBFUdIAAwOTA3BggrBgEFBQcCARYraHR0cHM6Ly9jZXJ0cy5zdGFy
# ZmllbGR0ZWNoLmNvbS9yZXBvc2l0b3J5LzANBgkqhkiG9w0BAQsFAAOCAQEAVmXK
# /vM/CqiTixjH3kNpEzQgvk5feKhrnNtqTUHbwRPs3DEAIl73AJ4M4DRlNPmxOk5I
# yBKBiFxbPghTevcaZN+4UGHMU1FAKUvC9K46X+TKrSbMTmFD5f1XpjdwzkMrsJTD
# kunhX6oQSbdp5ODQH2SkK80fb6D4hCQYznk9qZG/VBgTiZlUEQ1VxSYLeU9aHG75
# Y9sUgKQHq/qypbmI3ZH+ZTuko3m+iU3h0LD0yBcMCpYUfAm3bOHC2FXUGKCqQWlw
# JKO57+la3D7rlErwt95fDnb6+/tpA0VAUO5yDKQShoHNE9FOxDzKTg3SJvEAt7Sm
# ouFueoH9MKx6H8dZezCCBX0wggRloAMCAQICCQDvlcL0gOMbkzANBgkqhkiG9w0B
# AQsFADCBxjELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcT
# ClNjb3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIElu
# Yy4xMzAxBgNVBAsTKmh0dHA6Ly9jZXJ0cy5zdGFyZmllbGR0ZWNoLmNvbS9yZXBv
# c2l0b3J5LzE0MDIGA1UEAxMrU3RhcmZpZWxkIFNlY3VyZSBDZXJ0aWZpY2F0ZSBB
# dXRob3JpdHkgLSBHMjAeFw0xNzExMTQwNzAwMDBaFw0yMjExMTQwNzAwMDBaMIGH
# MQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRz
# ZGFsZTEkMCIGA1UEChMbU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgTExDMSswKQYD
# VQQDEyJTdGFyZmllbGQgVGltZXN0YW1wIEF1dGhvcml0eSAtIEcyMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5u99Crt0j8hGobYmn8k4UjErxlRcOiYQ
# a2JEGDnB9dEo4hEUVi59ww+dYrFmQyK5MZk3cv8xLdptKn9qHRpOykT3juzjJRG3
# hkuAnNdR+zr8RulUgAxW2E5K4BkRHg4BcTwPFs3miWBVcCau5HKBUhje/e4RzqGL
# HfxpA/4qpxIzX2EVHCnWh/W/2M48I7Xurm2uSHqZbDcdHl1lPs8u2339tUG9R0ND
# 9FU7mAm74kSZJ4SjmSkhrjYUPQhQ8zEG3G7G8sd/qL/4jGiBqezRzZZP+IUdaxRZ
# jMD0U/5tdtyfMRqaGATzzDh8pNeWxf9ZWkd5AK934W49DkKFDlBSAQIDAQABo4IB
# qTCCAaUwDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8EBAMCBsAwFgYDVR0lAQH/BAww
# CgYIKwYBBQUHAwgwHQYDVR0OBBYEFJ3PHID+Ctai/FgYPqfTVEDu1hRhMB8GA1Ud
# IwQYMBaAFCVFgWhQJjg9Oy0svs1q2bY9s2ZjMIGEBggrBgEFBQcBAQR4MHYwKgYI
# KwYBBQUHMAGGHmh0dHA6Ly9vY3NwLnN0YXJmaWVsZHRlY2guY29tLzBIBggrBgEF
# BQcwAoY8aHR0cDovL2NybC5zdGFyZmllbGR0ZWNoLmNvbS9yZXBvc2l0b3J5L3Nm
# X2lzc3VpbmdfY2EtZzIuY3J0MFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly9jcmwu
# c3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS9tYXN0ZXJzdGFyZmllbGQyaXNz
# dWluZy5jcmwwUAYDVR0gBEkwRzBFBgtghkgBhv1uAQcXAjA2MDQGCCsGAQUFBwIB
# FihodHRwOi8vY3JsLnN0YXJmaWVsZHRlY2guY29tL3JlcG9zaXRvcnkvMA0GCSqG
# SIb3DQEBCwUAA4IBAQBSRoHzylZjmuQVGBpIM4GVBwDw1QsQNKA1h9BOfpUAdA5Q
# x4L+RujuCbtnai/UwCX4UQEtIvj2l8Czlm8/8sWXPY6QjQ21ViESGXcc170e3Tkr
# 0T4FhcVtTLIqedcrPU0Fdsm1QMgPgo1cLjTgC2Fq09mYUARKeO5W7C0WoOFcGKcn
# VZG3ymuBIGnftFdEh0K1scJzGo/+z0/m/FopYU8U0VzVpcUZUPvcJWuUqsJ+T8Gn
# 3icL+nhkupygtNHETw0OlgwqOOlYTo5Jr+dCfqPd6fSzNoZBbqETK0eTtw/GXINY
# 22m+K0w0/n/lp+XmJ/T8G2Ae3uFjI0Wn8pZuRNx6MYICmzCCApcCAQEwgdQwgcYx
# CzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNk
# YWxlMSUwIwYDVQQKExxTdGFyZmllbGQgVGVjaG5vbG9naWVzLCBJbmMuMTMwMQYD
# VQQLEypodHRwOi8vY2VydHMuc3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS8x
# NDAyBgNVBAMTK1N0YXJmaWVsZCBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IC0gRzICCQDvlcL0gOMbkzANBglghkgBZQMEAgEFAKCBmDAaBgkqhkiG9w0BCQMx
# DQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTE4MDYwNjE2MDYwM1owKwYL
# KoZIhvcNAQkQAgwxHDAaMBgwFgQUDV40fNWzeT7P6ua4YNsPVV2+JKUwLwYJKoZI
# hvcNAQkEMSIEIL8mz/0JKTgrE3IHfjYIW5szi3641NmZM7FaaHzDc254MA0GCSqG
# SIb3DQEBAQUABIIBAA6SAY9zDKm9SA7bctyDWqXOIzgm09YYwwsRuyK7PXddTFNy
# fx05O4nyH/r38CoN5WV18MG1NvhfaoLz7KmDxKplivgucXllUbzXLIMb2lQIMMfA
# ek3Xlb73uBqRvwYdGFT7Z/2CPH1ZHOL6aAZXfkTIehKem86JItQqscPaDk4SqBYk
# hXyly99vJCDbcFRFlRHePvDBpgB98Yek8FwAST5NJDXWsrdoaadmZBjRZ4IxU8yQ
# eT0zq76fZY+b1noVtzMzXety0EBK7FkMOYmlpdnX+I17Q6UnNWH1MjvaYvZ1rUHv
# euE5KcUGI98+NIqp3ZMnCMBmIsGrF5Xkq4df5no=
# SIG # End signature block
