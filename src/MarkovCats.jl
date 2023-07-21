module MarkovCats
using Catlab
import Catlab.Theories:dom,codom,otimes,id,compose,munit,mcopy,delete,braid,mmerge,⊗
export MarkovCats,FreeMarkovCategory,MarkovKernel,Stat,dom,codom,otimes,id,compose,munit,mcopy,delete,braid,mmerge,Ob,Hom,Space,⊗

struct Space 
   name::Symbol
   dim::Int
end

mutable struct MarkovKernel
   dom::Space
   codom::Space

   # "syntax trees"
   f::Union{Vector{MarkovKernel},Expr,Symbol} 
end

se = Union{Symbol,Expr}

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
   id(A::Space) = MarkovKernel(A,A,A.name)

   function compose(f::MarkovKernel,g::MarkovKernel)
      f.codom.dim!=g.dom.dim &&  error("domain mismatch between $f and $g")
      if isa(g.f,se)
         out = Expr(g.codom.name,g.f)
         isa(f.f,se) ? push!(out.args,Expr(f.codom.name,f.f)) : append!(out.args,f.f)
      else
         isa(f.f,se) && error("domain mismatch: $f has one syntax tree, $g has more than one")
         it = 1
         out = []
         for kernel in g.f
            domcounter = 0
            ex = []
            while domcounter<kernel.dom.dim
               if domcounter + f.f[it].codom.dim <= kernel.dom.dim
                  push!(ex,f.f[it])
                  domcounter += f.f[it].codom.dim
                  it+=1
               else
                  error("domain mismatch or something... $f \nand \n$g don't compose well")
               end
            end
            push!(out,MarkovKernel(kernel.dom,kernel.codom,Expr(kernel.codom.name,kernel.f,ex...)))
         end
         out = map(x->convert(MarkovKernel,x),out)
      end
      return MarkovKernel(f.dom,g.codom,out)
   end

   otimes(A::MarkovKernel,B::MarkovKernel) = MarkovKernel(A.dom⊗B.dom,A.codom⊗B.codom,[flatten!(A);flatten!(B)])
   otimes(A::Space,B::Space) = Space(Symbol(A.name,:⊗,B.name),A.dim+B.dim)

   munit(::Type{Space}) = Space(:munit,0)
   create(A::Space) = MarkovKernel(Space(:null,0),A,A.name)

   # this is kind of a hack
   mcopy(A::Space) = MarkovKernel(A,A⊗A,[MarkovKernel(Space(:null,0),A,A.name),MarkovKernel(Space(:null,0),A,A.name)])
   
   mmerge(A::Space) = MarkovKernel(A⊗A,A,:+)
   delete(A::Space) = MarkovKernel(A,Space(:null,0),:delete)

   # don't use this
   braid(A::Space,B::Space) = MarkovKernel(A⊗B,A⊗B,id(otimes(A,B)))
end


@syntax FreeMarkovCategory{ObExpr,HomExpr} ThMonoidalCategoryWithBidiagonals begin
  otimes(A::Ob, B::Ob) = associate_unit(new(A,B), munit)
  otimes(f::Hom, g::Hom) = associate(new(f,g))
  compose(f::Hom, g::Hom) = associate_unit(new(f,g; strict=true), id)
end

end