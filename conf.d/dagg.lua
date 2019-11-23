dagg = {
    -- set of blocklisted domains
    blocklist = {

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
            domains[domain.."."] = true
        end

        f:close(f)
    else
        errlog("The domain list is missing or inaccessible!")
    end

    return domains
end

-- load the blocklisted domains
function daggLoadBlocklist()
    dagg.blocklist = daggLoadDomainsFromFile(dagg.config.blocklist.path)
end

-- clear the blocklist from memory
function daggClearBlocklist()
    -- free-up memory
    dagg.blocklist = {}
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

    if dagg.blocklist[qname]
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
        -- some apps resort to hard-coded entries if NX
        -- try spoofing in this instance.

        return DNSAction.Nxdomain, ""
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
