defmodule CoverexTest do
	use ExUnit.Case

	alias Coverex.Task
	
	test "coveralls wished?" do
	  	opts = [coveralls: true]
	  	assert Task.post_to_coveralls?(opts) 
	end

	test "coveralls not wished?" do
	  	opts = [coveralls: false]
	  	refute Task.post_to_coveralls?(opts) 
	end

	test "is coveralls requested on the commandline?" do
		conf = Mix.Project.config()
		IO.inspect conf
		assert Task.post_to_coveralls?(conf[:test_coverage])
	end
end
