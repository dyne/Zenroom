import { expect } from "chai";
import sinon from "sinon";
import zenroom from "../dist/wrapper";
const capcon = require("capture-console");
var assert = require("assert");

const encrypt_secret_to = {
  script: `Rule check version 1.0.0
Scenario 'simple': Alice encrypts a message for Bob
Given that I am known as 'Alice'
and I have my valid 'keypair'
and I have a valid 'public key' from 'Bob'
When I write 'This is my secret message.' in 'message'
and I write 'This is the header' in 'header'
and I encrypt the message for 'Bob'
Then print the 'secret message'
  `,
  keys: {
    zenroom: {
      curve: "goldilocks",
      encoding: "url64",
      version: "1.0.0+53387e8",
      scenario: "simple",
    },
    Alice: {
      keypair: {
        public_key:
          "u64:BCYfOkN2YUXJxGYToRt3Z1ESg_niBQ1DZbwI8lZnX04KmR4tYjL5zy40u5FZvtoi93GWvIQYalusL4KsgfOt73UrO2vixOztl2pzkhBh6HVBWiLRTXtCb_HaIZFGyqxMF_hMI30ZWzsSgKgiZsb-YQw",
        private_key:
          "u64:Ok51-tVCCCFCC4FOj6SgL0KPjHxELqDN8aEtODCo0LDcIHxy5T8k2Ns79zn2n23a_qszfGE5g5A",
      },
    },
  },
  data: {
    zenroom: {
      curve: "goldilocks",
      encoding: "url64",
      version: "1.0.0+53387e8",
      scenario: "simple",
    },
    Bob: {
      public_key:
        "u64:BGx9Of0O2se9j6hLtgSc-2qo_mdaMhRgoMGtvNFC72xLMm-oGTpRkavl1gzpv1wi_KMpZNEIef6fDUfDR0UrPyPE5kKhbOAqX4jwHFkO0HbRNNeOwe-KZtiXiDQ60iOOt5dogqu5QqULVaiP2Q9PBsI",
    },
  },
};

