import { expect } from 'chai'
import sinon from 'sinon'
import zenroom from '../src/wrapper'
const capcon = require('capture-console')
var assert = require('assert')

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
  keys: { 'zenroom': { 'curve': 'goldilocks', 'encoding': 'url64', 'version': '1.0.0+53387e8', 'scenario': 'simple' }, 'Alice': { 'keypair': { 'public_key': 'u64:BCYfOkN2YUXJxGYToRt3Z1ESg_niBQ1DZbwI8lZnX04KmR4tYjL5zy40u5FZvtoi93GWvIQYalusL4KsgfOt73UrO2vixOztl2pzkhBh6HVBWiLRTXtCb_HaIZFGyqxMF_hMI30ZWzsSgKgiZsb-YQw', 'private_key': 'u64:Ok51-tVCCCFCC4FOj6SgL0KPjHxELqDN8aEtODCo0LDcIHxy5T8k2Ns79zn2n23a_qszfGE5g5A' } } },
  data: { 'zenroom': { 'curve': 'goldilocks', 'encoding': 'url64', 'version': '1.0.0+53387e8', 'scenario': 'simple' }, 'Bob': { 'public_key': 'u64:BGx9Of0O2se9j6hLtgSc-2qo_mdaMhRgoMGtvNFC72xLMm-oGTpRkavl1gzpv1wi_KMpZNEIef6fDUfDR0UrPyPE5kKhbOAqX4jwHFkO0HbRNNeOwe-KZtiXiDQ60iOOt5dogqu5QqULVaiP2Q9PBsI' } }
}

