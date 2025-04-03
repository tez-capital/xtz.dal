local user = am.app.get("user")
ami_assert(type(user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local ok, error = fs.safe_mkdirp("data")
ami_assert(ok, "failed to create data directory: ".. tostring(error))
local ok, uid = fs.safe_getuid(user)
ami_assert(ok, "Failed to get " .. user .. "uid - " .. (uid or ""))

log_info("Configuring " .. am.app.get("id") .. " services...")

local backend = am.app.get_configuration("backend", os.getenv("ASCEND_SERVICES") ~= nil and "ascend" or "systemd")

local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"
services.remove_all_services() -- cleanup past install

for k, v in pairs(services.all) do
	local service_id = k
	local source_file = string.interpolate("${file}.${extension}", {
		file = v,
		extension = backend == "ascend" and "ascend.hjson" or "service"
	})
	local ok, err = service_manager.safe_install_service(source_file, service_id)
	ami_assert(ok, "Failed to install " .. service_id .. ".service " .. (err or ""))
end

log_success(am.app.get("id") .. " services configured")

log_info("Downloading zcash parameters... (This may take a few minutes.)")

local download_zk_params = require"__xtz.download-zk-params"
local ok, err = download_zk_params()
ami_assert(ok, "Failed to fetch params: " .. tostring(err))

local CONFIG_FILE_DIRECTORY = "./data/.tezos-dal-node"
local CONFIG_FILE_PATH = CONFIG_FILE_DIRECTORY .. "/config.json"

local config_file = am.app.get_configuration("CONFIG_FILE")
if type(config_file) == "table" and not table.is_array(config_file) then
	fs.safe_mkdirp(CONFIG_FILE_DIRECTORY)
	log_info("Creating config file...")
	fs.write_file(CONFIG_FILE_PATH, hjson.stringify_to_json(config_file))
elseif fs.exists("./__xtz/dal-node-config.json") then
	fs.safe_mkdirp(CONFIG_FILE_DIRECTORY)
	fs.copy_file("./__xtz/dal-node-config.json", CONFIG_FILE_PATH)
end

-- prism
local PRISM = am.app.get_configuration("PRISM")
if PRISM then
	require"__xtz.prism.setup"
end

-- finalize
local ok, error = fs.chown(os.cwd() or ".", uid, uid, {recurse = true})
ami_assert(ok, "Failed to chown data - " .. (error or ""))