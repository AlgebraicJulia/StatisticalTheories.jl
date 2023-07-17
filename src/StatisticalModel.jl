using Catlab, Catlab.Theories
include("MarkovCats.jl")
using .MarkovCats

θ = MarkovCats.Ob(FreeMarkovCategory.Ob,:θ)
X = MarkovCats.Ob(FreeMarkovCategory.Ob,:X)
P = MarkovCats.Hom(:P,θ,X)
ThStat = Presentation(FreeMarkovCategory)
add_generator!(ThStat,θ)
add_generator!(ThStat,X)
add_generator!(ThStat,P)

# # I am guessing this doesn't work due to my lack of understanding
## of the julia module system
# @present ThStat(FreeMarkovCategory) begin
#    θ::Ob
#    X::Ob
#    P::Hom(θ,X)
# end

# @present ThIIDCounts <: ThStat begin
#    P₀::Hom(θ,X)
# end

# ThIIDCounts = Presentation(FreeMarkovCategory) <: ThStat




# model = @finfunctor ThLinear Stat 

# f = MarkovKernel(1,1,Expr(:meh))
# g = MarkovKernel(1,1,Expr(:beh))
# h = MarkovKernel(2,2,Expr(:normal))
# j = MarkovKernel(3,1,Expr(:hi))

# k = MarkovKernel(5,3,[h,j])

# compose(otimes(f,g),h)