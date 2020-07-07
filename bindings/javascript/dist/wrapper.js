"use strict";

require("core-js/modules/es.symbol");

require("core-js/modules/es.symbol.description");

require("core-js/modules/es.symbol.iterator");

require("core-js/modules/es.array.iterator");

require("core-js/modules/es.object.assign");

require("core-js/modules/es.object.to-string");

require("core-js/modules/es.string.iterator");

require("core-js/modules/web.dom-collections.iterator");

require("core-js/stable");

require("regenerator-runtime/runtime.js");

var _zenroom = _interopRequireDefault(require("../dist/lib/zenroom.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

var C = (0, _zenroom.default)();
/* istanbul ignore next */

var zenroomExec = function zenroomExec(script) {
  var conf = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;
  var keys = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : null;
  var data = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : null;
  C.then(function (Module) {
    Module.ccall('zenroom_exec', 'number', ['string', 'string', 'string', 'string'], [script, conf, keys, data]);
  });
};
/* istanbul ignore next */


var zencodeExec = function zencodeExec(script) {
  var conf = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;
  var keys = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : null;
  var data = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : null;
  C.then(function (Module) {
    Module.ccall('zencode_exec', 'number', ['string', 'string', 'string', 'string'], [script, conf, keys, data]);
  });
};

var stringify = function stringify(field) {
  if (!field) {
    return null;
  }

  try {
    return JSON.stringify(JSON.parse(field));
  } catch (e) {
    if (_typeof(field) === 'object') {
      return JSON.stringify(field);
    }

    if (typeof field === 'string') {
      return field;
    }
  }
};

var zenroom = function () {
  var self = {};
  self.options = {};

  var __debug = function __debug() {
    return self;
  };
  /**
   * First, you'll have create a script that Zenroom can execute.
   * In this first section, we're covering Zenroom's scripts in Lua,
   * if you want to execute smart contracts in Zencode (Zenroom's
   * domain specific language), please see below.
   *
   * This method set the zenroom lua or zencode to run.
   *
   * The syntax of the Zenroom Lua scripts is documented at
   * https://dev.zenroom.org/
   * You may want also to look at some example in a live
   * executable environment at: https://dev.zenroom.org/demo
   *
   * @example <caption>Example usage of `script()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const script = 'print("hello")'
   * zenroom.script(script).zenroom_exec().reset()
   *
   * @param {string} script the lua script to be set
   * @returns {zenroom} as zenroom module
   */


  var script = function script(_script) {
    self.script = _script;
    return this;
  };
  /**
   * Set the parameter "keys" in JSON for the script/smart contract
   * you're executing in Zenroom.
   *
   * The keys will be available in the execution of the script/smart
   * contract as the `KEYS` variable.
   *
   * @example <caption>Example usage of `keys()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const script = `
   *                  keys = JSON.decode(KEYS)
   *                  print(keys)
   * `
   *
   * const keys = {a: 1, b: 2}
   * zenroom.script(script).keys(keys).zenroom_exec().reset()
   *
   * @param {object} keys the keys to be set as an object
   * @returns {object} as zenroom module
   */


  var keys = function keys(_keys) {
    self.keys = stringify(_keys);
    return this;
  };
  /**
   * Set the parameter "data" in JSON for the script/smart
   * contract you're executing in Zenroom.
   *
   * The data will be available in the execution of the
   * script/smart contract as the `DATA` variable.
   *
   * @example <caption>Example usage of `data()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const script = `
   *                  data = JSON.decode(DATA)
   *                  print(data)
   * `
   *
   * const data = {a: 1, b: 2}
   * zenroom.script(script).data(data).zenroom_exec()
   *
   * @param {string} data
   * @returns {object} as zenroom module
   */


  var data = function data(_data) {
    self.data = stringify(_data);
    return this;
  };
  /**
   * Set the configuration of zenroom execution.
   *
   * The possible configurations are available
   * [here](https://github.com/DECODEproject/Zenroom/blob/master/src/zen_config.c #L104-L111)
   *
   * @example <caption>Example usage of `conf()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const script = 'print("hello")'
   * const conf = 'debug=1,memwipe=0'
   * zenroom.script(script).conf(conf).zenroom_exec()
   *
   * @param {string} conf the string of configuration to be set
   * @returns {object} as zenroom module
   */


  var conf = function conf(_conf) {
    self.conf = _conf;
    return this;
  };
  /**
   * Set the print_err callback: customize the behaviour of the
   * print_err calls made to stderr,by default it prints to the
   * `console.error`
   *
   * @example <caption>Example usage of `print_err()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const savedLines = []
   * const print_err_fn = (text) => { savedLines.push(text) }
   * const script = 'print("hello")'
   * zenroom.print_err(print_err_fn).script(script).zenroom_exec()
   *
   * @callback print_err
   * @returns {object} as zenroom module
   */


  var print_err = function print_err(e) {
    self.print_err = e;
    C.then(function (Module) {
      Module.printErr = function (text) {
        return self.print_err(text);
      };
    });
    return this;
  };
  /**
   * Set the print callback: customize * the behavior of the
   * print calls made to stdout,by default it prints to the
   * `console.log`
   *
   * @example <caption>Example usage of `print()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const savedLines = []
   * const printFunction = (text) => { savedLines.push(text) }
   * const script = 'print("hello")'
   * zenroom.print(printFunction).script(script).zenroom_exec()
   *
   * @callback print
   * @returns {object} as zenroom module
   */


  var print = function print(printFunction) {
    self.print = printFunction;
    C.then(function (Module) {
      Module.print = function (text) {
        return self.print(text);
      };
    });
    return this;
  };
  /**
   * Set the `success` callback that is executed after
   * a successful execution of Zenroom
   *
   * @example <caption>Example usage of `success()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const script = 'print("hello")'
   * zenroom.script(script).success(()=>{
   *    pleaseRunSomeOtherMethodAfter()
   * }).zenroom_exec()
   *
   * @callback success
   * @returns {object} as zenroom module
   */


  var success = function success(successCallback) {
    self.success = successCallback;
    C.then(function (Module) {
      Module.exec_ok = successCallback;
    });
    return this;
  };
  /**
   * Set the "error callback" that is executed after an
   * unsuccessful execution of Zenroom
   *
   * @example <caption>Example usage of `error()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const script = 'print("hello")';
   * zenroom.script(script).error(()=>{
   *    pleaseRunSomeOtherMethodAfterError()
   * }).zenroom_exec()
   *
   * @callback error
   * @returns {object} as zenroom module
   */


  var error = function error(errorCallback) {
    self.error = errorCallback;
    C.then(function (Module) {
      Module.exec_error = errorCallback;
    });
    return this;
  };
  /**
   * Starts the Zenroom VM, using the parameters previously set.
   *
   * This is usually the last method of the chain. Just like the
   * other methods, it returns the zenroom module itself, so it
   * can be used for other calls if you need to run more executions
   * in a row.
   *
   * @example <caption>Example usage of `zenroom_exec()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const script = 'print("hello")';
   * zenroom.script(script).zenroom_exec()
   *
   * @returns {object} as zenroom module
   */


  var zenroom_exec = function zenroom_exec() {
    zenroomExec(self.script, self.conf, self.keys, self.data);
    return this;
  };
  /**
   * Execute [Zencode](https://dev.zenroom.org/#/pages/zencode)
   * smart contracts, using the previously setted options.
   *
   * This is usually the last method of the chain. Just like the
   * other methods, it returns the zenroom module itself, so it
   * can be used for other calls if you need to run more executions
   * in a row.
   *
   * @example <caption>Example usage of `zencode_exec()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const zencode = 'print("hello")';
   * zenroom.script(script).zencode_exec()
   *
   * @returns {object} as zenroom module
   */


  var zencode_exec = function zencode_exec() {
    zencodeExec(self.script, self.conf, self.keys, self.data);
    return this;
  };
  /**
   * This method allows the configuration of your call by passing one
   * configuration option object. You can chain methods after this anyway.
   *
   * If some attribute is already set, those will be overwritten by the new
  options.
   *
   * The following options are available:
   * <ul>
   *   <li><strong>script</strong></li>
   *   <li><strong>keys</strong></li>
   *   <li><strong>conf</strong></li>
   *   <li><strong>data</strong></li>
   *   <li><strong>print</strong></li>
   *   <li><strong>print_err</strong></li>
   *   <li><strong>success</strong></li>
   *   <li><strong>error</strong></li>
   * </ul>
   *
   * @example <caption>Example usage of `init()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const encrypt_secret_to_many = {
   *  script: `keyring = ECDH.new()
   *            secret = str(DATA)
   *            keys = JSON.decode(KEYS)
   *            keyring:private( base64(keys.keyring.secret) )
   *            res = {}
   *            for name,pubkey in pairs(keys.recipients) do
   *              pub = base64(pubkey)
   *              enc = ECDH.encrypt(keyring,pub,secret,keyring:public())
   *              res[name] = str( MSG.pack( map(enc,base64) ) ):base64()
   *            end
   *            print(JSON.encode(res))`,
   *
   *  keys: {
   *      keyring : {
   *        public : "BHMjcDM/aljpi8pNxFQ436R6F3J+kaB/Xk1kAVFPmkoLVyeFltDZPgiIYRquh+m2IfvPioBfet7YCd5vVXYoRTk=",
   *        secret : "ChW5qi5y//ISDIHKx5Fvxl+XY8IyDGVBHUfELp3PqJQ="
   *      },
   *      recipients : {
   *        paulus : "BBUw6Nr3A30cN65maERvAk1cEv2Ji6Vs80kSlpodOC0SCtM8ucaS7e+s158uVMSr3BsvIXVspBeafiL8Qb3kcgc=",
   *        mayo : "BHqBoQ2WJ3/FGVNTXzdIc+K/HzNx05bWzEhn8m58FvSsaqWVdH52jI6fQWdkdjnbqVKCJGmbjA/OCJ+IKHbiySI=",
   *        mark : "BFgkjrRMvN+wkJ6qA4UvMaNlYBvl37C9cNYGkqOE4w43AUzkEzcyIIdE6BrgOEUEVefhOOnO6SCBQMgXHXJUUPY=",
   *        francesca : "BCo102mVybieKMyhex8tnVtFM5+Wo1oP02k8JVwKF9OLIjw7w0LmofItbuAcfWl9rcoe++XLI3sySZnqljIfeyU=",
   *        jim : "BEs1jeqL0nVwFi7OmG4YdtlWuKADyOvZR4XHpLAEswg8ONPXQHvwJ8+PkHkphoORfSjk2045bMdYkwboU4FdG2Y=",
   *        jaromil : "BBZYJtHvFg0vGCxPROAWrThcGZ+vFZJj86k+uncjvbm4DysIg7cWS3J6GrcJKCY55Uf40m2KfBwfaT+T7TTO1e8="
   *      }
   *  },
   *
   *  data: 'This is a secret message.'
   * }
   *
   *
   * zenroom.init(encrypt_secret_to_many).zenroom_exec()
   *
   * @returns {object} as zenroom module
   */


  var init = function init(options) {
    /* istanbul ignore next */
    self.options = Object.assign(self.options, options) || {};
    script(self.options.script || '');
    keys(self.options.keys || null);
    conf(self.options.conf || null);
    data(self.options.data || null);
    print(self.options.print || function (text) {
      return console.log(text);
    });
    print_err(self.options.print_err || function (text) {
      return console.error(text);
    });
    success(self.options.success || new Function()); // eslint-disable-line no-new-func

    error(self.options.error || new Function()); // eslint-disable-line no-new-func

    return this;
  };

  var __setup = function __setup() {
    print(self.print || function (text) {
      return console.log(text);
    });
    print_err(self.print_err || function (text) {
      return console.error(text);
    });
    success(self.success || function () {});
    error(self.error || function () {});
  };
  /**
   * Reset the options previously set, and cleans up the zenroom module.
   *
   * This is can easily be the last method of the chain. Just like the
   * other methods, it returns the zenroom module itself, so it can be
   * used for other calls if you need to run more executions in a row.
   *
   * @example <caption>Example usage of `reset()`</caption>
   * // returns zenroom
   * import zenroom from 'zenroom'
   * // or without ES6 syntax
   * // const zenroom = require('zenroom')
   *
   * const script = 'print("hello")';
   * zenroom.script(script)
   *        .zenroom_exec()    // This runs the script
   *        .reset()
   *        .zenroom_exec()    // This does not run the script anymore
   *
   * @returns {object} as zenroom module
   */


  var reset = function reset() {
    self = {};
    self.options = {};

    __setup();

    return this;
  };

  __setup();

  return {
    script: script,
    keys: keys,
    conf: conf,
    data: data,
    print: print,
    print_err: print_err,
    success: success,
    zenroom_exec: zenroom_exec,
    zencode_exec: zencode_exec,
    error: error,
    init: init,
    reset: reset,
    __debug: __debug
  };
}();

module.exports = zenroom;