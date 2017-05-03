defmodule Coverex.Source do
  @moduledoc """
  This module provides access to the source code the system to be analyzed.
  """

  require Logger

  @type symbol :: :atom
  @type filename :: String.t
  @type line_pairs :: %{symbol => pos_integer}
  @type modules :: %{symbol => line_pairs}
  @type line_entries :: %{pos_integer => {pos_integer | nil, binary | nil}}
  @type source_file :: %{name: String.t, source: String.t, coverage: [pos_integer | nil]}
  @type lines :: {pos_integer, pos_integer | nil}

  @spec analyze_to_html(symbol) :: {line_entries, binary}
  def analyze_to_html(mod) when is_atom(mod) do
    Logger.debug("analyze_to_html of module #{inspect mod}")
    {quoted, source} = get_quoted_source(mod)
    mods = find_all_mods_and_funs(quoted)
    if mod == Observable.PID, do:
      Logger.debug("Mods and funs found: #{inspect mods}")
    {:ok, cover} = :cover.analyse(mod, :calls, :line)
    ## cover is [{{mod, line}, count}]
    # cover |> Enum.each &Logger.info/1
    {generate_lines(cover, mods[mod]), source}
  end

  @doc """
  Returns the coverall data for the list of mods as Elixir datastructure.
  This can be encoded as JSON for uploading to coveralls.
  """
  @spec coveralls_data([symbol]) :: [source_file]
  def coveralls_data(mods) do
    mc = mods |> Enum.map(fn(mod) -> {mod, cover_per_mod(mod)} end)
    sources_and_lines(mc) |>
      Enum.reduce([], fn({path, cover}, acc) ->
        [%{:name => filter_cwd_prefix(path),
          :source => File.read!(path),
          :coverage => cover |> lines_to_list} | acc]
      end)
  end

  @doc "Strips the current directory from the path"
  def filter_cwd_prefix(path) do
    Path.relative_to_cwd(path)
  end

  @doc """
  This function aggregates the coverage information per module to a coverage
  information per source file.

  Takes a list of modules and determines the list of corresponding filenames.
  Returns to each filename a map of coverage information for the entire file.
  """
  @spec sources_and_lines([{symbol, [lines]}]) :: [{filename, line_entries}]
  def sources_and_lines(mods) do
    # identify all modules of a source file
    # mod_files is %{path => [symbol]}
    mod_files = mods |>
      Enum.map(fn({mod, lines}) -> {mod, get_source_path(mod), lines} end) |>
      Enum.reduce(%{}, fn({m, p, l}, acc) ->
        Map.update(acc, p, [{m, l}], fn(old) -> [{m, l} | old] end)
      end)
    # for each source file, grab all coverage information on line basis,
    # merge them for all modules and fill up any leaks with nils
    mod_files |> Enum.map(fn({path, mods}) -> {path, merge_coverage(mods)} end)
  end

  @doc """
  Gets a list of all modules within one sourcefile. Calculates the coverage
  data for each module and merges them together. Returns a mapping of line number
  to coverage data for the entire source file. Guarantees that all line numbers up
  to the maximun reached line are filled in.
  """
  @spec merge_coverage([{symbol, lines}]) :: line_entries
  def merge_coverage(mods) do
    unmerged = mods |> Enum.map(fn({_mod, lines}) -> lines end) |> List.flatten
    # unmerged is [{line, count}]
    merged = unmerged |> Enum.reduce(%{}, fn ({line, count}, acc) ->
      Map.update(acc, line, count,
        fn(nil) -> count
           (c)  -> count + c end)
      end)
    # fill all gaps with nil
    max_lines = merged |> Map.keys |> Enum.max
    1..max_lines |> Enum.reduce(merged, fn(index, acc) ->
      Map.put_new(acc, index, nil) end)
  end

  @spec lines_to_list(line_entries) :: [pos_integer | nil]
  def lines_to_list(lines) do
    lines
    |> Enum.sort(fn({l1, _}, {l2, _}) -> l1 <= l2 end)
    |> Enum.drop(1) # drop the mythical line 0
    |> Enum.map(fn({_l, count}) -> count end)
  end


  @spec cover_per_mod(symbol) :: [lines]
  def cover_per_mod(mod) do
    ## cover is [{{mod, line}, count}]
    {:ok, cover} = :cover.analyse(mod, :calls, :line)
    cover |> Enum.map(fn({{_m, line}, count}) -> {line, count} end)
  end


  @spec generate_lines([{{symbol, pos_integer}, pos_integer}], line_pairs) :: line_entries
  def generate_lines(cover, nil) do
    # This seems to be a situation where Macros are used extensively.
    # Does no harm but is annoying.
    Logger.debug "mod_entry is nil and cover = #{inspect cover}"
    %{}
  end
  def generate_lines(cover, mod_entry) do
    lines_cover = cover |> Enum.map(fn({{_mod, line_nr}, count}) ->
      {line_nr, {count, nil}} end) |> Enum.into(%{})
    lines_anchors = mod_entry|> Enum.map(fn({sym, line_nr}) ->
      {line_nr, {nil, Coverex.Task.module_anchor(sym)}} end)
    _lines = Dict.merge(lines_cover, lines_anchors, fn(_k, {c, _}, {_, a}) -> {c, a} end)
  end

  @doc """
  Returns all modules and functions together with their start lines as they definend
  in the given quoted code
  """
  @spec find_all_mods_and_funs(any) :: modules
  def find_all_mods_and_funs(qs) do
    # Logger.info qs
    acc = %{:Elixir => %{}}
    do_all_mods([:Elixir], qs, acc)
  end

  # Walks the syntax tree
  # First parameter is a reverse list of nested module scopes, i.e.
  #    X.Y is encoded as [:Y, :X, :Elixir]
  defp do_all_mods(mod_reversed, {:defmodule, [line: ln], [{:__aliases__, _, mod_name} | body]}, acc) do
    # Logger.debug ("+++ Found module #{inspect mod_name}")
    mod_alias = Enum.reverse(mod_name) ++ mod_reversed
    mod = alias_to_atom(mod_alias)
    do_all_mods(mod_alias, body, acc |> Map.put(mod, %{} |> Map.put(mod,ln)))
  end
  defp do_all_mods(mod_reversed, {:defprotocol, [line: ln], [{:__aliases__, _, mod_name} | body]}, acc) do
    Logger.debug "### found defprotocol #{inspect mod_name}"
    mod_alias = Enum.reverse(mod_name) ++ mod_reversed
    mod = alias_to_atom(mod_alias)
    do_all_mods(mod_alias, body, acc |> Map.put(mod, %{} |> Map.put(mod,ln)))
  end
  defp do_all_mods(_mod_reversed, {:defimpl, [line: ln], [{:__aliases__, _, impl_name},
      [for: {:__aliases__, _, mod_name}] | body]}, acc) do
    Logger.debug "### found defimpl #{inspect impl_name} - #{inspect mod_name}"
    # impls are always toplevel modules?!
    mod_alias = Enum.reverse(mod_name) ++ Enum.reverse(impl_name) ++ [:Elixir] # mod_reversed
    mod = alias_to_atom(mod_alias)
    do_all_mods(mod_alias, body, acc |> Map.put(mod, %{} |> Map.put(mod,ln)))
  end
  defp do_all_mods(mod_reversed, {:def, [line: ln], [{fun_name, _, nil}, body]}, acc) do
    # Logger.debug ("--- Found function #{inspect fun_name}")
    m = alias_to_atom(mod_reversed)
    do_all_mods(m, body, acc |> put_in([m, {m, fun_name, 0}], ln))
  end
  defp do_all_mods(mod_reversed, {:def, [line: ln], [{fun_name, _, args}, body]}, acc) do
    # Logger.debug ("--- Found function #{inspect fun_name}")
    m = alias_to_atom(mod_reversed)
    do_all_mods(m, body, acc |> put_in([m, {m, fun_name, length(args)}], ln))
  end
  defp do_all_mods(mod_reversed, {:@, [line: ln], [{:derive, _, [{:__aliases__, _, [:Access]}]}]}, acc) do
    # derives a new module, where Access is put in front of the module name:
    # X.Y.Z @derive Access ==> Access.X.Y.Z <<-->> [:Z,:Y,:X,:Access, :Elixir]
    # This requires that we insert :Access before :Elixir in mod_reversed
    m = ((mod_reversed |> Enum.take(length(mod_reversed) - 1)) ++ [:Access, :Elixir]) |> alias_to_atom
    acc |> Map.put(m, %{} |> Map.put(m, ln))
  end
  defp do_all_mods(m, {:__block__, _, tree}, acc) when is_list(tree), do: do_all_mods(m, tree, acc)
  defp do_all_mods(m, {:do, tree}, acc), do: do_all_mods(m, tree, acc)
  defp do_all_mods(_m, t = {_t1, _t2, _t3}, acc) do
    Logger.debug "#### Found triple #{inspect t}"
    acc
  end
  defp do_all_mods(_m, [], acc), do: acc
  defp do_all_mods(m, [ head | tree], acc) do
    # basic recursion of the tree
    acc1 = do_all_mods(m, head, acc)
    do_all_mods(m, tree, acc1)
  end
  defp do_all_mods(_m, t, acc) do
    Logger.debug ">>> Found tree #{inspect t}"
    acc
  end


  @doc "Returns the aliased module name if there are any dots in its name"
  def alias_mod(mod) when is_atom(mod) do
    mod |> Atom.to_string|> String.split(".") |>
      Enum.drop(1) |> # first element contains "Elixir" which is not needed here!
      Enum.map(&String.to_atom/1)
  end

  @doc "Returns the atom module name based on the (reversed) alias list"
  def alias_to_atom(a) when is_list(a) do
    a |> Enum.reverse |> Enum.map_join(".", &Atom.to_string/1) |> String.to_atom
  end


  @doc "Returns the quoted code and the source of a module"
  @spec get_quoted_source(atom) :: {Macro.t, binary}
  def get_quoted_source(mod) do
    path = get_source_path(mod)
    {:ok, source} = File.read(path)
    {:ok, quoted} = Code.string_to_quoted(source)
    {quoted, source}
  end


  @spec get_source_path(atom) :: {atom, binary}
  def get_source_path(mod) when is_atom(mod) do
    get_compile_info(mod) |> Keyword.get(:source)
  end

  @spec get_compile_info(atom) :: [{atom, term}]
  def get_compile_info(mod) when is_atom(mod) do
    {^mod, beam, _filename} = :code.get_object_code(mod)
    case :beam_lib.chunks(beam, [:compile_info]) do
      {:ok, {^mod, [{:compile_info, compile}]}} -> compile
      _ -> []
    end
  end

end