describe('Zenroom module', function () {
  beforeEach(function (done) {
    zenroom.reset()
    this.clog = sinon.spy(console, 'log')
    this.cerr = sinon.spy(console, 'error')
    setTimeout(done, 200)
  })

  afterEach(function () {
    this.clog.restore()
    this.cerr.restore()
    zenroom.reset()
  })

  it('should stringify data with strings', function () {
    let result
    const option = {
      data: 'hello',
      script: 'print(DATA)',
      print: (text) => { result = text }
    }
    zenroom.init(option).zenroom_exec()
    assert(result, option.data)
  })

  it('should stringify data with object literals', function () {
    let result
    const option = {
      data: { 'a': 1 },
      script: 'print(JSON.encode(DATA))',
      print: (text) => { result = text }
    }
    zenroom.init(option).zenroom_exec()
    assert(result, option.data)
  })

  it('should stringify keys with strings', function () {
    let result
    const option = {
      keys: 'hello',
      script: 'print(KEYS)',
      print: (text) => { result = text }
    }
    zenroom.init(option).zenroom_exec()
    assert(result, option.keys)
  })

  it('should stringify keys with object literals', function () {
    let result
    const option = {
      keys: { 'a': 1 },
      script: 'print(JSON.encode(KEYS))',
      print: (text) => { result = text }
    }
    zenroom.init(option).zenroom_exec()
    assert(result, option.keys)
  })

  it('should stringify undefined with keys correctly', function () {
    let result
    const option = {
      keys: undefined,
      script: 'print(KEYS)',
      print: (text) => { result = text }
    }
    zenroom.init(option).zenroom_exec()
    assert(typeof result, 'string')
    assert(result === '')
  })

  it('should stringify null with keys correctly', function () {
    let result
    const option = {
      keys: null,
      script: 'print(KEYS)',
      print: (text) => { result = text }
    }
    zenroom.init(option).zenroom_exec()
    assert(typeof result, 'string')
    assert(result === '')
  })

  it('should import work and be an object', function () {
    assert(zenroom)
  })

  it('should zenroom have exposed all public method', function () {
    const z = zenroom.init()
    expect(z).to.be.an('object').to.have.all.keys('conf data zenroom_exec zencode_exec error init keys print print_err success script __debug reset'.split(' '))
  })

  it('should zenroom initialize script', function () {
    const z = zenroom.init({ script: 'print("hello")' })
    expect(console.log.called).to.be.false
  })

  it('should zenroom exec script', function () {
    const z = zenroom.script('print("one script")').zenroom_exec()
    expect(z).to.be.an('object')
    expect(console.log.calledWithExactly('one script')).to.be.true
  })

  it('should zenroom execute script with init', function () {
    zenroom.init({ script: 'print("exec with init")' }).zenroom_exec()
    expect(console.log.calledOnce).to.be.true
  })

  it('should zenroom execute correctly with data', function () {
    let result
    zenroom
      .data(encrypt_secret_to.data)
      .script(`print(JSON.encode(DATA))`)
      .print(text => { result = text })
      .zenroom_exec()
    expect(JSON.parse(JSON.parse(result))).to.have.all.keys('zenroom Bob'.split(' '))
  })

  it('should zenroom execute correctly with keys', function () {
    let result
    zenroom
      .keys(encrypt_secret_to.keys)
      .script(`print(JSON.encode(KEYS))`)
      .print(text => { result = text })
      .zenroom_exec()
    expect(JSON.parse(JSON.parse(result))).to.have.all.keys('zenroom Alice'.split(' '))
  })

  it('should zenroom execute correctly with string DATA', function () {
    let result
    const str = 'daoisj daosijd äåöó²³2ö³óœ²ö³óœ'
    zenroom
      .data(str)
      .script(`print(DATA)`)
      .print(text => { result = text })
      .zenroom_exec()
    assert(str === result)
  })

  it('should zenroom execute correctly with string KEYS', function () {
    let result
    const str = 'daoisj daosijd äåöó²³2ö³óœ²ö³óœ'
    zenroom
      .keys(str)
      .script(`print(KEYS)`)
      .print(text => { result = text })
      .zenroom_exec()
    assert(str === result)
  })

  it('should script method work correctly', function () {
    const script = 'print("hello")'
    const options = zenroom.script(script).__debug()
    expect(options.script).to.be.equal(script)
  })

  it('should conf method work correctly', function () {
    const conf = 'this monday is super monday'
    const options = zenroom.conf(conf).__debug()
    expect(options.conf).to.be.equal(conf)
  })

  it('should data method work correctly', function () {
    const data = 'This is my DATA'
    const options = zenroom.data(data).__debug()
    expect(options.data).to.be.equal(data)
  })

  it('should keys method work correctly', function () {
    const keys = { a: 1, b: 2 }
    const options = zenroom.keys(keys).__debug()
    const keysResult = JSON.parse(options.keys)
    expect(keysResult).to.have.all.keys('a', 'b')
    expect(keysResult).to.include(keys)
  })

  it('should initialize with correct params', function () {
    const data = { data: 'some data' }
    const options = zenroom.init(data).__debug()
    expect(options.options).to.include(data)
  })

  it('should execute the error method on error', function () {
    let errorExecuted = false
    const script = 'broken script on purpose'
    const error = () => {
      errorExecuted = true
    }
    zenroom.script(script).error(error).zenroom_exec()
    expect(errorExecuted).to.be.true
  })

  it('should execute the reset correctly', function () {
    let options = zenroom.init(encrypt_secret_to).__debug()
    expect(JSON.parse(options.data)).to.have.all.keys(Object.keys(encrypt_secret_to.data))
    options = zenroom.reset().__debug()
    expect(options.data).to.be.equal(undefined)
    expect(options.error).to.not.throw()
  })

  it('should work error method with init also', function () {
    let errorExecuted = false
    zenroom.init({
      script: 'broken script on purpose',
      error: () => { errorExecuted = true }
    }).zenroom_exec()
    expect(errorExecuted).to.be.true
  })

  it('should execute the success method on success', function () {
    let executed = false
    const script = 'print("hello")'
    const success = () => {
      executed = true
    }
    zenroom.script(script).success(success).zenroom_exec()
    expect(executed).to.be.true
  })

  it('should create a correct keygen', () => {
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
    `
    zenroom.script(script).zenroom_exec()
    const result = JSON.parse(console.log.args[0][0])
    expect(result).to.have.all.keys('public private'.split(' '))
  })

  it(`sohuld create correct keygen with zencode`, () => {
    let result
    const zencode = `
    Rule check version 1.0.0
Scenario 'simple': Bob generate a keypair
Given that I am known as 'Bob'
When I create the keypair
Then print my data
    `
    zenroom.script(zencode).print(output => { result = JSON.parse(output) }).zencode_exec()
    expect(result).to.have.all.keys('Bob')
    expect(result.Bob.keypair).to.have.all.keys('public_key private_key'.split(' '))
  })

  it(`should broke whith a broken zencode`, () => {
    let stderr = capcon.captureStderr(function scope () {
      zenroom.script(`apokspoas`).zencode_exec()
    })
    expect(stderr).to.have.string(`[!] [string "ZEN:begin()..."]:2: Invalid Zencode line: apokspoas
[!] Error detected. Execution aborted.`)
  })

  it(`should broke whith a broken zencode and call the error callback`, () => {
    let errorExecuted = false
    let stderr = capcon.captureStderr(function scope () {
      zenroom.init({
        script: 'broken script on purpose',
        error: () => { errorExecuted = true }
      }).zencode_exec()
    })
    expect(stderr).to.have.string('[!] [string "ZEN:begin()..."]:2: Invalid Zencode prefix: broken')
    expect(stderr).to.have.string('[!] Error detected. Execution aborted.')
    expect(errorExecuted).to.be.true
  })

  it(`should correctly count a tallied petition`, () => {
    let result
    const contract = `Scenario coconut: count petition
    Given that I have a valid 'petition'
    and I have a valid 'petition tally'
    When I count the petition results
    Then print the 'petition results'
    and print as 'string' the 'uid' inside 'petition'`
    const data = { 'petition': { 'list': ['AwUH_Rlj8Bcus2fSIq43TMQrsH6pkkwo3SU8j80QHy0DtY_MdRvKzy7EUWb2MCRANauVQU5wTovHTus'], 'owner': 'AgOeMqZ9U8x-Y2MpZW_7ol2ypzMVJ8R5GgRHDN28QzAmmqK0EoHn_6EDC1is_w6p6GGbAfbUet2iwXU', 'scores': { 'neg': { 'left': 'AwhTBQereoQOA6HZ4GxNvgAlZUniqs2o0VcEPVOEXtRWb8qnGAB82oUNWKnpVs2GxnNAGWyfSObRFD4', 'right': 'AwdPb0fDAr2uaNhnTXeLTxe88ANaNlt6m6ZvWEr82_RdRz1H-Kry8AXh4ezFFWZmh9nKZK-7Jg6S3lw' }, 'pos': { 'left': 'AghTBQereoQOA6HZ4GxNvgAlZUniqs2o0VcEPVOEXtRWb8qnGAB82oUNWKnpVs2GxnNAGWyfSObRFD4', 'right': 'AgPB7BJ1-wG8YaK-1M7h7WRCYhqxu7AYhjzFE0l9rUb746hjYbcjYiPaxWAbf8RQtLOvC7omLiyW0fo' } }, 'uid': 'cG9sbA' }, 'verifiers': { 'alpha': 'A9Qek4uE84c81vE1Ql737u8RGyfWXn3gTmM2W954sInwrVz-KHtufk6J7Yyj8LTNS6AWIeS9CxoXuQEo3PQYBlWsLbCrjOASQIb7g4vcC2gKk63HKA-EkEnbw11tZFZbL9d13PII3A_dhD7Qh-IJid_Q_sYTXVwSO0W5LgNOpdRSXVbWHxDDF6hpm1uRPOYcDzeVp0L_xVu1F7rcFs3iNZln06NQOruBHaoSm3jpBYafD5wd0-C_Mhf35NaaNtjGPgBbiFx-UJmtwyjolsk9kgNDPgvDPqcGbfpo1yZg9IrZjFMrWpFFXQ', 'beta': 'AwIuF4zyuGX4O6HQAdpkAAxqAf6DAaXDyCy_992ccO-kpc3RqJVh7st3wQBOR2N4CfuNrLzOL54_dwV3F4DWwrA759x3Vr0m-c03fGnBUlbqMR1E5bRqymURkzl5jV3ArbQeu7z24EwcYwm3IPmSPmbLjfEJezn8KDsYZl15YiF8M2rO0ORE2F6XcFsjL62NmWWmv7sE15ADLTzbZKsvspQM0Rd7UuM67Ws6lqDfAUxKFP7jBxlSQgR-0TUsCUjzBs-OeSJ9OvzzY_7Rdtqoi1zCkj0Xz8TAzHOVPQ0vykucxdzPRuyD7Q' } }
    const keys = { 'credential_keypair': { 'private': 'B9UsanWy7fvmQgpM2craxQ97KwKBT2swhjvzoc9ocEa0Pzpg_4I3', 'public': 'AgOeMqZ9U8x-Y2MpZW_7ol2ypzMVJ8R5GgRHDN28QzAmmqK0EoHn_6EDC1is_w6p6GGbAfbUet2iwXU' }, 'petition': { 'list': ['AwUH_Rlj8Bcus2fSIq43TMQrsH6pkkwo3SU8j80QHy0DtY_MdRvKzy7EUWb2MCRANauVQU5wTovHTus'], 'owner': 'AgOeMqZ9U8x-Y2MpZW_7ol2ypzMVJ8R5GgRHDN28QzAmmqK0EoHn_6EDC1is_w6p6GGbAfbUet2iwXU', 'scores': { 'neg': { 'left': 'AwhTBQereoQOA6HZ4GxNvgAlZUniqs2o0VcEPVOEXtRWb8qnGAB82oUNWKnpVs2GxnNAGWyfSObRFD4', 'right': 'AwdPb0fDAr2uaNhnTXeLTxe88ANaNlt6m6ZvWEr82_RdRz1H-Kry8AXh4ezFFWZmh9nKZK-7Jg6S3lw' }, 'pos': { 'left': 'AghTBQereoQOA6HZ4GxNvgAlZUniqs2o0VcEPVOEXtRWb8qnGAB82oUNWKnpVs2GxnNAGWyfSObRFD4', 'right': 'AgPB7BJ1-wG8YaK-1M7h7WRCYhqxu7AYhjzFE0l9rUb746hjYbcjYiPaxWAbf8RQtLOvC7omLiyW0fo' } }, 'uid': 'cG9sbA' }, 'petition_tally': { 'c': 'xTeVns8-JeofKqT5KSX1xtQUB_lyVkUQGJSZpEmJ7yA', 'dec': { 'neg': 'AgdPb0fDAr2uaNhnTXeLTxe88ANaNlt6m6ZvWEr82_RdRz1H-Kry8AXh4ezFFWZmh9nKZK-7Jg6S3lw', 'pos': 'AwdPb0fDAr2uaNhnTXeLTxe88ANaNlt6m6ZvWEr82_RdRz1H-Kry8AXh4ezFFWZmh9nKZK-7Jg6S3lw' }, 'rx': 'BLahbPKzsXDsbjHF2FN18BcIw8T5ZyvBRfU59ZTMye4qOGr3daBw', 'uid': 'cG9sbA' } }
    zenroom.script(contract).data(data).keys(keys).print(t => { result = JSON.parse(t) }).zencode_exec()
    expect(result).to.deep.include({ 'petition_results': 1, 'uid': 'poll' })
  })
})
