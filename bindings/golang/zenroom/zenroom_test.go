package zenroom

import (
	"fmt"
	"testing"
)

func TestBasicCall(t *testing.T) {
	script := "print (1)"
	res, _ := ZenroomExec(script, "", "", "")
	if res.output == "1" {
		t.Errorf("calling print (1), got:%s", res.output)
	}
}

func TestVersion(t *testing.T) {
	script := "print(VERSION)"
	res, _ := ZenroomExec(script, "", "", "")

	fmt.Printf("Zenroom version: %s\n", res.output)
}

func TestCallStrings(t *testing.T) {
	testcases := []struct {
		label  string
		script string
		resp   string
	}{
		{
			label:  "string variable",
			script: "hello = 'Hello World!' print(hello)",
			resp:   "Hello World!\n",
		},
		{
			label:  "naked string",
			script: "print('hello')",
			resp:   "hello\n",
		},
	}
	for _, testcase := range testcases {
		t.Run(testcase.label, func(t *testing.T) {
			res, _ := ZenroomExec(testcase.script, "", "", "")
			if res.output != testcase.resp {
				t.Errorf("calling [%s] got %s", testcase.script, res.output)
			}
		})
	}
}

// func BenchmarkBasicPrint(b *testing.B) {
// 	script := []byte(`print ('hello')`)
// 	for n := 0; n < b.N; n++ {
// 		_, _ = ZenroomExec(script)
// 	}
// }

// func BenchmarkBasicKeyandEncrypt(b *testing.B) {
// 	script := []byte(`
// 	msg = str(DATA)
// 	kr = ECDH.new()
// 	kr:keygen()
// 	encrypted = ECDH.encrypt(kr, kr:public(), msg, kr:public())
// 	print (encrypted)
// 	`)
// 	data := []byte(`temperature:25.1`)

// 	for n := 0; n < b.N; n++ {
// 		_, _ = ZenroomExec(script, WithData(data))
// 	}
// }

// func ExampleZenroomExec() {
// 	script := []byte(`print("hello")`)
// 	res, _ := ZenroomExec(script)
// 	fmt.Println(string(res))
// 	// Output: hello
// }
