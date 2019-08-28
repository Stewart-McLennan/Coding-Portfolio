%% Fung QLV Parameter Values from 5th Stress Relaxation Cycle
% Note: x=[A,B,C,tau1,tau2]
% Stewart McLennan

%% Housekeeping:
clear; close all;clc;

%% Initial Definitions
syms A B C tau1 tau2
gam=0.6;
t0=1.0;

%% Time Data Import
RampTime=xlsread('PVA 20% 10FTC Analysis',1,'A37523:A37528')...
    -xlsread('PVA 20% 10FTC Analysis',1,'A37523')...
    +0.000001;
HoldTime=xlsread('PVA 20% 10FTC Analysis',1,'A37528:A45525')...
    -xlsread('PVA 20% 10FTC Analysis',1,'A37523')...
    +0.000002;

RampTimeOptimised=linspace(RampTime(1),RampTime(end),6);

Time=[RampTimeOptimised';HoldTime(1:5:15);HoldTime(75:200:475);...
    HoldTime(1000:1000:end)];

%% Stress Data Import
RampStress=xlsread('PVA 20% 10FTC Analysis',1,'L37523:L37528')...
    -xlsread('PVA 20% 10FTC Analysis',1,'L37523')...
    +0.000001;
HoldStress=xlsread('PVA 20% 10FTC Analysis',1,'L37528:L45525')...
    -xlsread('PVA 20% 10FTC Analysis',1,'L37523')...
    +0.000002;

RampStressOptimised=linspace(RampStress(1),RampStress(end),6);

Stress=[RampStressOptimised';HoldStress(1:5:15);HoldStress(75:200:475);...
    HoldStress(1000:1000:end)];

%% Parameter Fitting
fun=@(x,Time)((x(1)*x(2)*gam/(1+x(3)*log(x(5)/x(4))))...
    *arrayfun(@(Time)integral(@(tau)((1+x(3)*(expint((Time-tau)/x(5))...
    -expint((Time-tau)/x(4))))*exp(x(2)*gam*tau)),0,Time,'ArrayValued'...
    ,true),Time)).*(Time<t0) + ((x(1)*x(2)*gam/(1+x(3)*log(x(5)/x(4))))...
    *integral(@(tau)(1+x(3)*(expint((Time-tau)/x(5))-expint((Time-tau)...
    /x(4)))*exp(x(2)*gam*tau)),0,t0,'ArrayValued',true)).*(Time>=t0);
x0=[500,0.01,0.1,0.5,500];
options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt',...
    'MaxFunctionEvaluations',1000000,'MaxIterations',1000000);
lb = [];
ub = [];
x=lsqcurvefit(fun,x0,Time,Stress,lb,ub,options)

%% Plot
plot(Time,Stress,'k-o',Time,fun(x,Time),'b-')
legend('Biaxial Test','Fung QLV')
title('Biaxial Test and Fung QLV - 20%PVA 10FTC')