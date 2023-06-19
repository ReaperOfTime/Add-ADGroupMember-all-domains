# Start logging
Start-Transcript -Path "<path_to_log_file>"

# Error action handeling
$ErrorActionPreference = "Continue"

# Dynamic group name
$ADGroupname = Get-ADGroup "<GroupName>" -Server czbortechvdc001.kktech.local

# Input path
$inputupn = "<path_to_input_csv>"

# Get Domain in Active Directory Forest
$Domains = (Get-ADForest).Domains

# Get Domain Controller list
$DClist = ForEach ($Domain in $Domains) {
Get-ADDomainController -DomainName $Domain -Discover -Service PrimaryDC | Select -ExpandProperty hostname
    }

# Import csv file with email addreses, convert to SamAccountName and add to group
foreach ($line in Import-Csv $inputupn)
{
    if([string]::IsNullOrWhiteSpace($line.UserPrincipalName))
    {
        Write-Warning 'Empty UserPrincialName Value:'
        Write-Warning $line
        continue
    }

    $adusers = foreach ($DC in $DClist){ Get-ADUser -Filter "UserPrincipalName -eq '$($line.UserPrincipalName)'" -Server $DC }
    if(-not $adusers)
    {
        Write-Warning "$($line.UserPrincipalName) could not be found."
        continue
    }

    # Input check - uncomment to see progress (errors) when running from terminal. When using in scheduled tasks comment.
    # Write-Host 'The following users will be added to the Group:' $adusers.samaccountname

    foreach ($aduser in $adusers.samaccountname)
    {
        Set-ADGroup $ADGroupname -Add @{member = $adusers.DistinguishedName}
    }
}

# Stop logging
Stop-Transcript