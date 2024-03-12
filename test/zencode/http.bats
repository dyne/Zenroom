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


@test "real HTTP url percentage encoding" {
    cat <<EOF | save_asset append_values.data
{
    "base-url": "http://",
	"client_id": "did:dyne:sandbox.signroom:PTDvvQn1iWQiVxkfsDnUid8FbieKbHq46Qs8c9CZx67",
    "code": "eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJlYWMyMjNmOTMwYmRkNzk1NDdlNzI2ZGRjZTg5ZTlmYTA1NWExZTFjIiwiaWF0IjoxNzA5MDQ4MzkzMjk1LCJpc3MiOiJodHRwczovL3ZhbGlkLmlzc3Vlci51cmwiLCJhdWQiOiJkaWQ6ZHluZTpzYW5kYm94LmdlbmVyaWNpc3N1ZXI6NkNwOG1QVXZKbVFhTXhRUFNuTnloYjc0ZjlHYTRXcWZYQ2tCbmVGZ2lrbTUiLCJleHAiOjE3MDkwNTE5OTN9.TahF8CqDDj5yynvtvkhr-Gt6RjzHSvKMosOhFf5sVmWGohKBPMNFhI8WlBlWj7aRauXB0lsvbQk03lf4eZN-2g",
    "code_verifier": "JYTDgtxcjiNqa3AvJjfubMX6gx98-wCH7iTydBYAeFg",
    "grant_type": "authorization_code",
    "redirectUris": "https://didroom.com/"
}
EOF
    cat <<EOF | zexe append_values.zen append_values.data
Scenario 'http': create a GET request concatenating values on a HTTP url

# The base URL and the parameters are loaded as strings
Given I have a 'string' named 'base-url'
Given I have a 'string' named 'client_id'
Given I have a 'string' named 'code'
Given I have a 'string' named 'code_verifier'
Given I have a 'string' named 'grant_type'
Given I have a 'string' named 'redirectUris'

# The statement 'create the url' creates an object to which parameters
# can be appended to create a valid GET request
When I create the url from 'base-url'
When I append the percent encoding of 'grant_type'     as http request to 'url'
When I append the percent encoding of 'client_id'      as http request to 'url'
When I append the percent encoding of 'code_verifier'  as http request to 'url'
When I append the percent encoding of 'redirectUris'   as http request to 'url'
When I append the percent encoding of 'code'           as http request to 'url'

When I split the leftmost '8' bytes of 'url'
When I rename the 'url' to 'body'

Then print the 'body'

EOF
    save_output 'append_values.json'
    assert_output '{"body":"grant_type=authorization_code&client_id=did%3Adyne%3Asandbox.signroom%3APTDvvQn1iWQiVxkfsDnUid8FbieKbHq46Qs8c9CZx67&code_verifier=JYTDgtxcjiNqa3AvJjfubMX6gx98-wCH7iTydBYAeFg&redirectUris=https%3A%2F%2Fdidroom.com%2F&code=eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJlYWMyMjNmOTMwYmRkNzk1NDdlNzI2ZGRjZTg5ZTlmYTA1NWExZTFjIiwiaWF0IjoxNzA5MDQ4MzkzMjk1LCJpc3MiOiJodHRwczovL3ZhbGlkLmlzc3Vlci51cmwiLCJhdWQiOiJkaWQ6ZHluZTpzYW5kYm94LmdlbmVyaWNpc3N1ZXI6NkNwOG1QVXZKbVFhTXhRUFNuTnloYjc0ZjlHYTRXcWZYQ2tCbmVGZ2lrbTUiLCJleHAiOjE3MDkwNTE5OTN9.TahF8CqDDj5yynvtvkhr-Gt6RjzHSvKMosOhFf5sVmWGohKBPMNFhI8WlBlWj7aRauXB0lsvbQk03lf4eZN-2g"}'
}

