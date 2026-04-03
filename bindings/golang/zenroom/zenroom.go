package zenroom

import (
	"bytes"
	b64 "encoding/base64"
	"os/exec"
	"strings"
)

type ZenResult struct {
	Output string
	Logs   string
}

var execCommand = exec.Command

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
	execCmd := execCommand(aux)
	var stdin strings.Builder
	var stdout bytes.Buffer
	var stderr bytes.Buffer

	stdin.WriteString(conf)
	stdin.WriteString("\n")
	stdin.WriteString(b64.StdEncoding.EncodeToString([]byte(script)))
	stdin.WriteString("\n")
	stdin.WriteString(b64.StdEncoding.EncodeToString([]byte(keys)))
	stdin.WriteString("\n")
	stdin.WriteString(b64.StdEncoding.EncodeToString([]byte(data)))
	stdin.WriteString("\n")
	stdin.WriteString(b64.StdEncoding.EncodeToString([]byte(extra)))
	stdin.WriteString("\n")
	stdin.WriteString(b64.StdEncoding.EncodeToString([]byte(context)))
	stdin.WriteString("\n")

	execCmd.Stdin = strings.NewReader(stdin.String())
	execCmd.Stdout = &stdout
	execCmd.Stderr = &stderr

	err := execCmd.Run()
	return ZenResult{Output: stdout.String(), Logs: stderr.String()}, err == nil
}
