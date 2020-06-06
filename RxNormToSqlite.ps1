<#
  .Synopsis
  Create SQLite DB of RxNorm RRF
  
  .Description
    Based on code from the CHB group at https://github.com/chb/py-umls/blob/master/databases/umls.sh

  .Parameter 
     
#>

# set variables
cd "C:\Users\wtrod\Documents\USU\RxNorm\RxNorm_full_04062020"

$rxn_dir = "$(pwd)"
$rxn_db = "RxNorm_MRCONSO_2.sqlite"

# check if the db exists in the current director 
Write-Host "==========================================="
Write-Host "Starting RRF-to-SQLite Conversion Process"
Write-Host "==========================================="
if ((Test-Path $rxn_db) -eq $false) {
    
    # test to make sure there's a scripts folder and then to make sure there's rrf folder 
    if (Test-Path "scripts") {
        if (Test-Path "rrf") {
            ### Database Creation
            # read in the create table statements 
            $SQL_TableScripts = Get-Content ".\scripts\mysql\Table_scripts_mysql_rxn.sql" | Out-String
            # confirmation
            Write-Host "Creating SQLite Database with Tables"
            # create the db and add the table structures 
            sqlite3 $rxn_db $SQL_TableScripts
            Write-Host "==========================================="
            
            ### RRF file manipulations 
            # read in files, clean up and output
            # remove trailing pipe and quotes 
            # this is because SQLite gets mad at the trailing pipe the CHB group had to do this too. idk why there's n pipes instead of n-1 pipes. 
            $rrf_fnames = Get-ChildItem ".\rrf" -Name -Include *.rrf           
            $i = 0
            Write-Host "Converting RRF Files for SQLite"
            # ForEach ($rrf in $rrf_fnames) { 
            #    Write-Host (" . . . "+$rrf_fnames[$i] + " in process")
            #    $rrf_clean = (Get-Content (".\rrf\"+$rrf_fnames[$i])) | ForEach {$_.TrimEnd("|")}              
            #    $rrf_clean | Out-File (".\rrf\"+$rrf_fnames[$i].Split(".")[0]+".pipe") -Encoding utf8
            #    $i++
            #}

            
            ForEach ($rrf in $rrf_fnames) { 
                Write-Host (" . . . "+$rrf_fnames[$i] + " in process")
                #$rrf_clean = (Get-Content (".\rrf\"+$rrf_fnames[$i]) -Encoding utf8 -Raw) -replace "\|`n", "`n" -replace "`"", "'"
                #$rrf_clean = (Get-Content (".\rrf\"+$rrf_fnames[$i]) -Raw) -replace "(\|`n)`.", "`n" -replace "(\|`n)", ""        
                $rrf_clean = ([System.IO.File]::ReadLines($rxn_dir+"\rrf\"+$rrf_fnames[$i])) -replace "\|`n", "`n" -replace "`"", "'"
                $rrf_clean | Out-File (".\rrf\"+$rrf_fnames[$i].Split(".")[0]+".pipe") -Encoding utf8 -NoNewline
                $i++
            }
            

            Write-Host "==========================================="
            ### change separator 
            $SQL_SeparatorPipe = ".separator '|'"
            sqlite3 $rxn_db $SQL_SeparatorPipe
            ### Import Files into SQLite DB 
            $rrf_piped = Get-ChildItem ".\rrf" -Name -Include *.pipe
            $j = 0
            Write-Host "Adding Converted RRF Files to SQLite DB"
            ForEach ($rrf in $rrf_piped) {
                Write-Host (" . . . "+$rrf+ " in process")
                $cur_f = ((pwd).ToString() + "\rrf\" + $rrf)
                $sql_cmd = ".import '"+$cur_f+"' '"+$rrf.Split(".")[0]+"'"
                sqlite3 $rxn_db $sql_cmd
            }

            Write-Host "==========================================="
            ### Create Indexes 
            $SQL_CreateIndexes = Get-Content ".\scripts\mysql\Indexes_mysql_rxn.sql" # | Out-String
            $SQL_CreateIndexes = $SQL_CreateIndexes | Where-Object{$_}
            # confirmation
            Write-Host "Creating Indexes on SQLite Tables"
            
            sqlite3 $rxn_db $SQL_CreateIndexes

            Write-Host "==========================================="
            Write-Host "Process Complete! `n `n"

        } else {
            # error if there isn't an rrf folder
            Write-Host "ERROR: "
            Write-Host "`tThe current directory doesn't have a subdirectory for 'rrf'."
            Write-Host "`tYou should run this in a folder that's downloaded from NLM UMLS with a name  like 'RxNorm_full_MMDDYYYY'."
        }
                
    } else {
        # error if the scripts folder doesn't exist
        Write-Host "ERROR: "
        Write-Host "`tThe current directory doesn't have a subdirectory for 'scripts'."
        Write-Host "`tYou should run this in a folder that's downloaded from NLM UMLS with a name  like 'RxNorm_full_MMDDYYYY'."

    }

} else {
    # error if there db already exists 
    Write-Host "There's already a database in this folder. Ending program."
}