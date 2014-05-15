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
end