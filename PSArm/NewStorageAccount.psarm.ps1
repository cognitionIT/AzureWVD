param(
    [Parameter(Mandatory)] [string] $StorageAccountName,
    [Parameter()] [ValidateSet('WestEurope', 'CentralUS')] [string] $Location = 'WestEurope',
    [Parameter()] [ValidateSet('Hot', 'Cool', 'Archive')] [string] $AccessTier = 'Hot'
)

Arm {
    Resource $StorageAccountName -Namespace 'Microsoft.Storage' -Type 'storageAccounts' `
        -apiVersion '2019-06-01' -Kind 'StorageV2' -Location $Location {
        ArmSku 'Standard_LRS'
        Properties {
            accessTier $AccessTier
            minimumTLSVersion 'TLS1_2'
            supportsHTTPSTrafficOnly $true
            allowBlobPublicAccess $true
            allowSharedKeyAccess $true
        }
    }
}

