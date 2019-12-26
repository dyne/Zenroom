var ZR = (function() {
    let autocompleteWords = []
    let outputBuffer = []
    let layout = null

    const initialConfig = {
        settings: {
            showPopoutIcon: false,
            showCloseIcon: false,
        },
        dimensions: {
            headerHeight: 28
        },
        content: [{
            type: 'row',
            content: [{
                type: 'stack',
                id: 'container',
                content: [{
                    type: 'component',
                    title: 'ZENCODE',
                    componentName: 'ZencodeEditor',
                    componentState: { label: 'zencode' },
                    isClosable: false,
                }, {
                    type: 'component',
                    title: 'LUA',
                    componentName: 'CodeEditor',
                    componentState: { label: 'code' },
                    isClosable: false,
                }]
            }, {
                type: 'column',
                content: [{
                    type: 'stack',
                    content: [{
                        type: 'component',
                        title: 'KEYS',
                        componentName: 'JsonEditor',
                        componentState: { label: 'keys' },
                        isClosable: false,
                    }, {
                        type: 'component',
                        title: 'DATA',
                        componentName: 'JsonEditor',
                        componentState: { label: 'data' },
                        isClosable: false,
                    }]
                }, {
                    type: 'component',
                    componentName: 'OUTPUT',
                    componentState: { label: 'output' },
                    isClosable: false,
                }]
            }]
        }]
    }

    const loadExamples = (e) => {
        const name = $(e.target).attr('id')
        const extensions = {'#code': '.lua', '#data': '.data', '#keys': '.keys'}
        const base_url = "/examples/"
        for (var e in extensions) {
            const editor = $(e)[0].env.editor
            editor.setValue("")
            $.get(base_url + name + extensions[e], value => {
                editor.setValue(value)
            })
        }
        return false;
    }


    const loadZencodeExamples = (e) => {
        const name = $(e.target).attr('id');
        const extensions = {'#zencode': '.zen', '#data': '.data', '#keys': '.keys'}
        const base_url = "/examples/"
        for (var e in extensions) {
            const editor = $(e)[0].env.editor
            editor.setValue("")
            $.get(base_url + name + extensions[e], value => {
                editor.setValue(value)
            })
        }
    }

    const loadCoconutExamples = (e) => {
        const name = $(e.target).attr('id');
        const base_url = "https://raw.githubusercontent.com/DECODEproject/zenroom/master/test/zencode_coconut/"
        const editor = $('#zencode')[0].env.editor
        editor.setValue("")
        $.get(base_url + name, value => {
            editor.setValue(value)
        })
    }

    const setupCodeEditor = editor => {
        editor.setOptions({
            enableBasicAutocompletion: true,
            enableLiveAutocompletion: true,
        });
        editor.session.setMode("ace/mode/lua");
        editor.commands.addCommand({
            name: 'run',
            bindKey: {win: 'Ctrl-Enter',  mac: 'Command-Enter'},
            exec: () => {
            }
        });
        editor.commands.addCommand({
            name: 'clear',
            bindKey: {win: 'Ctrl-l',  mac: 'Ctrl-l'},
            exec: editor =>  { $("#output").html("") }
        });
        editor.focus();
    }

    const setupCodeEditorComponent = function(container, state) {
        container.getElement().html(`<div style="height:100%" id="${state.label}"></div>`)
        container.on('open', ()=>{
            const editor = ace.edit(state.label);
            setupCodeEditor(editor)
        })
    }

    const setupZencodeEditorComponent = function(container, state) {
        container.getElement().html(`<div style="height:100%" id="${state.label}"></div>`)
        container.on('open', () => {
            const editor = ace.edit(state.label)
            editor.session.setMode("ace/mode/gherkin")
            container.extendState({editor: editor})
        })
    }

    const setupJsonEditorComponent = function(container, state) {
        container.getElement().html(`<div style="height:100%" id="${state.label}"></div>`)
        container.on('open', () => {
            const editor = ace.edit(state.label)
            editor.session.setMode("ace/mode/json")
            container.extendState({editor: editor})
        })
    }

    const setupOutputComponent = function(container, state) {
        container.getElement().html(`<div style="height:100%" class="has-background-dark has-text-light" id="${state.label}"></div>`)
        var elapsed = $('<span class="tag" id="timing">0 ms</span>')
        container.on('tab', tab => {
            tab.element.append(elapsed)
        })
    }

    const bindAutoFocus = function(stack) {
        stack.on('activeContentItemChanged', item => {
            const state = item.container.getState()
            if ("editor" in state) {
                state.editor.focus()
            }
        });
    }

    const clearOutput = () => $("#output").html('');

    const addControls = function(stack) {
        const component = stack.contentItems[0]
		if (!component)
			return
        if (component.componentName == 'ZencodeEditor') {
            const button = $($('#play-button-template').html())
            stack.header.controlsContainer.prepend(button)
            button.on('click', ()=>{
                setTimeout(zenroom, 100)
            })
        }

        if (component.componentName == 'OUTPUT') {
            const copyButton = $($('#copy-button-template').html())
            const button = $($('#clear-button-template').html())
            stack.header.controlsContainer.prepend(copyButton)
            stack.header.controlsContainer.prepend(button)
            button.on('click', clearOutput)
        }
    }

    const loadConfig = () => {
        return localStorage.getItem('savedState') || initialConfig
    }

    const layoutInit = () => {
        layout = new GoldenLayout(loadConfig());
        layout.registerComponent('CodeEditor', setupCodeEditorComponent)
        layout.registerComponent('JsonEditor', setupJsonEditorComponent)
        layout.registerComponent('ZencodeEditor', setupZencodeEditorComponent)
        layout.registerComponent('OUTPUT', setupOutputComponent)
        layout.on('stackCreated', bindAutoFocus)
        layout.on('stackCreated', addControls)
        layout.init()
    }

    const init = function() {
       layoutInit()
       $(".examples").on('click', e => loadExamples(e))
	   $(".zencode").on('click', e => loadZencodeExamples(e))
       // $(".coconut").on('click', e => loadCoconutExamples(e))
    };

    const addAutocompletionWord = word => {
        autocompleteWords.push(word)
    }

    const autocompleteSetup = () => {
        $.get('https://raw.githubusercontent.com/DECODEproject/zenroom/master/docs/completions.lua', data => {
            Module.ccall('zenroom_exec', 
                         'number',
                         ['string', 'string', 'string', 'string', 'number'],
                         [data, null, null, null, 3]);
            Module['print'] = (function() {
                return function(text) {
                    if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
                    outputBuffer.push(text)
                };
            })()
            const langTools = ace.require("ace/ext/language_tools");
            const cryptoCompleter = {
                getCompletions: function(editor, session, pos, prefix, callback) {
                    if (prefix.length === 0) { callback(null, []); return }
                    callback(null, autocompleteWords.map(word => ({name: word, value: word, meta: 'zenroom'})))
                }
            }
            langTools.addCompleter(cryptoCompleter)
        })
    }

    const flushOutput = () => {
        renderedJson = null
        if (outputBuffer.length == 1) {
            try {
                renderjson.set_show_to_level(2);
                renderedJson = renderjson(JSON.parse(outputBuffer))
            } catch {}
        }
        var resultBuffer = outputBuffer.join('<br/>')
        $('#output').append(renderedJson||resultBuffer)
        $('#copyOutput').removeClass('has-text-grey-light');
        $('#copyOutput').off('click').on('click', function() {
            $(this).addClass('has-text-grey-light')
            var $temp = $("<input>");
            $("body").append($temp);
            $temp.val(outputBuffer).select();
            document.execCommand("copy");
            $temp.remove();
        })
    }

    const execute_zenroom = function(code) {
        const keys = ace.edit("keys").getValue() || null
        const data = ace.edit("data").getValue() || null
        const conf = $('#umm').attr('checked') ? 'umm' : null
        outputBuffer = []
        clearOutput()
        let t0 = performance.now()
        Module.ccall('zenroom_exec', 
                         'number',
                         ['string', 'string', 'string', 'string', 'number'],
                         [code, conf, keys, data, 3]);
        let t1 = performance.now()
        console.log(t1-t0, 'ms')
        flushOutput()
        $('#timing').html(Math.ceil(t1-t0) + 'ms')
        $('#output')[0].scrollTop = $('#output')[0].scrollHeight
    }

    const zenroom = function() {
        const activeEditor = layout.root.getItemsById('container')[0].getActiveContentItem().container.getState().label
        let code = ace.edit(activeEditor).getValue()
        if (activeEditor == 'zencode') {
            code = `
ZEN:begin(0)
ZEN:parse([[
${code}
]])
ZEN:run()
            `
            console.log(code)
        }
        execute_zenroom(code)
    }

    return {
        init: init,
        zenroom: zenroom,
        addAutocompletionWord: addAutocompletionWord,
        autocompleteSetup: autocompleteSetup
    }
})();

var Module = {
    preRun: [ZR.autocompleteSetup],
    postRun: [],
    print:  (()=> {
        return text => { 
            ZR.addAutocompletionWord(text)
        }
    })(),
    printErr: function(text) {
        if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
        if (text.startsWith('[!]')) {
            $(`<span class='has-background-danger'>${text}</span><br>`).appendTo("#output")
            return
        }
        console.error(text)
    },
    exec_ok: () => {},
    exec_error: () => {},
}
