% $HeadURL: https://qak/svn/SymLab/models/LTE_PSS_SSS_withAddr/LTE_Main_PSS_SSS_Synchronize.m $
% $Author: korolev $
% $Date:: 2023-04-24 17:07#$
% $Rev: 60 $

% LTE PSS, SSS and CRS synchronisation. Analisys and testbenches preparing
% Based on "IQ_Reading_PSS_Filter_Generation.m" by Alexei Fedorov
%          "LTE_Main_AF_CRSInsertion_realdata.m" by Alexei Fedorov
%
% Korolev AI

clear; 
close all; 
clc;


%% Parameters declarations
% Test configuration
SNR = Inf;                           % Singnal-to-Noise Ratio for input (BEFORE DECIMATION) data. "Inf" for OFF
FREQUENCY_OFFSET = 0;              % Frequency offset (Hz). "0" for OFF

LTE_MODE = 'FDD'; UPLINK_DOWNLINK_CONFIGURATION = [];
% LTE_MODE = 'FDD'; UPLINK_DOWNLINK_CONFIGURATION = 2;
% LTE_MODE = 'TDD'; UPLINK_DOWNLINK_CONFIGURATION = 2;


CORDIC_ABS_ITERATION_QTY = 18;      % CORDIC_ABS    iteration quantity from Xilinx IP-core
CORDIC_ROT_ITERATION_QTY = 18;      % CORDIC_ROTATE iteration quantity from Xilinx IP-core
SSS_THRESHOLD_COEFS = 1/2 + 1/8;    % SSS threshold computing coefficient for maximum available SSS response
PHASE_SCALE = 2^(CORDIC_ABS_ITERATION_QTY -2) / pi;
PSS_POSITION_BOUND = 10; % AWAIT_BOUND
rng(123);

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


START_DMD_OFFSET_COEF = 6*2*pi/128; % Коэффициент ухода фазы демодулированных CRS, вызванного смещением начала БПФ

m = 0:(NRBSC -1);
COEFS_DIV3 = round( (2^CORDIC_ROT_ITERATION_QTY) / 3) / (2^CORDIC_ROT_ITERATION_QTY);


if NCP == 1 % Расчёты для Normal Cyclic prefix
    if strcmp(LTE_MODE, 'FDD')
        PSS_response_position = SLOT_LENGTH -1; % Номер последнего отсчёта в символе PSS (нумерация с 0). = 959 для Normal Cyclic Prefix.
        SSS_start_position = 695;               % Номер первого отсчёта в символе SSS (нумерация с 0)
    end
    if strcmp(LTE_MODE, 'TDD')
        PSS_response_position = SLOT_LENGTH + (10+128) + 2*(9+128) -1; % Номер последнего отсчёта в символе PSS (нумерация с 0). 1371 для Normal Cyclic Prefix.
        SSS_start_position = 832;               % Номер первого отсчёта в символе SSS (нумерация с 0)
    end
else % Расчёты для Extended Cyclic prefix
    if strcmp(LTE_MODE, 'FDD')
        PSS_response_position = SLOT_LENGTH -1; % Номер последнего отсчёта в символе PSS (нумерация с 0). = 959 для Extended Cyclic Prefix (Такой же как и Normal).
        SSS_start_position = 672;               % Номер первого отсчёта в символе SSS (нумерация с 0)
    end
    if strcmp(LTE_MODE, 'TDD')
        PSS_response_position = SLOT_LENGTH + 3*(32+128) -1; % Номер последнего отсчёта в символе PSS (нумерация с 0). 1371 для Normal Cyclic Prefix.
        SSS_start_position = 832;               % Номер первого отсчёта в символе SSS (нумерация с 0). (Такой же как и Normal)
    end
end


%% Stage 1. Data loading 
FN = 'iladata_20220603_0912.mat';        
%FN = 'iladata_20220603_0912.mat';   % FDD : CELL_ID = 419
% FN = 'usrp_samples_2630MHz_122880kS_40ms_40dB.mat';   % FDD
% FN = 'iladata_20230221_02.mat';                         % TDD, UPLINK_DOWNLINK_CONFIGURATION предположительно = 2;

load(FN);

fprintf('Selected division duplex type = %s.\n\n', LTE_MODE);

%% Stage 1. Noise and Frequency offset addition
dt = 1 / Fs;

