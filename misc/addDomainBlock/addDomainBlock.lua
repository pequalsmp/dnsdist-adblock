-- addDomainBlock all domains listed in the file
local function loadBlocklist(file)
    local f = io.open(file, "rb")

    -- verify that the file exists and it is accessible
    if f~=nil
    then
        for domain in io.lines(file) do
            addDomainBlock(domain)
        end

        f:close()
    else
        errlog("The domain list is missing or inaccessible!")
    end
end

infolog("[dagg] (re)loading blocklist...")

-- Warning: WAY TOO SLOW
loadBlocklist("/tmp/path-to-my-block.list")

infolog("[dagg] complete!")
