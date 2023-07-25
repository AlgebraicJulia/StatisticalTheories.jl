module TestPlateDiagrams

using Test
using StatisticalTheories
using Catlab.WiringDiagrams

θ = MarkovCats.Ob(FreeMarkovCategory.Ob,:θ)
X = MarkovCats.Ob(FreeMarkovCategory.Ob,:X)
P₀ = MarkovCats.Hom(:P0,θ,X)

d = to_wiring_diagram(P₀)

@test expand(PlateDiagrams.PlateDiagram(:P0,d),2,true)==compose(compose(mcopy(dom(d),2),otimes(d,d)),implicit_mmerge(codom(d),2))
@test expand(PlateDiagrams.PlateDiagram(:P0,d),2,false)==compose(mcopy(dom(d),2),otimes(d,d))
end