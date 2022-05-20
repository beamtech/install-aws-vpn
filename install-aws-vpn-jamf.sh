#!/bin/bash

# Download the a file at the given web address. Example: getFile $FILENAME "https://localhost/foo.dmg"
getFile() {
	echo "Downloading $1"
	curl --connect-timeout 30 --retry 300 --retry-delay 5 -o $1 -L "$2"
}

export pkg_location="/var/tmp/awsvpnclient.pkg"

export aws_client_url="https://d20adtppz83p9s.cloudfront.net/OSX/latest/AWS_VPN_Client.pkg"

getFile $pkg_location $aws_client_url

echo "Installing AWS VPN Client from $pkg_location"
installer -pkg /var/tmp/awsvpnclient.pkg -target /Applications

echo "Installation complete, cleaning up..."
rm -rf $pkg_location
