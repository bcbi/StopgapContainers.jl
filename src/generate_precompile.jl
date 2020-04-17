@inline function _generate_precompile_content(config::Config)
    pkgs = config.pkgs
    no_test = config.no_test
    exclude_packages_from_sysimage = config.exclude_packages_from_sysimage
    precompile_env_vars = config.precompile_env_vars
    pkg_names_to_import = Vector{String}(undef, 0)
    pkg_names_to_test = Vector{String}(undef, 0)
    for pkg in pkgs
        pkg_name = pkg[:name]
        if !(pkg_name in exclude_packages_from_sysimage)
            push!(pkg_names_to_import, pkg_name)
        end
        if ( !(pkg_name in no_test) ) && ( !(pkg_name in exclude_packages_from_sysimage) )
            push!(pkg_names_to_test, pkg_name)
        end
    end
    set_precompile_env_vars_string = ""
    for (name, value) in precompile_env_vars
        set_precompile_env_vars_string *= "ENV[\"$(name)\"] = \"$(value)\"\n"
    end
    import_string = ""
    for pkg_name in pkg_names_to_import
        import_string *= "import $(pkg_name) # pkg_names_to_import\n"
    end
    return string("$(import_string)",
                  "import Pkg\n",
                  "for (uuid, info) in Pkg.dependencies()\n",
                  "if info.name in $(pkg_names_to_test) # pkg_names_to_test\n",
                  "$(set_precompile_env_vars_string)",
                  "include(joinpath(info.source, \"test\", \"runtests.jl\"))\n",
                  "end\n",
                  "end\n")
end
