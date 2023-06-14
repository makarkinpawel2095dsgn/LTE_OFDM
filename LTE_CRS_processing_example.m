% LTE CRS processing example
% Korolev AI

% clear; 
% close all; 
% clc;


%% Data loading 
% FN = 'iladata_20220603_0912_withAddr_FDD_CRSonly.mat';
% FN = 'usrp_samples_2630MHz_122880kS_40ms_40dB_withAddr_FDD_CRSonly.mat';
% FN = 'iladata_20230221_02_withAddr_TDD_CRSonly.mat';

load(FN);


%% Parameters declaration
CORDIC_ABS_ITERATION_QTY = 18;      % CORDIC_ABS    iteration quantity from Xilinx IP-core
CORDIC_ROT_ITERATION_QTY = 18;      % CORDIC_ROTATE iteration quantity from Xilinx IP-core


%% Data processing
CRS_recovered = CRS_rcvd .* conj(CRS_orig);
%CRS_recovered = CRS_rcvd .* CRS_orig(CRS_orig);


[CRS_Amps, CRS_Phases] = CORDIC_abs2(CRS_recovered, CORDIC_ABS_ITERATION_QTY);

figure(1);
subplot(3,1,1);
plot(CRS_Amps, '.-');
title('Amps');

subplot(3,1,2);
plot(CRS_Phases, '.-');
title('Phases');

subplot(3,1,3);
plot(CRS_EN, '.-');
title('Enable');


%% Selfcompmensation
% phase_shift_array = exp(1j*(-CRS_Phases));
phase_shift_array = cos(-CRS_Phases) + 1j*sin(-CRS_Phases);
CRS_rot = CRS_rcvd .* phase_shift_array;


[CRS_Amps_rot, CRS_Phases_rot] = CORDIC_abs2(CRS_rot, CORDIC_ABS_ITERATION_QTY);

figure(2);
subplot(3,1,1);
plot(CRS_rot, 'o');
title('Eye');

subplot(3,1,2);
plot(CRS_Phases_rot, '.-');
title('Phases rotated');