local download_links = hjson.parse(fs.read_file("__xtz/sources.hjson"))
local download_urls = nil

local system_os = am.app.get_model("SYSTEM_OS", "unknown")
local system_distro = am.app.get_model("SYSTEM_DISTRO", "unknown")
local system_type = am.app.get_model("SYSTEM_TYPE", "unknown")

if system_os == "unix" then
    if system_distro == "MacOS" then
        download_urls = download_links["darwin-arm64"]
    else
        download_urls = download_links["linux-x86_64"]
        if system_type:match("[Aa]arch64") then
            download_urls = download_links["linux-arm64"]
        end
    end
end

ami_assert(download_urls ~= nil, "no download URLs found for the current platform: " .. system_os .. " " .. system_distro .. " " .. system_type)

am.app.set_model(
    {
        DOWNLOAD_URLS = am.app.get_configuration("SOURCES", download_urls),
    },
    { merge = true, overwrite = true }
)

local services = require("__xtz.services")
local wanted_binaries = services.wanted_binaries

local TEZOS_LOG_LEVEL = am.app.get_configuration("TEZOS_LOG_LEVEL", "info")

local DAL_STARTUP_ARGS = am.app.get_configuration("DAL_STARTUP_ARGS", {})

local attester_profiles = am.app.get_configuration("ATTESTER_PROFILES", {})
-- additional attester_profiles from attester_profiles.list
local attester_profiles_list_raw = io.open("attester_profiles.list", "r+b")
if attester_profiles_list_raw ~= nil then
    for profile in attester_profiles_list_raw:lines() do
        if profile:match("%S") then -- Check if the profile is not just whitespace
            table.insert(attester_profiles, string.trim(profile))
        end
    end
end

attester_profiles = table.reduce(attester_profiles, function(acc, v)
    if type(v) == "string" and not table.includes(acc, v) then
        table.insert(acc, v)
    end
    return acc
end, {})

if table.is_array(attester_profiles) and #attester_profiles > 0 then
    table.insert(DAL_STARTUP_ARGS, 1, "--attester-profiles")
    table.insert(DAL_STARTUP_ARGS, 2, string.join(",", table.unpack(attester_profiles)))
end

local base_utils = require("__xtz.base_utils")
local node_endpoint = am.app.get_configuration("NODE_ENDPOINT", "http://127.0.0.1:8732/")
local node_endpoint_host_and_port = base_utils.extract_host_and_port(node_endpoint, 8732)
table.insert(DAL_STARTUP_ARGS, 1, "--endpoint")
table.insert(DAL_STARTUP_ARGS, 2, node_endpoint)

local rpc_addr = am.app.get_configuration("RPC_ADDR", "http://127.0.0.1:10732")
local rpc_host_and_port = base_utils.extract_host_and_port(rpc_addr, 10732)

local local_rpc_addr = rpc_addr
local local_rpc_addr_host_and_port = base_utils.extract_host_and_port(local_rpc_addr, 10732)
if not local_rpc_addr:match("127%.0%.0%.1") then
    local_rpc_addr = am.app.get_configuration("LOCAL_RPC_ADDR", "http://127.0.0.1:10732")
    local_rpc_addr_host_and_port = base_utils.extract_host_and_port(local_rpc_addr, 10732)
    table.insert(DAL_STARTUP_ARGS, "--rpc-addr")
    table.insert(DAL_STARTUP_ARGS, local_rpc_addr_host_and_port)
end

am.app.set_model(
    {
        WANTED_BINARIES = wanted_binaries,
        RPC_ADDR = rpc_addr,
        RPC_HOST_AND_PORT = rpc_host_and_port,
        LOCAL_RPC_ADDR = local_rpc_addr,
        LOCAL_RPC_HOST_AND_PORT = local_rpc_addr_host_and_port,
        NODE_ENDPOINT = node_endpoint, -- injected to args too
        NODE_ENDPOINT_HOST_AND_PORT = node_endpoint_host_and_port,
        ATTESTER_PROFILES = attester_profiles,
		SERVICE_CONFIGURATION = util.merge_tables(
            {
                TimeoutStopSec = 300,
            },
            type(am.app.get_configuration("SERVICE_CONFIGURATION")) == "table" and am.app.get_configuration("SERVICE_CONFIGURATION") or {},
            true
        ),
        DAL_LOG_LEVEL = am.app.get_configuration("DAL_LOG_LEVEL", TEZOS_LOG_LEVEL),
        DAL_STARTUP_ARGS = DAL_STARTUP_ARGS,
        -- prism
        PRISM_REMOTE = am.app.get_configuration({ "PRISM", "remote" }),
        PRISM_NODE_FORWARDING_DISABLED = am.app.get_configuration({ "PRISM", "node" }, false) ~= true,
        PRISM_SERVER_LISTEN_ON = am.app.get_configuration({ "PRISM", "listen" }),
    },
    { merge = true, overwrite = true }
)
