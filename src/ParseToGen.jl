module ParseToGen
using StatisticalTheories.MarkovCats
using Gen
using Catlab.Graphs
using ACSets.ACSetInterface
export toGen

# generate Gen.jl model code based on a syntax tree
# this code will assume that variables in the domain of the tree are instantiated

function get_args(g::TermGraph,edge::Int)
   inc = incident(g,g[edge,:binIn₁],:binOut)
   if !(:Pair in map(x->x[1],g[inc,:binLabel][:,1]))
      return [g[edge,[:binIn₁,:var]].name,g[edge,[:binIn₂,:var]].name]
   else
      return [map(x->get_args(g,x),inc)...; g[edge,[:binIn₂,:var]].name]
   end
end

function to_line(var::Int,og::OpenTermGraph)
   out = []
   g = og.cospan.apex
   for edge in incident(g,var,:nullOut)
      var = g[edge,[:nullOut,:var]].name
      line = if g[edge,:nullLabel][2]==Gen.Distribution
         "    $var = ({:$var} ~ $(g[edge,:nullLabel][1])())"
      else
         "    $var = $(g[edge,:nullLabel][1])()"
      end
      push!(out,line)
   end
   for edge in incident(g,var,:unOut)
      var = g[edge,[:unOut,:var]].name
      line = if g[edge,:unLabel][2]==Gen.Distribution
         "    $var = ({:$var} ~ $(g[edge,:unLabel][1])($(g[edge,[:unIn,:var]].name)))"
      else
         "    $var = $(g[edge,:unLabel][1])($(g[edge,[:unIn,:var]].name))"
      end
      push!(out,line)
   end
   for edge in incident(g,var,:binOut)
      g[edge,:binLabel][1]==:Pair&&continue
      var = g[edge,[:binOut,:var]].name
      args = join(map(String,get_args(g,edge)),",")
      line = if g[edge,:binLabel][2]==Gen.Distribution
         "    $var = ({:$var} ~ $(g[edge,:binLabel][1])($args))"
      else
         "    $var = $(g[edge,:binLabel][1])($args)"
      end
      push!(out,line)
   end
   return out
end

function to_lines(g::OpenTermGraph)
   nondom = filter!(x->!(x in parts(dom(g).ob,:Node)),topological_sort(g.cospan.apex))
   mainbody = reduce(append!,map(x->to_line(x,g),nondom))
end

function make_header(g::OpenTermGraph,name)
   args = join(map(x->String(x.name),dom(g).ob[:var]),",")
   return "using Gen\n@gen function $name($args)"
end

function make_footer(g::OpenTermGraph)
   outs = join(map(x->String(x.name),codom(g).ob[:var]),",")
   return "    return $outs\nend"
end

function toGen(g::OpenTermGraph,fname::String)
   out = to_lines(g)
   insert!(out,1,make_header(g,fname))
   push!(out,make_footer(g))
   open("$fname.jl","w") do f
      write(f,join(out,"\n"))
   end
end
end