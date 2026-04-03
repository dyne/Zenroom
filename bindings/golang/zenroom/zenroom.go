package zenroom

import (
	"bytes"
	b64 "encoding/base64"
	"io"
	"os/exec"
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
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	stdinReader, stdinWriter := io.Pipe()
	writeErr := make(chan error, 1)
	go func() {
		defer close(writeErr)
		err := writeRequestTo(stdinWriter, script, conf, keys, data, extra, context)
		if err != nil {
			_ = stdinWriter.CloseWithError(err)
			writeErr <- err
			return
		}
		writeErr <- stdinWriter.Close()
	}()

	execCmd.Stdin = stdinReader
	execCmd.Stdout = &stdout
	execCmd.Stderr = &stderr

	err := execCmd.Run()
	if closeErr := stdinReader.Close(); err == nil && closeErr != nil {
		err = closeErr
	}
	if requestErr := <-writeErr; err == nil && requestErr != nil {
		err = requestErr
	}
	return ZenResult{Output: stdout.String(), Logs: stderr.String()}, err == nil
}

func writeRequestTo(w io.Writer, script string, conf string, keys string, data string, extra string, context string) error {
	if _, err := io.WriteString(w, conf); err != nil {
		return err
	}
	if _, err := io.WriteString(w, "\n"); err != nil {
		return err
	}

	for _, field := range []string{script, keys, data, extra, context} {
		if err := writeBase64Line(w, field); err != nil {
			return err
		}
	}

	return nil
}

func writeBase64Line(w io.Writer, value string) error {
	encoder := b64.NewEncoder(b64.StdEncoding, w)
	if _, err := io.WriteString(encoder, value); err != nil {
		_ = encoder.Close()
		return err
	}
	if err := encoder.Close(); err != nil {
		return err
	}
	_, err := io.WriteString(w, "\n")
	return err
}
