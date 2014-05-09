defmodule Coverex do
    @moduledoc false

   	def start(_type, _args) do
   		Coverex.Supervisor.start_link()
   	end
  	def start() do
  		start(:none, :none)  		
  	end


  end
