# a plate has:
#     a set of input ports (objects)
#     a set out output ports (objects)
#     a number corresponding to numcopies
#     
module PlateDiagrams
using Catlab
using Catlab.WiringDiagrams
using Catlab.DirectedWiringDiagrams
using Catlab.Graphics
import Catlab.Graphics: Graphviz
include("/Users/harperhults/.julia/packages/Catlab/MWkgx/experiments/Markov/src/Markov.jl")
using Catlab.Theories
import Catlab.DirectedWiringDiagrams: input_ports,output_ports,box
export input_ports,output_ports,PlateDiagram,expand,to_graphviz

struct PlateDiagram <: AbstractBox
   value::Any
   diagram::WiringDiagram

   PlateDiagram(value,WiringDiagram) = new(value,WiringDiagram)
   PlateDiagram(value, inputs::Vector,outputs::Vector) = new(value,WiringDiagram(value,inputs,outputs))
end

function expand(p::PlateDiagram,n::Integer,mergeOut::Bool)
   newdiag = compose(mcopy(dom(p.diagram),n),otimes(repeat([p.diagram],n)))
   return mergeOut ? compose(newdiag,implicit_mmerge(codom(p.diagram),n)) : newdiag
end

input_ports(f::PlateDiagram) = input_ports(f.diagram)
output_ports(f::PlateDiagram) = output_ports(f.diagram)
box(p::PlateDiagram,n) = box(p.diagram,n)
to_graphviz(p::PlateDiagram) = to_graphviz(p.diagram)
end
