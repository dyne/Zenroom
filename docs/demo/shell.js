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
                    type: 'stack',
                    content: [{
                        type: 'component',
                        componentName: 'OUTPUT',
                        componentState: { label: 'output' },
                        isClosable: false,
                    }, {
                        type: 'component',
                        componentName: 'LOGS',
                        componentState: { label: 'logs' },
                        isClosable: false,
                    }]
                }]
            }]
        }]
    }

    const loadExample = (e) => {
        const el = $(e.target)
        const zencode = el.data('zencode') || false
        const lua = el.data('lua') || false
        const data = el.data('data') || false
        const keys = el.data('keys') || false
        const editors = {'#code': lua, '#data': data, '#keys': keys, "#zencode": zencode}
        for (const eid in editors) {
            const url = editors[eid]
            const editor = $(eid)[0].env.editor
            editor.setValue("")
            if (url) {
                $.get(editors[eid], value => {
                    editor.setValue((typeof value === 'string') ? value : JSON.stringify(value))
                })
            }
        }
        return false
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

    const setupLogsComponent = function(container, state) {
        container.getElement().html(`<div style="height:88%" id="${state.label}"></div>`)
    }

    const bindAutoFocus = function(stack) {
        stack.on('activeContentItemChanged', item => {
            const state = item.container.getState()
            if ("editor" in state) {
                state.editor.focus()
            }
        });
    }

    const clearOutput = () => $("#output,#logs").html('');

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
        layout.registerComponent('LOGS', setupLogsComponent)
        layout.on('stackCreated', bindAutoFocus)
        layout.on('stackCreated', addControls)
        layout.init()
    }

    const init = function() {
       layoutInit()
       $(".example").on('click', e => loadExample(e))
    };

    const addAutocompletionWord = word => {
        autocompleteWords.push(word)
    }

    const autocompleteSetup = () => {
        $.get('/completions.lua', data => {
            Module.ccall('zenroom_exec', 
                         'number',
                         ['string', 'string', 'string', 'string'],
                         [data, null, null, null]);
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

    const execute_zenroom = function(code, zencode) {
        const keys = ace.edit("keys").getValue() || null
        const data = ace.edit("data").getValue() || null
        // const conf = $('#umm').attr('checked') ? 'umm' : null
        const conf = `verbose 3`
        outputBuffer = []
        clearOutput()
        let t0 = performance.now()
        Module.ccall(zencode ? 'zencode_exec' : 'zenroom_exec',
                         'number',
                         ['string', 'string', 'string', 'string'],
                         [code, conf, keys, data]);
        let t1 = performance.now()
        // console.log(t1-t0, 'ms')
        flushOutput()
        $('#timing').html(Math.ceil(t1-t0) + 'ms')
        $('#output')[0].scrollTop = $('#output')[0].scrollHeight
    }

    const zenroom = function() {
        const activeEditor = layout.root.getItemsById('container')[0].getActiveContentItem().container.getState().label
        let code = ace.edit(activeEditor).getValue()
        execute_zenroom(code, (activeEditor==='zencode'))
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
        let bg = ''
        let elements = '#logs'
        if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
        if (text.startsWith('[!]')) bg = 'has-background-danger has-text-light'
        if (text.startsWith('[W]')) bg = 'has-background-warning'
        if (bg) elements = '#logs, #output'

        $(`<span class="${bg}">${text}</span><br>`).appendTo(elements)
    },
    exec_ok: () => {},
    exec_error: () => {},
}
