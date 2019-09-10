package zenroom_test

import (
	"encoding/json"
	"fmt"
	"reflect"
	"testing"

	"github.com/DECODEproject/zenroom-go"
)

func TestBasicCall(t *testing.T) {
	script := []byte(`print (1)`)
	res, err := zenroom.Exec(script)
	if err != nil {
		t.Error(err)
	}
	if !reflect.DeepEqual(res, []byte("1")) {
		t.Errorf("calling print (1), got:%s len:%d", res, len(res))
	}
}

func TestVersion(t *testing.T) {
	script := []byte(`print(VERSION)`)
	res, err := zenroom.Exec(script)
	if err != nil {
		t.Error(err)
	}

	fmt.Printf("Zenroom version: %s\n", res)
}

func TestCallStrings(t *testing.T) {
	testcases := []struct {
		label  string
		script []byte
		data   []byte
		resp   []byte
	}{
		{
			label:  "string variable",
			script: []byte(`hello = 'Hello World!' print(hello)`),
			resp:   []byte("Hello World!"),
		},
		{
			label:  "naked string",
			script: []byte(`print('hello')`),
			resp:   []byte("hello"),
		},
	}
	for _, testcase := range testcases {
		t.Run(testcase.label, func(t *testing.T) {
			res, err := zenroom.Exec(testcase.script, zenroom.WithData(testcase.data))
			if err != nil {
				t.Error(err)
			}

			if !reflect.DeepEqual(res, testcase.resp) {
				t.Errorf("calling [%s] got %s of len %d", testcase.script, res, len(res))
			}
		})
	}
}

func TestEncodeDecode(t *testing.T) {
	encryptKeys := []byte(`
	{
 		"device_token": "abc123",
 		"community_id": "foo",
 		"community_pubkey": "BBLewg4VqLR38b38daE7Fj\/uhr543uGrEpyoPFgmFZK6EZ9g2XdK\/i65RrSJ6sJ96aXD3DJHY3Me2GJQO9\/ifjE="
	}
	`)

	data := []byte(`{"msg": "secret"}`)

	encryptScript := []byte(`
-- Encryption script for DECODE IoT Pilot
curve = 'ed25519'

-- data schema to validate input
keys_schema = SCHEMA.Record {
  device_token     = SCHEMA.String,
  community_id     = SCHEMA.String,
  community_pubkey = SCHEMA.String
}

-- import and validate KEYS data
keys = read_json(KEYS, keys_schema)

-- generate a new device keypair every time
device_key = ECDH.keygen(curve)

-- read the payload we will encrypt
payload = read_json(DATA)

-- The device's public key, community_id and the curve type are tranmitted in
-- clear inside the header, which is authenticated AEAD
header = {}
header['device_pubkey'] = device_key:public():base64()
header['community_id'] = keys['community_id']

iv = RNG.new():octet(16)
header['iv'] = iv:base64()

-- encrypt the data, and build our output object
local session = device_key:session(base64(keys.community_pubkey))
local head = str(MSG.pack(header))
local out = { header = head }
out.text, out.checksum = ECDH.aead_encrypt(session, str(MSG.pack(payload)), iv, head)

output = map(out, base64)
output.zenroom = VERSION
output.encoding = 'base64'
output.curve = curve

print(JSON.encode(output))
`)

	decryptKeys := []byte(`
{
	"community_seckey": "D19GsDTGjLBX23J281SNpXWUdu+oL6hdAJ0Zh6IrRHA="
}
`)

	decryptScript := []byte(`
-- Decryption script for DECODE IoT Pilot

-- curve used
curve = 'ed25519'

-- data schemas
keys_schema = SCHEMA.Record {
  community_seckey = SCHEMA.String
}

data_schema = SCHEMA.Record {
  header   = SCHEMA.String,
  encoding = SCHEMA.String,
  text     = SCHEMA.String,
  curve    = SCHEMA.String,
  zenroom  = SCHEMA.String,
  checksum = SCHEMA.String
}

-- read and validate data
keys = read_json(KEYS, keys_schema)
data = read_json(DATA, data_schema)

header = MSG.unpack(base64(data.header):str())

community_key = ECDH.new(curve)
community_key:private(base64(keys.community_seckey))

session = community_key:session(base64(header.device_pubkey))

decode = { header = header }
decode.text, decode.checksum = ECDH.aead_decrypt(session, base64(data.text), base64(header.iv), base64(data.header))

print(JSON.encode(MSG.unpack(decode.text:str())))
`)

	encryptedMessage, err := zenroom.Exec(encryptScript, zenroom.WithData(data), zenroom.WithKeys(encryptKeys))
	if err != nil {
		t.Fatalf("Error encrypting message: %v", err)
	}

	if len(encryptedMessage) == 0 {
		t.Errorf("Length of encrypted message should not be 0")
	}

	decryptedMessage, err := zenroom.Exec(decryptScript, zenroom.WithData(encryptedMessage), zenroom.WithKeys(decryptKeys))
	if err != nil {
		t.Fatalf("Error encrypting message: %v", err)
	}

	var decrypted map[string]interface{}
	err = json.Unmarshal(decryptedMessage, &decrypted)
	if err != nil {
		t.Fatalf("Error unmarshalling json: %v", err)
	}

	if decrypted["msg"] != "secret" {
		t.Errorf("Unexpected decrypted output, got %v, expected %v", decrypted["msg"], "secret")
	}
}

func BenchmarkBasicPrint(b *testing.B) {
	script := []byte(`print ('hello')`)
	for n := 0; n < b.N; n++ {
		_, _ = zenroom.Exec(script)
	}
}

func BenchmarkBasicKeyandEncrypt(b *testing.B) {
	script := []byte(`
	msg = str(DATA)
	kr = ECDH.new()
	kr:keygen()
	encrypted = ECDH.encrypt(kr, kr:public(), msg, kr:public())
	print (encrypted)
	`)
	data := []byte(`temperature:25.1`)

	for n := 0; n < b.N; n++ {
		_, _ = zenroom.Exec(script, zenroom.WithData(data))
	}
}

func ExampleExec() {
	script := []byte(`print("hello")`)
	res, _ := zenroom.Exec(script)
	fmt.Println(string(res))
	// Output: hello
}