describe("Zenroom module", function () {
  beforeEach(function (done) {
    zenroom.reset();
    this.clog = sinon.spy(console, "log");
    this.cerr = sinon.spy(console, "error");
    setTimeout(done, 200);
  });

  afterEach(function () {
    this.clog.restore();
    this.cerr.restore();
    zenroom.reset();
  });

  it("should stringify data with strings", function () {
    let result;
    const option = {
      data: "hello",
      script: "print(DATA)",
      print: (text) => {
        result = text;
      },
    };
    zenroom.init(option).zenroom_exec();
    assert(result, option.data);
  });

  it("should stringify data with object literals", function () {
    let result;
    const option = {
      data: { a: 1 },
      script: "print(JSON.encode(DATA))",
      print: (text) => {
        result = text;
      },
    };
    zenroom.init(option).zenroom_exec();
    assert(result, option.data);
  });

  it("should stringify keys with strings", function () {
    let result;
    const option = {
      keys: "hello",
      script: "print(KEYS)",
      print: (text) => {
        result = text;
      },
    };
    zenroom.init(option).zenroom_exec();
    assert(result, option.keys);
  });

  it("should stringify keys with object literals", function () {
    let result;
    const option = {
      keys: { a: 1 },
      script: "print(JSON.encode(KEYS))",
      print: (text) => {
        result = text;
      },
    };
    zenroom.init(option).zenroom_exec();
    assert(result, option.keys);
  });

  it("should stringify undefined with keys correctly", function () {
    let result;
    const option = {
      keys: undefined,
      script: "print(KEYS)",
      print: (text) => {
        result = text;
      },
    };
    zenroom.init(option).zenroom_exec();
    assert(typeof result, "string");
    assert(result === "");
  });

  it("should stringify null with keys correctly", function () {
    let result;
    const option = {
      keys: null,
      script: "print(KEYS)",
      print: (text) => {
        result = text;
      },
    };
    zenroom.init(option).zenroom_exec();
    assert(typeof result, "string");
    assert(result === "");
  });

  it("should import work and be an object", function () {
    assert(zenroom);
  });

  it("should zenroom have exposed all public method", function () {
    const z = zenroom.init();
    expect(z)
      .to.be.an("object")
      .to.have.all.keys(
        "conf data zenroom_exec zencode_exec error init keys print print_err success script __debug reset".split(
          " "
        )
      );
  });

  it("should zenroom initialize script", function () {
    const z = zenroom.init({ script: 'print("hello")' });
    expect(console.log.called).to.be.false;
  });

  it("should zenroom exec script", function () {
    const z = zenroom.script('print("one script")').zenroom_exec();
    expect(z).to.be.an("object");
    expect(console.log.calledWithExactly("one script")).to.be.true;
  });

  it("should zenroom execute script with init", function () {
    zenroom.init({ script: 'print("exec with init")' }).zenroom_exec();
    expect(console.log.calledOnce).to.be.true;
  });

  it("should zenroom execute correctly with data", function () {
    let result;
    zenroom
      .data(encrypt_secret_to.data)
      .script(`print(JSON.encode(DATA))`)
      .print((text) => {
        result = text;
      })
      .zenroom_exec();
    expect(JSON.parse(JSON.parse(result))).to.have.all.keys(
      "zenroom Bob".split(" ")
    );
  });

  it("should zenroom execute correctly with keys", function () {
    let result;
    zenroom
      .keys(encrypt_secret_to.keys)
      .script(`print(JSON.encode(KEYS))`)
      .print((text) => {
        result = text;
      })
      .zenroom_exec();
    expect(JSON.parse(JSON.parse(result))).to.have.all.keys(
      "zenroom Alice".split(" ")
    );
  });

  it("should zenroom execute correctly with string DATA", function () {
    let result;
    const str = "daoisj daosijd äåöó²³2ö³óœ²ö³óœ";
    zenroom
      .data(str)
      .script(`print(DATA)`)
      .print((text) => {
        result = text;
      })
      .zenroom_exec();
    assert(str === result);
  });

  it("should zenroom execute correctly with string KEYS", function () {
    let result;
    const str = "daoisj daosijd äåöó²³2ö³óœ²ö³óœ";
    zenroom
      .keys(str)
      .script(`print(KEYS)`)
      .print((text) => {
        result = text;
      })
      .zenroom_exec();
    assert(str === result);
  });

  it("should script method work correctly", function () {
    const script = 'print("hello")';
    const options = zenroom.script(script).__debug();
    expect(options.script).to.be.equal(script);
  });

  it("should conf method work correctly", function () {
    const conf = "this monday is super monday";
    const options = zenroom.conf(conf).__debug();
    expect(options.conf).to.be.equal(conf);
  });

  it("should data method work correctly", function () {
    const data = "This is my DATA";
    const options = zenroom.data(data).__debug();
    expect(options.data).to.be.equal(data);
  });

  it("should keys method work correctly", function () {
    const keys = { a: 1, b: 2 };
    const options = zenroom.keys(keys).__debug();
    const keysResult = JSON.parse(options.keys);
    expect(keysResult).to.have.all.keys("a", "b");
    expect(keysResult).to.include(keys);
  });

  it("should initialize with correct params", function () {
    const data = { data: "some data" };
    const options = zenroom.init(data).__debug();
    expect(options.options).to.include(data);
  });

  it("should execute the error method on error", function () {
    let errorExecuted = false;
    const script = "broken script on purpose";
    const error = () => {
      errorExecuted = true;
    };
    zenroom.script(script).error(error).zenroom_exec();
    expect(errorExecuted).to.be.true;
  });

  it("should print_err work correctly", function () {
    const script = "broken script for print_err";
    let errors = [];
    let stderr = capcon.captureStderr(function scope() {
      zenroom
        .script(script)
        .print_err((text) => errors.push(text))
        .zencode_exec();
    });
    expect(errors).to.include(
      `[!] [string "ZEN:begin()..."]:2: Invalid Zencode prefix: broken\n`
    );
  });

  it("should print_err work correctly with zencode_exec", function () {
    const script = "broken script for print_err";
    let stderr = capcon.captureStderr(function scope() {
      zenroom
        .script(script)
        .print_err((text) => console.error(text))
        .zencode_exec();
    });
    expect(stderr).to.have.string(
      `[!] [string "ZEN:begin()..."]:2: Invalid Zencode prefix: broken`
    );
  });

  it("should print_err work correctly with zenroom_exec", function () {
    const script = "broken script for print_err";
    let stderr = capcon.captureStderr(function scope() {
      zenroom
        .script(script)
        .print_err((text) => console.error(text))
        .zenroom_exec();
    });
    expect(stderr).to.have.string(
      `[!] [string "broken script for print_err"]:1: syntax error near 'script'`
    );
  });

  it("should print_err work correctly with init", function () {
    let stderr = capcon.captureStderr(function scope() {
      zenroom
        .init({
          script: "broken init print_err",
          print_err: (text) => {
            console.error(text);
          },
        })
        .zenroom_exec();
    });
    expect(stderr).to.have.string(
      `[!] [string "broken init print_err"]:1: syntax error near 'init'`
    );
  });

  it("should execute the reset correctly", function () {
    let options = zenroom.init(encrypt_secret_to).__debug();
    expect(JSON.parse(options.data)).to.have.all.keys(
      Object.keys(encrypt_secret_to.data)
    );
    options = zenroom.reset().__debug();
    expect(options.data).to.be.equal(undefined);
    expect(options.error).to.not.throw();
  });

  it("should work error method with init also", function () {
    let errorExecuted = false;
    zenroom
      .init({
        script: "broken script on purpose",
        error: () => {
          errorExecuted = true;
        },
      })
      .zenroom_exec();
    expect(errorExecuted).to.be.true;
  });

  it("should execute the success method on success", function () {
    let executed = false;
    const script = 'print("hello")';
    const success = () => {
      executed = true;
    };
    zenroom.script(script).success(success).zenroom_exec();
    expect(executed).to.be.true;
  });

  it("should create a correct keygen", () => {
    const script = `
    -- generate a simple keyring
    keyring = ECDH.keygen()
    
    -- export the keypair to json
    export = JSON.encode(
       {
          public  = base64(keyring.public),
          private = base64(keyring.private)
       }
    )
    print(export)
    `;
    zenroom.script(script).zenroom_exec();
    const result = JSON.parse(console.log.args[0][0]);
    expect(result).to.have.all.keys("public private".split(" "));
  });

  it(`sohuld create correct keygen with zencode`, () => {
    let result;
    const zencode = `Rule check version 1.0.0
Scenario 'ecdh': Bob generate a keypair
Given that I am known as 'Bob'
When I create the keypair
Then print my data`;
    zenroom
      .script(zencode)
      .print((output) => {
        result = JSON.parse(output);
      })
      .zencode_exec();
    expect(result).to.have.all.keys("Bob");
    expect(result.Bob.keypair).to.have.all.keys(
      "public_key private_key".split(" ")
    );
  });

  it(`should broke whith a broken zencode`, () => {
    let stderr = capcon.captureStderr(function scope() {
      zenroom.script(`apokspoas`).zencode_exec();
    });
    expect(stderr).to.have
      .string(`[!] [string "ZEN:begin()..."]:2: Invalid Zencode line: apokspoas\n
[!] Error detected. Execution aborted.`);
  });

  it(`should broke whith a broken zencode and call the error callback`, () => {
    let errorExecuted = false;
    let stderr = capcon.captureStderr(function scope() {
      zenroom
        .init({
          script: "broken script on purpose",
          error: () => {
            errorExecuted = true;
          },
        })
        .zencode_exec();
    });
    expect(stderr).to.have.string(
      '[!] [string "ZEN:begin()..."]:2: Invalid Zencode prefix: broken'
    );
    expect(stderr).to.have.string("[!] Error detected. Execution aborted.");
    expect(errorExecuted).to.be.true;
  });

  it(`should correctly count a tallied petition`, () => {
    let result;
    const contract = ` Scenario credential
      Scenario petition: count
      Given that I have a valid 'petition'
      and I have a valid 'petition tally'
      When I count the petition results
      Then print the 'petition results' as 'number'
      and print the 'uid' as 'string' inside 'petition'`;
    const data = {
      credential_keypair: {
        private: "N4Gd2EwL8+PnbuaP/9LAiaJWkUALRj6+56Ek1Q57xLw=",
        public:
          "Awc2E4Zc7mQmWaRQPDQvaDus4Tx9AqUkxyUzJcJlqj+1FiukupJH0hS0mCoHkPK+0w==",
      },
      petition: {
        list: [
          "AkahcgTYCfvZjdW4u+F594V1cKBPuRvW96tIAzSo0gkvba/bZuKiKKkoH0KfzA5y+Q==",
        ],
        owner:
          "Awc2E4Zc7mQmWaRQPDQvaDus4Tx9AqUkxyUzJcJlqj+1FiukupJH0hS0mCoHkPK+0w==",
        scores: {
          neg: {
            left:
              "AwN1zq+OAXiSMWTtSVTJHWXDbyKGxvW8OXJ3NtZk31jJBPVJM8gEhBwZxtgicnRgzw==",
            right:
              "AiGDecOcxDGM1mNopKk3l+Z7MlFbcFBSUorLxaKT+MpX93TI6uk+IzG4FblfytLvJQ==",
          },
          pos: {
            left:
              "AgN1zq+OAXiSMWTtSVTJHWXDbyKGxvW8OXJ3NtZk31jJBPVJM8gEhBwZxtgicnRgzw==",
            right:
              "A0B4FiBMT+w9tedyZsqxqutlZmdaezSmKyf709cyQYB/8Le/GlEnfyCVmVoKc9ixpA==",
          },
        },
        uid: "cG9sbA==",
      },
      petition_tally: {
        c: "RcADcuTaeatXWo8m8tivd839+JWUONT7edpk8uYohU4=",
        dec: {
          neg:
            "AyGDecOcxDGM1mNopKk3l+Z7MlFbcFBSUorLxaKT+MpX93TI6uk+IzG4FblfytLvJQ==",
          pos:
            "AiGDecOcxDGM1mNopKk3l+Z7MlFbcFBSUorLxaKT+MpX93TI6uk+IzG4FblfytLvJQ==",
        },
        rx: "5Qht6r0p0t7tH2ALaXBlHR1238XywLRExKDPDnb2iqs=",
        uid: "cG9sbA==",
      },
    };
    const keys = {
      petition: {
        list: [
          "AkahcgTYCfvZjdW4u+F594V1cKBPuRvW96tIAzSo0gkvba/bZuKiKKkoH0KfzA5y+Q==",
        ],
        owner:
          "Awc2E4Zc7mQmWaRQPDQvaDus4Tx9AqUkxyUzJcJlqj+1FiukupJH0hS0mCoHkPK+0w==",
        scores: {
          neg: {
            left:
              "AwN1zq+OAXiSMWTtSVTJHWXDbyKGxvW8OXJ3NtZk31jJBPVJM8gEhBwZxtgicnRgzw==",
            right:
              "AiGDecOcxDGM1mNopKk3l+Z7MlFbcFBSUorLxaKT+MpX93TI6uk+IzG4FblfytLvJQ==",
          },
          pos: {
            left:
              "AgN1zq+OAXiSMWTtSVTJHWXDbyKGxvW8OXJ3NtZk31jJBPVJM8gEhBwZxtgicnRgzw==",
            right:
              "A0B4FiBMT+w9tedyZsqxqutlZmdaezSmKyf709cyQYB/8Le/GlEnfyCVmVoKc9ixpA==",
          },
        },
        uid: "cG9sbA==",
      },
      verifiers: {
        alpha:
          "FmgBYRaSGhNmVCcQHf+PKxPia9U7fX4tf+Fx2w9SbyJs5Q5P5fgcS/LDv/Nb4+V7ST8TGs+2k2WZPbEido8/IRqmF/y75JlCBQskPd51iXy8spK9OpqRr6P8Ym53PQ7AFUzYDTcmt/twbiQOaitFcZIpYJDcT249mdEP8pqRxesWfJfd6uDeHij76qwlfLOJFOgwMs0xLLX9ZcUsELifSzy4MBMpIqxOgy9TfDsoIN6Pq9umZfpBCDi4plF+dDk6",
        beta:
          "LI2bJdTIKkrjXeXjZKYn8aT/mIcPaE2oK62la2Z4qfui/fiB/R4OUn3iyBrEggK4LoERvVUtXwkRO0cwBTgrSERH7nUl/n1B20kFIBkxJGse0CnDHBpQ7OTCan5oxvbmCPRcYOp9CNJ81ResBILgOIYhF23oqWTZwq8PZdhFIkznrI5+V9y4APEV1g2oog6QIvu4L38GsuqhbqA/TEq4qJZ4ULCosBLrKs2vvGYaX5kGA8AF6u5LTMPejIEmvXZp",
      },
    };
    zenroom
      .script(contract)
      .data(data)
      .keys(keys)
      .print((t) => {
        result = JSON.parse(t);
      })
      .zencode_exec();
    expect(result).to.deep.include({ petition_results: 1, uid: "poll" });
  });
});