@test "create a GET parameters from a table" {
    cat <<EOF | save_asset append_values.data
{
    "parameters": {
        "client_id": "did:dyne:sandbox.signroom:PTDvvQn1iWQiVxkfsDnUid8FbieKbHq46Qs8c9CZx67",
        "code": "eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJlYWMyMjNmOTMwYmRkNzk1NDdlNzI2ZGRjZTg5ZTlmYTA1NWExZTFjIiwiaWF0IjoxNzA5MDQ4MzkzMjk1LCJpc3MiOiJodHRwczovL3ZhbGlkLmlzc3Vlci51cmwiLCJhdWQiOiJkaWQ6ZHluZTpzYW5kYm94LmdlbmVyaWNpc3N1ZXI6NkNwOG1QVXZKbVFhTXhRUFNuTnloYjc0ZjlHYTRXcWZYQ2tCbmVGZ2lrbTUiLCJleHAiOjE3MDkwNTE5OTN9.TahF8CqDDj5yynvtvkhr-Gt6RjzHSvKMosOhFf5sVmWGohKBPMNFhI8WlBlWj7aRauXB0lsvbQk03lf4eZN-2g",
        "code_verifier": "JYTDgtxcjiNqa3AvJjfubMX6gx98-wCH7iTydBYAeFg",
        "grant_type": "authorization_code",
        "redirectUris": "https://didroom.com/"
    }
}
EOF
    cat <<EOF | zexe append_values.zen append_values.data
Scenario 'http': create a GET request concatenating values on a HTTP url

# the parameters are loaded as string dictionary
Given I have a 'string dictionary' named 'parameters'

# create the get parameters string
When I create the get parameters from 'parameters'
When I create the percent encoded get parameters from 'parameters'

Then print the 'get_parameters'
and print the 'percent_encoded_get_parameters'

EOF
    save_output 'append_values.json'
    assert_output '{"get_parameters":"client_id=did:dyne:sandbox.signroom:PTDvvQn1iWQiVxkfsDnUid8FbieKbHq46Qs8c9CZx67code=eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJlYWMyMjNmOTMwYmRkNzk1NDdlNzI2ZGRjZTg5ZTlmYTA1NWExZTFjIiwiaWF0IjoxNzA5MDQ4MzkzMjk1LCJpc3MiOiJodHRwczovL3ZhbGlkLmlzc3Vlci51cmwiLCJhdWQiOiJkaWQ6ZHluZTpzYW5kYm94LmdlbmVyaWNpc3N1ZXI6NkNwOG1QVXZKbVFhTXhRUFNuTnloYjc0ZjlHYTRXcWZYQ2tCbmVGZ2lrbTUiLCJleHAiOjE3MDkwNTE5OTN9.TahF8CqDDj5yynvtvkhr-Gt6RjzHSvKMosOhFf5sVmWGohKBPMNFhI8WlBlWj7aRauXB0lsvbQk03lf4eZN-2gredirectUris=https://didroom.com/grant_type=authorization_codecode_verifier=JYTDgtxcjiNqa3AvJjfubMX6gx98-wCH7iTydBYAeFg","percent_encoded_get_parameters":"client_id=did%3Adyne%3Asandbox.signroom%3APTDvvQn1iWQiVxkfsDnUid8FbieKbHq46Qs8c9CZx67code=eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJlYWMyMjNmOTMwYmRkNzk1NDdlNzI2ZGRjZTg5ZTlmYTA1NWExZTFjIiwiaWF0IjoxNzA5MDQ4MzkzMjk1LCJpc3MiOiJodHRwczovL3ZhbGlkLmlzc3Vlci51cmwiLCJhdWQiOiJkaWQ6ZHluZTpzYW5kYm94LmdlbmVyaWNpc3N1ZXI6NkNwOG1QVXZKbVFhTXhRUFNuTnloYjc0ZjlHYTRXcWZYQ2tCbmVGZ2lrbTUiLCJleHAiOjE3MDkwNTE5OTN9.TahF8CqDDj5yynvtvkhr-Gt6RjzHSvKMosOhFf5sVmWGohKBPMNFhI8WlBlWj7aRauXB0lsvbQk03lf4eZN-2gredirectUris=https%3A%2F%2Fdidroom.com%2Fgrant_type=authorization_codecode_verifier=JYTDgtxcjiNqa3AvJjfubMX6gx98-wCH7iTydBYAeFg"}'
}
