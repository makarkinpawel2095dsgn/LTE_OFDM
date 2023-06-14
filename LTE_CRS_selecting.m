% $HeadURL: https://qak/svn/SymLab/models/LTE_PSS_SSS_withAddr/LTE_CRS_selecting.m $
% $Author: korolev $
% $Date:: 2023-04-24 17:07#$
% $Rev: 60 $

% LTE CRS selection 
% Korolev AI

% clear; 
% close all; 
% clc;


%% Data loading 
% FN = 'iladata_20220603_0912_withAddr_FDD.mat';
% FN = 'usrp_samples_2630MHz_122880kS_40ms_40dB_withAddr_FDD.mat'; 
% FN = 'iladata_20230221_02_withAddr_TDD.mat';
load(FN);


%%
% LTE constants
NRBminDL = 6;% Smallest downlink bandwidth configuration
NRBmaxDL = 110;% Largest downlink bandwidth configuration
NFFT = 128; % For delta_f = 15 kHz

% LTE configuration
NRBSC = 12;% Resource block size in the frequency domain, expressed as a number of subcarriers
NRBDL = 6; % Downlink bandwidth configuration (=6 for 1.4 MHz bandwidth)
NCP = 1;   % Normal cyclic prefix

NsymbDL = 6 + NCP;  % Symbols at slot quantity
SLOT_LENGTH = (10 + NFFT) + (9 + NFFT)*(NsymbDL -1);
SUBFRAME_LENGTH = SLOT_LENGTH*2;
CRS_PRS_ADDON = (NRBmaxDL - NRBDL) *2;

% Матрицы позиций CRS-символов для NRBSC = 12
% CRS_Positions_Table_0 используется для: 
%   Антенна 0, символ 0
%   Антенна 1, символ 4
%   Антенна 2,   чётный слот (, символ 1)
%   Антенна 3, нечётный слот (, символ 1)
CRS_Positions_Table_0 = [0,6,12,18,24,30,36,42,48,54,60,66; 1, 7,13,19,25,31,37,43,49,55,61,67; 2, 8,14,20,26,32,38,44,50,56,62,68; 3,9,15,21,27,33,39,45,51,57,63,69; 4,10,16,22,28,34,40,46,52,58,64,70; 5,11,17,23,29,35,41,47,53,59,65,71];

% CRS_Positions_Table_1 используется для: 
%   Антенна 0, символ 4
%   Антенна 1, символ 0
%   Антенна 2, нечётный слот (, символ 1)
%   Антенна 3,   чётный слот (, символ 1)
CRS_Positions_Table_1 = [3,9,15,21,27,33,39,45,51,57,63,69; 4,10,16,22,28,34,40,46,52,58,64,70; 5,11,17,23,29,35,41,47,53,59,65,71; 0,6,12,18,24,30,36,42,48,54,60,66; 1, 7,13,19,25,31,37,43,49,55,61,67; 2, 8,14,20,26,32,38,44,50,56,62,68];

% Расчёт частот для гармоник CRS
SC_Step = 15e3; % Расстояние между соседними гармониками
SC_QTY = NRBSC*NRBDL;
SC_half_QTY = SC_QTY / 2;
SC_idxs = 0:(SC_QTY-1);

CRS_FREQS_TABLE = SC_Step .* (-SC_half_QTY + SC_idxs + (SC_idxs >= SC_half_QTY) );

clear SC_Step SC_QTY SC_half_QTY SC_idxs;


%% CRS processing
% Превычисления
m = 0:(NRBSC -1);

CRS_Cinits = zeros(20, NsymbDL);        % Матрица значений инициализации PRS-генератора
CRS_Values = zeros(20, NsymbDL, NRBSC); % Массив "идеальных" значений CRS
for slot = 0:19
    for sym = 0:(NsymbDL -1)
        CRS_Cinits(slot+1, sym+1) = (2^10)*(7*(slot +1) + sym +1)*(2*CELL_ID + 1) + 2*CELL_ID + NCP ;
        PRS_Values = AK_func_PRSGen(CRS_Cinits(slot+1, sym+1), 2*NRBSC, CRS_PRS_ADDON);
        CRS_Values(slot+1, sym+1, :) = ( (1-2*PRS_Values(2*m +1)) + 1j*(1-2*PRS_Values(2*m +1 +1)) );
    end
end
v_shift = 3*mod(SSS_ID, 2) + PSS_ID; % see to mod_test.m

clear CRS_Cinits slot;


CRS_Starts = find( mod(Frame_Addresses, SLOT_LENGTH) == 0 ); % Послотовая обработка

fc_ReGrid = zeros(NsymbDL, NRBDL*NRBSC);
% fc_Data = zeros(length(CRS_Starts)*2, NRBSC); 

CRS_rcvd = zeros(length(CRS_Starts)*2, NRBSC); 
CRS_orig = zeros(length(CRS_Starts)*2, NRBSC);
CRS_Addr = zeros(length(CRS_Starts)*2, 1);
CRS_Pos  = zeros(length(CRS_Starts)*2, 1);
CRS_AntN = zeros(length(CRS_Starts)*2, 1);
CRS_EN   = zeros(length(CRS_Starts)*2, 1);
CRS_freq = zeros(size(CRS_rcvd));


