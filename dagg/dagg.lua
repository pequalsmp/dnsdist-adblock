Dagg = {
	-- config
	config = {
		actionlog = {
			path = "/tmp/path/to/my/action.log",
		},
		blocklist = {
			path = "/tmp/path/to/my/block.list",
		},
		reload = {
			target = "reload.change.me.to.something.local.",
		},
		unload = {
			target = "unload.hange.me.to.something.local.",
		},
	},
	-- table storing the domains that need to be blocked
	table = {
		-- only used for wildcard domains
		smn = newSuffixMatchNode(),
		-- default - fast string comparison
		str = {},
	},
}

-- read all the domains in a set
function DaggLoadDomainsFromFile(file)
	local f = io.open(file, "rb")

	-- verify that the file exists and it is accessible
	if f ~= nil then
		for domain in f:lines() do
			if string.find(domain, "*") then
				local suffix = domain:gsub("*.", "")
				Dagg.table.smn:add(suffix)
			else
				Dagg.table.str[domain] = 1
			end
		end

		f:close()
	end
end

-- verbose, but clear
function DaggLoadBlocklist()
	-- no reason, just for clarity
	local file = Dagg.config.blocklist.path
	-- not really necessary, but keep similarity to other versions

	local f = io.open(file, "rb")

	if f ~= nil then
		-- file exists, close and proceed with sed
		f:close()

		-- it appears that even when using:
		--
		-- 'local var = str2 .. str2'
		--
		-- the variable is not being garbage-collected
		-- and it ends up looking like a memory leak.
		--
		-- let me know if if there's a better way
		os.execute("sed '/\\.$/ ! s/$/\\./' -i " .. file)
	else
		errlog "[Dagg] the blocklist file is missing or inaccessible!"
	end

	DaggLoadDomainsFromFile(file)
end

-- clear the table from memory
function DaggClearTable()
	Dagg.table = {
		smn = newSuffixMatchNode(),
		str = {},
	}
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

	if Dagg.table.str[qname] or Dagg.table.smn:check(dq.qname) then
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

		-- return Spoof - you can spoof the response
		-- instead of NX, but this may lead to time-outs
		--
		-- return DNSAction.Spoof, "127.0.0.1"
	end

	return DNSAction.None, ""
end
addAction(AllRule(), LuaAction(DaggIsDomainBlocked))

-- reload action
function DaggReloadBlocklist(dq)
	infolog "[Dagg] re/loading blocklist..."

	-- prevent the query from going upstream
	dq.dh:setQR(true)

	-- clear
	DaggClearTable()

	-- clean-up
	collectgarbage "collect"

	-- load
	DaggLoadBlocklist()

	-- clean-up
	collectgarbage "collect"

	-- respond with a local address just in case
	return DNSAction.Spoof, "127.0.0.127"
end
addAction(Dagg.config.reload.target, LuaAction(DaggReloadBlocklist))

-- unload action
function DaggUnloadBlocklist(dq)
	infolog "[Dagg] unloading blocklist..."

	-- prevent the query from going upstream
	dq.dh:setQR(true)

	-- clear
	DaggClearTable()

	-- clean-up
	collectgarbage "collect"

	-- respond with a local address just in case
	return DNSAction.Spoof, "127.0.0.127"
end
addAction(Dagg.config.unload.target, LuaAction(DaggUnloadBlocklist))
