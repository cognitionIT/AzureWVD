Publish-PSArmTemplate -Path .\NewStorageAccount.psarm.ps1 -OutFile .\NewStorageAccount.armtemplate.json `
        -Parameters @{
            storageAccountName='psarmsa';
            location='WestEurope'
        } `
        -Force

