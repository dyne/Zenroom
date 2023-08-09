package zenroom

import (
	"io"
	"log"
	"os/exec"
	"strings"
	b64 "encoding/base64"
)

type ZenResult struct {
	Output string;
	Logs string;
}
func ZencodeExec(script string, conf string, keys string, data string) (ZenResult, bool) {
	return ZencodeExecExtra(script, conf, keys, data, "", "")
}

func ZencodeExecExtra(script string, conf string, keys string, data string, extra string, context string) (ZenResult, bool) {
	execCmd := exec.Command("zencode-exec")

	stdout, err := execCmd.StdoutPipe()
	if err != nil {
		log.Fatalf("Failed to create stdout pipe: %v", err)
	}

	stderr, err := execCmd.StderrPipe()
	if err != nil {
		log.Fatalf("Failed to create stderr pipe: %v", err)
	}

	stdin, err := execCmd.StdinPipe()
    if err != nil {
		log.Fatalf("Failed to create stdin pipe: %v", err)
    }
    defer stdin.Close()



	io.WriteString(stdin, conf)
	io.WriteString(stdin, "\n")

	b64script := b64.StdEncoding.EncodeToString([]byte(script))
	io.WriteString(stdin, b64script)
	io.WriteString(stdin, "\n")

	b64keys := b64.StdEncoding.EncodeToString([]byte(keys))
	io.WriteString(stdin, b64keys)
	io.WriteString(stdin, "\n")

	b64data := b64.StdEncoding.EncodeToString([]byte(data))
	io.WriteString(stdin, b64data)
	io.WriteString(stdin, "\n")

	b64extra := b64.StdEncoding.EncodeToString([]byte(extra))
	io.WriteString(stdin, b64extra)
	io.WriteString(stdin, "\n")

	b64context := b64.StdEncoding.EncodeToString([]byte(context))
	io.WriteString(stdin, b64context)
	io.WriteString(stdin, "\n")

	err = execCmd.Start()
	if err != nil {
		log.Fatalf("Failed to start command: %v", err)
	}
	stdoutOutput := make(chan string)
	stderrOutput := make(chan string)
	go captureOutput(stdout, stdoutOutput)
	go captureOutput(stderr, stderrOutput)

	stdoutStr := <-stdoutOutput
	stderrStr := <-stderrOutput

	err = execCmd.Wait()

	return ZenResult{Output: stdoutStr, Logs: stderrStr}, err == nil
}

func captureOutput(pipe io.ReadCloser, output chan<- string) {
	defer close(output)

	buf := new(strings.Builder)
	_, err := io.Copy(buf, pipe)
	if err != nil {
		log.Printf("Failed to capture output: %v", err)
		return
	}
	output <- buf.String()
}
