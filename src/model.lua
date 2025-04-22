local ok, platform_plugin = am.plugin.safe_get("platform")
if not ok then
    log_error("Cannot determine platform!")
    return
end
local ok, platform = platform_plugin.get_platform()
if not ok then
    log_error("Cannot determine platform!")
    return
end

local download_links = hjson.parse(fs.read_file("__xtz/sources.hjson"))

local download_urls = nil

if platform.OS == "unix" then
	download_urls = download_links["linux-x86_64"]
    if platform.SYSTEM_TYPE:match("[Aa]arch64") then
        download_urls = download_links["linux-arm64"]
    end
end

if download_urls == nil then
    log_error("Platform not supported!")
    return
end

am.app.set_model(
    {
        DOWNLOAD_URLS = am.app.get_configuration("SOURCES", download_urls),
    },
    { merge = true, overwrite = true }
)

local services = require("__xtz.services")
local wanted_binaries = services.all_binaries

local TEZOS_LOG_LEVEL = am.app.get_configuration("TEZOS_LOG_LEVEL", "info")

local DAL_STARTUP_ARGS = am.app.get_configuration("DAL_STARTUP_ARGS", {})

local attester_profiles = am.app.get_configuration("ATTESTER_PROFILES", {})
-- additional attester_profiles from attester_profiles.list
local attester_profiles_list_raw = io.open("attester_profiles.list", "r+b")
if attester_profiles_list_raw ~= nil then
    for profile in attester_profiles_list_raw:lines() do
        table.insert(attester_profiles, profile)
    end
end

if table.is_array(attester_profiles) and #attester_profiles > 0 then
    table.insert(DAL_STARTUP_ARGS, 1, "--attester-profiles")
    table.insert(DAL_STARTUP_ARGS, 2, string.join(",", table.unpack(attester_profiles)))
end

local package_utils = require("__xtz.utils")
local node_endpoint = am.app.get_configuration("NODE_ENDPOINT", "http://127.0.0.1:8732/")
local node_endpoint_host_and_port = package_utils.extract_host_and_port(node_endpoint, 8732)
table.insert(DAL_STARTUP_ARGS, 1, "--endpoint")
table.insert(DAL_STARTUP_ARGS, 2, node_endpoint)

local rpc_addr = am.app.get_configuration("RPC_ADDR", "http://127.0.0.1:10732")
local rpc_host_and_port = package_utils.extract_host_and_port(rpc_addr, 10732)

am.app.set_model(
    {
        WANTED_BINARIES = wanted_binaries,
        RPC_ADDR = rpc_addr,
        RPC_HOST_AND_PORT = rpc_host_and_port,
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
    },
    { merge = true, overwrite = true }
)
