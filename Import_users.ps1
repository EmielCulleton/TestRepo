function check-ou {
    
    param($description)
    $exist = $false
    
    if(Get-ADOrganizationalUnit -Filter * | Where-Object {$_.name -eq $description})
    {

        $exist = $true
        

    }

    $exist


}

function check-user {

    param($name)
    $exist = $false

    if(Get-ADUser -Filter * | Where-Object {$_.givenname -eq "$name"}){ #!!check!!
    
        $exist = $true


    }

    $exist
}

function check-user2 {

    
    param($name)
    
    $exist = $true
    
    try
    {
        $OU= Get-ADUser -identity $name -ErrorAction Stop

    }

    catch
    {

        $exist = $false

    }

    $exist

}

function check-group{

    param($description)
    $exist = $false

    if(Get-ADGroup -Filter * | Where-Object {$_.name -eq $description}){
    
        $exist = $true
    
    }

    $exist
}

function is-finance{

    $finance = $false
    if(Get-ADGroup -Filter * | Where-Object {$_.name -eq 'finance'}){
    
        $finance = $true

    }

    $finance

}

$user_file = Import-Csv "C:\Users\Administrator\Documents\year3.csv"


foreach($i in $user_file){
    
    #create variables
    $name = $i.FIRSTNAME + " " + $i.LASTNAME
    $givenname = $i.FIRSTNAME
    $surname = $i.LASTNAME
    $sam = $i.FIRSTNAME[0] + $surname
    $suffix = "@vdl.prod"
    $upn = $sam + $suffix

    $description = $i.description

    $password = ConvertTo-SecureString "Pa55w.rd1234" -AsPlainText -Force

    $path = "OU=" + $description + ",DC=VDL,DC=PROD"


    #check whether ou exists, create OU when -eq $false
    if(!(check-ou -description $description)){
        
        New-ADOrganizationalUnit -Name $description -path "DC=VDL,DC=PROD" -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue

    }


    #check whether user exists, create user when -eq $false
    if(!(check-user -name $givenname)){

        New-ADUser -name $name -givenname $givenname -surname $surname -description $description -samaccountname $sam -userprincipalname $upn -accountpassword $password -path $path -Enabled $true
    
    }


    #check whether group exists, create group when -eq $false
    if(!(check-group -description $description)){
        
        New-ADGroup -Name $description -DisplayName $description -Path "CN=USERS,DC=VDL,DC=PROD" -Description ("Members of this group are part of the " + $description + "unit.") -GroupScope Global
    
    }


    #add user to group that matches description
    Add-ADGroupMember -Identity $description -Members $sam


    #if description = finance, add user to HR aswell
    if((is-finance -description $description -sam $sam) -eq $true){
    
        Add-ADGroupMember -Identity "HR" -Members $sam
    
    }

}

"Done!"