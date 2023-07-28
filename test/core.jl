module TestCore

using StatisticalTheories
using Test
using Catlab.Theories
using Catlab
using Catlab.WiringDiagrams
using Gen.Distributions
using StatisticalTheories.MarkovCats

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
theory = Presentation(FreeMarkovCategory)
for g in [θ,X,μ,σ,β,π₁,π₂,data,normal] add_generator!(theory,g) end

theta= Space(:theta,2)
mu = Space(:mu,1)
beta = Space(:beta,1)
sigma = Space(:sigma,1)
ex = Space(:X,1)
pi1 = opentermgraph_edge([theta],beta,:pi1,Function)
pi2 = opentermgraph_edge([theta],sigma,:pi2,Function)
dta = opentermgraph_edge([beta],mu,:data,Function)
norm = opentermgraph_edge([mu,sigma],ex,:normal,Distribution)
# this could be something like opentermgraph_edge([theta],[beta],:π₁,Function)

gens = Dict(θ => dom(pi1),
            μ => codom(dta),
            β => dom(dta),
            σ => codom(pi2),
            X => codom(norm),
            π₁ => pi1,
            π₂ => pi2,
            data => dta,
            normal => norm
            )

π₁,π₂,data,normal = map(to_wiring_diagram,[π₁,π₂,data,normal])
# d = compose(mcopy(to_wiring_diagram(θ)),compose(otimes(compose(π₁,data),π₂)),normal)
d = compose(mcopy(to_wiring_diagram(θ)),compose(otimes(compose(π₁,data),π₂),normal))

model = functor((OpenTermGraphOb,OpenTermGraph),to_hom_expr(FreeMarkovCategory,d);generators=gens)

g = Open(@acset TermGraph begin 
   Node = 5
   Unary = 3
   Binary = 1
   unIn = [1,1,2]
   unOut = [2,3,4]
   binOut = [5]
   binIn₁ = [4]
   binIn₂ = [3]
   binLabel = [(:normal,Distribution)]
   unLabel = [(:pi1,Function),(:pi2,Function),(:data,Function)]
   var = [Space(:theta,2),Space(:beta,1),Space(:sigma,1),Space(:mu,1),Space(:X,1)]
end)

@test codom(model).ob[:var][1] == Space(:X,1)
@test dom(model).ob[:var][1] == Space(:theta,2)
# ex = ParseToGen.ker2expr(model)
# @test ex==:($(Expr(:X, :normal, :($(Expr(:mu, :data, :($(Expr(:beta, :pi1, :theta)))))), :($(Expr(:sigma, :pi2, :theta))))))

# model = functor((Space,MarkovKernel),to_hom_expr(FreeMarkovCategory,expand(PlateDiagram(:D,d),2,true));generators=gens)
# # iid count on 2
# theory = Presentation(FreeMarkovCategory)
# P₀ = MarkovCats.Hom(:P0,θ,X)
# add_generator!(theory,θ)
# add_generator!(theory,X)
# add_generator!(theory,P₀)
# P = expand(PlateDiagram(:P,to_wiring_diagram(P₀)),2,true)
# gens = Dict(θ => 1,X => 1, P₀ => MarkovKernel(1,1,Expr(:call,:Beta)))
# model = functor((Int,MarkovKernel),to_hom_expr(FreeMarkovCategory,P),generators=gens)

end