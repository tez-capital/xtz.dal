local sources_raw = fs.read_file("__xtz/trusted_setup_sources.hjson")
local sources = hjson.parse(sources_raw)

log_info("Downloading DAL trusted setup... (This may take a few minutes.)")

DESTINATION_DIR = "./data/_opam/share/dal-trusted-setup"

fs.mkdirp(DESTINATION_DIR)

for id, source in pairs(sources) do
    local url = source.url
    local sha256 = source.sha256

    local destination_file = path.combine(DESTINATION_DIR, id)
    if fs.exists(destination_file) then
        log_debug("File " .. destination_file .. " already exists, verifying...")
        local hash = fs.hash_file(destination_file, { type = "sha256", binary_mode = true })
        if hash == sha256 then
            log_debug("File " .. destination_file .. " is already verified.")
            goto continue
        else
            log_debug("File " .. destination_file .. " is not verified, downloading again.")
        end
    end

    log_info("Downloading " .. id .. "... (This may take a few minutes.)")
    local ok, err = net.download_file(url, destination_file, { follow_redirects = true, show_default_progress = true })
    if not ok then
        ami_error("Failed to download " .. id .. ": " .. (err or ""))
    end

    log_debug("Verifying " .. id .. " with sha256: " .. sha256)
    local hash = fs.hash_file(destination_file, { type = "sha256", binary_mode = true, hex = true })
    if hash ~= sha256 then
        ami_error("Hash mismatch for " .. id .. ": expected " .. sha256 .. ", got " .. hash)
    end
    log_debug("Successfully downloaded and verified " .. id)
    ::continue::
end

log_success("DAL trusted setup installed successfully")
