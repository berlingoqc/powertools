#   convertbadmedia.ps1 - William Quintal
#
#   Script to find and convert the media type you don't want anymore !
#
#

# Argument qui peuvent être passé en mode commande
Param(
    [string]$RootPath,
    [string]$Mode,
    [bool]$Clean
)

# Nom de l'executation de ffmpeg
$ffmpeg="ffmpeg.exe";

# Avant toute chose valide que ffmpeg est présent
if ($null -eq (Get-Command $ffmpeg -ErrorAction SilentlyContinue) ) {
    "Impossible de trouver ffmpeg dans votre PATH";
    return 1;
}

# test si l'hôte possède cuda pour accelerer le decodage
$haveCuda=@(& $ffmpeg "-hwaccels").Contains("cuda");

if($haveCuda) {
    "Votre plateforme supporte l'accéleration matériel avec cuda";
}



function convertVideo {
    Param(
        $inFile,
        $outFile
    )
    $ext = [System.IO.Path]::GetExtension($item); 
    $addArgIn=@();
    $addArgOut=@();
    # si le type de fichier video est h.264, HEVC, MJPEG, MPEG, VP8/9 ou VC-1 utilise cuda
    if ($haveCuda) {
        if($ext -eq ".mkv") {
            $addArgIn=@("-hwaccel" ,"cuvid", "-c:v" ,"h264_cuvid");
        } 
        $addArgOut=@("-c:v" ,"h264_nvenc","-preset" ,"slow");
    }

    & "ffmpeg.exe" "-threads" "4" "-y" $addArgIn "-i" "$item" $addArgOut "-b:v" "1000k" "-minrate" "500k" "-maxrate" "3000k"  "$newfile";
    # si la commande a fail on liste le fichier comment etant un fichier qui a fail
    if(!$?) {
        Add-Content -P ".\failconvert.txt" $item;
    }
}

function convertAudio {
    Param (
        $inFile,
        $outFile
    )
    & "ffmpeg.exe" "-y" "-i" $inFile "-ab" "320k" "-map_metadata" "0" "-id3v2_version" "3" $outFile;
}




$modeAudio = "audio";
$modeVideo = "video";

# Format qu'on va convertir
$inTypeVideo = @("*.avi","*.flv","*.webm","*.mkv","*.mpg");
$inTypeAudio = @("*.flac");


# Format de destination
$outTypeAudio = ".mp3";
$outTypeVideo = ".mp4";


Write-Output "Convertbadmedia type ! Get away from those";

# valid que le dossier est valide
if($RootPath -eq "") {
    "Aucun répertoire entré";
    return $false;
}
if(!(Test-Path -Path $RootPath)) {
    Write-Output "$rootPath n'existe pas";
    return $false;
}
# valide que le mode soit egale a audio ou video
if(!($Mode -eq $modeAudio) -and !($Mode -eq $modeVideo)) {
    "Mode $Mode est invalide";
    return $false;
}


# variable que j'utilise qui sont assigné selon le mode
$inType = "";
$outType = "";


if($Mode -eq $modeVideo) {
    $inType = $inTypeVideo;
    $outType = $outTypeVideo;
} elseif($Mode -eq $modeAudio) {
    $inType = $inTypeAudio;
    $outType = $outTypeAudio;
}

# Va chercher tout les items a fouiller
$items = Get-ChildItem -Path $rootPath -Recurse -Include $inType | % { $_.FullName };
$size = @($items).Count;
$count = 1;

@("Démarrage de la conversion en mode {0} type d'entrée : {1} vers : {2}. Il y a {3} éléments à traités" -f $Mode,[string]::Join(" ",$inType),$outType, $size);


# Si on veut faire un menage des fichiers crée
if($Clean) {
    $items = Get-ChildItem -Path $rootPath -Recurse -Include $inType | ForEach-Object {New-Object psobject -Property @{File = $_.FullName; Directory = $_.DirectoryName; Extension = $_.Extension; BaseName = $_.BaseName}};
    # Refiltre dans les données a traités
    foreach ($item in $items) {
        # get l'extension sans le criss de point
        $ext = $item.Extension.Substring(1);
        # regarde si le morceau est deja dans son dossier de son type
        $lastDir = Split-Path -leaf $item.Directory;
        if($lastDir -eq $ext) { continue }

        $newPath = Join-Path -Path $item.Directory -ChildPath $ext;

        # Crée le repertoire pour le type de fichier
        New-Item -ItemType directory -Force -Path $newPath
        #Copie le fichier vers le répertoire
        $newPath = Join-Path -Path $newPath -ChildPath "$($item.BaseName)$($item.Extension)";
        @("Moving {0} to {1}" -f $item.File,$newPath)
        Move-Item -LiteralPath "$($item.File)" -Destination "$newPath";
        $?
    }
    return "Cleaning terminer avec succès";
} # returne pour ne pas executer le reste qui a surement deja ete faite


# loop les fichier retourner
foreach ($item in $items) {

    $filenoext = $item -replace '\.[^.\\/]+$';

    $newfile = $filenoext + $outType;

    @("Démarrage de la conversion de {0} item {1} / {2}" -f $item,$count,$size);

   if($mode -eq $modeVideo) {
       convertVideo($item,$newfile);
   } elseif($mode -eq $modeAudio) {
       convertAudio($item,$newfile);
   }
   $count++;
}

