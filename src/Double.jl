module Double
using Catlab.CategoricalAlgebra
using Catlab.Presentations
using Catlab.Theories
using Catlab.WiringDiagrams
using Catlab.SyntaxSystems
using StatisticalTheories.MarkovCats
using Catlab.FinCats:FinCatPresentation
import Catlab.Limits.colimit
import Catlab.Theories:pcompose
import Catlab.CategoricalAlgebra.StructuredCospans:shift_left
export OpenPresentationHom,PresentationHom,colimit,Open,OpenPresentation,OpenStatisticalTheory,pcompose,shift_left,DiscreteCatPres

const PresentationHom = TermGraphUntyped{HomExpr,ObExpr}
const OpenPresentationHomOb,OpenPresentationHom = OpenTermGraphUntypedOb{HomExpr,ObExpr},OpenTermGraphUntyped{HomExpr,ObExpr}

function expand_dom(e::ObExpr)
   arity = length(e.args)
   pairs = (arity-1)*2
   acc = accumulate(otimes,e.args)
   var = Vector{ObExpr}(undef,1+pairs)
   var[1] = e.args[1]
   var[2:2:end-1] = e.args[2:end]
   var[3:2:pairs-1] = acc[2:end-1]
   var[end] = acc[end]
   g = @acset PresentationHom begin
      Node = 1+pairs
      Binary = arity-1
      binIn₁ = [1:2:pairs...]
      binIn₂ = [2:2:pairs...]
      binOut = [3:2:(1+pairs)...]
      binLabel = map(id,acc[2:end])
      var = var
   end
   return OpenPresentationHom(g,FinFunction([1,2:2:pairs...],1+pairs),FinFunction([1+pairs],1+pairs))
end

function expand_codom(e::ObExpr)
   arity = length(e.args)
   g = @acset PresentationHom begin
      Node = 1+arity
      Unary = arity
      unIn = fill(1,arity)
      unOut = [2:1+arity...]
      unLabel = map(id,e.args)
      var = [e,e.args...]
   end
   return OpenPresentationHom(g,FinFunction([1],arity+1),FinFunction([2:arity+1...],arity+1))
end

function fix_doms(g::OpenPresentationHom)
   if head(dom(g).ob[:var][1])==:otimes
      g = compose(expand_dom(dom(g).ob[:var][1]),g)
   end
   if head(codom(g).ob[:var][1])==:otimes
      g = compose(g,expand_codom(codom(g).ob[:var][1]))
   end
   len = nparts(g.feet[1],:Node)
   syntax = SyntaxSystems.syntax_module(g.cospan.apex[:var][1])
   set_subpart!(g.cospan.legs[1].dom,1:len,:var,map(x->Ob(syntax.Ob,Symbol(x)),1:len))
   set_subpart!(g.feet[1],1:len,:var,map(x->Ob(syntax.Ob,Symbol(x)),1:len))
   len = nparts(g.feet[2],:Node)
   set_subpart!(g.cospan.legs[2].dom,1:len,:var,map(x->Ob(syntax.Ob,Symbol(x)),1:len))
   set_subpart!(g.feet[2],1:len,:var,map(x->Ob(syntax.Ob,Symbol(x)),1:len))
   return g
end 

# this function may have some issues wrt product domains
function OpenPresentationHom(e::HomExpr)
   if head(e)==:generator
      g = @acset PresentationHom begin
         Node = 2
         Unary = 1
         unIn = [1]
         unOut = [2]
         unLabel = [e]
         var = [e.args[2],e.args[3]]
      end
      g = OpenPresentationHom(g,FinFunction([1],2),FinFunction([2],2))
   elseif e.args[1] isa ObExpr  # ob args
      g = @acset PresentationHom begin
         Node = 2
         Unary = 1
         unIn = [1]
         unOut = [2]
         unLabel = [e]
         var = [e.type_args[1],e.type_args[2]]
      end
      g = OpenPresentationHom(g,FinFunction([1],2),FinFunction([2],2))
   else  # hom args
      g= foldl(eval(head(e)),map(OpenPresentationHom,e.args))
   end
   return fix_doms(g)
end

