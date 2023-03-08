load ../bats_setup
load ../bats_zencode
SUBDOC=and

@test "And inside foreach" {
    cat <<EOF | save_asset andforeach.data
{
	"to_be_hashed": [
		"a",
		"b",
		"john",
		12345,
		"john@doe.com",
		"(!)"
	]
}
EOF
    cat <<EOF | zexe andforeach.zen andforeach.data
Given I have a 'string array' named 'to_be_hashed'

When I create the 'base64 array' named 'array of hashes'

Foreach 'element_to_be_hashed' in 'to_be_hashed'
When I create the hash of 'element_to_be_hashed'
and I move 'hash' in 'array of hashes'
EndForeach

Then print 'array of hashes'
EOF
    save_output "andforeach.json"
    assert_output '{"array_of_hashes":["ypeBEsobvcr6wjGzmiPcTaeG7/gUfE5yuYB3ha/uSLs=","PiPoFgA5WUoziU9lZOGxNIu9egCI1CxKy3PurtWcAJ0=","ltljLzY1ZMwwMlIUCc8iqFLyAy7sCZ7VlnwNAAzsYHo=","WZRHGrsBESr8wYFZ9sx0tPURuZgG2lmzyvWpwXPKz8U=","1wnzcOUrV7TrdfBOKzQixNQaBRSMrY+Bd22UoEj7cK8=","CVh+6HMogNKneQFF+XSaFy0nJ80KKduyZRbky5xVGKg="]}'
}

