package main

import (
  "os"
  "fmt"
  "io/ioutil"
  "path"
  "strings"
  "github.com/dyne/Zenroom/bindings/golang/zenroom"
  "log"
  "time"
)

func main() {
  script_name := os.Args[1]
  script_path := os.Args[2]
  final_path := path.Join(script_name, script_path)

  fmt.Println("[GO] zenroom_exec ", final_path)

  buffer, err := ioutil.ReadFile(final_path)
  if err != nil {
    log.Fatal(err)
  }
  script := string(buffer)

  start := time.Now()
  result, success := zenroom.ZenroomExec(script, "", "", "")
  elapsed := time.Since(start)
  if !success {
    log.Fatal(result)
  }

  fmt.Println(result)
  fmt.Println("--- ", elapsed, "seconds ---")
  fmt.Println("@", strings.Repeat("=", 40), "@")

}

