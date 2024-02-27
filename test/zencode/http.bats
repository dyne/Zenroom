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

@test "create a GET request concatenating values on a HTTP url percentage encoding" {
    cat <<EOF | save_asset reserved_values.json
{
    "colon": ":",
    "slash": "/",
    "question_mark": "?",
    "hash": "#",
    "percentage": "%",
    "square_bracket_open": "[",
    "square_bracket_close": "]",
    "at": "@",
    "esclamation_mark": "!",
    "dollar": "$",
    "single_quote": "'",
    "parenthesis_open": "(",
    "parenthesis_close": ")",
    "asterisk": "*",
    "plus": "+",
    "comma": ",",
    "semicolon": ";",
    "equal": "=",
    "space": " "
}
EOF
    cat <<EOF | zexe api-compose-percent.zen base-url.json reserved_values.json
Scenario 'http': create a GET request concatenating values on a HTTP url

# The base URL and the parameters are loaded as strings
Given I have a 'string' named 'base-url'
Given I have a 'string' named 'colon'
Given I have a 'string' named 'slash'
Given I have a 'string' named 'question_mark'
Given I have a 'string' named 'hash'
Given I have a 'string' named 'percentage'
Given I have a 'string' named 'square_bracket_open'
Given I have a 'string' named 'square_bracket_close'
Given I have a 'string' named 'at'
Given I have a 'string' named 'esclamation_mark'
Given I have a 'string' named 'single_quote'
Given I have a 'string' named 'parenthesis_open'
Given I have a 'string' named 'parenthesis_close'
Given I have a 'string' named 'asterisk'
Given I have a 'string' named 'plus'
Given I have a 'string' named 'comma'
Given I have a 'string' named 'semicolon'
Given I have a 'string' named 'equal'
Given I have a 'string' named 'space'

# The statement 'create the url' creates an object to which parameters
# can be appended to create a valid GET request
When I create the url from 'base-url'

# And here are the parameters to be appended to the query
# They are appended as 'key=value&'
When I append the percent encoding of 'colon' as http request to 'url'
When I append the percent encoding of 'slash' as http request to 'url'
When I append the percent encoding of 'question_mark' as http request to 'url'
When I append the percent encoding of 'hash' as http request to 'url'
When I append the percent encoding of 'percentage' as http request to 'url'
When I append the percent encoding of 'square_bracket_open' as http request to 'url'
When I append the percent encoding of 'square_bracket_close' as http request to 'url'
When I append the percent encoding of 'at' as http request to 'url'
When I append the percent encoding of 'esclamation_mark' as http request to 'url'
When I append the percent encoding of 'single_quote' as http request to 'url'
When I append the percent encoding of 'parenthesis_open' as http request to 'url'
When I append the percent encoding of 'parenthesis_close' as http request to 'url'
When I append the percent encoding of 'asterisk' as http request to 'url'
When I append the percent encoding of 'plus' as http request to 'url'
When I append the percent encoding of 'comma' as http request to 'url'
When I append the percent encoding of 'semicolon' as http request to 'url'
When I append the percent encoding of 'equal' as http request to 'url'
When I append the percent encoding of 'space' as http request to 'url'

Then print the 'url'

EOF
    save_output 'api-compose-percent-output.json'
    assert_output '{"url":"http://www.7timer.info/bin/api.pl?colon=%3A&slash=%2F&question_mark=%3F&hash=%23&percentage=%25&square_bracket_open=%5B&square_bracket_close=%5D&at=%40&esclamation_mark=%21&single_quote=%27&parenthesis_open=%28&parenthesis_close=%29&asterisk=%2A&plus=%2B&comma=%2C&semicolon=%3B&equal=%3D&space=+"}'
}
