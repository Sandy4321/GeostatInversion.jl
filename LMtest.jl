using Calculus
using Optim
using JLD

# Test 2D example using Lev-Marq

# Last updated July 29, 2015 by Ellen Le
# Questions: ellenble@gmail.com
#
# References: 
# Jonghyun Lee and Peter K. Kitanidis, 
# Large-Scale Hydraulic Tomography and Joint Inversion of Head and
# Tracer Data using the Principal Component Geostatistical Approach
# (PCGA), 
# Water Resources Research, 50(7): 5410-5427, 2014
# Peter K. Kitanidis and Jonghyun Lee, 
# Principal Component Geostatistical Approach for Large-Dimensional
# Inverse Problem, 
# Water Resources Research, 50(7): 5428-5443, 2014

PLOTFLAG = 1
SAVEFLAG = 1

include("finite_difference.jl")
include("ellen.jl") #get R, Q

save("diffAlphasCovs.jld", "logk", logk)

testForward = forwardObsPoints
strue = [truelogk1[:]; truelogk2[:]] #vectorized 2D parameter field

yvec = u_obsNoise #see ellen.jl for noise level

L = chol(inv(R),:U)
S = chol(inv(Q),:U)

## check
# norm(L'*L-inv(C))
# norm(S'*S-inv(Gamma))

s0 = zeros(length(strue));
mu = 0.3*ones(length(strue));

function f_lm(s::Vector)
    result = [L*(yvec - testForward(s)); S*(s-mu)]
    return result
end


function g_lm(s::Vector)
   J =  finite_difference_jacobian(f_lm,s)
return J
end

initial_s = zeros(length(strue));

tic()
# Set trace to true to see iterates and call results.trace
results = Optim.levenberg_marquardt(f_lm, g_lm, initial_s, tolX=1e-15, tolG=1e-15, maxIter=7, lambda=200.0, show_trace=true)
timeLM = toq()


vmin = minimum(logk)
vmax = maximum(logk)

k1p,k2p = x2k(results.minimum);
logkp = ks2k(k1p,k2p);

if PLOTFLAG == 1

    fig = figure(figsize=(6*2, 6)) 

    plotfield(logk,2,1,vmin,vmax)
    title("the true logk")

    plotfield(logkp,2,2,vmin,vmax)
    title("LM 2D,
          its=$(results.iterations),covdenom=$(covdenom),alpha=$(alpha)")

    ax1 = axes([0.92,0.1,0.02,0.8])   
    colorbar(cax = ax1)


    figure()
    x = 1:(length(s0)+length(yvec))
    plot(x,abs(f_lm(strue)),x,abs(f_lm(s0)),x,abs(f_lm(results.minimum)),linestyle="-",marker="o")
    title("|f(s)|, LM 2D, its=$(results.iterations),covdenom=$(covdenom),alpha=$(alpha)")
    
    legend(["at s_true","at s0","at s_min"])

    figure()
    x2 = 1:(length(s0))
    plot(x2,abs(S*(strue-mu)),x2, abs(S*(s0-mu)), x2, abs(S*(results.minimum-mu)),linestyle="-",marker="o")
    title("|S*(s-mu)|, LM 2D, its=$(results.iterations),covdenom=$(covdenom),alpha=$(alpha)")
    legend(["at s_true","at s0","at s_min"])
    errLM = norm(results.minimum-strue)/norm(strue)
    @show(errLM,timeLM, alpha,covdenom,results.iterations)

else
    println("not plotting")
end

@show(timeLM)

if SAVEFLAG == 1
    str="logkp_its$(results.iterations)_al$(alpha)_cov$(covdenom).jld"
    @show(str)
    save(str,"logkp",logkp)
else
    println("not saving min logK")
end

# Q[1:5,1:5]


# Plots all mins after all runs are saved separately
# include("ellen.jl")

# ncol = 4
# nrow = 2

# fig = figure(figsize=(6*ncol, 6*nrow)) 

# vmin = minimum(logk)
# vmax = maximum(logk)

# plotfield(logk,ncol,1,vmin,vmax)
# title("the true logk")

# i=2
# for alpha = [4,8,80,800,8000,80000,800000]
#     str="logkp_its$(results.iterations)_al$(alpha)_cov$(covdenom).jld"
#     logkp = load(str,"logkp")

#     plotfield(logkp,ncol,i,vmin,vmax)
#     title("LM 2D,
#           its=$(results.iterations),covdenom=$(covdenom),alpha=$(alpha)")
#     i = i+1
# end

# ax1 = axes([0.92,0.1,0.02,0.8])   
# colorbar(cax = ax1)




# #Plotting different covariances
# include("ellen.jl")
# ncol = 2
# nrow = 2

# fig = figure(figsize=(6*ncol, 6*nrow)) 

# vmin = minimum(logk)
# vmax = maximum(logk)

# plotfield(logk,ncol,1,vmin,vmax)
# title("the true logk")

# alpha = 800
# i=2
# for covdenom = [0.1,0.2,0.3]
#     str="logkp_its$(results.iterations)_al$(alpha)_cov$(covdenom).jld"
#     logkp = load(str,"logkp")

#     plotfield(logkp,ncol,i,vmin,vmax)
#     title("LM 2D,
#           its=$(results.iterations),covdenom=$(covdenom),alpha=$(alpha)")
#     i = i+1
# end


# ax1 = axes([0.92,0.1,0.02,0.8])   
# colorbar(cax = ax1)






ncol = 4
nrow = 2

fig = figure(figsize=(6*ncol, 6*nrow)) 

vmin = minimum(logk)
vmax = maximum(logk)

plotfield(logk,ncol,1,vmin,vmax)
title("the true logk")

# Plotting different iterations
i=2
for its = [1,5,10,13,100,10000]                     
    str="logkp_its$(its)_al$(alpha)_cov$(covdenom).jld"
    logkp = load(str,"logkp")
    plotfield(logkp,ncol,i,vmin,vmax)
    title("LM 2D, its=$(its),covdenom=$(covdenom),alpha=$(alpha)")
    i = i+1
end
