defmodule CoverexSourceTest do
	
	use ExUnit.Case

	@mod Coverex.Source

  	# test "compile info " do
  	# 	info = Coverex.Source.get_compile_info(@mod)

  	# 	assert is_list(info)
  	# 	assert Keyword.get(info, :options) == [:debug_info]
  	# end

  	# test "source info" do
  	# 	source = Coverex.Source.get_source_path(@mod)

  	# 	assert is_list(source)
  	# end

  	# test "get source and quoted" do
  	# 	{quoted, source} = Coverex.Source.get_quoted_source(@mod)

  	# 	assert is_binary(source)
  	# 	assert {:defmodule, [line: 1], _} = quoted
  	# end

  	test "check 1 alias" do
  		as = Coverex.Source.alias_mod(X)
  		assert [:X] = as
      m = Coverex.Source.alias_to_atom(as)
      assert X == m
  	end

  	test "check 2 aliases" do
  		as = Coverex.Source.alias_mod(@mod)
  		assert [:Coverex, :Source] == as
      m = Coverex.Source.alias_to_atom(as)
      assert @mod == m
  	end

  	test "find a single module" do
  		{:ok, quoted} = generate_mod("X", ["f", "g", "hs"]) |> Code.string_to_quoted
  		# IO.puts "quoted code is \n #{inspect quoted}"

      mods = Coverex.Source.find_all_mods_and_funs(quoted)
      # IO.inspect mods
      assert mods[X][X] == 1
  	end

    test "find all modules and funs" do
      ms = %{"X" => X, "Y" => Y, "A.B.C" => A.B.C}
      funs = [{X, :f, 0}, {X, :g, 0}, {X, :hs, 0}]
      {:ok, mod} = generate_mod(Map.keys(ms), funs) |> Code.string_to_quoted
      # IO.inspect mod 
      all_mods = Coverex.Source.find_all_mods_and_funs(mod)
      # IO.inspect all_mods 

      ms |> Dict.values |> Enum.each fn(mod_name) ->
        assert %{} = all_mods[mod_name]
        assert is_integer(all_mods[mod_name][mod_name]) 
        funs |> # Enum.map(&String.to_atom/1) |> 
          Enum.each fn({_m, f, a}) ->
            # IO.puts "f = #{inspect f}"
            assert is_integer(all_mods[mod_name][{mod_name, f, a}])
          end
      end
    end

    test "generate line entries" do
      m = [{X, 1}, 
        {{X, :f, 2}, 5}, 
        {{X, :g, 0}, 9}] |> 
          Enum.into %{}
      cover = [{{X, 5}, 1}, {{X, 6}, 1}, {{X, 7}, 1}, {{X, 9}, 3}]
      lines = Coverex.Source.generate_lines(cover, m)

      f_link = Coverex.Task.module_anchor({X, :f, 2})
      # IO.puts "Lines = #{inspect lines}"
      assert %{} = lines
      assert {1, f_link} == lines[5]
      assert {1, nil} = lines[6]
    end
    


  	@doc """
  	Generates modules with functions as binaries
  	"""
  	def generate_mod(mod), do: generate_mod(mod, [])
  	def generate_mod(mod, funs) when is_binary(mod) do
  		fs = funs |> Enum.reduce("", fn(f, acc) -> make_fun(f) <> acc end)
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
  	
    defp make_fun({_, f, 0}), do: "def #{f}(), do: :funny0\n"
    defp make_fun({_, f, args}), do: "def #{f}(#{1..args |> Enum.map_join(",", &("args#{&1}"))}), do: :funny#{args}\n"
    defp make_fun(f), do: "def #{f}(), do: :funny_0\n"

end