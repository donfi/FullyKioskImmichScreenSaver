# Random screen-saver images on Fully Kiosk screensaver
# oliver@donfi.com

# declare some variables...
# url for local Immich API
$immich = 'http://192.168.0.203:2283/api/'
# Immich API key
$apikey = '[REDACTED]'
# how many images to transfer
$max_images = 200
# url of the Fully Kiosk API
$fully = 'http://192.168.0.155:2323/?password=[REDACTED]'
# url of the web server where zipped images will be available from
$nginx = 'http://192.168.0.206'
# location of the Fully Kiosk privileged storaga on the Android tablet
$filelocation = 'storage/emulated/0/Android/data/de.ozerov.fully/files'

# clear the working output folder & zip file
Write-Output "Initializing..."
Remove-Item ./Screensaver/*
Remove-Item ./screensaver.zip

# get random selection of images from Immich
Write-Output "Getting random images..."
$uri = $immich + 'search/random?apiKey=' + $apikey
$random_images = Invoke-RestMethod -Uri $uri -Method POST

# go through the results and download the image to the output folder
Write-Output "Downloading images..."
$i = 1
foreach ($item in $random_images) {
    # only look at images
    if ($item.type -eq 'IMAGE' -and $i -lt $max_images) {
        $uri = $immich + 'assets/' + $item.id + '/original?apiKey=' + $apikey
        $filename = $item.id+'_'+$item.originalFileName
        $outfile = Join-Path ./Screensaver $filename
        Invoke-RestMethod -Uri $uri -Outfile $outfile
        $i++
    }
}

Write-Output "$i images downloaded"

# zip the output file
Compress-Archive -Path ./Screensaver -DestinationPath ./screensaver.zip
cp ./screensaver.zip /data/www/zip

# invoke the command on Fully Kiosk to delete the current screensaver folder
Write-Output "Clearing files from Fully Kiosk on tablet..."
$uri = $fully + 'cmd=deleteFolder&foldername=' + $filelocation + '/Screensaver'
$output = Invoke-RestMethod -Uri $uri
if ($output -contains "<p class='success'") {
        Write-Output "Success!"
}

# invoke the command on Fully Kiosk to upload and unzip the current zip file
Write-Output "Telling Fully Kiosk to download and unzip the archive..."
$uri = $fully + '&cmd=loadZipFile&url=' + $nginx + '/zip/screensaver.zip'
$output = Invoke-RestMethod -Uri $uri
if ($output -contains "<p class='success'") {
        Write-Output "Success!"
}
