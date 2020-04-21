// This javascript code is Public Domain

var zencodeResults = [];

var ZC = (function() {
    let bobKeys = null
    let aliceKeys = null
    let t0 = 0
    let t1 = 0
    let zencode_encrypt_contract = `Rule check version 1.0.0
Scenario 'simple': Alice encrypts a message for Bob
        Given that I am known as 'Alice'
        and I have my valid 'keypair'
        and I have a valid 'public key' from 'Bob'
        When I write string 'This is my secret message.' in 'message'
        and I write string 'This is the header' in 'header'
        and I encrypt the message for 'Bob'
        Then print the 'secret message'
`
    const init = function() {
        setupForm()
		// show the contract
        $('#encrypt_contract').html(zencode_encrypt_contract)

		// generate the keypairs
        zencode(`Scenario 'simple': $scenario
                 Given that I am known as 'Bob'
                 When I create the keypair
                 Then print my data`, null, null)
        bobKeys = JSON.parse(zencodeResults.pop())
        $("#bob").html(JSON.stringify({Bob: { public_key: bobKeys.Bob.keypair.public_key}}))
        zencode(`Scenario 'simple': $scenario
                 Given that I am known as 'Alice'
                 When I create the keypair
                 Then print my data`, null, null)
        aliceKeys = JSON.parse(zencodeResults.pop())
        $("#alice").html(JSON.stringify(aliceKeys))
    };

    const setupForm = () => {
        const form = document.querySelector('form')

        form.addEventListener('submit', e => {
            e.preventDefault()

            const file = document.querySelector('[type=file]').files[0]
			if(file.size > 409600) { alert('File size too big'); return; }
            const reader = new FileReader();
            reader.onloadend = evt => {
                if (evt.target.readyState == FileReader.DONE) {
                    encrypt(evt.target.result)
                }
            }
            reader.readAsText(file, "UTF-8")
        })
    }

    const encrypt = (rawContent) => {
        const content = [
            { base64: btoa(unescape(encodeURIComponent(rawContent))) },
            { Bob: { public_key: bobKeys.Bob.keypair.public_key }}
        ]

        zencode(zencode_encrypt_contract,
                JSON.stringify(aliceKeys),
                JSON.stringify(content))

        $("#result").html(zencodeResults)
    }

    const zencode = function(code, keys, data) {
        zencodeResults = []
        t0 = performance.now()
        Module.ccall('zencode_exec',
                     'number',
                     ['string', 'string', 'string', 'string', 'number'],
                     [code, null, keys, data, 1]);
        t1 = performance.now()
        $('#speed').html(t1-t0)
    }

    return {
        init: init
    }
})();

var Module = {
    preRun: [],
    postRun: [],

    print: text => { zencodeResults.push(text) },

    printErr: function(text) {
		// pretty printing Zenroom messages on JS console
		if(text.charAt(1)=='!') console.error(text)
		else if(text.charAt(1)=='F') console.debug(text)
		else if(text.charAt(1)=='W') console.warn(text)
		else if(text.charAt(1)=='*') console.info(text)
        else console.log(text)
    },

    exec_ok: () => {},
    exec_error: () => {},
    onRuntimeInitialized: function () { ZC.init() }
}
