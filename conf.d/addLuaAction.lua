-- read all the domains in a set
function loadDomainsFromFile(file)
    local domains = {}

    local f = io.open(file, "rb")

    -- verify that the file exists and it is accessible
    if f~=nil
    then
        for domain in io.lines(file) do
            domains[domain] = true
        end

        io.close(f)
    else
        errlog("The file containing blacklisted domains is missing or inaccessible!")
    end

    return domains
end

function isDomainBlacklisted(dq)
    local qname = dq.qname:toString()

    -- as public lists do not have proper domain notation
    -- (ending with dot), remove the one in the query
    if blacklist[qname:sub(1,-2)]
    then
        -- set QueryResponse, so the query never goes upstream
        dq.dh:setQR(true)

        -- return NXDOMAIN - its fast, but apparently 
        -- some apps resort to hard-coded entries in this case.
        return DNSAction.Nxdomain, ""
    end

    return DNSAction.None, ""
end

addLuaAction(AllRule(), isDomainBlacklisted)

infolog("Loading the blacklisted domains ...")

blacklist = loadDomainsFromFile("/tmp/domain.blacklist")

infolog("Domain Blacklist loaded!")