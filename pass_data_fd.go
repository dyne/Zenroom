package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

func main() {
	fmt.Println("zenroom with keys and data via FDs")

	cmd := exec.Command("./src/zenroom", "-z", "-k", "-", "-a", "-")

	// copy output to stdout
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stdout

	// the zencode is fed via stdin
	cmd.Stdin = strings.NewReader(`Scenario 'ecdh': create the signature of an object

	Given I am known as 'Alice'
	Given I have my 'keypair'
	Given I have a 'string' named 'Message' in 'MyData'
	When I create the signature of 'Message'
	Then print 'signature'
`)

	cmd.ExtraFiles = []*os.File{
		// fd:3
		prepareFile(`{"Alice":{"keypair":{"private_key":"60MNAaCSj67vNjp/90jAYzCNCok61UpwJ61OQm0ud7g=","public_key":"BDUElhJa9AuMruX5o0q/ldJ7o8IAbm6geuf7S8fD8lYZDgXTxoa3TUjQ7zN1A3EjqDuoKvgxbombOJPHba27mwY="}}}`),
		// fd:4
		prepareFile(`{ "MyData": { "Message": "Hello, World!", "foo": 1234 } }`),
	}

	err := cmd.Run()
	check(err)
	log.Println("success!")
}

// copies all the data that should be passed to the sub-process into an os pipe and returns the reading side of it.
func prepareFile(data string) *os.File {
	rd, wr, err := os.Pipe()
	check(err)
	fmt.Fprintln(wr, data)
	err = wr.Close()
	check(err)
	return rd
}

// if something bad happens, crash fataly with the error
func check(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
