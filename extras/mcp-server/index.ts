#!/usr/bin/env bun

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListPromptsRequestSchema,
  GetPromptRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ErrorCode,
  McpError,
} from "@modelcontextprotocol/sdk/types.js";

// Import zenroom using require for CommonJS module
const { zencode_exec } = require("zenroom");

// Server information
const SERVER_NAME = "zenroom-mcp-server";
const SERVER_VERSION = "1.0.0";

// Create the MCP server
const server = new Server(
  {
    name: SERVER_NAME,
    version: SERVER_VERSION,
  },
  {
    capabilities: {
      tools: {},
      prompts: {},
      resources: {},
    },
  }
);

// Tool definitions
const tools = [
  {
    name: "execute_zencode",
    description: "Execute a Zencode script with optional data and keys",
    inputSchema: {
      type: "object",
      properties: {
        script: {
          type: "string",
          description: "The Zencode script to execute",
        },
        data: {
          type: "string",
          description: "JSON data to pass to the script (optional)",
        },
        keys: {
          type: "string",
          description: "JSON keys to pass to the script (optional)",
        },
        conf: {
          type: "string",
          description: "Configuration string for Zenroom (optional)",
        },
      },
      required: ["script"],
    },
  },
  {
    name: "validate_zencode",
    description: "Validate a Zencode script without executing it",
    inputSchema: {
      type: "object",
      properties: {
        script: {
          type: "string",
          description: "The Zencode script to validate",
        },
      },
      required: ["script"],
    },
  },
];

// Prompt definitions
const prompts = [
  {
    name: "keygen",
    description: "Generate a new ECDH keypair",
    arguments: [],
  },
  {
    name: "sign",
    description: "Create a signature using ECDH",
    arguments: [
      {
        name: "message",
        description: "Message to sign",
        required: true,
      },
    ],
  },
  {
    name: "verify",
    description: "Verify a signature using ECDH",
    arguments: [
      {
        name: "message",
        description: "Message that was signed",
        required: true,
      },
      {
        name: "signature",
        description: "Signature to verify",
        required: true,
      },
    ],
  },
];

// Resource definitions
const resources = [
  {
    uri: "zenroom://documentation",
    name: "Zenroom Documentation",
    description: "Official Zenroom documentation and examples",
    mimeType: "text/plain",
  },
  {
    uri: "zenroom://examples/keygen",
    name: "Key Generation Example",
    description: "Example Zencode script for generating keypairs",
    mimeType: "text/plain",
  },
  {
    uri: "zenroom://examples/signature",
    name: "Signature Example",
    description: "Example Zencode script for creating signatures",
    mimeType: "text/plain",
  },
];

// Handle tool listing
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools,
  };
});

// Handle tool execution
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case "execute_zencode": {
      const { script, data, keys, conf } = args as any;

      try {
        // Execute the Zencode script
        const result = await zencode_exec(script, {
          data: data || "",
          keys: keys || "",
          conf: conf || "",
        });

        // Parse the result if it's JSON
        let outputText = result.result || "Script executed successfully";
        try {
          const parsed = JSON.parse(outputText);
          outputText = JSON.stringify(parsed, null, 2);
        } catch {
          // Keep as is if not JSON
        }

        return {
          content: [
            {
              type: "text",
              text: outputText,
            },
          ],
          _meta: {
            logs: result.logs,
          },
        };
      } catch (error: any) {
        const errorMessage = error.logs || error.message || JSON.stringify(error);
        return {
          content: [
            {
              type: "text",
              text: `Error executing Zencode: ${errorMessage}`,
            },
          ],
          isError: true,
        };
      }
    }

    case "validate_zencode": {
      const { script } = args as any;

      try {
        // Try to execute with a safe configuration to validate
        await zencode_exec(script, {
          data: "",
          keys: "",
          conf: "",
        });

        return {
          content: [
            {
              type: "text",
              text: "✓ Script is valid",
            },
          ],
        };
      } catch (error: any) {
        const errorMessage = error.logs || error.message || JSON.stringify(error);
        return {
          content: [
            {
              type: "text",
              text: `✗ Script validation failed: ${errorMessage}`,
            },
          ],
        };
      }
    }

    default:
      throw new McpError(
        ErrorCode.MethodNotFound,
        `Tool not found: ${name}`
      );
  }
});

