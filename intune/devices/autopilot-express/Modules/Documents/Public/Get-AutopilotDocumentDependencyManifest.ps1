<#
.SYNOPSIS
    Return the reviewed document-only NuGet dependency lock.
.DESCRIPTION
    PowerShell 5.1 or later; no network, files or assembly loading. SHA-512 values
    were independently read from NuGet metadata on 24 October 2026. Selected DLL
    SHA-256 values were calculated only after archive hash verification.
.FILECREATED
    2026-10-24
.FILELASTUPDATED
    2026-10-24
#>
function Get-AutopilotDocumentDependencyManifest {
    <#
    .SYNOPSIS
        Pin one common .NET Framework 4.8 child-runtime bundle for both parent shells.
    .OUTPUTS
        Fresh ordered dictionary. NuGet trust is HTTPS plus reviewed hashes, not
        a claim that publisher signatures or future advisories were verified.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param()
    return [ordered]@{
        SchemaVersion = 1
        BundleId = 'openxml-3.3.0-zxing-0.16.11-netfx48-v1'
        Source = 'https://api.nuget.org/v3-flatcontainer'
        WorkerRuntime = 'WindowsPowerShell51-NetFramework48'
        AdvisoryCheckedOn = '2026-10-24'
        AdvisorySource = 'GitHub Advisory Database; three exact NuGet packages; no known advisories returned'
        PlatformAssemblies = @('WindowsBase', 'System.Drawing')
        Packages = @(
            [ordered]@{
                Id = 'DocumentFormat.OpenXml.Framework'; Version = '3.3.0'; Licence = 'MIT'
                Target = '.NETFramework4.6'; Dependencies = @()
                ArchiveSHA512 = 'yngzsSoeR1DQuv3/EtB7Ptpl2pwqrI/iHpvjd0SLRPckVwPtZOmMJeUL5RxOUNJxjvMHFe34LvdDPJM4t1k/nA=='
                Asset = 'lib/net46/DocumentFormat.OpenXml.Framework.dll'; FileName = 'DocumentFormat.OpenXml.Framework.dll'
                AssetSHA256 = '17245C964EEC15C0F218DB0EC30689B0145C0BDF72BB6ED045D3392A16A7AC32'
            }
            [ordered]@{
                Id = 'DocumentFormat.OpenXml'; Version = '3.3.0'; Licence = 'MIT'
                Target = '.NETFramework4.6'; Dependencies = @('DocumentFormat.OpenXml.Framework')
                ArchiveSHA512 = '5AaTgSxQH1UFrZvtkHy3iSOzElt1F3+nhcxfI8gcXuTG3/0BiMMskOTVvKWtn/bwr6g5ZPb9fM6fTHos04BH/Q=='
                Asset = 'lib/net46/DocumentFormat.OpenXml.dll'; FileName = 'DocumentFormat.OpenXml.dll'
                AssetSHA256 = '29816A4FCA1EE01DEEFBCFC777FB57B7161BECA1A6CF21EE9AD0F3395EBCEA30'
            }
            [ordered]@{
                Id = 'ZXing.Net'; Version = '0.16.11'; Licence = 'Apache-2.0'
                Target = '.NETFramework4.8'; Dependencies = @()
                ArchiveSHA512 = 'kHBBMH1ZKN4Y5IZY8Cq6iETXOr7k00ZrJ8Nbsow9QlTcJZvJVR26bX7VMR/oY1XOJuPzLyMu79WKdw+bKhechg=='
                Asset = 'lib/net48/zxing.dll'; FileName = 'zxing.dll'
                AssetSHA256 = '52F00A43F9574A411009899A6236F3EFB5B597FBAE0F3163DFEC9CBB0C1F4D38'
            }
        )
    }
}