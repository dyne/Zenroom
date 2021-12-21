local SLAXML = require 'slaxdom'

local XML = { namespace_prefix = [[
<r xmlns:f="foo">
	<f:a>explicit namespaced close</f:a>
</r>
]],
			  xml_namespace = [[
<!-- Generator: Adobe Illustrator 17.1.0, SVG Export Plug-In  -->
<svg version="1.1"
     xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:a="http://ns.adobe.com/AdobeSVGViewerExtensions/3.0/"
     x="0px" y="0px" width="110.6px" height="82px" viewBox="0 0 110.6 82" enable-background="new 0 0 110.6 82" xml:space="preserve"
    >
<defs>
</defs>
<path fill="#B3B0A1" stroke="#000000" stroke-miterlimit="10" d="M3.8,18.4c0,0-9-14.1,12.8-17.3s28.2,6.4,17.9,20.5
    s-37.8,19.2-0.6,25s105.8-58.3,62.2-11.5S29.4,84.5,12.1,80C-5.2,75.5,2,37,2,37"/>
<path fill="#9B9A91" stroke="#000000" stroke-miterlimit="10" d="M27.5,53c0,0-16-14.8,0-24.4s16-1.9,19.2,5.1
    c3.2,7.1,6.4,12.8,0,16c-6.4,3.2-11.3,6.4-11.3,6.4"/>
</svg>
]],
			  namespace_declare_and_use = [[
<r>
	<cat xmlns="cat" xmlns:a="dog">
		<cat />
		<a:dog>
			<cat />
			<a:hog a:hog="yes" xmlns:a="hog" xmlns:b="bog" b:bog="yes">
				<a:hog />
				<b:bog />
			</a:hog>
			<a:dog />
		</a:dog>
	</cat>
	<c:cog xmlns:c="cog" />
</r>
]]
}

local function countParsings(xmlName,options,expected)
	local counts,counters = {},{}
	expected.closeElement = expected.startElement
	for name,_ in pairs(expected) do
		counts[name]   = 0
		counters[name] = function() counts[name]=counts[name]+1 end
	end
	SLAXML:parser(counters):parse(XML[xmlName],options)
	for name,ct in pairs(expected) do
		assert(counts[name] == ct,"There should have been be exactly "..ct.." "..name.."() callback(s) in "..xmlName..", not "..counts[name])
	end
end

local function namespace()
	local elementStack = {}
	SLAXML:parser{
		startElement = function(name,nsURI)
			table.insert(elementStack,{name=name,nsURI=nsURI})
		end,
		closeElement = function(name,nsURI)
			local pop = table.remove(elementStack)
			assert(name == pop.name,"Got close "..name.." to close "..pop.name)
			assert(nsURI == pop.nsURI,"Got close namespace "..(nsURI or "nil").." to close namespace "..(pop.nsURI or "nil"))
		end,
	}:parse(XML['namespace_prefix'])
end

function xml_namespace()
   local doc = SLAXML:dom(XML['xml_namespace'])
   for i,attr in ipairs(doc.root.attr) do
	  if attr.name=='space' then
		 assert(attr.nsURI == [[http://www.w3.org/XML/1998/namespace]])
		 break
	  end
   end
end

function xml_namespace_immediate_use()
	local doc = SLAXML:dom(XML['namespace_declare_and_use'])
	local cat1 = doc.root.el[1]
	assert(cat1.name == 'cat')
	assert(cat1.nsURI == 'cat')
	local cat2 = cat1.el[1]
	assert(cat2.name=='cat')
	assert(cat2.nsURI=='cat')
	local dog1 = cat1.el[2]
	assert(dog1.name=='dog')
	assert(dog1.nsURI=='dog')
	local cat3 = dog1.el[1]
	assert(cat3.name=='cat')
	assert(cat3.nsURI=='cat')
	local hog1 = dog1.el[2]
	assert(hog1.name=='hog')
	assert(hog1.nsURI=='hog')
	for _,attr in ipairs(hog1.attr) do
		if attr.value=='yes' then
			assert(attr.nsURI,attr.name)
		end
	end
	local hog2 = hog1.el[1]
	assert(hog2.name=='hog')
	assert(hog2.nsURI=='hog')
	local bog1 = hog1.el[2]
	assert(bog1.name=='bog')
	assert(bog1.nsURI=='bog')
	local dog2 = dog1.el[3]
	assert(dog2.name=='dog')
	assert(dog2.nsURI=='dog')
	local cog2 = doc.root.el[2]
	assert(cog2.name=='cog')
	assert(cog2.nsURI=='cog')
end

namespace()
xml_namespace()
xml_namespace_immediate_use()
