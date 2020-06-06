<#
  .Synopsis
  Create SQLite DB of ATC RRF's subset from the UMLS 
  
  .Description
    Based on code from the CHB group at https://github.com/chb/py-umls/blob/master/databases/umls.sh

  .Parameter 
     
#>

$rxn_dir = "$(pwd)"
$rxn_db = "UMLS_RxNorm.sqlite"

# check if the db exists in the current director 
Write-Host "==========================================="
Write-Host "Starting RRF-to-SQLite Conversion Process"
Write-Host "==========================================="
if ((Test-Path $rxn_db) -eq $false) {
    
    # test to make sure there's a scripts folder and then to make sure there's rrf folder 
            ### Database Creation
            # read in the create table statements, clean up the MySQL to be sqlite compatible 
            $SQL_TableScripts = Get-Content ".\mysql_tables.sql" | Out-String
            $SQL_TableScripts = $SQL_TableScripts -replace "\\W", "" -replace " CHARACTER SET utf8", "" -replace 'load[^;]*;', ''
            # confirmation
            Write-Host "Creating SQLite Database with Tables"
            # create the db and add the table structures 
            sqlite3 $rxn_db $SQL_TableScripts
            Write-Host "==========================================="
            
            ### RRF file manipulations 
            # read in files, clean up and output
            # remove trailing pipe and quotes 
            # this is because SQLite gets mad at the trailing pipe the CHB group had to do this too. idk why there's n pipes instead of n-1 pipes. 
            $rrf_fnames = Get-ChildItem * -Include *.RRF | Where Length -ne 0 # Get-ChildItem -Name -Include *.rrf   
            $rrf_fnames = $rrf_fnames.Name        
            $i = 0

            Write-Host "Converting RRF Files for SQLite"
           
            ForEach ($rrf in $rrf_fnames) { 
                Write-Host (" . . . "+$rrf_fnames[$i] + " in process")      
                $rrf_clean = ([System.IO.File]::ReadAllText($rxn_dir+"\"+$rrf_fnames[$i])) -replace "\|\r", "" -replace "`"", "'"
                $rrf_clean | Out-File ($rrf_fnames[$i].Split(".")[0]+".pipe") -Encoding utf8 -NoNewline
                $i++
            }
            

            Write-Host "==========================================="
            ### change separator 
            $SQL_SeparatorPipe = ".separator '|'"
            sqlite3 $rxn_db $SQL_SeparatorPipe
            ### Import Files into SQLite DB 
            $rrf_piped = Get-ChildItem -Name -Include *.pipe
            $j = 0
            Write-Host "Adding Converted RRF Files to SQLite DB"
            ForEach ($rrf in $rrf_piped) {
                Write-Host (" . . . "+$rrf+ " in process")
                $cur_f = ($rxn_dir + "\" + $rrf)
                $sql_cmd = ".import '"+$cur_f+"' '"+$rrf.Split(".")[0]+"'"
                sqlite3 $rxn_db $sql_cmd
            }

            Write-Host "==========================================="
            ### Create Indexes 
            $SQL_CreateIndexes = Get-Content ".\mysql_indexes.sql"
            $SQL_CreateIndexes = $SQL_CreateIndexes | Where-Object{$_ -like "CREATE*"}
            $SQL_CreateIndexes = $SQL_CreateIndexes -replace "\\W", ""
            # confirmation
            Write-Host "Creating Indexes on SQLite Tables"
            
            sqlite3 $rxn_db $SQL_CreateIndexes

            Write-Host "==========================================="
            Write-Host "Process Complete! `n `n"

} else {
    # error if there db already exists 
    Write-Host "There's already a database in this folder. Ending program."
}