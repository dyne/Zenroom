#!/usr/bin/env bun

import { $ } from "bun";

// Test helper to send JSON-RPC request
async function sendRequest(request: any): Promise<any> {
  const input = JSON.stringify(request) + "\n";
  const result = await $`echo ${input} | bun run index.ts`.text();
  
  // Parse the response (may have multiple lines, find the JSON response)
  const lines = result.split("\n");
  for (const line of lines) {
    if (line.trim() === "") continue;
    try {
      return JSON.parse(line);
    } catch {
      // Skip non-JSON lines (like debug output)
    }
  }
  throw new Error("No valid JSON response found");
}

// Test cases
const tests = [
  {
    name: "Initialize",
    request: {
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: {},
        clientInfo: {
          name: "test-client",
          version: "1.0.0",
        },
      },
    },
    validate: (response: any) => {
      return (
        response.result?.protocolVersion &&
        response.result?.capabilities &&
        response.result?.serverInfo?.name === "zenroom-mcp-server"
      );
    },
  },
  {
    name: "List Tools",
    request: {
      jsonrpc: "2.0",
      id: 2,
      method: "tools/list",
      params: {},
    },
    validate: (response: any) => {
      return (
        Array.isArray(response.result?.tools) &&
        response.result.tools.length === 2
      );
    },
  },
  {
    name: "Execute Zencode - Keygen",
    request: {
      jsonrpc: "2.0",
      id: 3,
      method: "tools/call",
      params: {
        name: "execute_zencode",
        arguments: {
          script: `Scenario 'ecdh': Generate a key
Given I am 'TestUser'
When I create the ecdh key
Then print my keyring`,
        },
      },
    },
    validate: (response: any) => {
      const content = response.result?.content?.[0]?.text;
      if (!content) return false;
      try {
        const data = JSON.parse(content);
        // The keyring is nested under the user's name
        return data.TestUser?.keyring?.ecdh !== undefined;
      } catch {
        return false;
      }
    },
  },
  {
    name: "Validate Valid Zencode",
    request: {
      jsonrpc: "2.0",
      id: 4,
      method: "tools/call",
      params: {
        name: "validate_zencode",
        arguments: {
          script: `Scenario 'ecdh': Create the keypair
Given that I am 'Bob'
When I create the ecdh key
Then print my data`,
        },
      },
    },
    validate: (response: any) => {
      const content = response.result?.content?.[0]?.text;
      return content && content.includes("✓ Script is valid");
    },
  },
  {
    name: "Validate Invalid Zencode",
    request: {
      jsonrpc: "2.0",
      id: 5,
      method: "tools/call",
      params: {
        name: "validate_zencode",
        arguments: {
          script: "This is not valid Zencode",
        },
      },
    },
    validate: (response: any) => {
      const content = response.result?.content?.[0]?.text;
      return content && content.includes("✗ Script validation failed");
    },
  },
  {
    name: "Execute with Data",
    request: {
      jsonrpc: "2.0",
      id: 6,
      method: "tools/call",
      params: {
        name: "execute_zencode",
        arguments: {
          script: `Given that I have a 'string' named 'message'
Then print the 'message'`,
          data: JSON.stringify({ message: "Hello from test!" }),
        },
      },
    },
    validate: (response: any) => {
      const content = response.result?.content?.[0]?.text;
      if (!content) return false;
      try {
        const data = JSON.parse(content);
        return data.message === "Hello from test!";
      } catch {
        return false;
      }
    },
  },
  {
    name: "List Prompts",
    request: {
      jsonrpc: "2.0",
      id: 7,
      method: "prompts/list",
      params: {},
    },
    validate: (response: any) => {
      return (
        Array.isArray(response.result?.prompts) &&
        response.result.prompts.length === 3
      );
    },
  },
  {
    name: "Get Keygen Prompt",
    request: {
      jsonrpc: "2.0",
      id: 8,
      method: "prompts/get",
      params: {
        name: "keygen",
        arguments: {},
      },
    },
    validate: (response: any) => {
      return (
        response.result?.messages?.length > 0 &&
        response.result?.description === "Generate a new ECDH keypair"
      );
    },
  },
  {
    name: "List Resources",
    request: {
      jsonrpc: "2.0",
      id: 9,
      method: "resources/list",
      params: {},
    },
    validate: (response: any) => {
      return (
        Array.isArray(response.result?.resources) &&
        response.result.resources.length === 3
      );
    },
  },
  {
    name: "Read Documentation Resource",
    request: {
      jsonrpc: "2.0",
      id: 10,
      method: "resources/read",
      params: {
        uri: "zenroom://documentation",
      },
    },
    validate: (response: any) => {
      const content = response.result?.contents?.[0]?.text;
      return content && content.includes("Zenroom Documentation");
    },
  },
];

async function runTests() {
  console.log("🧪 Zenroom MCP Server Tests\n");
  console.log("=" .repeat(50));

  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    process.stdout.write(`Testing: ${test.name}... `);
    
    try {
      const response = await sendRequest(test.request);
      
      if (test.validate(response)) {
        console.log("✅ PASS");
        passed++;
      } else {
        console.log("❌ FAIL");
        console.error(`  Response: ${JSON.stringify(response, null, 2)}`);
        failed++;
      }
    } catch (error: any) {
      console.log("❌ ERROR");
      console.error(`  Error: ${error.message}`);
      failed++;
    }
  }

  // Summary
  console.log("\n" + "=" .repeat(50));
  console.log(`\n📊 Results:`);
  console.log(`   ✅ Passed: ${passed}/${tests.length}`);
  console.log(`   ❌ Failed: ${failed}/${tests.length}`);
  console.log(`   📈 Success Rate: ${Math.round((passed / tests.length) * 100)}%`);
  
  if (failed === 0) {
    console.log("\n🎉 All tests passed!");
    process.exit(0);
  } else {
    console.log("\n⚠️  Some tests failed");
    process.exit(1);
  }
}

// Run tests
runTests().catch((error) => {
  console.error("Test runner error:", error);
  process.exit(1);
});