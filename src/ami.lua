return {
    title = "XTZ dal node",
    commands = {
        info = {
            description = "ami 'info' sub command",
            summary = "Prints runtime info and status of the app",
            action = "__xtz/info.lua",
            options = {
                ["timeout"] = {
                    aliases = { "t" },
                    description = 'Sets time to wait for info collections',
                    type = "number"
                },
                ["services"] = {
                    description = "Prints info about services",
                    type = "boolean"
                },
                ["simple"] = {
                    aliases = "s",
                    description = "Prints simplified info",
                    type = "boolean"
                }
            },
            context_fail_exit_code = EXIT_APP_INFO_ERROR
        },
        setup = {
            options = {
                configure = {
                    description = "Configures application, renders templates and installs services"
                }
            },
            action = function(options, _, _, _)
                local no_options = #table.keys(options) == 0
                if no_options or options.environment then
                    am.app.prepare()
                end

                if no_options or not options["no-validate"] then
                    am.execute("validate", { "--platform" })
                end

                if no_options or options.app then
                    am.execute_extension("__xtz/download-binaries.lua", { context_fail_exit_code = EXIT_SETUP_ERROR })
                end

                if no_options and not options["no-validate"] then
                    am.execute("validate", { "--configuration" })
                end

                if no_options or options.configure then
                    am.execute_extension('__xtz/create_user.lua', { context_fail_exit_code = EXIT_APP_CONFIGURE_ERROR })
                    am.app.render()
                    am.execute_extension("__xtz/configure.lua", { context_fail_exit_code = EXIT_APP_CONFIGURE_ERROR })
                end
                log_success("XTZ node setup complete.")
            end
        },
        start = {
            description = "ami 'start' sub command",
            summary = "Starts the XTZ node",
            action = "__xtz/start.lua",
            context_fail_exit_code = EXIT_APP_START_ERROR
        },
        stop = {
            description = "ami 'stop' sub command",
            summary = "Stops the XTZ node",
            action = "__xtz/stop.lua",
            context_fail_exit_code = EXIT_APP_STOP_ERROR
        },
        validate = {
            description = "ami 'validate' sub command",
            summary = "Validates app configuration and platform support",
            action = function(options, _, _, cli)
                if options.help then
                    am.print_help(cli)
                    return
                end
                -- //TODO: Validate platform
                ami_assert(proc.EPROC, "xtz node AMI requires extra api - eli.proc.extra", EXIT_MISSING_API)
                ami_assert(fs.EFS, "xtz node AMI requires extra api - eli.fs.extra", EXIT_MISSING_API)

                ami_assert(type(am.app.get("id")) == 'string', "id not specified!", EXIT_INVALID_CONFIGURATION)
                ami_assert(type(am.app.get_configuration()) == 'table', "configuration not found in app.h/json!",
                    EXIT_INVALID_CONFIGURATION)
                ami_assert(type(am.app.get("user")) == 'string', "USER not specified!", EXIT_INVALID_CONFIGURATION)
                ami_assert(type(am.app.get_type()) == "table" or type(am.app.get_type()) == "string", "Invalid app type!"
                    , EXIT_INVALID_CONFIGURATION)
                log_success("XTZ node configuration validated.")
            end
        },
        ["dal-node"] = {
            description = "ami 'dal-node' sub command",
            summary = "Passes any passed arguments directly to tezos-node.",
            index = 9,
            type = "external",
            exec = "bin/dal-node",
            environment = {
                HOME = path.combine(os.cwd() or ".", "data")
            },
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        log = {
            description = "ami 'log' sub command",
            summary = 'Prints logs from services.',
            options = {
                ["follow"] = {
                    aliases = { "f" },
                    description = "Continuously prints the log in real-time.",
                    type = "boolean"
                },
                ["end"] = {
                    aliases = { "e" },
                    description = "Jumps to the end of the log.",
                    type = "boolean"
                },
                ["since"] = {
                    description = "Displays logs starting from the specified time or date. Format: 'YYYY-MM-DD HH:MM:SS'",
                    type = "string"
                },
                ["until"] = {
                    description = "Displays logs up until the specified time or date. Format: 'YYYY-MM-DD HH:MM:SS'",
                    type = "string"
                }
            },
            type = "namespace",
            action = '__xtz/log.lua',
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        about = {
            description = "ami 'about' sub command",
            summary = "Prints information about application",
            action = '__xtz/log.lua',
        },
        ["install-trusted-setup"] = {
            description = "ami 'install-trusted-setup' sub command",
            summary = "Downloads trusted setup files for dal-node",
            action = "__xtz/install_trusted_setup.lua",
        },
        pack = {
            description = "ami 'pack' sub command",
            options = {
                output = {
                    index = 1,
                    aliases = {"o"},
                    description = "Output path for the archive"
                },
                light = {
                    index = 2,
                    description = "If used the archive will not include chain data"
                }
            },
            action = function (options)
                am.app.pack({
                    destination = options.output,
                    mode = options.light and "light" or "full",
                })
            end
        },
        remove = {
            index = 7,
            action = function(options, _, _, _)
                if options.all then
                    am.execute_extension("__xtz/remove-all.lua", { context_fail_exit_code = EXIT_RM_ERROR })
                    am.app.remove()
                    log_success("Application removed.")
                end
                if #table.keys(options) == 0 then
                    am.app.remove_data()
                    log_success("Application data removed.")
                end
                return
            end
        },
    }
}
