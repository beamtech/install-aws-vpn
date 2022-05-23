# Wait for initial setup to finish
waitForSetup

# Get the currently active user
getCurrentUser

user_home=$(getUsersHome $currentUser)
aws_config_dir="$user_home/.config/AWSVPNClient"
aws_ovpn_dir="$aws_config_dir/OpenVpnConfigs"

# Move and rename configuation files into the AWS VPN Client configuation directory.
mkdir -p "$aws_ovpn_dir"
cp -R $RESOURCE_DIR/openvpn/*.ovpn  "$aws_ovpn_dir/"
cd "$aws_ovpn_dir"

# Remove file extension and create the ~/.config/AWSVPNClient/ConnectionProfile
total_profiles=$( ls | wc -l | awk 'BEGIN { FS = " " }; { print $1 }' )
connectionprofiles='{"Version":"1","LastSelectedProfileIndex":2,"ConnectionProfiles":['
i=0
for f in *.ovpn
do
	# Remove .ovpn file extension
	filename="$(echo $f | cut -d '.' -f1)"
	filepath="$aws_ovpn_dir/$filename"
	mv $f $filename
	
	# Strip auth-federate from openvpn configuation.
	awk '!/auth-federate/' $filename > temp && mv temp $filename

	# Build ConnectionProfiles configuration.
	remote=$( grep "remote " $filename | awk 'BEGIN { FS = " " }; { print $2 }' )
	e_id=$( echo $remote | awk 'BEGIN { FS = "." }; { print $1 }' )
	e_region=$( echo $remote | awk 'BEGIN { FS = "." }; { print $4 }' )
	connectionprofiles="$connectionprofiles{\"ProfileName\":\"$filename\",\"OvpnConfigFilePath\":\"$filepath\",\"CvpnEndpointId\":\"$e_id\",\"CvpnEndpointRegion\":\"$e_region\",\"CompatibilityVersion\":\"2\",\"FederatedAuthType\":1}"
	if [[ $i -lt $( expr $total_profiles - 1 ) ]]
	then
		connectionprofiles="$connectionprofiles,"
	fi
	let i++
done
connectionprofiles="$connectionprofiles]}"

echo -e "$connectionprofiles" > $aws_config_dir/ConnectionProfiles
chown -hR "$currentUser":staff "$aws_config_dir"
