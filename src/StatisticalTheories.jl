""" Provides an implementation of statistical theories & models a la https://arxiv.org/abs/2006.08945
in Catlab. Allows for specification of theories and their models as well as integration with Turing.jl.
"""
module StatisticalTheories
include("PlateDiagrams.jl")
include("MarkovCats.jl")
include("ParseToGen.jl")
include("Double.jl")

using Reexport

@reexport using .MarkovCats
@reexport using .PlateDiagrams
@reexport using .ParseToGen
@reexport using .Double

end
