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
			target = "unload.change.me.to.something.local.",
		},
	},
	-- table storing the domains that need to be blocked
	table = {
		-- struct of the filter
		fuse16 = nil,
		-- only used for wildcard-suffixed domains
		suffix = nil,
	},
	-- keep a local FFI copy to avoid API conflict
	ffi = require "ffi",
	-- C-library containing the filter implementation
	lib = {},
}

Dagg.ffi.cdef [[
  typedef struct binary_fuse16_s {
    uint64_t Seed;
    uint32_t SegmentLength;
    uint32_t SegmentLengthMask;
    uint32_t SegmentCount;
    uint32_t SegmentCountLength;
    uint32_t ArrayLength;
    uint16_t *Fingerprints;
  } binary_fuse16_t;

  binary_fuse16_t initialize(uint64_t *set, size_t set_size);
  void deinit(binary_fuse16_t filter);
  bool contains(const char* value, binary_fuse16_t filter);
  uint64_t xxhash(const char* str);
]]

Dagg.lib = Dagg.ffi.load "libdagg"

-- read all the domains in a set
function DaggLoadDomainsFromFile(file)
	local domains = {
		fuse16 = {},
		suffix = {},
	}

	-- string concat is not working in lua
	-- but this uses concat
	-- yes, it's ironic
	--
	-- by not working, it appears that even when
	-- using 'local var = str2 .. str2', the memory
	-- is not being garbage-collected and it ends up
	-- looking like a memory leak.
	--
	-- might be an oversight, let me know if if there's
	-- a better way. otherwise run this hack
	os.execute("sed '/\\.$/ ! s/$/\\./' -i " .. file)

	local f = io.open(file, "rb")

	-- optimization?
	local strFind = string.find

	-- verify that the file exists and it is accessible
	if f ~= nil then
		for domain in f:lines() do
			if strFind(domain, "*") then
				-- slightly faster compared to table.insert
				-- should quantify by how much, though
				domains["suffix"][#domains["suffix"] + 1] = domain
			else
				domains["fuse16"][#domains["fuse16"] + 1] = domain
			end
		end

		f:close()
	else
		errlog "The domain list is missing or inaccessible!"
	end

	DaggBuildFuseFilter(domains.fuse16)
	DaggLoadSuffixTable(domains.suffix)
end

-- verbose, but clear
function DaggLoadBlocklist()
	-- local domains = DaggLoadDomainsFromFile(Dagg.config.blocklist.path)
	--
	-- DaggBuildFuseFilter(domains.fuse16)
	-- DaggLoadSuffixTable(domains.suffix)

	DaggLoadDomainsFromFile(Dagg.config.blocklist.path)
end

-- load the str domains
function DaggBuildFuseFilter(domains)
	local set = Dagg.ffi.new("uint64_t[?]", #domains)

	for _, domain in pairs(domains) do
		set[_] = Dagg.lib.xxhash(domain)
	end

	Dagg.table.fuse16 = Dagg.ffi.gc(Dagg.lib.initialize(set, #domains), Dagg.lib.deinit)

	-- needed?
	-- set = nil
end

-- load suffix (wildcard) domains
function DaggLoadSuffixTable(domains)
	Dagg.table.suffix = newSuffixMatchNode()

	for _, domain in pairs(domains) do
		local suffix = domain:gsub("*.", "")
		Dagg.table.suffix:add(suffix)
	end
end

-- clear the table from memory
function DaggClearTable()
	-- zero-out the tables
	Dagg.table.fuse16 = nil
	Dagg.table.suffix = nil
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
	local block = false

	if Dagg.table.fuse16 and Dagg.lib["contains"] then
		block = block or Dagg.lib.contains(dq.qname:toString():lower(), Dagg.table.fuse16)
	end

	if Dagg.table.suffix then
		block = block or Dagg.table.suffix:check(dq.qname)
	end

	if block then
		-- set QueryResponse, so the query never goes upstream
		dq.dh:setQR(true)

		-- set a CustomTag
		-- you can optionally set a tag and process
		-- this request with other actions/pools
		--
		-- dq:setTag("Dagg", "true")

		-- WARNING: it (may) affect(s) performance
		--
		-- DaggWriteToActionLog(dq)

		-- return NXDOMAIN - its fast, but apparently
		-- some apps resort to hard-coded entries if NX
		-- try spoofing in this instance.
		--
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
	infolog "[Dagg] (re)loading blocklist..."

	-- prevent the query from going upstream
	dq.dh:setQR(true)

	-- clear
	DaggClearTable()

	-- free-up memory
	collectgarbage "collect"

	-- load
	DaggLoadBlocklist()

	-- free-up memory
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

	-- free-up memory
	collectgarbage "collect"

	-- respond with a local address just in case
	return DNSAction.Spoof, "127.0.0.127"
end
addAction(Dagg.config.unload.target, LuaAction(DaggUnloadBlocklist))
