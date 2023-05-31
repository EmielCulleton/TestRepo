function check-ou {
    
    param($description)
    $exist = $false
    
    if(Get-ADOrganizationalUnit -Filter * | Where-Object {$_.name -eq $description})
    {

        $exist = $true
        

    }

    $exist


}

#create OU DisabledUsers once
if(!(check-ou -description "DisabledUsers")){
        
        New-ADOrganizationalUnit -Name "DisabledUsers" -path "DC=VDL,DC=PROD" -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue

    }

#Insert info of users that needs to be disabled
"Please specify name of user(s): "
$users = read-host
$users_array = $users.split(",").TrimStart()


foreach($sam in $users_array){
    #create userobjects
    $user = Get-ADUser -Identity $sam
    $dist_name = $user.distinguishedname
    $displayname = $user.GivenName + " " + $user.Surname
    $UPN = $user.UserPrincipalName

    #disable user
    Set-ADUser -Identity $sam -Enabled $false

    #remove from all groups but domain users
    $groups = (get-aduser $sam -properties MemberOf).MemberOf
    foreach($group in $groups){
  
            Remove-ADGroupMember -Identity $group -Members $sam 

    }

    $outfile = "C:\temp\DisbledUsersLog.csv"

    $userobject = [PSCustomObject]@{
        Displayname=$displayname
        UPN=$UPN
        DatumUitDienst=Get-Date
    }

    $userobject | Export-Csv $outfile -Append -NoTypeInformation

    Import-Csv "C:\temp\Year2.csv" | Where-Object {$_.Firstname -ne $user.GivenName} | export-csv -path "C:\temp\year2_test.csv" -NoTypeInformation

    Remove-Item "C:\temp\Year2.csv"
    Rename-Item "C:\temp\Year2_test.csv" -NewName "C:\temp\Year2.csv"

    #move disabled user to DisabledUsers OU
    Move-ADObject -Identity $dist_name -targetpath "OU=DisabledUsers,DC=VDL,DC=PROD"


}








""
"done!"


