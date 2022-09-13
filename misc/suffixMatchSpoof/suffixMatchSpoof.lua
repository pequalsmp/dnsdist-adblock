local blocklistPath = "/tmp/path/to/my/block.list"

BlockNode = newSuffixMatchNode()

-- read all the domains in a set
local function loadBlocklist(smn, file)
	local f = io.open(file, "rb")

	-- verify that the file exists and it is accessible
	if f ~= nil then
		for domain in io.lines(file) do
			smn:add(newDNSName(domain))
		end

		f:close()
	else
		errlog "The domain list is missing or inaccessible!"
	end
end

infolog "[suffixMatchSpoof] loading blocklist..."

loadBlocklist(BlockNode, blocklistPath)

infolog "[suffixMatchSpoof] loading done."

-- Action to take against the domains in the blocklist
--
-- It is recommended to return an IP, as some apps have
-- apply workarounds when the response is NXDOMAIN
addAction(AndRule { SuffixMatchNodeRule(BlockNode), QTypeRule "A" }, SpoofAction "127.0.0.1")
