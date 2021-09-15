using Metatheory
using Test
using Metatheory.Library
using Metatheory.EGraphs
using Metatheory.Util
using Metatheory.EGraphs.Schedulers

t = @theory begin 
    f(a...) |> (println.(a); 42)
end 

dump(t)

g = EGraph(:(f(1,2,3)))
saturate!(g, t)