module MarkovCats
using Catlab
import Catlab.Theories:dom,codom
export MarkovCats,FreeMarkovCategory,MarkovKernel,Stat,dom,codom

mutable struct MarkovKernel
   dom::Int
   codom::Int

   # syntax trees of param'd distributions
   # vector means they're in parallel
   f::Union{Vector{MarkovKernel},Expr} 
end

function flatten!(k::MarkovKernel) 
   if !isa(k.f,Expr)
      k.f = reduce(vcat,map(flatten,k.f))
   end
   return k
end

"""The category of statistical semantics. In this case our semantics are 
'make a syntax tree out of distributions for us to parse into a Turing model'.
So objects are finite dimensional vector spaces represented as ints and morphisms
are 'Markov Kernels'
"""
Stat = @instance ThMonoidalCategoryWithDiagonals{Int,MarkovKernel} begin
   dom(f::MarkovKernel) = f.dom
   codom(f::MarkovKernel) = f.codom
   id(A::Int) = MarkovKernel(A,A,Expr(:call,Dirac))
   
   # question : do we want to support missing parameter values? turing does this...
   function compose(f::MarkovKernel,g::MarkovKernel)
      f.codom!=g.dom &&  error("domain mismatch between $f and $g")
      out = []
      if isa(g.f,Expr)
         out = Expr(:call,g.f,isa(f.f,Expr) ? f.f : a for a in f.f )
      else
         isa(f.f,Expr) && error("domain mismatch: $f has one syntax tree, $g has more than one")
         it = 1
         for kernel in g.f
            domcounter = 0
            ex = []
            while domcounter<kernel.dom
               if domcounter + f.f[it].codom <= kernel.dom
                  ex.append(f.f[it])
                  it+=1
                  domcounter += f.f[it].codom
               else
                  error("domain mismatch or something... $f and $g don't compose well")
               end
            end
            out.append(Expr(:call,kernel.f,ex...))
         end
      end
      return MarkovKernel(f.dom,g.codom,out)
   end

   otimes(A::MarkovKernel,B::MarkovKernel) = MarkovKernel(A.dom+B.dom,A.codom+B.codom,[flatten(A);flatten(B)])
   otimes(A::Int,B::Int) = A+B

   # stuff below here is sketch / dubious
   munit(::Type{Int}) = 0
   mcopy(A::Int) = A+A
   delete(A::Int) = 0
   braid(A::Int,B::Int) = nothing
end

@syntax FreeMarkovCategory{ObExpr,HomExpr} ThMonoidalCategoryWithDiagonals begin
  otimes(A::Ob, B::Ob) = associate_unit(new(A,B), munit)
  otimes(f::Hom, g::Hom) = associate(new(f,g))
  compose(f::Hom, g::Hom) = associate_unit(new(f,g; strict=true), id)
end

end