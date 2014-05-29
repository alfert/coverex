defmodule CoverexSourceTest do
	
	use ExUnit.Case

	@mod Coverex.Source

  	test "compile info " do
  		info = Coverex.Source.get_compile_info(@mod)

  		assert is_list(info)
  		assert Keyword.get(info, :options) == [:debug_info]
  	end

  	test "source info" do
  		source = Coverex.Source.get_source_path(@mod)

  		assert is_list(source)
  	end

  	test "get source and quoted" do
  		{quoted, source} = Coverex.Source.get_quoted_source(@mod)

  		assert is_binary(source)
  		assert {:defmodule, [line: 1], _} = quoted
  	end

  	test "check 1 alias" do
  		as = Coverex.Source.alias_mod(X)
  		assert [:X] = as
  	end

  	test "check 2 aliases" do
  		as = Coverex.Source.alias_mod(@mod)
  		assert [:Coverex, :Source] = as
  	end

  	# test "find the proper module" do
  	# 	{:ok, mod} = generate_mod("X", ["f", "g", "hs"]) |> Code.string_to_quoted
  	# 	IO.inspect mod 
  	# 	alias_modname = Coverex.Source.alias_mod(X)

  	# 	assert {:defmodule, _, [{:__aliases__, _, [:X]}, _]} = Coverex.Source.find_mod(mod, alias_modname)
  	# end

  	test "find all module" do
  		ms = %{"X" => X, "Y" => Y, "A.B.C" => A.B.C}
  		{:ok, mod} = generate_mod(Map.keys(ms), ["f", "g", "hs"]) |> Code.string_to_quoted
  		IO.inspect mod 
  		as = ms |> Enum.map fn({s, m}) -> Coverex.Source.alias_mod(m) end

  		as |> Enum.each fn(alias_modname) ->
  			assert [{:defmodule, _, [{:__aliases__, _, alias_modname}, _]}] = 
  				Coverex.Source.find_mod(mod, alias_modname) end
  	end


  	@doc """
  	Generates modules with functions as binaries
  	"""
  	def generate_mod(mod), do: generate_mod(mod, [])
  	def generate_mod(mod, funs) when is_binary(mod) do
  		fs = funs |> Enum.reduce("", fn(f, acc) -> "def #{f}(), do: :funny\n" <> acc end)
  		"""
  		defmodule #{mod} do
		""" <> fs <>
		"""  			
  		end
  		"""
  	end
  	def generate_mod(mods, funs) when is_list(mods) do
  		mods |> Enum.reduce("", fn(m, acc) -> generate_mod(m, funs) <> acc end)
  	end
  	

end