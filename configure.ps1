function Add-Shortcut-Software {
    Param([string]$execname)
    # Pourrait valider le fichier recu

    # Get le base name de executable qu'on veut crée
    $filenoext = [io.path]::GetFileNameWithoutExtension($execname);
    # Crée le fichier de lien vers le bureau
    $ShortcutFile = "C:\Users\Public\Desktop\$filenoext.lnk";
    
    $WScriptShell = New-Object -ComObject WScript.Shell;
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile);
    $Shortcut.TargetPath = $execname;
    $Shortcut.Save();
}

function Add-ShortcutList-FromFile {
    Param([string]$basepath,[string]$filepath)

    # Valie que le fichier existe
    foreach($line in [System.IO.File]::ReadLines($filepath)) {
        $fullpath = Join-Path $basepath -ChildPath $line;
        Add-Shortcut-Software $fullpath; 
    }
}


function Add-Variable-ToFile {
    Param([string]$name,[string]$path, [string]$csvfile)
    $AdditionalContent = [PSCustomObject]@{Variable="$name"; Path="$path"};
    $AdditionalContent | Export-Csv -Path $csvfile -Append;
}

function Add-Variable-FromCsv {
    Param([string]$basepath,[string]$csvfile)
    Import-Csv $csvfile -Header Variable,Path | Select -skip 1 | ForEach-Object {
        $var=$_.Variable;
        $path=$_.Path;

        $fullpath = Join-Path -Path $basepath -ChildPath $path;
        echo "Setting $var to $fullpath";
        [Environment]::SetEnvironmentVariable($var,$fullpath,"User");
    }
}

function Delete-Variable-FromCsv {
    Param([string]$csvfile)
    Import-Csv $csvfile -Header Variable,Path | Select -skip 1 | ForEach-Object {
        $var=$_.Variable;
        echo "Deleting variable $var";
        [Environment]::SetEnvironmentVariable($var,$null,"User");
    }
}

function Add-Directory-ToPath-FromFile {
    Param([string]$basepath,[string]$filepath)
    foreach($line in [System.IO.File]::ReadLines("$filepath")) {
        $fullpath = Join-Path -Path $basepath -ChildPath $line;
        echo "Adding $fullpath to PATH";
        $env:Path += ";$fullpath";
    }
    [Environment]::SetEnvironmentVariable("Path",$env:Path,"User");

}

function Configure-Git-User {
    Param([string]$name,[string]$email)
    git config --global user.email $email
    git config --global user.email $name
}


$SoftwareRoot = Join-Path -Path $PSScriptRoot -ChildPath "Software";

echo "Configuration du workspace avec comme racine le répertoire $PSScriptRoot";


echo "Création des shortcut vers le bureau";

Add-ShortcutList-FromFile $SoftwareRoot "$PSScriptRoot\link.txt";

echo "Ajout de mes variables d'environment";

Add-Variable-FromCsv $SoftwareRoot "$PSScriptRoot\variables.csv";

echo "Ajout des dossiers au path de l'utilisateur courrant";

Add-Directory-ToPath-FromFile $SoftwareRoot "$PSScriptRoot\path.txt";

echo "Configuration de l'usager git";

Configure-Git-User "William Quintal" "william95quintalwilliam@outlook.com"