for idx = 1:length(CRS_Starts)
    CRS_Start = CRS_Starts(idx);
    CRS_End = CRS_Start + SLOT_LENGTH -1;% 1 slot processing

    if CRS_End <= length(S_ds)
        Data_to_CRS_processing = S_ds(CRS_Start:CRS_End); % this data has 1 slot length
        Slot_to_process_num = fix(Frame_Addresses(CRS_Start) / SLOT_LENGTH);

        ReGrid = AK_func_OFDMDemodulate_Slot_Normal_72( Data_to_CRS_processing );

        % Выбор CRS для 0-го символа
        sym = 0;
        out_idx = idx*2 -1;
        CRS_0 = ReGrid(sym +1, CRS_Positions_Table_0(v_shift +1, :) +1 );
        CRS_1 = ReGrid(sym +1, CRS_Positions_Table_1(v_shift +1, :) +1 );
        if sum(abs(CRS_0)) >= sum(abs(CRS_1))
            CRS_rcvd(out_idx, :) = CRS_0;
            CRS_AntN(out_idx) = 0;
            CRS_freq(out_idx, :) = CRS_FREQS_TABLE( CRS_Positions_Table_0(v_shift +1, :) +1 );
        else
            CRS_rcvd(out_idx, :) = CRS_1;
            CRS_AntN(out_idx) = 1;
            CRS_freq(out_idx, :) = CRS_FREQS_TABLE( CRS_Positions_Table_1(v_shift +1, :) +1 );
        end
        CRS_orig(out_idx, :) = squeeze( CRS_Values(Slot_to_process_num+1, sym +1, :) );
        CRS_Pos(out_idx) = CRS_Start+ (10 + round(NFFT/2));
        CRS_Addr(out_idx) = Frame_Addresses(CRS_Start) + (10 + round(NFFT/2));
        
        % Выбор CRS для 4-го символа
        sym = 4;
        out_idx = idx*2 -0;
        CRS_0 = ReGrid(sym +1, CRS_Positions_Table_1(v_shift +1, :) +1 );
        CRS_1 = ReGrid(sym +1, CRS_Positions_Table_0(v_shift +1, :) +1 );
        if sum(abs(CRS_0)) >= sum(abs(CRS_1))
            CRS_rcvd(out_idx, :) = CRS_0;
            CRS_AntN(out_idx) = 0;
            CRS_freq(out_idx, :) = CRS_FREQS_TABLE( CRS_Positions_Table_1(v_shift +1, :) +1 );
        else
            CRS_rcvd(out_idx, :) = CRS_1;
            CRS_AntN(out_idx) = 1;
            CRS_freq(out_idx, :) = CRS_FREQS_TABLE( CRS_Positions_Table_0(v_shift +1, :) +1 );
        end
        CRS_orig(out_idx, :) = CRS_Values(Slot_to_process_num+1, sym +1, :);
        CRS_Pos(out_idx) = CRS_Start + (10 + NFFT) + 3*(9 + NFFT) + (9 + round(NFFT/2));
        CRS_Addr(out_idx) = Frame_Addresses(CRS_Start) + (10 + NFFT) + 3*(9 + NFFT) + (9 + round(NFFT/2));
        
    else
        % Обработка недостаточных данных
        CRS_rcvd = CRS_rcvd(1:end-2, :);
        CRS_orig = CRS_orig(1:end-2, :);
        CRS_Addr = CRS_Addr(1:end-2);
        CRS_Pos  = CRS_Pos(1:end-2);
        CRS_AntN = CRS_AntN(1:end-2);
        CRS_EN   = CRS_EN(1:end-2);
        CRS_freq = CRS_freq(1:end-2, :);
    end
    
end

CRS_EN = AK_func_LTE_isSlotDownlink( fix(CRS_Addr / 960), UPLINK_DOWNLINK_CONFIGURATION);

FN = [FN(1:end-4) '_CRSonly.mat'];
save(FN, 'Fs', 'LTE_MODE', 'PSS_ID', 'SSS_ID', 'CELL_ID', 'CRS_rcvd', 'CRS_orig', 'CRS_Addr', 'CRS_EN', 'CRS_freq', 'SNR', 'FREQUENCY_OFFSET');
fprintf('SNR              = %d dB\n', SNR);
fprintf('FREQUENCY_OFFSET = %d Hz\n', FREQUENCY_OFFSET);
fprintf('CRS are selected and saved.\n\n');



%%

CRS_rcvd_mean = mean( abs(CRS_rcvd), 2);

figure(21);
plot(Frame_Addresses, abs(S_ds), '.'); hold on;
plot(CRS_Addr, CRS_rcvd_mean, 'o-' );
plot(CRS_Addr, CRS_EN * max(abs(S_ds)), 'o-' ); hold off;

figure(22);
plot(abs(S_ds), '.-'); hold on;
plot(CRS_Pos, CRS_rcvd_mean, 'o-' );
plot(CRS_Pos, CRS_EN * max(abs(S_ds)), 'o-' ); hold off;