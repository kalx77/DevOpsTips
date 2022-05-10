$PSDefaultParameterValues['*:Encoding'] = 'utf8'
# https://docs.rocket.chat/guides/user-guides/user-panel/managing-your-account/personal-access-token#creating-a-personal-access-token
$RocketChatAdminToken = "SuperToken"
$RocketChatAdminID = "SuperID"

#https://github.com/RocketChat/developer-docs/tree/master/reference/api/rest-api/endpoints/team-collaboration-endpoints/users-endpoints
$RocketChatAPI = "http://chat:3000/api/v1"
$RocketChatAuthHeaders = @{
  "X-Auth-Token" = $RocketChatAdminToken
  "X-User-Id" = $RocketChatAdminID
}

$DomainName = "DOMAIN"
$FullDomainName = "domain.local"
$RootUsersGroup = "OU=domain-users,DC=domain,DC=local"
$UserShareFolder = "\\domain.local\Shares\UsersShares"

Function Generate-Password {
  param (
    [Parameter(Mandatory)]
    [int] $length
  )

  $charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.ToCharArray()
  $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
  $bytes = New-Object byte[]($length)
  $rng.GetBytes($bytes)
  $result = New-Object char[]($length)
  for ($i = 0 ; $i -lt $length ; $i++) {
      $result[$i] = $charSet[$bytes[$i]%$charSet.Length]
  }
  return (-join $result)

}

Function Create-JSONPayload {
  param (
    [Parameter(Mandatory=$True,Position=0)][String]$UserName,
    [Parameter(Mandatory=$True,Position=1)][String]$Email,
    [Parameter(Mandatory=$False,Position=2)][String]$Pass,
    [Parameter(Mandatory=$False,Position=3)][String]$Name
  )

  $JSONBody = @{
    "username" = $UserName
    "email" = $Email
    "password" = $Pass
    "name" = $Name
  }
  return $JSONBody | ConvertTo-Json

  }

Function Create-RocketChatUser {
  param (
    [Parameter(Mandatory=$True,Position=0)][String]$UserName,
    [Parameter(Mandatory=$True,Position=1)][String]$Email,
    [Parameter(Mandatory=$False,Position=2)][String]$Pass,
    [Parameter(Mandatory=$False,Position=3)][String]$Name
  )

  $JSONBody = Create-JSONPayload $UserName $Email $Pass $Name

  Try {
    Invoke-RestMethod -Method Get -ContentType "application/json" -Uri "$RocketChatAPI/users.info?username=$UserName" -Headers $RocketChatAuthHeaders | Out-Null
  }
  Catch
  {
    Write-Host "Создаем пользователя $UserName в Rocket.Chat"
    Invoke-RestMethod -Method Post -ContentType "application/json" -Uri "$RocketChatAPI/users.create" -Headers $RocketChatAuthHeaders -Body ([System.Text.Encoding]::UTF8.GetBytes($JSONBody))
  }

}

Function Create-UserSharedFolder {
  [Parameter(Mandatory=$True,Position=0)][String]$UserName

  $UserSharedFolderPath = Join-Path $UserShareFolder $UserName

  New-Item -ItemType Directory $UserSharedFolderPath

  $DomainAdminRule = New-Object System.Security.AccessControl.FileSystemAccessRule ("$DomainName\Domain Admins","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow");
  $RootUserRule = New-Object System.Security.AccessControl.FileSystemAccessRule ("$DomainName\$UserName","Write, ReadAndExecute, Synchronize", "None", "None", "Allow");
  $InheritUserRule = New-Object System.Security.AccessControl.FileSystemAccessRule ("$DomainName\$UserName","FullControl","ContainerInherit, ObjectInherit", "InheritOnly", "Allow");
  $FolderOwner = New-Object System.Security.Principal.Ntaccount("$DomainName\$UserName");

  $acl = Get-Acl $UserSharedFolderPath;
  #Отключаем и удаляем наследуемые права
  $acl.SetAccessRuleProtection($true,$false);
  #Задаем владельца и новые права доступа
  $acl.SetOwner($FolderOwner);
  $acl.SetAccessRule($DomainAdminRule)
  $acl.SetAccessRule($RootUserRule)
  $acl.AddAccessRule($InheritUserRule)
  $acl | Set-Acl $UserSharedFolderPath;

}

Function Create-ADUser {
  param (
    [Parameter(Mandatory=$True,Position=0)][String]$FullName,
    [Parameter(Mandatory=$True,Position=1)][String]$Email,
    [Parameter(Mandatory=$True,Position=2)][String]$Pass,
    [Parameter(Mandatory=$False,Position=3)][String]$JobTitle,
    [Parameter(Mandatory=$False,Position=4)][String]$Department,
    [Parameter(Mandatory=$False,Position=5)][String]$City,
    [Parameter(Mandatory=$False,Position=6)][String]$OUGroup,
    [Parameter(Mandatory=$False,Position=6)][bool]$NetFolder
  )

    $UserName = ($_.Email -split "@")[0]
    $FirstName = ($_.FullName -split " ")[1]
    $LastName = ($_.FullName -split " ")[0]

  If (Get-ADUser -LDAPFilter "(SAMAccountName=$UserName)") {
    Write-Host "Пользователь $UserName уже есть в Active Directory"
  }
  else {
    Write-Host "Создаем пользователя $UserName в Active Directory"
    New-ADUser  -Name $FullName -GivenName $FirstName -SamAccountName $UserName -Enabled $true `
                -UserPrincipalName "$UserName@$FullDomainName" -Department $Department -Title $JobTitle `
                -City $City -EmailAddress $Email -Path "OU=$City,$RootUsersGroup" `
                -DisplayName $FullName -Surname $LastName `
                -AccountPassword (ConvertTo-SecureString $Pass -AsPlainText -force) -ChangePasswordAtLogon $true
    If ($OUGroup) {
      Write-Host "Добавляем пользователя $UserName в группу $OUGroup"
      Add-ADGroupMember -Identity $OUGroup -Members $UserName
    }

    Add-Content UsersCredentials.csv "$FullName,$UserName,$Pass,$Email"  -Encoding UTF8
    Create-RocketChatUser $UserName $Email $Pass $FullName

    If ($NetFolder) {
      Create-UserSharedFolder $UserName
    }
  }

}

# Создадим файл куда будем вносить данные всех созданных скриптом пользователей
Add-Content UsersCredentials.csv "FullName,Username,Password,Email"

Import-Module ActiveDirectory

# Название колонок в CSV "FullName","Email","JobTitle","Department","OUGroup","City","NetFolder","1CUser"(последний пока не используется)
Import-Csv "test.csv" -Encoding UTF8 | ForEach-Object {

  If ($_.NetFolder){
    $NetFolder = [System.Convert]::ToBoolean($_.NetFolder)
  } else {
    $NetFolder = $false
  }
  If ($_.User1C) {
    $1CUser = [System.Convert]::ToBoolean($_.User1C)
  } else {
    $1CUser = $false
  }

  $UserPassword = Generate-Password(16)

  Create-ADUser -FullName $_.FullName -Email $_.Email -Pass $UserPassword -JobTitle $_.JobTitle `
                -Department $_.Department -City $_.City -OUGroup $_.OUGroup -NetFolder $NetFolder

}
