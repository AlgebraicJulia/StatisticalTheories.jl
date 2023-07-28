module MarkovCats
using Catlab
using Catlab.Theories
using Catlab.CategoricalAlgebra.StructuredCospans
using ACSets
import Catlab.BasicGraphs:vertices,nv,outneighbors
export nv,vertices,outneighbors
import Base.:+
import Catlab.Theories:otimes,compose,dom,codom,id,mcopy
export MarkovCats,FreeMarkovCategory,TermGraph,Open,OpenTermGraph,OpenTermGraphOb,Space,+,opentermgraph_edge,compose,otimes,dom,codom,id,mcopy

struct Space 
   name::Symbol
   dim::Int
   Space(n::Symbol,d::Int) = new(n,d)
end

+(A::Space,B::Space) = Space(Symbol(A.name,:⊕,B.name),A.dim+B.dim)


@present SchTermGraph(FreeSchema) begin
   Label::AttrType
   Space::AttrType
   Node::Ob
   (Nullary,Unary,Binary)::Ob

   nullOut::Hom(Nullary,Node)
   unOut::Hom(Unary,Node)
   binOut::Hom(Binary,Node)
   unIn::Hom(Unary,Node)
   (binIn₁,binIn₂)::Hom(Binary,Node)

   nullLabel::Attr(Nullary,Label)
   unLabel::Attr(Unary,Label)
   binLabel::Attr(Binary,Label)
   var::Attr(Node,Space)
end

@acset_type TermGraphUntyped(SchTermGraph)

nv(g::TermGraphUntyped{S,T}) where {S,T} = nparts(g,:Node)
vertices(g::TermGraphUntyped{S,T}) where {S,T} = parts(g,:Node)
function outneighbors(g::TermGraphUntyped{S,T},v::Int) where {S,T}
   return unique(reduce(append!,[
      subpart(g,incident(g,v,:binIn₂),:binOut),
      subpart(g,incident(g,v,:binIn₁),:binOut),
      subpart(g,incident(g,v,:unIn),:unOut)
   ]))
end

function inneighbors(g::TermGraphUntyped{S,T},v::Int) where {S,T}
   outIncident = incident(g,v,:binOut)
   return unique(reduce(append!,[
      subpart(g,outIncident,:binIn₁),
      subpart(g,outIncident,:binIn₂),
      subpart(g,incident(g,v,:unOut),:unIn)
   ]))
end

function get_initial(g::TermGraphUntyped{S,T}) where {S,T}
   return filter(x->isempty(inneighbors(g,x))
      && isempty(incident(g,x,:nullOut)),vertices(g))
end

function get_terminal(g::TermGraphUntyped{S,T}) where {S,T}
   return filter(x->isempty(outneighbors(g,x)),vertices(g))
end

const OpenTermGraphUntypedOb,OpenTermGraphUntyped = OpenACSetTypes(TermGraphUntyped,:Node)
const TermGraph = TermGraphUntyped{Tuple{Symbol,Type},Space}
const OpenTermGraphOb,OpenTermGraph = OpenTermGraphUntypedOb{Tuple{Symbol,Type},Space},OpenTermGraphUntyped{Tuple{Symbol,Type},Space}
Open(g::TermGraph) = OpenTermGraph(g,FinFunction(get_initial(g),nv(g)),FinFunction(get_terminal(g),nv(g)))
function opentermgraph_edge(dom::Vector{Space},codom::Space,label::Symbol,type::Type)
   arity = length(dom)
   if arity>=2
      pairs = (arity-1)*2
      var = Vector{Space}(undef,1+pairs)
      var[1] = dom[1]
      var[2:2:end-1] = dom[2:end]
      for i=3:2:(pairs-1)
         var[i] = var[i-1]+var[i-2]
      end
      var[end] = codom
      g = @acset TermGraph begin
         Node = 1+pairs
         Binary = arity-1
         binIn₁ = [1:2:pairs...]
         binIn₂ = [2:2:pairs...]
         binOut = [3:2:(1+pairs)...]
         binLabel = [fill((:Pair,Function),arity-2);(label,type)]
         var = var
      end
   elseif arity==1
      g = @acset TermGraph begin
         Node = 2
         Unary = 1
         unIn = [1]
         unOut = [2]
         unLabel = [(label,type)]
         var = [dom[1],codom]
      end
   else
      g = @acset TermGraph begin
         Node = 1
         Nullary = 1
         nullOut = [1]
         nullLabel = [(label,type)]
         var = [codom]
      end
   end
   return Open(g)
end

@syntax FreeMarkovCategory{ObExpr,HomExpr} ThMonoidalCategoryWithBidiagonals begin
  otimes(A::Ob, B::Ob) = associate_unit(new(A,B), munit)
  otimes(f::Hom, g::Hom) = associate(new(f,g))
  compose(f::Hom, g::Hom) = associate_unit(new(f,g; strict=true), id)
end

end