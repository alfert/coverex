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
		IO.inspect conf[:test_coverage]
		assert Task.post_to_coveralls?(conf[:test_coverage]),
			"coveralls must be set on the commandline to make a positive test"
	end

	test "positive check environment for travis" do
		env = %{"TRAVIS" => "true"}
		assert Task.running_travis?(env)
	end

	test "negative check environment for travis" do
		env = %{"TRAVIS" => "no"}
		refute Task.running_travis?(env)

		env = %{"TRAVIS" => "TRUE"}
		refute Task.running_travis?(env)
	end

	# test "post to whatever" do
	# 	conf = Mix.Project.config()
	# 	assert nil != conf[:test_coverage], "requires to run under `test --cover` "

	# 	assert :ok = Task.post_coveralls([Coverex.Task], ".", "id-123", "http://pastebin.com")
	# end
end
