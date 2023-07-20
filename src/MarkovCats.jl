module MarkovCats
using Catlab
import Catlab.Theories:dom,codom,otimes,id,compose,munit,mcopy,delete,braid,mmerge
export MarkovCats,FreeMarkovCategory,MarkovKernel,Stat,dom,codom,otimes,id,compose,munit,mcopy,delete,braid,mmerge,Ob,Hom,Space

struct Space 
   dim::Int
end

mutable struct MarkovKernel
   dom::Int
   codom::Int

   # syntax trees of param'd distributions
   # vector means they're in parallel
   f::Union{Vector{MarkovKernel},Expr,Symbol} 
end

se = Union{Symbol,Expr}

# this doesn't do what it is supposed to do.
# what's wrong?
function flatten!(k::MarkovKernel) 
   if !isa(k.f,se)
      return reduce(vcat,map(flatten!,k.f))
   end
   return k
end

"""The category of statistical semantics. In this case our semantics are 
'make a syntax tree out of distributions for us to parse into a Turing model'.
So objects are finite dimensional vector spaces represented as ints and morphisms
are 'Markov Kernels'
"""
@instance ThMonoidalCategoryWithBidiagonals{Space,MarkovKernel} begin
   dom(f::MarkovKernel) = f.dom
   codom(f::MarkovKernel) = f.codom
   id(A::Space) = MarkovKernel(A.dim,A.dim,:Dirac)

   function compose(f::MarkovKernel,g::MarkovKernel)
      print("composing $f \n and \n $g")
      f.codom!=g.dom &&  error("domain mismatch between $f and $g")
      if isa(g.f,se)
         out = Expr(:call,g.f)
         isa(f.f,se) ? push!(out.args,f.f) : append!(out.args,f.f)
      else
         isa(f.f,se) && error("domain mismatch: $f has one syntax tree, $g has more than one")
         
         it = 1
         out = []
         for kernel in g.f
            domcounter = 0
            ex = []
            while domcounter<kernel.dom
               if domcounter + f.f[it].codom <= kernel.dom
                  push!(ex,f.f[it])
                  domcounter += f.f[it].codom
                  it+=1
               else
                  error("domain mismatch or something... $f \nand \n$g don't compose well")
               end
            end
            push!(out,MarkovKernel(kernel.dom,kernel.codom,Expr(:call,kernel.f,ex...)))
         end
         out = map(x->convert(MarkovKernel,x),out)
      end
      return MarkovKernel(f.dom,g.codom,out)
   end

   otimes(A::MarkovKernel,B::MarkovKernel) = MarkovKernel(A.dom+B.dom,A.codom+B.codom,[flatten!(A);flatten!(B)])
   otimes(A::Space,B::Space) = Space(A.dim+B.dim)

   munit(::Type{Space}) = Space(0)
   create(A::Space) = MarkovKernel(0,A.dim,:create)

   # this is messing with my head ... in general dimensions are conserved so copying actually
   # completely messes up the way composition is calculated .....
   # this sort of hack works when copying is the first thing we do
   # but im pretty sure it doesn't jive with precomposition
   mcopy(A::Space) = MarkovKernel(A.dim,2*A.dim,[MarkovKernel(0,A.dim,:Dirac),MarkovKernel(0,A.dim,:Dirac)])
   mmerge(A::Space) = MarkovKernel(2*A.dim,A.dim,:+)
   delete(A::Space) = MarkovKernel(A.dim,0,:delete)

   # don't use this; it doesn't do anything... humans were not meant to braid syntax trees
   braid(A::Space,B::Space) = MarkovKernel(A.dim+B.dim,A.dim+B.dim,id(otimes(A,B)))
end


@syntax FreeMarkovCategory{ObExpr,HomExpr} ThMonoidalCategoryWithBidiagonals begin
  otimes(A::Ob, B::Ob) = associate_unit(new(A,B), munit)
  otimes(f::Hom, g::Hom) = associate(new(f,g))
  compose(f::Hom, g::Hom) = associate_unit(new(f,g; strict=true), id)
end

end