function genagent() {

cat <<EOF | zexe keygen.zen | save bitcoin ${1}-keys.json
Scenario bitcoin
Given I am known as '${1}'
When I create the bitcoin key
Then print my 'keys'
EOF

cat <<EOF | debug pubkey.zen -k ${1}-keys.json | save bitcoin ${1}-address.json
Scenario bitcoin
Given I am known as '${1}'
and I have my 'keys'
When I create the bitcoin public key
and I create the bitcoin address
and I write string 'tb' in 'network'
and I write number '0' in 'version'
and I move 'version' in 'bitcoin address'
and I move 'network' in 'bitcoin address'
Then print 'bitcoin address'
EOF

}
