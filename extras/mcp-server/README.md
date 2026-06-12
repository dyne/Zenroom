# Zenroom MCP Server

A Model Context Protocol (MCP) server that provides cryptographic capabilities through Zenroom's Zencode scripting language.

## Features

- Execute Zencode scripts with the `execute_zencode` tool
- Validate Zencode scripts with the `validate_zencode` tool
- Provides sample prompts for common cryptographic operations
- Exposes documentation and example resources
- Built with the official MCP SDK
- TypeScript support with Bun runtime

## Requirements

- [Bun](https://bun.sh) runtime (v1.0 or later)
- Zenroom library (included via local dependency)

## Installation

```bash
bun install
```

## Usage

### Start the Server

```bash
bun run start
```

Or for development with auto-reload:

```bash
bun run dev
```

The server communicates over stdin/stdout using the JSON-RPC protocol as specified by MCP.

### Run Tests

```bash
bun test
```

Or run the integration test:

```bash
bun run test.ts
```

## Tools

### execute_zencode

Execute a Zencode script with optional data and keys.

**Parameters:**
- `script` (string, required): The Zencode script to execute
- `data` (string, optional): JSON data to pass to the script
- `keys` (string, optional): JSON keys to pass to the script
- `conf` (string, optional): Configuration string for Zenroom

**Returns:**
- `result` (string): The output of the Zencode script execution
- `logs` (string): Logs from the execution (in metadata)

**Example:**
```json
{
  "name": "execute_zencode",
  "arguments": {
    "script": "Scenario 'ecdh': Create the keypair\nGiven that I am 'Alice'\nWhen I create the ecdh key\nThen print my data",
    "data": "{\"name\": \"Alice\"}",
    "conf": "color=0,debug=0"
  }
}
```

### validate_zencode

Validate a Zencode script without executing it.

**Parameters:**
- `script` (string, required): The Zencode script to validate

**Returns:**
- `valid` (boolean): Whether the script is valid
- `message` (string): Validation message

## Prompts

The server provides pre-configured prompts for common operations:

- **keygen**: Generate a new ECDH keypair
- **sign**: Create a signature using ECDH (requires message parameter)
- **verify**: Verify a signature using ECDH (requires message and signature parameters)

## Resources

The server exposes the following resources:

- `zenroom://documentation` - Zenroom documentation overview
- `zenroom://examples/keygen` - Key generation example
- `zenroom://examples/signature` - Signature creation example

## Example Zencode Scripts

### Generate a keypair

```zencode
Scenario 'ecdh': Create the keypair
Given that I am 'Alice'
When I create the ecdh key
Then print my data
```

### Create a signature

```zencode
Scenario 'ecdh': Create the signature
Given that I am 'Alice'
Given that I have my 'keyring'
Given that I have a 'string' named 'message'
When I create the ecdh signature of 'message'
Then print the 'ecdh signature'
```

### Verify a signature

```zencode
Scenario 'ecdh': Verify the signature
Given that I am 'Bob'
Given that I have a 'public key' from 'Alice'
Given that I have a 'string' named 'message'
Given that I have a 'ecdh signature'
When I verify the 'ecdh signature' of 'message' from 'Alice'
Then print 'signature is valid' as 'string'
```

## Integration with AI Applications

This MCP server can be integrated with AI applications that support the Model Context Protocol, such as:

- Claude Desktop App
- Cline (VS Code extension)
- Custom LLM applications using MCP SDKs

### Claude Desktop Configuration

Add to your Claude Desktop configuration file:

```json
{
  "mcpServers": {
    "zenroom": {
      "command": "bun",
      "args": ["run", "/path/to/zenroom/extras/mcp-server/index.ts"]
    }
  }
}
```

### Use Cases

The server enables AI assistants to:

1. **Generate cryptographic keys** - Create keypairs for various algorithms
2. **Sign and verify messages** - Digital signatures for authentication
3. **Perform zero-knowledge proofs** - Privacy-preserving computations
4. **Work with credentials** - Anonymous credential systems
5. **Blockchain operations** - Bitcoin, Ethereum integrations
6. **Secure multi-party computations** - Distributed cryptographic protocols

## Development

### Project Structure

```
mcp-server/
├── index.ts           # Main server implementation
├── test.ts            # Integration tests
├── index.test.ts      # Unit tests (optional)
├── package.json       # Dependencies and scripts
├── examples/          # Example Zencode scripts
│   ├── keygen.zen
│   ├── signature.zen
│   └── verify.zen
└── README.md          # This file
```

### Adding New Tools

To add a new tool, modify `index.ts`:

1. Add tool definition to the `tools` array
2. Handle the tool in the `CallToolRequestSchema` handler
3. Add tests for the new tool

### Testing

The test suite covers:
- Server initialization
- Tool execution
- Prompt handling
- Resource reading
- Error handling

## License

AGPL-3.0-or-later