load ../bats_setup
load ../bats_zencode
SUBDOC=http

@test "create a GET request concatenating values on a HTTP url (pt. 1)" {
    cat <<EOF | save_asset base-url.json
{
     	"base-url": "http://www.7timer.info/bin/api.pl"
}
EOF
    cat <<EOF | save_asset api-values.json
{
	"lon": "113.17",
	"lat": "23.09",
	"product": "astro",
	"output": "json"
}
EOF


    cat <<EOF | zexe api-compose-1.zen base-url.json
Scenario http: create a GET request concatenating values on a HTTP url

Given I have a 'string' named 'base-url'
When I create the url from 'base-url'
Then print all data
EOF
    save_output 'api-compose-output.json'
    assert_output '{"base-url":"http://www.7timer.info/bin/api.pl","url":"http://www.7timer.info/bin/api.pl"}'
}


@test "create a GET request concatenating values on a HTTP url (pt. 2)" {
    cat <<EOF | zexe api-compose.zen base-url.json api-values.json
Scenario 'http': create a GET request concatenating values on a HTTP url

# The base URL and the parameters are loaded as strings
Given I have a 'string' named 'base-url'
Given I have a 'string' named 'lon'
Given I have a 'string' named 'lat'
Given I have a 'string' named 'product'
Given I have a 'string' named 'output'

# The statement 'create the url' creates an object to which parameters
# can be appended to create a valid GET request
When I create the url from 'base-url'

# And here are the parameters to be appended to the query
# They are appended as 'key=value&'
When I append 'lon'     as http request to 'url'
When I append 'lat'     as http request to 'url'
When I append 'product' as http request to 'url'
When I append 'output'  as http request to 'url'

Then print the 'url'

EOF
    save_output 'api-compose-output.json'
    assert_output '{"url":"http://www.7timer.info/bin/api.pl?lon=113.17&lat=23.09&product=astro&output=json"}'
}
