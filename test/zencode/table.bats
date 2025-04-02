load ../bats_setup
load ../bats_zencode
SUBDOC=table


@test "move with pointer" {
cat <<EOF | save_asset pointer.data
{ 
  "dataFromEndpoint": {
    "cod": "200",
    "count": 1,
    "list": [
      {
        "clouds": {
          "all": 20
        },
        "coord": {
          "lat": 43.7667,
          "lon": 11.25
        },
        "dt": 1624277371,
        "id": 3176959,
        "main": {
          "feels_like": 305.32,
          "humidity": 48,
          "pressure": 1010,
          "temp": 304.11,
          "temp_max": 304.82,
          "temp_min": 303.15
        },
        "name": "Florence",
        "sys": {
          "country": "IT"
        },
        "weather": [
          {
            "description": "few clouds",
            "icon": "02d",
            "id": 801,
            "main": "Clouds"
          }
        ],
        "wind": {
          "deg": 0,
          "speed": 2.06
        }      }
    ],
    "message": "accurate"
  },
  "key_inside_list": "main"
}
EOF
cat <<EOF | zexe pointer.zen pointer.data
Given I have a 'string dictionary' named 'dataFromEndpoint'
and I have a 'string' named 'key_inside_list'

When I set pointer to 'dataFromEndpoint'
and I enter 'list' with pointer
and I enter '1' with pointer
and I enter 'key_inside_list' with pointer
and I move 'key_inside_list' in 'pointer'

Then print 'pointer'
and print 'dataFromEndpoint'
EOF
    save_output 'pointer.out'
    assert_output '{"dataFromEndpoint":{"cod":"200","count":1,"list":[{"clouds":{"all":20},"coord":{"lat":43.7667,"lon":11.25},"dt":1624277371,"id":3176959.0,"main":{"feels_like":305.32,"humidity":48,"key_inside_list":"main","pressure":1010,"temp":304.11,"temp_max":304.82,"temp_min":303.15},"name":"Florence","sys":{"country":"IT"},"weather":[{"description":"few clouds","icon":"02d","id":801,"main":"Clouds"}],"wind":{"deg":0,"speed":2.06}}],"message":"accurate"},"pointer":{"feels_like":305.32,"humidity":48,"key_inside_list":"main","pressure":1010,"temp":304.11,"temp_max":304.82,"temp_min":303.15}}'
}

@test "pointer fails" {
cat <<EOF | save_asset pointer_fails.data
{
  "dict": {
    "list": [
        "hello",
        "world"
    ]
  },
  "not an array key": "not a number",
  "non existing key": "not a dict key"
}
EOF
cat <<EOF | save_asset pointer_fails_array.zen
Given I have a 'string dictionary' named 'dict'
and I have a 'string' named 'not an array key'

When I set pointer to 'dict'
and I enter 'list' with pointer
and I enter 'not an array key' with pointer

Then print 'pointer'
EOF
    run $ZENROOM_EXECUTABLE -z -a pointer_fails.data pointer_fails_array.zen
    assert_line --partial 'Pointer is an array but key is not a position number: not_an_array_key'

cat <<EOF | save_asset pointer_fails_dict.zen
Given I have a 'string dictionary' named 'dict'
and I have a 'string' named 'non existing key'

When I set pointer to 'dict'
and I enter 'non existing key' with pointer

Then print 'pointer'
EOF
    run $ZENROOM_EXECUTABLE -z -a pointer_fails.data pointer_fails_dict.zen
    assert_line --partial 'Cannot find not a dict key in pointer'
}

@test "move and copy statements" {
    cat <<EOF | save_asset move_and_copy_statements.data.json
{
    "my_dict": {
        "str": "hello"
    },
	"keyring": {
		"eddsa": "Cwj9CcqHNoBnXBo8iDfnhFkQeDun4Y4LStd2m3TEAYAg",
        "ecdh": "yxL8P0pLHxsl3m8Nt6m9Zm0wSMzrWlD0JTAWlaheQg4="
	},
	"to_be_signed": "some data to be signed",
    "base64_string": "aGVsbG8gbXkgZnJpZW5k"
}
EOF
    cat <<EOF | zexe move_and_copy_statements.zen move_and_copy_statements.data.json
Scenario 'eddsa': sign
Scenario 'ecdh': sign
Given I have a 'keyring'
and I have a 'base64' named 'base64_string'
and I have a 'string' named 'to_be_signed'
and I have a 'string dictionary' named 'my_dict'

# sign
When I create the eddsa signature of 'to_be_signed'
and I create the ecdh signature of 'to_be_signed'

# copy
When I copy 'my_dict' to 'result_copy'
and I copy 'to_be_signed' to 'signed' in 'result_copy'
and I copy 'eddsa signature' as 'base58' in 'result_copy'
and I copy 'ecdh signature' as 'ecdh_signature' in 'result_copy'
and I copy 'base64_string' as 'string' in 'result_copy'

# move statement
When I rename 'my_dict' to 'result_move'
and I move 'to_be_signed' to 'signed' in 'result_move'
and I move 'eddsa signature' as 'base58' in 'result_move'
and I move 'ecdh signature' as 'ecdh_signature' in 'result_move'
and I move 'base64_string' as 'string' in 'result_move'

Then print the 'result_copy'
Then print the 'result_move'
EOF
    save_output move_and_copy_statements.out.json
    assert_output '{"result_copy":{"base64_string":"hello my friend","ecdh_signature":{"r":"d2tYw0FFyVU7UjX+IRpiN8SLkLR4S8bYZmCwI2rzurI=","s":"vUljXtnKkBqle/Ik7y3GfMa1o3wEIi4lRC+b/KmVbaI="},"eddsa_signature":"2iSCa9YxtYTQtmcUHHKsYZXVsqnSWSa7E2skWZqN4EdY8wBX9UuBgCYx7Np3hJmDVQ2NiHSebLHmz5BGH3cuZ4um","signed":"some data to be signed","str":"hello"},"result_move":{"base64_string":"hello my friend","ecdh_signature":{"r":"d2tYw0FFyVU7UjX+IRpiN8SLkLR4S8bYZmCwI2rzurI=","s":"vUljXtnKkBqle/Ik7y3GfMa1o3wEIi4lRC+b/KmVbaI="},"eddsa_signature":"2iSCa9YxtYTQtmcUHHKsYZXVsqnSWSa7E2skWZqN4EdY8wBX9UuBgCYx7Np3hJmDVQ2NiHSebLHmz5BGH3cuZ4um","signed":"some data to be signed","str":"hello"}}'
}