if FREQUENCY_OFFSET ~= 0 
    % Introducing phase shift
    t = 0:dt:dt*(length(D)-1);
    phase_shift_array = exp(1j*mod(2*pi*-FREQUENCY_OFFSET*t',2*pi));
    S_freq = phase_shift_array.*D; % signal with frequency offset
else
    S_freq = D;
end

if SNR < Inf
    % Noise
    S_noise = awgn(S_freq, SNR, 'measured');
else
    S_noise = S_freq;
end

S_ds = round(S_noise);

clear t dt phase_shift_array D S_freq S_noise;


% fo = fopen('LTE_SSS_Detector_24_Data_in.txt', 'w');
% for idx = 1:length(S_ds)
%     fprintf( fo, '%d %d %d\n', real(S_ds(idx)), imag(S_ds(idx)), 0 );
% end
% fclose(fo);

% % Visualisation
% figure(100);
% plot( real(S_ds), 'b-'); hold on;
% plot( imag(S_ds), 'r-'); hold off;


%% Stage 2. PSS detecting
[Positions, PSS_IDs, Amps, Thresholds, dFreqs, pss_all_Responses] = AK_func_PSS_Search(S_ds);

% % Visualisation
% figure(1);
% for pss_i = 1:4 % 4-th is Threshold
%     plot( pss_all_Responses(pss_i, :), '.-'); hold on;
% end
% hold off;
% legend('PSS = 0', 'PSS = 1', 'PSS = 2', 'Threshold');


% Исключаем посторонние (с другим PSS_ID) отклики
[~, max_idx] = max(Amps);
Best_PSS_ID = PSS_IDs(max_idx);
sel_PSS_idxs = (PSS_IDs == Best_PSS_ID);    
Positions   = Positions(sel_PSS_idxs);
PSS_IDs     = PSS_IDs(sel_PSS_idxs);
Amps        = Amps(sel_PSS_idxs);
Thresholds  = Thresholds(sel_PSS_idxs);
dFreqs      = dFreqs(sel_PSS_idxs);

[~, max_idx] = max(Amps); % Обновляем максимальный индекс


if isempty( max_idx )
    fprintf('None of the responses were found.\n');
    return;
else
    fprintf('Best response was finded with PSS_ID = %d.\n', Best_PSS_ID );
    fprintf('Best cell PSS responces:\n');
    RIGHT_PSS_BOUND = 9600 - PSS_POSITION_BOUND;
    LEFT_PSS_BOUND  = 9600 + PSS_POSITION_BOUND;
    
    % Максимальный отклик однозначно оставляем
    new_Cell = struct;
    new_Cell.PSS_ID         = PSS_IDs(max_idx);
    new_Cell.PSS_Position   = Positions(max_idx);
    new_Cell.PSS_Amp        = Amps(max_idx);
    new_Cell.PSS_TH         = Thresholds(max_idx);
    new_Cell.PSS_dFreq      = dFreqs(max_idx);
    
    PSS_Cells = new_Cell;

    
    % Оставляем только отклики со смещением кратным 9600 отсчётов
    % относительно максимального
    point_idx = max_idx;
    Pp = Positions(point_idx);

    % Ретроспективная обработка
    for idx = (max_idx -1) : -1 : 1
        Offset = Pp - Positions(idx);
        
        if (Offset >= RIGHT_PSS_BOUND) && (Offset <= LEFT_PSS_BOUND)
            % Фиксируем подходящий отклик
            new_Cell = struct;
            new_Cell.PSS_ID         = PSS_IDs(idx);
            new_Cell.PSS_Position   = Positions(idx);
            new_Cell.PSS_Amp        = Amps(idx);
            new_Cell.PSS_TH         = Thresholds(idx);
            new_Cell.PSS_dFreq      = dFreqs(idx);
            PSS_Cells = [new_Cell PSS_Cells]; % Добавляем "левее"
            Pp = Positions(idx);
        else
            while (Offset > LEFT_PSS_BOUND)
                % Подставляем пропущенный отклик
                Pp = Pp - 9600;
                Offset = Pp - Positions(idx);
            end
        end
    end
    
    point_idx = max_idx;
    Pp = Positions(point_idx);
    % Перспективная обработка
    for idx = (max_idx +1) : 1 : length(Positions)
        Offset = Positions(idx) - Pp;
        
        if (Offset >= RIGHT_PSS_BOUND) && (Offset <= LEFT_PSS_BOUND)
            % Фиксируем подходящий отклик
            new_Cell = struct;
            new_Cell.PSS_ID         = PSS_IDs(idx);
            new_Cell.PSS_Position   = Positions(idx);
            new_Cell.PSS_Amp        = Amps(idx);
            new_Cell.PSS_TH         = Thresholds(idx);
            new_Cell.PSS_dFreq      = dFreqs(idx);
            PSS_Cells = [PSS_Cells new_Cell]; % Добавляем "правее"
            Pp = Positions(idx);
        else
            while (Offset > LEFT_PSS_BOUND)
                % Подставляем пропущенный отклик
                Pp = Pp + 9600;
                Offset = Positions(idx) - Pp;
            end
        end
    end    
end

% Расстановка адресов (0..9599) в полукадре
Subframe_Addresses = zeros( size(S_ds) );

% Ретроспективная расстановка
AL = 1;
AR = PSS_Cells(1).PSS_Position;
Subframe_Addresses( AR:-1:AL ) = mod( (AR:-1:1) - AR + PSS_response_position, 9600);

for idx = 1 : (length(PSS_Cells) -1)
    AL = PSS_Cells(idx   ).PSS_Position;
    AR = PSS_Cells(idx +1).PSS_Position;
    Subframe_Addresses( (AL+1):AR) = mod( (1:(AR-AL)) + PSS_response_position, 9600);
end

% Расстановка остатка (после последнего отклика)
AL = PSS_Cells(end).PSS_Position;
AR = length(Subframe_Addresses);
Subframe_Addresses( (AL+1):AR) = mod( (1:(AR-AL)) + PSS_response_position, 9600);

for idx = 1:length(PSS_Cells)
    fprintf('    PSS_ID = %d:  at %7d position  with  Amp = %6d (Threshold = %6d);    dFreq =  %9.2f Hz\n', ...
             PSS_Cells(idx).PSS_ID, PSS_Cells(idx).PSS_Position, PSS_Cells(idx).PSS_Amp, PSS_Cells(idx).PSS_TH, PSS_Cells(idx).PSS_dFreq );
end
fprintf('\n');

clear Positions PSS_IDs Amps Thresholds dFreqs pss_all_Responses AL AR new_Cell Pp Offset point_idx max_idx sel_PSS_idxs idx;


%% SSS sequence pregenerate
SSS_coefs = zeros(3, 2, 168, 62); % PSS number, subframe number, SSS number, index
for pss_i = 1:3
    for sss_i = 1:168
        [d0, d5] = AF_func_SSSGen(pss_i -1, sss_i -1);
        SSS_coefs(pss_i, 1, sss_i, :) = d0;
        SSS_coefs(pss_i, 2, sss_i, :) = d5;
    end
end

SSS_C0 = squeeze( SSS_coefs(Best_PSS_ID+1, 1, :, :) );
SSS_C5 = squeeze( SSS_coefs(Best_PSS_ID+1, 2, :, :) );
SSS_Coefs = [SSS_C0; SSS_C5];


clear pss_i sss_i d0 d5;



%% Вычисления SSS
SSS_Starts = find( Subframe_Addresses == SSS_start_position);
fprintf('\nBest cell SSS responces:\n');

SSS_Cells = [];

Starts_markers = zeros(size(S_ds));
for idx = 1:length(SSS_Starts)


    Start_Point  = SSS_Starts(idx);
    Finish_Point = Start_Point + 128 -1;
        
    Starts_markers(Start_Point) = 1;

    if Finish_Point <= length(S_ds)
        Data_to_SSS_processing = S_ds(Start_Point : Finish_Point);
        Data_to_SSS_processing_i32 = int32(Data_to_SSS_processing);
        [SSS_ID, SSS_Resp, TH] = AK_func_SSS_Search(Data_to_SSS_processing, SSS_Coefs, CORDIC_ABS_ITERATION_QTY, 0 );
        SSS_TH = round(TH*SSS_THRESHOLD_COEFS);

        if SSS_ID < 168 
            Subframe = 0;
        else
            Subframe = 5;
            SSS_ID = SSS_ID - 168;
        end

        Cell_ID = SSS_ID*3 + Best_PSS_ID;
        fprintf('   Cell_ID = %3d    SSS_ID  = %3d (subframe "%d")  with  Amp = %6d (Threshold = %6d)   start at %7d position \n', Cell_ID, SSS_ID, Subframe, SSS_Resp, SSS_TH, Start_Point);

        if SSS_Resp >= SSS_TH
            new_Cell = struct;
            new_Cell.SSS_ID = SSS_ID;
            new_Cell.SSS_SubFrame = Subframe;
            new_Cell.SSS_Amp = SSS_Resp;
            new_Cell.SSS_TH = SSS_TH;
            new_Cell.SSS_Position = Start_Point;
            new_Cell.CELL_ID = Cell_ID;
            SSS_Cells = [SSS_Cells new_Cell]; %Добавляем "правее"        
        end
    else
        fprintf('    Not enough data for SSS forward detection!\n');
    end
end

clear Starts_markers PSS_ID SSS_C0 SSS_C5 SSS_Coefs Start_Point Finish_Point Data_to_SSS_processing SSS_ID SSS_Resp TH SSS_TH Cell_ID;
clear idx new_Cell SSS_Starts;

if isempty( SSS_Cells )
    fprintf('None of the SSS were found.\n');
    return;
end

SSS_Amps = zeros(size(SSS_Cells));
for idx = 1:length(SSS_Amps)
    SSS_Amps(idx) = SSS_Cells(idx).SSS_Amp;
end

[~, max_idx] = max(SSS_Amps);
Best_SSS_ID = SSS_Cells(max_idx).SSS_ID;
Best_CELL_ID = SSS_Cells(max_idx).CELL_ID;

fprintf('Best SSS response was finded with SSS_ID = %d; CELL_ID = %3d.\n', Best_SSS_ID, Best_CELL_ID );

fprintf('\n');


% Добавление номера полукадра
HF = zeros(size(Subframe_Addresses));
L = length(Subframe_Addresses);

% Проход назад до начала полукадра (позицию SSS пока не изменяем)
HF_bit = ( SSS_Cells(1).SSS_SubFrame ~= 0);
HF_point = SSS_Cells(1).SSS_Position -1;

HF_start = HF_point - (SSS_start_position-1);
HF_start = max(1, HF_start);

HF( HF_start : HF_point) = HF_bit;

% Проход назад до самого начала
while (HF_start -1) > 0
    HF_bit = ~HF_bit;
    HF_point = HF_start -    1;
    HF_start = HF_point - 9599;
    HF_start = max(1, HF_start);
    HF( HF_start : HF_point) = HF_bit;
end

% Проход вперёд
for idx = 1:length(SSS_Cells)
    HF_bit = ( SSS_Cells(idx).SSS_SubFrame ~= 0);
    % Проход до конца полукадра
    HF_start = SSS_Cells(idx).SSS_Position;
    HF_point = HF_start + (9599 - SSS_start_position);
    HF_point = min(HF_point, L);
    HF( HF_start : HF_point) = HF_bit;
    
    % Всегда проходим до конца, эмулируя возможное отключение синхронизации
    while (HF_point +1) < L
        HF_bit = ~HF_bit;
        HF_start = HF_point +   1;
        HF_point = HF_point +9599;
        HF_point = min(HF_point, L);
        HF( HF_start : HF_point) = HF_bit;
    end
end
    
fprintf('\n');

clear SSS_Amps max_idx HF_bit HF_point HF_start idx L;

%% 
Frame_Addresses = 9600*HF + Subframe_Addresses;
PSS_ID  = Best_PSS_ID;
SSS_ID  = Best_SSS_ID;
CELL_ID = Best_CELL_ID;

FN = [FN(1:end-4) '_withAddr_' LTE_MODE '.mat'];
save(FN, 'S_ds', 'Frame_Addresses', 'Fs', 'LTE_MODE', 'PSS_ID', 'SSS_ID', 'CELL_ID', 'UPLINK_DOWNLINK_CONFIGURATION', 'SNR', 'FREQUENCY_OFFSET');



%% Визуализация распределения амплитуд по кадру
figure(11);
plot(Frame_Addresses, abs(S_ds), '.'); hold on;
AmpLine = max(abs(S_ds));

PSS_rect = zeros(1, 19200);
PSS_rect(PSS_response_position       -127 +1 : PSS_response_position       +1) = AmpLine;
PSS_rect(PSS_response_position +9600 -127 +1 : PSS_response_position +9600 +1) = AmpLine;


SSS_rect = zeros(1, 19200);
SSS_rect(SSS_start_position       +1 : SSS_start_position       + 128) = AmpLine;
SSS_rect(SSS_start_position +9600 +1 : SSS_start_position +9600 + 128) = AmpLine;

plot(PSS_rect, 'r.-'); 
plot(SSS_rect, 'm.-'); hold off;

%% Запуск следующих этапов обработки
LTE_CRS_selecting

LTE_CRS_processing_example