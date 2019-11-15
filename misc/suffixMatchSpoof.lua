
blDomains=newSuffixMatchNode()

-- read all the domains in a set
function loadBlocklist(smn, file)
    local f = io.open(file, "rb")

    -- verify that the file exists and it is accessible
    if f~=nil
    then
        for domain in io.lines(file) do
            smn:add(newDNSName(domain))
        end

        f:close(f)
    else
        errlog("The domain list is missing or inaccessible!")
    end
end

infolog("[dagg] (re)loading blocklist...")

loadBlocklist(blDomains, "/tmp/path-to-my-block.list")

infolog("[dagg] complete!")

-- Action to take against the domains in the blocklist
-- it is recommended to return an ip, as some apps have 
-- NXDOMAIN-response workarounds
addAction(AndRule{SuffixMatchNodeRule(blDomains), QTypeRule("A")}, SpoofAction("127.0.0.1"))     
