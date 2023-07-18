module MarkovCats
using Catlab
import Catlab.Theories:dom,codom,otimes,id,compose,munit,mcopy,delete,braid,mmerge
export MarkovCats,FreeMarkovCategory,MarkovKernel,Stat,dom,codom,otimes,id,compose,munit,mcopy,delete,braid,mmerge,Ob,Hom

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
@instance ThMonoidalCategoryWithBidiagonals{Int,MarkovKernel} begin
   dom(f::MarkovKernel) = f.dom
   codom(f::MarkovKernel) = f.codom
   id(A::Int) = MarkovKernel(A,A,Expr(:call,:Dirac))
   
   # question : do we want to support missing parameter values? turing does this...
   function compose(f::MarkovKernel,g::MarkovKernel)
      f.codom!=g.dom &&  error("domain mismatch between $f and $g")
      if isa(g.f,Expr)
         out = Expr(:call,g.f,isa(f.f,Expr) ? f.f : a for a in f.f )
      else
         isa(f.f,Expr) && error("domain mismatch: $f has one syntax tree, $g has more than one")
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
                  error("domain mismatch or something... $f and $g don't compose well")
               end
            end
            push!(out,MarkovKernel(kernel.dom,kernel.codom,Expr(:call,kernel.f,ex...)))
         end
         out = map(x->convert(MarkovKernel,x),out)
      end
      return MarkovKernel(f.dom,g.codom,out)
   end

   otimes(A::MarkovKernel,B::MarkovKernel) = MarkovKernel(A.dom+B.dom,A.codom+B.codom,[flatten!(A);flatten!(B)])
   otimes(A::Int,B::Int) = A+B

   # stuff below here is sketch / dubious
   munit(::Type{Int}) = 0
   create(A::Int) = MarkovKernel(0,A,Expr(:call,()->A))
   mcopy(A::Int) = MarkovKernel(A,2*A,[id(A),id(A)])
   mmerge(A::Int) = MarkovKernel(2*A,A,Expr(:call,:+,A,A))
   delete(A::Int) = MarkovKernel(A,0,Expr(:call,x->0))

   # don't use this; it doesn't do anything... humans were not meant to braid syntax trees
   braid(A::Int,B::Int) = MarkovKernel(A+B,A+B,id(otimes(A,B)))
end


@syntax FreeMarkovCategory{ObExpr,HomExpr} ThMonoidalCategoryWithBidiagonals begin
  otimes(A::Ob, B::Ob) = associate_unit(new(A,B), munit)
  otimes(f::Hom, g::Hom) = associate(new(f,g))
  compose(f::Hom, g::Hom) = associate_unit(new(f,g; strict=true), id)
end

end