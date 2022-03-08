package.path = ";./bloom-filter/?.lua;./xxhash/?.lua;" .. package.path

local bloom_filter = require("bloom-filter")

local Dagg = {
	-- bloom filter config
	bloom = {
		filter = nil,
		-- it's important to tune this parameter to your
		-- setup higher false-positive probability
		-- reduces the memory usage, but increases the
		-- chance for a false-positive.
		--
		-- change the exponent if you would like to
		-- increase/decrease the false-positive probability
		probability = 1.0 * (10 ^ -6),
	},
	-- config
	config = {
		actionlog = {
			path = "/tmp/path-to-my-action.log",
		},
		blocklist = {
			path = "/tmp/path-to-my-block.list",
		},
		reload = {
			target = "reload.change.me.to.something.local.",
		},
		unload = {
			target = "unload.change.me.to.something.local.",
		},
	},
}

-- read all the domains in a set
function DaggLoadDomainsFromFile(file)
	local domains = {}

	local f = io.open(file, "rb")

	-- verify that the file exists and it is accessible
	if f ~= nil then
		for domain in f:lines() do
			table.insert(domains, domain .. ".")
		end

		-- init the bloom filter
		Dagg.bloom.filter = bloom_filter.new(#domains, Dagg.bloom.probability)

		for _, domain in pairs(domains) do
			Dagg.bloom.filter:add(domain)
		end

		f:close()
	else
		errlog("The domain list is missing or inaccessible!")
	end

	collectgarbage()
end

-- load the blocklisted domains
function DaggLoadBlocklist()
	DaggLoadDomainsFromFile(Dagg.config.blocklist.path)
end

-- clear the blocklist from memory
function DaggClearBlocklist()
	Dagg.bloom.filter = nil

	collectgarbage()
end

-- write down a query to the action log
function DaggWriteToActionLog(dq)
	-- write-down the query
	local f = io.open(Dagg.config.actionlog.path, "a")

	if f ~= nil then
		local query_name = dq.qname:toString()
		local remote_addr = dq.remoteaddr:toString()

		local msg = string.format("[%s][%s] %s", os.date("!%Y-%m-%dT%TZ", t), remote_addr, query_name)

		f:write(msg, "\n")
		f:close()
	end
end

-- main query action
function DaggIsDomainBlocked(dq)
	local qname = dq.qname:toString():lower()

	if Dagg.bloom.filter:query(qname) == 1 then
		-- set QueryResponse, so the query never goes upstream
		dq.dh:setQR(true)

		-- set a CustomTag
		-- you can optionally set a tag and process
		-- this request with other actions/pools
		-- dq:setTag("Dagg", "true")

		-- WARNING: it (may?) affect(s) performance
		-- DaggWriteToActionLog(dq)

		-- return NXDOMAIN - its fast, but apparently
		-- some apps resort to hard-coded entries if NX
		-- try spoofing in this instance.

		return DNSAction.Nxdomain, ""
		-- return DNSAction.Spoof, "127.0.0.1"
	end

	return DNSAction.None, ""
end
addAction(AllRule(), LuaAction(DaggIsDomainBlocked))

-- reload action
function DaggReloadBlocklist(dq)
	infolog("[Dagg] (re)loading blocklist...")

	-- prevent the query from going upstream
	dq.dh:setQR(true)

	-- clear
	DaggClearBlocklist()

	-- load
	DaggLoadBlocklist()

	-- respond with a local address just in case
	return DNSAction.Spoof, "127.0.0.1"
end
addAction(Dagg.config.reload.target, LuaAction(DaggReloadBlocklist))

-- unload action
function DaggUnloadBlocklist(dq)
	infolog("[Dagg] unloading blocklist...")

	-- prevent the query from going upstream
	dq.dh:setQR(true)

	-- clear
	DaggClearBlocklist()

	-- respond with a local address just in case
	return DNSAction.Spoof, "127.0.0.1"
end
addAction(Dagg.config.unload.target, LuaAction(DaggUnloadBlocklist))
