std = 'lua54'
ignore = { '611', '612', '614', '621', '631' }
globals = {
    'ZEN', 'OCTET', 'O', 'BIG', 'INT', 'ECP', 'ECP2', 'SALT', 'FLOAT', 'F', 'TIME', 'U',
    'Given','When','Then','IN','KIN','ACK','keyring','OUT','CONF','WHO',
    'INSPECT', 'CBOR', 'JSON', 'ECDH', 'AES', 'HASH', 'BENCH', 'KDF',
    'MACHINE', 'DATE', 'VERSION', 'SEMVER', 'I', 'EXTRA', 'KEYS', 'CODEC',
    'require', 'require_once','fif', 'deepmap', 'luatype', 'sort_pairs',
    'empty', 'have', 'initkeyring', 'havekey', 'zenguard', 'exitcode',
    'deprecated', 'mayhave', 'parse_prefix', 'strtok', 'strcasecmp',
    'uscore', 'debug_traceback', 'isnumber', 'trimq', 'load_scenario',
    'G2','ABC','ECDH', 'schema_get', 'deepsortmap', 
    'check_codec', 'ZKP_challenge', 'SHA256', 'SHA512', 'sha256', 'sha512',
    'printerr', 'act', 'notice', 'warn', 'error', 'xxx', 'fatal', 'trim', 'serialize', 'iszen',
    'DEBUG', 'ZEN_traceback', 'input_encoding', 'get_encoding_function', 'get_format',
    'isarray', 'isdictionary', 'array_contains',
    'guess_conversion', 'operate_conversion', 'deepcopy', 'guess_outcast', 'new_codec',
    'hex', 'str', 'bin', 'base64', 'url64', 'base58',
    'IfWhen', 'jsontok', 'zencode_assert', 'zencode_serialize', 'zulu2timestamp'
    }
local _columns = 140
max_line_length	= _columns
max_code_line_length = _columns
max_string_line_length = _columns
max_comment_line_length	= _columns
