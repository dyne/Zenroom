package zenroom_test

import (
	"fmt"
	"reflect"
	"testing"

	"github.com/DECODEproject/Zenroom/bindings/golang/zenroom"
)

func TestBasicCall(t *testing.T) {
	script := []byte(`print (1)`)
	res, err := zenroom.ZenroomExec(script)
	if err != nil {
		t.Error(err)
	}
	if !reflect.DeepEqual(res, []byte("1\n")) {
		t.Errorf("calling print (1), got:%s len:%d", res, len(res))
	}
}

func TestVersion(t *testing.T) {
	script := []byte(`print(VERSION)`)
	res, err := zenroom.ZenroomExec(script)
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
			resp:   []byte("Hello World!\n"),
		},
		{
			label:  "naked string",
			script: []byte(`print('hello')`),
			resp:   []byte("hello\n"),
		},
	}
	for _, testcase := range testcases {
		t.Run(testcase.label, func(t *testing.T) {
			res, err := zenroom.ZenroomExec(testcase.script, zenroom.WithData(testcase.data))
			if err != nil {
				t.Error(err)
			}

			if !reflect.DeepEqual(res, testcase.resp) {
				t.Errorf("calling [%s] got %s of len %d", testcase.script, res, len(res))
			}
		})
	}
}

func BenchmarkBasicPrint(b *testing.B) {
	script := []byte(`print ('hello')`)
	for n := 0; n < b.N; n++ {
		_, _ = zenroom.ZenroomExec(script)
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
		_, _ = zenroom.ZenroomExec(script, zenroom.WithData(data))
	}
}

func ExampleZenroomExec() {
	script := []byte(`print("hello")`)
	res, _ := zenroom.ZenroomExec(script)
	fmt.Println(string(res))
	// Output: hello
}
