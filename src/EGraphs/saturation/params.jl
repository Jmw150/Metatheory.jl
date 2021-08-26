using Parameters

"""
Configurable Parameters for the equality saturation process.
"""
@with_kw mutable struct SaturationParams
    timeout::Int = 8
    # default sizeout. TODO make this bytes
    # sizeout::Int = 2^14
    matchlimit::Int = 5000
    eclasslimit::Int = 5000
    enodelimit::Int = 15000
    goal::Union{Nothing, SaturationGoal} = nothing
    stopwhen::Function = ()->false
    scheduler::Type{<:AbstractScheduler} = BackoffScheduler
    schedulerparams::Tuple=()
    threaded::Bool = false
    timer::Bool = true
end
