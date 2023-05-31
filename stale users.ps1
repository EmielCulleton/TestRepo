#functions
function check-ou {
    
    param($description)
    $exist = $false
    
    if(Get-ADOrganizationalUnit -Filter * | Where-Object {$_.name -eq $description})
    {

        $exist = $true
        

    }

    $exist


}


### ------------------------




#create OU DisabledUsers once
if(!(check-ou -description "DisabledUsers")){
        
        New-ADOrganizationalUnit -Name "DisabledUsers" -path "DC=VDL,DC=PROD" -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue

    }


#specify stale_time
"Insert time users have to be stale for: "
$stale_value = Read-Host
$today = Get-Date
$stale_time = $today.AddDays(-$stale_value)


#loop through users and check/report their stale times
$users = get-aduser -filter * 

foreach($i in $users){

    $logon_time = Get-ADUser -Identity $i -Properties lastLogon
    $logon_time_date_time = [datetime]::FromFileTime($logon_time.lastlogon)
    $logon_time_date_time

        #see if logon_time < stale_time
        if($logon_time_date_time -lt $stale_time){
            
            #disable  user
            Disable-ADAccount -Identity $i
            #Enable-ADAccount -Identity $i
            
            #move to DisabledUsers
            $dist_name = $i.distinguishedname
            Move-ADObject -Identity $dist_name -targetpath "OU=DisabledUsers,DC=VDL,DC=PROD"

            "User " + $i.name +  " has been disabled"
            ""
        }

}




