module ParseToGen
using StatisticalTheories.MarkovCats
using Gen
export ker2expr,toGen

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

pi1(x) = x[1]
pi2(x) = x[2]
data(x) = x*2

# generate Gen.jl model code based on a syntax tree
# this code will assume that variables in the domain of the tree are instantiated
# somewhere we need to look up whether stuff is deterministic or not

function to_lines(e::Expr)
   if e.head==:par
      return map(to_lines,e.args) # ?
   else
      out = []
      args = []
      for ex in e.args[2:end]
         if isa(ex,Expr)
            push!(out,to_lines(ex)...)
            push!(args,ex.head)
         else push!(args,ex)
         end
      end
      args = join(map(String,args),",")
      line = isa(eval(e.args[1]),Distribution) ?  "    $(e.head) = ({:$(e.head)} ~ $(e.args[1])($(args...)))" : "    $(e.head) = $(e.args[1])($(args...))"
      
      push!(out,line)
      return out
   end
end

function make_header(m::MarkovKernel,name)
   return "using Gen\n@gen function $name($(m.dom.name))"
end

function make_footer(m::MarkovKernel)
   return "    return $(m.codom.name)\nend"
end

function toGen(m::MarkovKernel,fname::String)
   ex = ker2expr(m)
   out = to_lines(ex)
   insert!(out,1,make_header(m,fname))
   push!(out,make_footer(m))
   open("$fname.jl","w") do f
      write(f,join(out,"\n"))
   end
end
end