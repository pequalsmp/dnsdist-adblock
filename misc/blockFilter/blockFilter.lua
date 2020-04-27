-- load the blocked domain list
function loadBlockedDomains(file)
	local domains = {}
	local f = io.open(file, "rb")

    -- verify that the file exists and it is accessible
    if f~=nil
    then
		for domain in io.lines(file) do
			-- as public lists do not have proper domain notation
    		-- (ending with dot), remove the one in the query
			domains[domain.."."] = true
		end

		f:close(f)
    else
        errlog("The domain list is missing or inaccessible!")
    end
	
	return domains
end

infolog("[dagg] (re)loading blocklist...")

blocklist = loadBlockedDomains("/tmp/path-to-my-block.list")

infolog("[dagg] complete!")

-- blockFilter is a built-in function in dnsdist
-- it gets called whenever a query is received
function blockFilter(dq)
	local qname = dq.qname:toString()

	if blocklist[qname]
	then
		-- this drops the query COMPLETELY
		-- the client will timeout (hang)
		return true
	end
	
	return false
end
