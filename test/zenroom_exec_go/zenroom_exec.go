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
  final_path := path.Join(os.Args[1:]...)

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

