parser = require'ast_parser'
pp = require'ast_pp'
local _ast, error_msg = parser.parse(CODE, "AST")
if not _ast then
   print(error_msg)
end
print(json.encode(_ast))
