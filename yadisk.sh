#!/bin/bash
api_url="https://cloud-api.yandex.net/v1/disk/";
access_token="<TOKEN_HERE>"
screenshot_filename_format="screenshot-%Y_%m_%d-%H_%M_%S.png" 
screenshot_save_dir="$HOME/Pictures/"
open_in_browser="true"


function post {
	request=$1 
	data=$(curl --silent  -H"Authorization: OAuth "$access_token $api_url$1)
	echo $data;
}


function getJsonValue {
	json=$1
	prop=$2
    temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop`
    echo ${temp##*|}
}


function uploadfile {
	filename_with_path=$1
	filename=$2
	url=$(post "resources/upload?path=$filename&overwrite=1")
	upload_url=$(getJsonValue $url "href")
	if [ -n "$upload_url"  ];
		then
		data=$(curl --silent --upload-file $filename_with_path $upload_url)
		tmp=$(curl  -X "PUT" --silent --header "Authorization: OAuth $access_token"  --url $api_url"resources/publish?path=$filename")
		response=$(post "resources/?path=$filename")
		download_href=$(getJsonValue $response "public_url")
		notify-send "Upload complete" "Link copied to clipboard"
		if [ $open_in_browser == "true" ]
			then
				tmp=$(xdg-open $download_href)
			fi 
		echo $download_href |  xclip -selection clipboard
	else 
		notify-send "Error occured" "File already exists"
	fi

}

function takeScreenShot {
	filename_with_path=$(scrot -s $screenshot_save_dir$screenshot_filename_format -e 'echo $f')
	filename="${filename_with_path/#$screenshot_save_dir/""}"
	uploadfile $filename_with_path $filename
}

takeScreenShot

