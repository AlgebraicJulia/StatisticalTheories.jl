using Catlab, Catlab.Theories
include("MarkovCats.jl")
include("PlateDiagrams.jl")
using .MarkovCats
using .PlateDiagrams

θ = MarkovCats.Ob(FreeMarkovCategory.Ob,:θ)
X = MarkovCats.Ob(FreeMarkovCategory.Ob,:X)
μ = MarkovCats.Ob(FreeMarkovCategory.Ob,:μ)
σ = MarkovCats.Ob(FreeMarkovCategory.Ob,:σ)
β = MarkovCats.Ob(FreeMarkovCategory.Ob,:β)
P₀ = MarkovCats.Hom(:P0,θ,X)

π₁ = MarkovCats.Hom(:π1,θ,β)
π₂ = MarkovCats.Hom(:π2,θ,σ)
data = MarkovCats.Hom(:data,β,μ)
normal = MarkovCats.Hom(:normal,otimes(μ,σ),X)
ThStat = Presentation(FreeMarkovCategory)
for g in [θ,X,μ,σ,β,π₁,π₂,data,normal] add_generator!(ThStat,g) end

one = Space(1)
two = Space(2)

gens = Dict(θ => two,
            μ => one,
            β => one,
            σ => one,
            X => one,
            π₁ => MarkovKernel(2,1,:pi1),
            π₂ => MarkovKernel(2,1,:pi2),
            data => MarkovKernel(1,1,:x),
            normal => MarkovKernel(2,1,:Normal)
            )



π₁,π₂,data,normal = map(to_wiring_diagram,[π₁,π₂,data,normal])
d = compose(mcopy(to_wiring_diagram(θ)),compose(otimes(compose(π₁,data),π₂),normal))
model = functor((Space,MarkovKernel),to_hom_expr(FreeMarkovCategory,d);generators=gens)

# # I thnk this doesn't work because the functor is not strict monoidal
# model = functor((Space,MarkovKernel),to_hom_expr(FreeMarkovCategory,expand(PlateDiagram(:D,d),2,true));generators=gens)

# # iid count on 2
# ThStat = Presentation(FreeMarkovCategory)
# P₀ = MarkovCats.Hom(:P0,θ,X)
# add_generator!(ThStat,θ)
# add_generator!(ThStat,X)
# add_generator!(ThStat,P₀)
# P = expand(PlateDiagram(:P,to_wiring_diagram(P₀)),2,true)
# gens = Dict(θ => 1,X => 1, P₀ => MarkovKernel(1,1,Expr(:call,:Beta)))
# model = functor((Int,MarkovKernel),to_hom_expr(FreeMarkovCategory,P),generators=gens)
