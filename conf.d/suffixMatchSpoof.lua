
blDomains=newSuffixMatchNode()

-- read all the domains in a set
function loadBlacklist(smn, file)
    local f = io.open(file, "rb")

    -- verify that the file exists and it is accessible
    if f~=nil
    then
        for domain in io.lines(file) do
            smn:add(newDNSName(domain))
        end

        io.close(f)
    else
        errlog("The file containing blacklisted domains is missing or inaccessible!")
    end
end

infolog("Loading the blacklisted domains ...")

loadBlacklist(blDomains, "/tmp/domain.blacklist")

infolog("Domain Blacklist loaded!")

-- Action to take against the domains in the Blacklist
--  it is recommended to return an ip, as some apps have NXDOMAIN-response workarounds
--  using 127.0.0.2 as apparently 0.0.0.0 is invalid
addAction(AndRule{SuffixMatchNodeRule(blDomains), QTypeRule("A")}, SpoofAction("127.0.0.2"))     
