-- load the blocked domain list
function loadBlockedDomains(file)
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

infolog("Loading the blacklisted domains ...")

blocklist = loadBlockedDomains("/tmp/domain.blacklist")

infolog("Domain Blacklist loaded!")

-- blockFilter is a built-in function in dnsdist
-- it gets called when a query is received
function blockFilter(dq)
	local qname = dq.qname:toString()

	-- as public lists do not have
    -- proper domain notation (ending with dot)
    -- remove the one in the query
	if blocklist[qname:sub(1,-2)]
	then
		-- this drop the query, COMPLETELY
		-- the client will have to timeout
		-- IT WILL NOT RECEIVE A RESPONSE
		return true
	end
	
	return false
end
