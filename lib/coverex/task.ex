defmodule Coverex.Task do
    require EEx

    def start(compile_path, opts) do
      Mix.shell.info "Coverex compiling modules ... "
      Mix.shell.info "compile_path is #{inspect compile_path}"
      :cover.start
      :cover.compile_beam_directory(compile_path |> to_char_list)

      if :application.get_env(:cover, :started) != {:ok, true} do
        output = opts[:output]

        System.at_exit fn(_) ->
          Mix.shell.info "\nGenerating cover results ... "
          File.mkdir_p!(output)
          Enum.each :cover.modules, fn(mod) ->
            :cover.analyse_to_file(mod, '#{output}/#{mod}.html', [:html])
          end
          {mods, funcs} = coverage_data()
          write_module_overview(mods, output)
          write_function_overview(funcs, output)
          generate_assets(output)
        end

        :application.set_env(:cover, :started, true)
      end
    end
    
    def write_module_overview(modules, output) do
      mods = Enum.map(modules, fn({mod, v}) -> {module_link(mod), v} end)
      content = overview_template("Modules", mods)
      File.write("#{output}/modules.html", content)
    end

    def write_function_overview(functions, output) do
      funs = Enum.map(functions, fn({{m,f,a}, v}) -> {module_link(m, f, a), v} end)
      content = overview_template("Functions", funs)
      File.write("#{output}/functions.html", content)
    end
    
    defp module_link(mod), do: "<a href=\"#{mod}.html\">#{mod}</a>"
    defp module_link(m, f, a), do: "<a href=\"#{m}.html\">#{m}.#{f}/#{a}</a>"

    @doc """
    Returns detailed coverage data `{mod, mf}` for all modules from the `:cover` application. 

    ## The `mod` data
    The `mod` data is a list of pairs: `{modulename, {no of covered lines, no of uncovered lines}}`
  
    ## The `mf` data
    The `mf` data is list of pairs: `{{m, f, a}, {no of covered lines, no of uncovered lines}}`

    """
    def coverage_data() do
      modules = Enum.map(:cover.modules, fn(mod) ->
        {:ok, {m, {cov, noncov}}} = :cover.analyse(mod, :coverage, :module) 
        {m, {cov, noncov}}
      end) |> Enum.sort
      mfunc = Enum.flat_map(:cover.modules, fn(mod) ->
        {:ok, funcs} = :cover.analyse(mod, :coverage, :function)
        funcs
      end) |> Enum.sort
      {modules, mfunc}
    end

    ## Generate templating functions via EEx, borrowd from ex_doc
    templates = [
      overview_template: [:title, :entries],
      overview_entry_template: [:entry, :cov, :uncov, :ratio]
    ]
    Enum.each templates, fn({ name, args }) ->
      filename = Path.expand("templates/#{name}.eex", __DIR__)
      EEx.function_from_file :def, name, filename, args
    end

    # generates asset files
    defp generate_assets(output) do
      Enum.each assets, fn({ pattern, dir }) ->
        output = "#{output}/#{dir}"
        File.mkdir output

        Enum.map Path.wildcard(pattern), fn(file) ->
          base = Path.basename(file)
          File.copy file, "#{output}/#{base}"
        end
      end
    end
    # assets are javascript, css and gif resources
    defp assets do
      [ { templates_path("css/*.css"), "css" },
        { templates_path("js/*.js"), "js" },
        { templates_path("css/*.gif"), "css" },
      ]
    end
    defp templates_path(other), do: Path.expand("templates/#{other}", __DIR__)

end