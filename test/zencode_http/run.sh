#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

echo '{ 
     	"base-url": "http://www.7timer.info/bin/api.pl"
}' | save http base-url.json

echo '{ 
	"lon": "113.17",
	"lat": "23.09",
	"product": "astro",
	"output": "json"
}' | save http api-values.json

cat <<EOF | zexe api-compose.zen -z -a base-url.json | save http api-compose-output.json
Scenario http: create a GET request concatenating values on a HTTP url

Given I have a 'string' named 'base-url'
When I create the url from 'base-url'
Then print all data
EOF

cat <<EOF | zexe api-compose.zen -z -a base-url.json -k api-values.json | save http api-compose-output.json
Scenario http: create a GET request concatenating values on a HTTP url

Given I have a 'string' named 'base-url'
and I have a 'string' named 'lon'
and I have a 'string' named 'lat'
and I have a 'string' named 'product'
and I have a 'string' named 'output'

When I create the url from 'base-url'
When I append 'lon'     as http request to 'url'
and  I append 'lat'     as http request to 'url'
and  I append 'product' as http request to 'url'
and  I append 'output'  as http request to 'url'

Then print the 'url'
EOF

# Now we have created the api-request, which should look like this:
#
# http://www.7timer.info/bin/api.pl?lon=113.17&lat=23.09&product=astro&output=json

if [[ "`cat api-compose-output.json | cut -d'"' -f4`" == "http://www.7timer.info/bin/api.pl?lon=113.17&lat=23.09&product=astro&output=json" ]]; then
    exit 0
else
    exit 1
fi
