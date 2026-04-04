import { describe, it, expect, beforeAll, afterAll } from "bun:test";
import { spawn, type Subprocess } from "bun";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

describe("Zenroom MCP Server", () => {
  let client: Client;
  let transport: StdioClientTransport;
  let serverProcess: Subprocess;

  beforeAll(async () => {
    // Start the server
    serverProcess = spawn(["bun", "run", "index.ts"], {
      cwd: import.meta.dir,
      stdio: ["pipe", "pipe", "inherit"],
    });

    // Create client transport
    transport = new StdioClientTransport({
      command: "bun",
      args: ["run", "index.ts"],
      cwd: import.meta.dir,
    });

    // Create and connect client
    client = new Client(
      {
        name: "test-client",
        version: "1.0.0",
      },
      {
        capabilities: {},
      }
    );

    await client.connect(transport);
  });

  afterAll(async () => {
    await client.close();
    serverProcess.kill();
  });

  describe("Server Initialization", () => {
    it("should return server info", () => {
      const serverInfo = client.getServerInfo();
      expect(serverInfo?.name).toBe("zenroom-mcp-server");
      expect(serverInfo?.version).toBe("1.0.0");
    });

    it("should have expected capabilities", () => {
      const capabilities = client.getServerCapabilities();
      expect(capabilities?.tools).toBeDefined();
      expect(capabilities?.prompts).toBeDefined();
      expect(capabilities?.resources).toBeDefined();
    });
  });

  describe("Tools", () => {
    it("should list available tools", async () => {
      const result = await client.listTools();
      expect(result.tools).toHaveLength(2);
      
      const toolNames = result.tools.map(t => t.name);
      expect(toolNames).toContain("execute_zencode");
      expect(toolNames).toContain("validate_zencode");
    });

    it("should execute a simple Zencode script", async () => {
      const script = `
Scenario 'ecdh': Create the keypair
Given that I am 'Alice'
When I create the ecdh key
Then print my data
`;

      const result = await client.callTool("execute_zencode", {
        script,
      });

      expect(result.content).toHaveLength(1);
      expect(result.content[0].type).toBe("text");
      
      const text = result.content[0].text;
      expect(text).toContain("Alice");
      
      // Parse the result to check for keypair
      const data = JSON.parse(text);
      expect(data.Alice).toBeDefined();
      expect(data.Alice.keyring).toBeDefined();
      expect(data.Alice.keyring.ecdh).toBeDefined();
    });

    it("should validate a correct Zencode script", async () => {
      const script = `
Scenario 'ecdh': Create the keypair
Given that I am 'Bob'
When I create the ecdh key
Then print my data
`;

      const result = await client.callTool("validate_zencode", {
        script,
      });

      expect(result.content).toHaveLength(1);
      expect(result.content[0].type).toBe("text");
      expect(result.content[0].text).toContain("✓ Script is valid");
    });

    it("should detect invalid Zencode script", async () => {
      const script = `
This is not valid Zencode
`;

      const result = await client.callTool("validate_zencode", {
        script,
      });

      expect(result.content).toHaveLength(1);
      expect(result.content[0].type).toBe("text");
      expect(result.content[0].text).toContain("✗ Script validation failed");
    });

    it("should execute script with data", async () => {
      const script = `
Given that I have a 'string' named 'message'
Then print the 'message'
`;

      const data = JSON.stringify({
        message: "Hello from test!",
      });

      const result = await client.callTool("execute_zencode", {
        script,
        data,
      });

      expect(result.content).toHaveLength(1);
      const text = result.content[0].text;
      const output = JSON.parse(text);
      expect(output.message).toBe("Hello from test!");
    });
  });

  describe("Prompts", () => {
    it("should list available prompts", async () => {
      const result = await client.listPrompts();
      expect(result.prompts).toHaveLength(3);
      
      const promptNames = result.prompts.map(p => p.name);
      expect(promptNames).toContain("keygen");
      expect(promptNames).toContain("sign");
      expect(promptNames).toContain("verify");
    });

    it("should get keygen prompt", async () => {
      const result = await client.getPrompt("keygen", {});
      
      expect(result.description).toBe("Generate a new ECDH keypair");
      expect(result.messages).toHaveLength(1);
      expect(result.messages[0].role).toBe("user");
      expect(result.messages[0].content.text).toContain("ECDH keypair");
    });

    it("should get sign prompt with custom message", async () => {
      const result = await client.getPrompt("sign", {
        message: "Test message",
      });
      
      expect(result.description).toBe("Create a signature using ECDH");
      expect(result.messages[0].content.text).toContain("Test message");
    });
  });

  describe("Resources", () => {
    it("should list available resources", async () => {
      const result = await client.listResources();
      expect(result.resources).toHaveLength(3);
      
      const resourceUris = result.resources.map(r => r.uri);
      expect(resourceUris).toContain("zenroom://documentation");
      expect(resourceUris).toContain("zenroom://examples/keygen");
      expect(resourceUris).toContain("zenroom://examples/signature");
    });

    it("should read documentation resource", async () => {
      const result = await client.readResource("zenroom://documentation");
      
      expect(result.contents).toHaveLength(1);
      expect(result.contents[0].mimeType).toBe("text/plain");
      expect(result.contents[0].text).toContain("Zenroom Documentation");
      expect(result.contents[0].text).toContain("cryptographic operations");
    });

    it("should read keygen example", async () => {
      const result = await client.readResource("zenroom://examples/keygen");
      
      expect(result.contents).toHaveLength(1);
      expect(result.contents[0].text).toContain("ECDH Key Generation");
      expect(result.contents[0].text).toContain("Create the keypair");
    });
  });

  describe("Error Handling", () => {
    it("should handle unknown tool gracefully", async () => {
      try {
        await client.callTool("unknown_tool", {});
        expect(true).toBe(false); // Should not reach here
      } catch (error: any) {
        expect(error.message).toContain("Tool not found");
      }
    });

    it("should handle unknown prompt gracefully", async () => {
      try {
        await client.getPrompt("unknown_prompt", {});
        expect(true).toBe(false); // Should not reach here
      } catch (error: any) {
        expect(error.message).toContain("Prompt not found");
      }
    });

    it("should handle unknown resource gracefully", async () => {
      try {
        await client.readResource("zenroom://unknown");
        expect(true).toBe(false); // Should not reach here
      } catch (error: any) {
        expect(error.message).toContain("Resource not found");
      }
    });
  });
});