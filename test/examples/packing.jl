# Copyright (c) 2022 MiniZinc.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

# Inspired from the square packing tutorial in https://www.minizinc.org/
function test_packing()
    n = 6
    sizes = collect(1:n)
    upper_bound = sum(sizes)
    model = MOI.instantiate(
        () -> MiniZinc.Optimizer{Int}("chuffed");
        with_cache_type = Int,
        with_bridge_type = Int,
    )
    MOI.set(model, MOI.RawOptimizerAttribute("model_filename"), "test.mzn")
    # We need this `s` variable that is trivially equal to `sizes`
    # because `MiniZincSet` supports only VectorOfVariables
    s = [MOI.add_constrained_variable(model, MOI.Integer())[1] for i in 1:n]
    x = [MOI.add_constrained_variable(model, MOI.Integer())[1] for i in 1:n]
    y = [MOI.add_constrained_variable(model, MOI.Integer())[1] for i in 1:n]
    max_x, _ = MOI.add_constrained_variable(model, MOI.Integer())
    max_y, _ = MOI.add_constrained_variable(model, MOI.Integer())
    MOI.add_constraint.(model, s, MOI.EqualTo.(sizes))
    MOI.add_constraint.(model, x, MOI.Interval(1, upper_bound))
    MOI.add_constraint.(model, y, MOI.Interval(1, upper_bound))
    MOI.add_constraint(model, max_x, MOI.Interval(1, upper_bound))
    MOI.add_constraint(model, max_y, MOI.Interval(1, upper_bound))
    MOI.add_constraint.(model, 1max_x .- 1x, MOI.GreaterThan.(sizes))
    MOI.add_constraint.(model, 1max_y .- 1y, MOI.GreaterThan.(sizes))
    MOI.add_constraint(
        model,
        MOI.VectorOfVariables([x; y; s; s]),
        MiniZinc.MiniZincSet(
            "diffn",
            [1:n, n .+ (1:n), 2n .+ (1:n), 3n .+ (1:n)],
        ),
    )
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    obj = (1max_x) * max_y
    MOI.set(model, MOI.ObjectiveFunction{typeof(obj)}(), obj)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) === MOI.OPTIMAL
    @test MOI.get(model, MOI.PrimalStatus()) === MOI.FEASIBLE_POINT
    @test MOI.get(model, MOI.ResultCount()) == 1
    @test MOI.get(model, MOI.ObjectiveValue()) == 120
    rm("test.mzn")
    return
end
