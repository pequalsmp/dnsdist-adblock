package.path = ';/<dnsdist-conf-path>/bloom-filter/?.lua;/<dnsdist-conf-path>/xxhash/?.lua;' .. package.path

local bloom_filter = require "bloom-filter"

local dagg = {
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
        probability = 1.0 * (10^-6)
    },
    -- config
    config = {
        actionlog = {
            path =  "/tmp/path-to-my-action.log",
        },
        blocklist = {
            path  = "/tmp/path-to-my-block.list",
        },
        reload = {
            target = "reload.change.me.to.something.local.",
        },
        unload = {
            target = "unload.hange.me.to.something.local.",
        }
    }
}
    
-- read all the domains in a set
function daggLoadDomainsFromFile(file)
    local domains = {}

    local f = io.open(file, "rb")

    -- verify that the file exists and it is accessible
    if f~=nil
    then
        for domain in f:lines() do
            table.insert(domains, domain..".")
        end

        -- init the bloom filter
        dagg.bloom.filter = bloom_filter.new(table.getn(domains), dagg.bloom.probability)

        for i, domain in pairs(domains) do
            dagg.bloom.filter:add(domain)
        end

        f:close(f)
    else
        errlog("The domain list is missing or inaccessible!")
    end
end

-- load the blocklisted domains
function daggLoadBlocklist()
    daggLoadDomainsFromFile(dagg.config.blocklist.path)
end

-- clear the blocklist from memory
function daggClearBlocklist()
    -- free-up memory
    dagg.bloom.filter = nil
    collectgarbage()
end

-- write down a query to the action log
function daggWriteToActionLog(dq)
    -- write-down the query
    local f = io.open(dagg.config.actionlog.path, "a")

    if f~=nil
    then
        local query_name  = dq.qname:toString()
        local remote_addr = dq.remoteaddr:toString()

        local msg = string.format("[%s][%s] %s", os.date("!%Y-%m-%dT%TZ",t), remote_addr, query_name)

        f:write(msg, "\n")
        f:close(f)
    end
end

-- main query action
function daggIsDomainBlocked(dq)
    local qname = dq.qname:toString():lower()

    if (dagg.bloom.filter ~= nil) and (dagg.bloom.filter:query(qname) == 1)
    then
        -- set QueryResponse, so the query never goes upstream
        dq.dh:setQR(true)

        -- set a CustomTag
        -- you can optionally set a tag and process
        -- this request with other actions/pools
        -- dq:setTag("dagg", "true")

        -- WARNING: it (may?) affect(s) performance
        -- daggWriteToActionLog(dq)

        -- return NXDOMAIN - its fast, but apparently 
        -- some apps resort to hard-coded entries 
        return DNSAction.Nxdomain, ""

        -- if NX doesn't work, try spoofing.
        -- return DNSAction.Spoof, "127.0.0.1"
    end

    return DNSAction.None, ""
end
addAction(AllRule(), LuaAction(daggIsDomainBlocked))

-- reload action
function daggReloadBlocklist(dq)
    infolog("[dagg] (re)loading blocklist...")

    -- prevent the query from going upstream
    dq.dh:setQR(true)

    -- clear
    daggClearBlocklist()

    -- load
    daggLoadBlocklist()

    -- respond with a local address just in case
    return DNSAction.Spoof, "127.0.0.1"
end
addAction(dagg.config.reload.target, LuaAction(daggReloadBlocklist))

-- unload action
function daggUnloadBlocklist(dq)
    infolog("[dagg] unloading blocklist...")

    -- prevent the query from going upstream
    dq.dh:setQR(true)

    -- clear
    daggClearBlocklist()

    -- respond with a local address just in case
    return DNSAction.Spoof, "127.0.0.1"
end
addAction(dagg.config.unload.target, LuaAction(daggUnloadBlocklist))
