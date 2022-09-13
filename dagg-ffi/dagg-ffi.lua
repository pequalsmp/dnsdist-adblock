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
		-- only used for wildcard domains
		suffix = nil,
	},
	-- keep a local ffi copy to avoid API conflict
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
function DaggLoadDomainsFromFile(file, lineCount)
	local f = io.open(file, "rb")

	-- make sure the file has opened successfully
	-- yes, we just counted the lines, but still
	if f ~= nil then
		-- initialize filter
		--
		-- yes, the array is larger, than the set, it's easier
		-- instead of running another loop, just to count the domains
		local set = Dagg.ffi.new("uint64_t[?]", lineCount)

		-- initialize suffix for wildcard domains
		Dagg.table.suffix = newSuffixMatchNode()

		-- set index
		local _ = 0

		for domain in f:lines() do
			-- handle wildcard domains
			if string.find(domain, "*") then
				local suffix = domain:gsub("*.", "")
				Dagg.table.suffix:add(suffix)
			-- everything else
			else
				set[_] = Dagg.lib.xxhash(domain)
				_ = _ + 1
			end
		end

		-- close the file
		f:close()

		-- initialize the filter set
		Dagg.table.fuse16 = Dagg.ffi.gc(Dagg.lib.initialize(set, lineCount), Dagg.lib.deinit)
	end
end

-- verbose, but clear
function DaggLoadBlocklist()
	-- no reason, just for clarity
	local file = Dagg.config.blocklist.path

	local f = io.open(file, "rb")

	-- no built-in method for counting lines
	-- so do it, really verbose
	local lineCount = 0

	-- verify that the file exists and it is accessible
	if f ~= nil then
		for _ in f:lines() do
			lineCount = lineCount + 1
		end
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

		f:close()
	else
		errlog "[Dagg] the blocklist file missing or inaccessible!"
	end

	DaggLoadDomainsFromFile(file, lineCount)
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
