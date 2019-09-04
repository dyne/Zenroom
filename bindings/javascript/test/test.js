import { expect } from 'chai'
import sinon from 'sinon'
import zenroom from '../src/wrapper'
var assert = require('assert')

const encrypt_secret_to_many = {
  script: `
  keyring = ECDH.new('ED25519')
  secret = str(DATA)
  keys = JSON.decode(KEYS)
  keyring:private( base64(keys.keyring.secret) )
  res = {}
  for name,pubkey in pairs(keys.recipients) do
     pub = base64(pubkey)
     session = keyring:session(pub)
     iv = RNG.new():octet(16)
     out = { header = "encoded using zenroom " .. VERSION}
     out.text, out.checksum = 
      ECDH.aead_encrypt(session, secret, iv, out.header)
     res[name] = str( MSG.pack( map(out,base64) ) ):base64()
  end
  print(JSON.encode(res))
  `,
  keys: {
    "keyring" : {
       "public" : "BHMjcDM/aljpi8pNxFQ436R6F3J+kaB/Xk1kAVFPmkoLVyeFltDZPgiIYRquh+m2IfvPioBfet7YCd5vVXYoRTk=",
       "secret" : "ChW5qi5y//ISDIHKx5Fvxl+XY8IyDGVBHUfELp3PqJQ="
    },
    "recipients" : {
       "paulus" : "BBUw6Nr3A30cN65maERvAk1cEv2Ji6Vs80kSlpodOC0SCtM8ucaS7e+s158uVMSr3BsvIXVspBeafiL8Qb3kcgc=",
       "mayo" : "BHqBoQ2WJ3/FGVNTXzdIc+K/HzNx05bWzEhn8m58FvSsaqWVdH52jI6fQWdkdjnbqVKCJGmbjA/OCJ+IKHbiySI=",
       "mark" : "BFgkjrRMvN+wkJ6qA4UvMaNlYBvl37C9cNYGkqOE4w43AUzkEzcyIIdE6BrgOEUEVefhOOnO6SCBQMgXHXJUUPY=",
       "francesca" : "BCo102mVybieKMyhex8tnVtFM5+Wo1oP02k8JVwKF9OLIjw7w0LmofItbuAcfWl9rcoe++XLI3sySZnqljIfeyU=",
       "jim" : "BEs1jeqL0nVwFi7OmG4YdtlWuKADyOvZR4XHpLAEswg8ONPXQHvwJ8+PkHkphoORfSjk2045bMdYkwboU4FdG2Y=",
       "jaromil" : "BBZYJtHvFg0vGCxPROAWrThcGZ+vFZJj86k+uncjvbm4DysIg7cWS3J6GrcJKCY55Uf40m2KfBwfaT+T7TTO1e8="
    }
  },
  data: 'This is a secret message.'
}

