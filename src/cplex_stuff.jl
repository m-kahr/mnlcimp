#****************************************************************
#**** CPLEX RELATED STUFF
#****************************************************************

#GETTERS
#NOTE: for enumerations, i.e. "what" in the function below see:
#https://www.ibm.com/docs/en/icos/22.1.1?topic=manual-cpxcallbackinfo
#integer infos
function cpx_callbackgetinfoint( cb_data::CPLEX.CallbackContext, what )
    data_p = Ref{Cint}()
    ret = CPXcallbackgetinfoint(cb_data, what, data_p)

    if ret != 0
        @warn "error retrieving $what"
    end
    return data_p[]::Int32
end

#float infos
function cpx_callbackgetinfodbl( cb_data::CPLEX.CallbackContext, what )
    data_p = Ref{Cdouble}()
    ret = CPXcallbackgetinfodbl(cb_data, what, data_p)

    if ret != 0
        @warn "error retrieving $what"
    end
    return data_p[]::Float64
end

#compute mip gap in %
function cpx_callbackget_mip_gap( cb_data::CPLEX.CallbackContext )
    best_bnd::Float64   = cpx_callbackgetinfodbl( cb_data, CPLEX.CPXCALLBACKINFO_BEST_BND )
    best_sol::Float64   = cpx_callbackgetinfodbl( cb_data, CPLEX.CPXCALLBACKINFO_BEST_SOL )
    mip_gap::Float64    = ((best_bnd - best_sol) / (0.0000000001 + best_sol)) * 100
    return mip_gap::Float64
end


#get number of cuts
#NOTE: see link for cuttypes:
#https://www.ibm.com/docs/en/icos/22.1.1?topic=g-cpxxgetnumcuts-cpxgetnumcuts
function cpx_getnumcuts( model::Model, cuttype::Int )
    moi_model = backend( model )

    data_p = Ref{Cint}()
    ret = CPXgetnumcuts(moi_model.env, moi_model.lp, cuttype, data_p)

    if ret != 0
        @warn "error retrieving $cuttype"
    end
    return data_p[]::Int32
end


"""
 CREATE EMPTY MODEL
and set CPLEX Parameters
documentation: https://www.ibm.com/docs/en/icos/22.1.1?topic=cplex-list-parameters
"""
function createEmptyModelMOI( params::Dict, timelimit::Int )
    #create model
    model = JuMP.direct_model( CPLEX.Optimizer() )

    #set params
    if params["solveRoot"]  #deactivate all heuristics etc. to obtain the true LP bound (Not implemented here)
        #general
        set_optimizer_attribute( model, "CPXPARAM_TimeLimit", timelimit )
        set_optimizer_attribute( model, "CPXPARAM_WorkMem", params["memlimit"] )
        set_optimizer_attribute( model, "CPXPARAM_Threads", 1 )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Display", 2 )
        #set_optimizer_attribute(model, "CPXPARAM_MIP_Limits_Nodes", 0 )

        #numerics
        set_optimizer_attribute( model, "CPXPARAM_MIP_Tolerances_MIPGap", 0.00001 )
        set_optimizer_attribute( model, "CPXPARAM_Emphasis_Numerical", 1 )

        #used LP methods (0:auto (default), 1:primal simplex, 2:dual simplex, 4:barrier)
        set_optimizer_attribute( model, "CPXPARAM_LPMethod", params["LPMethod"] )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Strategy_SubAlgorithm", params["LPMethod"] )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Strategy_StartAlgorithm", params["LPMethod"] )

        #deactivate general purpose cuts
        set_optimizer_attribute( model, "CPXPARAM_MIP_Limits_EachCutLimit", 0 )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Cuts_Gomory", -1 )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Cuts_LiftProj", -1 )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Strategy_CallbackReducedLP", 0 )

        #deactivate preprocessing
        set_optimizer_attribute( model, "CPXPARAM_Preprocessing_Presolve", 0 )
        set_optimizer_attribute( model, "CPXPARAM_Preprocessing_Relax", 0 )
        set_optimizer_attribute( model, "CPXPARAM_Preprocessing_RepeatPresolve", 0 )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Strategy_PresolveNode", -1 )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Strategy_Probe", -1 )

        #deactivate  heuristics
        set_optimizer_attribute( model, "CPXPARAM_MIP_Strategy_HeuristicFreq", -1 )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Strategy_RINSHeur", -1 )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Strategy_FPHeur", -1 )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Strategy_LBHeur", 0 )
    else
        #general
        set_optimizer_attribute( model, "CPXPARAM_TimeLimit", timelimit )
        set_optimizer_attribute( model, "CPXPARAM_WorkMem", params["memlimit"] )
        set_optimizer_attribute( model, "CPXPARAM_Threads", 1 )
        set_optimizer_attribute( model, "CPXPARAM_MIP_Display", 2 )
        #set_optimizer_attribute(model, "CPXPARAM_MIP_Limits_Nodes", 0 )

        #numerics
        set_optimizer_attribute( model, "CPXPARAM_MIP_Tolerances_MIPGap", 0.00001 )
        #set_optimizer_attribute( model, "CPXPARAM_Emphasis_Numerical", 1 )

        #used LP methods (0:auto (default), 1:primal simplex, 2:dual simplex, 4:barrier)
        #set_optimizer_attribute( model, "CPXPARAM_LPMethod", params["LPMethod"] )
        #set_optimizer_attribute( model, "CPXPARAM_MIP_Strategy_SubAlgorithm", params["LPMethod"] )
        #set_optimizer_attribute( model, "CPXPARAM_MIP_Strategy_StartAlgorithm", params["LPMethod"] )
    end

    return model::Model
end


#****************************************************************
#**** CALLBACK FOR CHECKING MEMORY CONSUMPTION DURING SOLVING 
#****************************************************************
# PROCSTATUS - check if the used memory is with in the set limit, utherwise abort solving (packed in heuristic callback)
function startProcStatus( cb_data::CPLEX.CallbackContext, inst::instance, memorylimit::Int, res::results )
    mb = get_mem_use()
    if( mb > res.memMaxUse )
        res.memMaxUse = mb
        #println("MaxMem = ", mb)
    end
    if( !memOK(mb, memorylimit) )
        res.exitflag = 3
        ret = CPXcallbackabort( cb_data )
    end
    return 
end