function colimit(s::Span{<:FinCatPresentation{Ob}}) where Ob
   pres = copy(codom(s.legs[1]).presentation)
   add_generators!(pres,codom(s.legs[2]).presentation.generators[:Ob])
   add_generators!(pres,codom(s.legs[2]).presentation.generators[:Hom])
   for i=1:length(s.apex.presentation.generators[:Ob])
      add_equation!(pres,s.legs[1].ob_map[Symbol(i)],s.legs[2].ob_map[Symbol(i)])
   end
   for i=1:length(s.apex.presentation.generators[:Hom])
      add_equation!(pres,s.legs[1].hom_map[Symbol(i)],s.legs[2].hom_map[Symbol(i)])
   end
   pres = FinCatPresentation(pres)
   l1 = FinFunctor(Dict(x=>x for x in codom(s.legs[1]).presentation.generators[:Ob]),Dict(x=>x for x in codom(s.legs[1]).presentation.generators[:Hom]),codom(s.legs[1]),pres)
   l2 = FinFunctor(Dict(x=>x for x in codom(s.legs[2]).presentation.generators[:Ob]),Dict(x=>x for x in codom(s.legs[2]).presentation.generators[:Hom]),codom(s.legs[2]),pres)
   return Colimit(s,Cospan(pres,l1,l2))
end

## this stuff goes in StructuredCospans.jl?
struct DiscreteCatPres{ObExpr} end

function (::Type{L})(A::FinSet{Int}) where {ObExpr,L<:DiscreteCatPres{ObExpr}}
   pres = Presentation(parentmodule(ObExpr))
   add_generators!(pres,map(x->Ob(ObExpr,Symbol(x)),1:A.n))
   FinCat(pres)
end

function (::Type{L})(f::FinFunction{Int,Int}) where {ObExpr,L<:DiscreteCatPres{ObExpr}}
   d = L(dom(f))
   c = L(codom(f))
   FinFunctor(Dict(zip(d.presentation.generators[:Ob],c.presentation.generators[:Ob][f.func])),d,c)
end

function shift_left(::Type{L}, x::FinCatPresentation{Th,ObExpr,HomExpr}, f::FinFunction) where
   {Th,ObExpr,HomExpr, L <: DiscreteCatPres{ObExpr}}
   d = L(dom(f))
   FinFunctor(Dict(zip(d.presentation.generators[:Ob],x.presentation.generators[:Ob][f.func])), d, x)
end

function Open(p::Presentation, dom::Vector, codom::Vector)
   L = DiscreteCatPres{p.syntax.Ob}
   apex = FinCatPresentation(p)
   l1 = FinFunction([p.generator_name_index[x].second for x in dom],length(dom),length(p.generators[:Ob]))
   l2 = FinFunction([p.generator_name_index[x].second for x in codom],length(codom),length(p.generators[:Ob]))
   co = Cospan(FinSet(length(p.generators[:Ob])),l1,l2)
   return StructuredCospan{L}(apex,co)
end

OpenPresentation{Ob} = StructuredCospan{DiscreteCatPres{Ob}}

struct OpenStatisticalTheory{Ob}
   T::OpenPresentation{Ob}
   p::HomExpr
end

# function shift_apex(f::FinFunctor,c::Cospan)
#    n = nparts(c.apex,:Node)
#    nb = nparts(c.apex,:Binary)
#    nu = nparts(c.apex,:Unary)
#    set_subpart!(c.apex,1:n,:var,map(x->ob_map(f,x),subpart(c.apex,1:n,:var)))
#    set_subpart!(c.apex,1:nb,:binLabel,map(x->hom_map(f,x),subpart(c.apex,1:nb,:binLabel)))
#    set_subpart!(c.apex,1:nu,:unLabel,map(x->hom_map(f,x),subpart(c.apex,1:nu,:unLabel)))
#    comp1 = c.legs[1].components
#    comp1[]
# end

function pcompose(f::OpenStatisticalTheory{Ob},g::OpenStatisticalTheory{Ob}) where Ob
   If,Ig = colim = pushout(right(f.T),left(g.T))
   cospan = Cospan(ob(colim), left(f.T)⋅If, right(g.T)⋅Ig)

   OpenStatisticalTheory{Ob}(OpenPresentation{Ob}(cospan,dom(f.T),codom(g.T)),compose(f.p,g.p))
end

# @instance ThDoubleCategory{FinCatPresentation,FinFunctor,OpenStatisticalTheory,OpenTheoryMorphism} begin
   

#    pid(p::FinCatPresentation) = OpenStatisticalTheory(Open(p,p.generators[:Ob],p.generators[:Ob]),
#    OpenPresentationHomEdge(otimes(map(id,p.generators[:Ob]))))

#    function compose(a::OpenTheoryMorphism,b::OpenTheoryMorphism)

#    end

# end

end