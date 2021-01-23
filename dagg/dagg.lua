dagg = {
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
    },
    -- table storing the domains that
    -- need to be blocked
    table = {
        -- only used for wildcard domains
        smn = newSuffixMatchNode(),
        -- default - fast string comparison
        str = {},
    }
}

-- read all the domains in a set
function daggLoadDomainsFromFile(file, isWildCard)
    local domains = {
        smn = {},
        str = {}
    }

    local f = io.open(file, "rb")

    -- verify that the file exists and it is accessible
    if f~=nil
    then
        for domain in f:lines() do
            if string.find(domain, "*") then
                table.insert(domains["smn"], domain)
            else
                table.insert(domains["str"], domain)
            end
        end

        f:close(f)
    else
        errlog("The domain list is missing or inaccessible!")
    end

    return domains
end

-- verbose, but clear
function daggLoadBlocklist()
    local domains = daggLoadDomainsFromFile(dagg.config.blocklist.path)

    daggLoadStrTable(domains.str)
    daggLoadSmnTable(domains.smn)
end

-- load the str domains
function daggLoadStrTable(domains)
    for _,domain in pairs(domains) do
        dagg.table.str[domain.."."] = true
    end
end

-- load smn domains
function daggLoadSmnTable(domains)
    dagg.table.smn = newSuffixMatchNode()

    for _,domain in pairs(domains) do
        local suffix = domain:gsub("*.", "")
        dagg.table.smn:add(suffix)
    end
end

-- clear the table from memory
function daggClearTable()
    dagg.table = {
        smn = newSuffixMatchNode(),
        str = {}
    }

    -- free-up memory
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

    if dagg.table.str[qname] or dagg.table.smn:check(dq.qname)
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
    daggClearTable()

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
    daggClearTable()

    -- respond with a local address just in case
    return DNSAction.Spoof, "127.0.0.1"
end
addAction(dagg.config.unload.target, LuaAction(daggUnloadBlocklist))
