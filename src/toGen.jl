using .MarkovCats

# compositionality means our syntax trees can be kinda hard to make into code
# before we get rid of our dimensionality data we would like to fix this

function balance(m::MarkovKernel) 
   # I am going to think about how to write this
end

# so the idea is that the markov kernel struct is necessary to ensure that composition is well defined
# but once we put stuff together we need to get rid of them in order to have nice syntax trees

# convert a kernel to an expression
function ker2expr(m::MarkovKernel) 
   if isa(m.f,Symbol) return m.f
   elseif isa(m.f,Expr) return clean(m.f)
   else return Expr(:par,map(ker2expr,m.f)...)
   end
end

# clean an expression of all kernels
function clean(e::Expr) 
   return Expr(e.head,map(e.args) do x
      if isa(x,Symbol) x
      elseif isa(x,Expr) clean(x)
      else ker2expr(x)
      end
      end...)
end

# generate Gen.jl code based on a syntax tree
# this code will assume that variables in the domain of the tree are instantiated

# somewhere we need to look up whether stuff is deterministic or not

# function to_lines(e::Expr)
#    if e.head==:par
#       return map(to_lines,e.args) # ?
#    else

#    end
# end
