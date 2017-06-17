-- Warning: WAY TOO SLOW
function loadBlacklist(file)
    local f = io.open(file, "rb")

    -- verify that the file exists and it is accessible
    if f~=nil
    then
        for domain in io.lines(file) do
            addDomainBlock(domain)
        end

        io.close(f)
    else
        errlog("The file containing blacklisted domains is missing or inaccessible!")
    end
end

infolog("Loading the blacklisted domains ...")

loadBlacklist("/tmp/domain.blacklist")

infolog("Domain Blacklist loaded!")