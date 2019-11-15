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
            target = "change.me.to.something.local.",
        }
    }
}

-- read all the domains in a set
function loadDomainsFromFile(file)
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
function loadBlocklist()
    -- free-up memory
    dagg.blocklist = {}
    collectgarbage()
 
    infolog("[dagg] (re)loading blocklist...")

    dagg.blocklist = loadDomainsFromFile(dagg.config.blocklist.path)

    infolog("[dagg] complete!")
end

-- write down a query to the action log
function writeToActionLog(dq)
    -- write-down the query
    local f = io.open(dagg.config.actionlog.path, "a")

    if f~=nil
    then
        local query_name  = dq.qname:toString()
        local remote_addr = dq.remoteaddr:toString()

        msg = string.format("[%s][%s] %s", os.date("!%Y-%m-%dT%TZ",t), remote_addr, query_name)

        f:write(msg, "\n")
        f:close(f)
    end
end

-- main query action
function isDomainBlocked(dq)
    local qname = dq.qname:toString()

    -- as public lists do not have proper domain notation
    -- (ending with dot), remove the one in the query
    if dagg.blocklist[qname]
    then
        -- set QueryResponse, so the query never goes upstream
        dq.dh:setQR(true)

        -- set Custom tag, so we can process only
        -- dq:setTag("dagg", "true")

        -- WARNING: it (may?) affect performance
        -- writeToActionLog(dq)
	
        -- return NXDOMAIN - its fast, but apparently 
        -- some apps resort to hard-coded entries if NX
        -- try spoofing in this instance.

        return DNSAction.Nxdomain, ""
        -- return DNSAction.Spoof, "127.0.0.1"
    end

    return DNSAction.None, ""
end

-- reload action
function reloadBlocklist(dq)
    -- reload
    loadBlocklist()

    -- prevent the query from going upstream
    dq.dh:setQR(true)
 
    -- respond with a local address just in case
    return DNSAction.Spoof, "127.0.0.1"
end

addLuaAction(AllRule(), isDomainBlocked)

addLuaAction(dagg.config.reload.target, reloadBlocklist)