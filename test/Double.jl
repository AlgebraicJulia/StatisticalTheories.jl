module TestDouble

using StatisticalTheories,StatisticalTheories.MarkovCats
using Test
using Catlab.Theories
using Catlab
using Catlab.WiringDiagrams


a = Ob(FreeMarkovCategory.Ob,:a)
b = Ob(FreeMarkovCategory.Ob,:b)
c = Ob(FreeMarkovCategory.Ob,:c)
d = Ob(FreeMarkovCategory.Ob,:d)

e = Ob(FreeMarkovCategory.Ob,:e)
x = Ob(FreeMarkovCategory.Ob,:x)
w = Ob(FreeMarkovCategory.Ob,:w)

f = Hom(:f,otimes(a,b),c)
g = Hom(:g,c,d)

l = Hom(:l,e,x)
k = Hom(:k,x,w)

theory = Presentation(FreeMarkovCategory)
theory2 = Presentation(FreeMarkovCategory)
[add_generator!(theory,x) for x in (a,b,c,d,f,g)]
[add_generator!(theory2,x) for x in (e,x,w,l,k)]
opentheory = Double.Open(theory,[:a,:b],[:d])
opentheory2 = Double.Open(theory2,[:e],[:w])

s1 = OpenStatisticalTheory{FreeMarkovCategory.Ob}(opentheory,compose(f,g))
s2 = OpenStatisticalTheory{FreeMarkovCategory.Ob}(opentheory2,compose(l,k))

p = pcompose(s1,s2)

@test dom(p.p) == otimes(a,b)
@test codom(p.p) == w
@test dom(p.T).ob == FinSet(2)
@test codom(p.T).ob == FinSet(1)
end