local blocklistPath = "/tmp/path/to/my/block.list"

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
        errlog("The blocklist file is missing or inaccessible!")
    end
end

infolog("[addDomainBlock] loading blocklist...")

-- Warning: SLOW
loadBlocklist(blocklistPath)

infolog("[addDomainBlock] loading done.")
