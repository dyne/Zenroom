package zenroom

import (
	b64 "encoding/base64"
	"io"
	"log"
	"os/exec"
	"strings"
)

type ZenResult struct {
	Output string
	Logs   string
}

func ZencodeExec(script string, conf string, keys string, data string) (ZenResult, bool) {
	return ZenExecExtra("zencode-exec", script, conf, keys, data, "", "")
}
func ZencodeExecExtra(script string, conf string, keys string, data string, extra string, context string) (ZenResult, bool) {
	return ZenExecExtra("zencode-exec", script, conf, keys, data, extra, context)
}
func LuaExec(script string, conf string, keys string, data string, extra string, context string) (ZenResult, bool) {
	return ZenExecExtra("lua-exec", script, conf, keys, data, extra, context)
}

func ZenExecExtra(aux string, script string, conf string, keys string, data string, extra string, context string) (ZenResult, bool) {
	execCmd := exec.Command(aux)

	stdout, err := execCmd.StdoutPipe()
	if err != nil {
		return ZenResult{}, false
	}

	stderr, err := execCmd.StderrPipe()
	if err != nil {
		return ZenResult{}, false
	}

	stdin, err := execCmd.StdinPipe()
	if err != nil {
		return ZenResult{}, false
	}

	// Start first so the child can read from stdin
	if err := execCmd.Start(); err != nil {
		stdin.Close()
		return ZenResult{}, false
	}

	stdoutCh := make(chan string, 1)
	stderrCh := make(chan string, 1)
	go captureOutput(stdout, stdoutCh)
	go captureOutput(stderr, stderrCh)

	go func() {
		defer stdin.Close()
		io.WriteString(stdin, conf)
		io.WriteString(stdin, "\n")
		io.WriteString(stdin, b64.StdEncoding.EncodeToString([]byte(script)))
		io.WriteString(stdin, "\n")
		io.WriteString(stdin, b64.StdEncoding.EncodeToString([]byte(keys)))
		io.WriteString(stdin, "\n")
		io.WriteString(stdin, b64.StdEncoding.EncodeToString([]byte(data)))
		io.WriteString(stdin, "\n")
		io.WriteString(stdin, b64.StdEncoding.EncodeToString([]byte(extra)))
		io.WriteString(stdin, "\n")
		io.WriteString(stdin, b64.StdEncoding.EncodeToString([]byte(context)))
		io.WriteString(stdin, "\n")
	}()

	err = execCmd.Wait()
	stdoutStr := <-stdoutCh
	stderrStr := <-stderrCh

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