describe('Zenroom module', function () {
  beforeEach(function (done) {
    zenroom.reset()
    this.clog = sinon.spy(console, 'log')
    this.cerr = sinon.spy(console, 'error')
    setTimeout(done, 200);
  })

  afterEach(function () {
    this.clog.restore()
    this.cerr.restore()
    zenroom.reset()
  })

  it('should import work and be an object', function () {
    assert(zenroom)
  })

  it('should zenroom have exposed all public method', function () {
    const z = zenroom.init()
    expect(z).to.be.an('object').to.have.all.keys('conf data zenroom_exec zencode_exec error init keys print success verbosity script __debug reset'.split(' '))
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

  it('should zenroom execute correctly with data and keys', function () {
    zenroom
      .script(encrypt_secret_to_many.script)
      .keys(encrypt_secret_to_many.keys)
      .data(encrypt_secret_to_many.data)
      .zenroom_exec()
    const result = JSON.parse(console.log.args[0][0])
    expect(result).to.have.all.keys('paulus mayo mark jim jaromil francesca'.split(' '))
    expect(console.log.calledOnce).to.be.true
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

  it('should verbosity method work correctly', function () {
    const options = zenroom.verbosity(2).__debug()
    expect(options.verbosity).to.be.equal(2)
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
    let options = zenroom.init(encrypt_secret_to_many).__debug()
    expect(options.data).to.be.equal(encrypt_secret_to_many.data)
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
    keyring = ECDH.new()
    keyring:keygen()
    
    -- export the keypair to json
    export = JSON.encode(
       {
          public  = keyring: public():base64(),
          private = keyring:private():base64()
       }
    )
    print(export)
    `
    zenroom.script(script).zenroom_exec()
    const result = JSON.parse(console.log.args[0][0])
    expect(result).to.have.all.keys('public private'.split(' '))
  })

  it(`sohuld create correct keygen with zencode`, () => {
    const zencode = `
    Scenario 'coconut': "To run over the mobile wallet the first time and store the output as keypair.keys"
    Given that I am known as 'identifier'
    When I create my new keypair
    Then print all data
    `
    zenroom.script(zencode).zencode_exec()
    const result = JSON.parse(console.log.args[0][0])
    expect(result).to.have.all.keys('identifier')
    expect(result.identifier).to.have.all.keys('public private curve encoding schema zenroom'.split(' '))
  })

  it(`should broke whith a broken zencode`, () => {
    zenroom.script(`apokspoas`).zencode_exec()
    const result = console.log.args[0][0]
    expect(console.log.called).to.be.true
    expect(result).to.be.equal('[W] Zencode text too short to parse')
  })

  it(`should broke whith a broken zencode and call the error callback`, () => {
    let errorExecuted = false
    zenroom.init({
      script: 'broken script on purpose',
      error: () => { errorExecuted = true }
    }).zencode_exec()
    const result = console.log.args[0][0]
    expect(result).to.be.equal('[W] No scenario found in first line of Zencode')
    expect(errorExecuted).to.be.false
  })

  it(`should correctly count a tallied petition`, () => {
    const contract = `Scenario 'coconut': "Count the petition results: any Citizen can count the petition as long as they have the 'tally'"
    Given that I receive a petition
    and I receive a tally
    When I count the petition results
    Then print all data`
    const data = {"verifier":{"alpha":"44ea1a84d36924acbf83bd4b53059b63dc5697990f456f0dbcd3dd29eaaa92e903f85828a9d8ff7bf6bdbf9515aa477f004b8c01db0df3e1d2689028d1204b0eb8acec26c2bfdef075b8c00dd1c4098ad759d88a6e5e14b4a8abbca316d50a2c1f7ede0ce19bc2a98af56210b5ab2c3238700db985564b8c0bdd4d999167e64feef014cc34713dd8dd7464a62b9c743f168e873866b434b90e3d758f8a03e7f778dfb7103d174f76be1bf6ec68aea9b6e8a8c266fc4ee71e1ac99b0d7f9de19d","zenroom":"0.10","curve":"bls383","beta":"53750ebd2642ad839e631dd58fd3467ae253f9cb197348acd418cd281f079eefa1374694bf9af9ee2788d4facb0027c64761f0324e9ea5b368fe5d3ccce40226385353f21ecf2db0ecdf656fe71381c67a33f452cae5822458b6387940d605052385419c4ce15781ecf1efeac9e4ab14314d29611b4be1e041af035d1252e5a2b2e995701d4336278888965ab456a4d728fa343100b6e858242b6661a3239744e03c9bbad7f19f9e72d831add5a23e7ecd8b7b84892dfe7343fbf2e2c9820cf9","encoding":"hex","schema":"issue_verify"},"petition":{"schema":"petition","scores":{"pos":{"left":"043944905aa1040a08018a17016325b6b14179d4edad14834c611805d841e60d7c2001de7b9d10b100162a7c7ff2b6b77e530a8f365f0266eed93660983a410502a58c41a99db0c6a2dd423b3773158d2cdb83c57154a0091453c80e43f4e1edfb","right":"044208118ae8eb9805d9634fd81f9ffbf06714bdf8000c5f709309ae71abd9896300fbd133f8eae766e071e54258387f0d41b74b8c9d7f3f35975c2ba0148fe2189841a2254557ca9be29f4517ab095772bd83352c7d55834a8df61f583cad75ea"},"zenroom":"0.10","curve":"bls383","neg":{"left":"043944905aa1040a08018a17016325b6b14179d4edad14834c611805d841e60d7c2001de7b9d10b100162a7c7ff2b6b77e025ac75f05a907c6c7374d2be5a98d81fb21048355b4de6eceef7cc9f64b97c79f0879b835c47c17866f0f2090c8c2b0","right":"04270b066337f935acfae701a89b051de2262bbc89dc66cecbe2c8c36b1b5ab604ad2d693b5011f4360a2768538d1e7fb63d2750a8dd5744102db212e4f842d0b7c0e52e62c31aaa1e6d82a419ec01b3ca77d802707442130f753b91e2fc1b819d"},"encoding":"hex","schema":"petition_scores"},"owner":"042a67cbac82b3e6c98516650cf3be60e8a9b2de33a3b48f15243fcbd5e8a8697a06a4158e21f44d0abf6a83414896a61a4292787022f5fa229f79fd1c6c4d1d12f84654b5dd40a05adc6e63a0111688a61b1aa829a22f753374f6cc8b0229c030","zenroom":"0.10","curve":"bls383","list":{"0411963c6efa4d89f955fb5fa642914ec5fdd45f06090ef91b97977fa6b062829f906605e753cd64f9bd7c53ccec78215c4d61734af501506a15d8ec3779874183f3b52a8dad7e5b9d824a9a71ae60e7a0e4288b2b0e37f477b52babf62779f969":true},"encoding":"hex","uid":"petition"}}
    const keys = {"petition":{"zenroom":"0.10","scores":{"encoding":"hex","pos":{"left":"043944905aa1040a08018a17016325b6b14179d4edad14834c611805d841e60d7c2001de7b9d10b100162a7c7ff2b6b77e530a8f365f0266eed93660983a410502a58c41a99db0c6a2dd423b3773158d2cdb83c57154a0091453c80e43f4e1edfb","right":"044208118ae8eb9805d9634fd81f9ffbf06714bdf8000c5f709309ae71abd9896300fbd133f8eae766e071e54258387f0d41b74b8c9d7f3f35975c2ba0148fe2189841a2254557ca9be29f4517ab095772bd83352c7d55834a8df61f583cad75ea"},"zenroom":"0.10","schema":"petition_scores","neg":{"left":"043944905aa1040a08018a17016325b6b14179d4edad14834c611805d841e60d7c2001de7b9d10b100162a7c7ff2b6b77e025ac75f05a907c6c7374d2be5a98d81fb21048355b4de6eceef7cc9f64b97c79f0879b835c47c17866f0f2090c8c2b0","right":"04270b066337f935acfae701a89b051de2262bbc89dc66cecbe2c8c36b1b5ab604ad2d693b5011f4360a2768538d1e7fb63d2750a8dd5744102db212e4f842d0b7c0e52e62c31aaa1e6d82a419ec01b3ca77d802707442130f753b91e2fc1b819d"},"curve":"bls383"},"encoding":"hex","curve":"bls383","owner":"042a67cbac82b3e6c98516650cf3be60e8a9b2de33a3b48f15243fcbd5e8a8697a06a4158e21f44d0abf6a83414896a61a4292787022f5fa229f79fd1c6c4d1d12f84654b5dd40a05adc6e63a0111688a61b1aa829a22f753374f6cc8b0229c030","schema":"petition","uid":"petition"},"tally":{"zenroom":"0.10","encoding":"hex","schema":"petition_tally","curve":"bls383","dec":{"neg":"04270b066337f935acfae701a89b051de2262bbc89dc66cecbe2c8c36b1b5ab604ad2d693b5011f4360a2768538d1e7fb6183e05ec87542aa572bb9adf27a7c1ccdfc817ca304afaf33eaf13e77d5f712a02b43cb91622721c64fb8b81898f2f0e","pos":"04270b066337f935acfae701a89b051de2262bbc89dc66cecbe2c8c36b1b5ab604ad2d693b5011f4360a2768538d1e7fb63d2750a8dd5744102db212e4f842d0b7c0e52e62c31aaa1e6d82a419ec01b3ca77d802707442130f753b91e2fc1b819d"},"uid":"petition","c":"650ce8460c8dfea188c6d39b30b3f5d70263fb5223ad9cd1b2c079f381222971","rx":"1dd316314adf32dc5ad906c611318fd5ca34e2cf3a1b663c3fad1fa4dc30f56e"}}
    zenroom.script(contract).data(data).keys(keys).verbosity(1).zencode_exec()
    const result = JSON.parse(console.log.args[7][0])
    expect(result).to.have.all.keys('result uid'.split(' '))
    expect(result.result).to.be.equal(1)
  })
})
