local service_manager = require"__xtz.service-manager"
local services = require"__xtz.services"

log_info("stopping dal node services... this may take a few minutes.")

service_manager.stop_services(services.active_names)

log_success("dal node services successfully stopped.")