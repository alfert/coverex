defmodule Coverex.Source do
	@moduledoc """
	This module provides access to the source code the system to be analyzed.
	"""

	require Logger

	@type symbol :: :atom
	@type line_pairs :: %{symbol => pos_integer}
	@type modules :: %{symbol => line_pairs}
	@type line_entries :: %{pos_integer => {pos_integer | nil, binary | nil}}	

	@spec analyze_to_html(symbol) :: {line_entries, binary}
	def analyze_to_html(mod) when is_atom(mod) do
		Logger.info("analyze_to_html of module #{inspect mod}")
		{quoted, source} = get_quoted_source(mod)
		mods = find_all_mods_and_funs(quoted)
		Logger.info("Mods and funs found: #{inspect mods}")
		{:ok, cover} = :cover.analyse(mod, :calls, :line)
		## cover is [{{mod, line}, count}]
		# cover |> Enum.each &Logger.info/1
		{generate_lines(cover, mods[mod]), source}
	end
	
	@spec generate_lines([{{symbol, pos_integer}, pos_integer}], line_pairs) :: line_entries
	def generate_lines(cover, nil) do
		Logger.error "mod_entry is nil and cover = #{inspect cover}"
		%{}
	end
	def generate_lines(cover, mod_entry) do
		lines_cover = cover |> Enum.map(fn({{_mod, line_nr}, count}) -> 
			{line_nr, {count, nil}} end) |> Enum.into %{}
		lines_anchors = mod_entry|> Enum.map(fn({sym, line_nr}) -> 
			{line_nr, {nil, Coverex.Task.module_anchor(sym)}} end)
		lines = Dict.merge(lines_cover, lines_anchors, fn(k, {c, _}, {_, a}) -> {c, a} end)		
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
		# Logger.info ("+++ Found module #{inspect mod_name}")
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
	defp do_all_mods(mod_reversed, {:defimpl, [line: ln], [{:__aliases__, _, impl_name}, 
			[for: {:__aliases__, _, mod_name}] | body]}, acc) do
		Logger.debug "### found defimpl #{inspect impl_name} - #{inspect mod_name}"
		mod_alias = Enum.reverse(mod_name) ++ impl_name ++ mod_reversed
		mod = alias_to_atom(mod_alias)
		do_all_mods(mod_alias, body, acc |> Map.put(mod, %{} |> Map.put(mod,ln)))
	end
	defp do_all_mods(mod_reversed, {:def, [line: ln], [{fun_name, _, nil}, body]}, acc) do
		# Logger.info ("--- Found function #{inspect fun_name}")
		m = alias_to_atom(mod_reversed)
		do_all_mods(m, body, acc |> put_in([m, {m, fun_name, 0}], ln))
	end
	defp do_all_mods(mod_reversed, {:def, [line: ln], [{fun_name, _, args}, body]}, acc) do
		# Logger.info ("--- Found function #{inspect fun_name}")
		m = alias_to_atom(mod_reversed)
		do_all_mods(m, body, acc |> put_in([m, {m, fun_name, length(args)}], ln))
	end
	defp do_all_mods(m, {:__block__, _, tree}, acc) when is_list(tree), do: do_all_mods(m, tree, acc)
	defp do_all_mods(m, {:do, tree}, acc), do: do_all_mods(m, tree, acc)
	defp do_all_mods(m, t = {t1, t2, t3}, acc) do
		Logger.debug "#### Found triple #{inspect t}"
		acc
	end
	defp do_all_mods(m, [], acc), do: acc
	defp do_all_mods(m, [ head | tree], acc) do
		# basic recursion of the tree
		acc1 = do_all_mods(m, head, acc)
		do_all_mods(m, tree, acc1)
	end
	defp do_all_mods(m, t, acc) do
		Logger.debug ">>> Found tree #{inspect t}"
		acc
	end


	@doc "Returns the aliased module name if there are any dots in its name"
	def alias_mod(mod) when is_atom(mod) do
		mod |> Atom.to_string|> String.split(".") |> 
			Enum.drop(1) |> # first element contains "Elixir" which is not needed here!
			Enum.map &String.to_atom/1 
	end
	
	@doc "Returns the atom module name based on the alias list"
	def alias_to_atom(a) when is_list(a) do
		a |> IO.inspect |> Enum.reverse |> Enum.map_join(".", &Atom.to_string/1) |> String.to_atom
	end
	

	@doc "Returns the quoted code and the source of a module"
	@spec get_quoted_source(atom) :: {Mactro.t, binary}
	def get_quoted_source(mod) do
		path = get_source_path(mod)
		{:ok, source} = File.read(path)
		{:ok, quoted} = Code.string_to_quoted(source)
		{quoted, source}
	end
	

	@spec get_source_path(atom) :: {atom, binary}
	def get_source_path(mod) when is_atom(mod) do
		get_compile_info(mod) |> Keyword.get :source
	end
	
	@spec get_compile_info(atom) :: [{atom, term}]
	def get_compile_info(mod) when is_atom(mod) do
		{^mod, beam, filename} = :code.get_object_code(mod)
		case :beam_lib.chunks(beam, [:compile_info]) do
			{:ok, {^mod, [{:compile_info, compile}]}} -> compile
			_ -> []
		end		
	end

end