// Handle prompt listing
server.setRequestHandler(ListPromptsRequestSchema, async () => {
  return {
    prompts,
  };
});

// Handle prompt retrieval
server.setRequestHandler(GetPromptRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case "keygen":
      return {
        description: "Generate a new ECDH keypair",
        messages: [
          {
            role: "user",
            content: {
              type: "text",
              text: `Please execute this Zencode script to generate a new ECDH keypair:

Scenario 'ecdh': Create the keypair
Given that I am 'Alice'
When I create the ecdh key
Then print my data`,
            },
          },
        ],
      };

    case "sign": {
      const message = (args as any)?.message || "Hello, World!";
      return {
        description: "Create a signature using ECDH",
        messages: [
          {
            role: "user",
            content: {
              type: "text",
              text: `Please sign the message "${message}" using ECDH. You'll need:
1. An ECDH keypair (use the keygen prompt first if needed)
2. Execute a signing script with the message as data`,
            },
          },
        ],
      };
    }

    case "verify": {
      const message = (args as any)?.message || "Hello, World!";
      const signature = (args as any)?.signature || "";
      return {
        description: "Verify a signature using ECDH",
        messages: [
          {
            role: "user",
            content: {
              type: "text",
              text: `Please verify the signature for message "${message}". 
Signature: ${signature}
You'll need the public key of the signer to verify.`,
            },
          },
        ],
      };
    }

    default:
      throw new McpError(
        ErrorCode.MethodNotFound,
        `Prompt not found: ${name}`
      );
  }
});

// Handle resource listing
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  return {
    resources,
  };
});

// Handle resource reading
server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const { uri } = request.params;

  switch (uri) {
    case "zenroom://documentation":
      return {
        contents: [
          {
            uri,
            mimeType: "text/plain",
            text: `# Zenroom Documentation

Zenroom is a secure computation environment for cryptographic operations.

## Quick Start

Zencode is Zenroom's domain-specific language for cryptographic operations.

### Basic Structure:
- Scenario: Defines the cryptographic context
- Given: Declares existing data/keys
- When: Performs operations
- Then: Outputs results

### Common Scenarios:
- 'ecdh': Elliptic Curve Diffie-Hellman operations
- 'bbs': BBS+ signatures
- 'credential': Anonymous credentials
- 'petition': Threshold signatures

For full documentation, visit: https://dev.zenroom.org`,
          },
        ],
      };

    case "zenroom://examples/keygen":
      return {
        contents: [
          {
            uri,
            mimeType: "text/plain",
            text: `# ECDH Key Generation Example

Scenario 'ecdh': Create the keypair
Given that I am 'Alice'
When I create the ecdh key
Then print my data

# This will output a JSON with your keypair`,
          },
        ],
      };

    case "zenroom://examples/signature":
      return {
        contents: [
          {
            uri,
            mimeType: "text/plain",
            text: `# ECDH Signature Example

## First, you need a keypair (see keygen example)

## Then, to sign a message:

Scenario 'ecdh': Create the signature
Given that I am 'Alice'
Given that I have my 'keyring'
Given that I have a 'string' named 'message'
When I create the ecdh signature of 'message'
Then print the 'ecdh signature'

# Pass the keyring as keys and message as data`,
          },
        ],
      };

    default:
      throw new McpError(
        ErrorCode.InvalidRequest,
        `Resource not found: ${uri}`
      );
  }
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error(`${SERVER_NAME} v${SERVER_VERSION} started`);
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});