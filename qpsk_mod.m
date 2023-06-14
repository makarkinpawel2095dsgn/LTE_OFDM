function [cosx, jsinx, phasex, jphasex] = qpsk_mod(m_signal, bitRate, Nbit_sample, N_Nyic, fs, fd, time_model)
%% finction qpsk modulated
% m_signal - signal type uint, int
% Nbit_sample - couter sampel bit
% N_Nyic - filter nyicvist N_Nyic = 0 null filter
% SinX_n, CosX_n - signal freqwency NCO

t = 0:1/fd/time_model;

% form signal
for i = 1 : length(m_signal)
    % bit "11"
    if (m_signal(i) == 3)
        phasx(i) = - 1/sqrt(2);
        jphasx(i) = - 1/sqrt(2);
    % bit "10"
    elseif (m_signal(i) == 2)
        phasx(i) = 1/sqrt(2);
        jphasx(i) = - 1/sqrt(2);
    % bit "01"
    elseif (m_signal(i) == 1)
        phasx(i) = - 1/sqrt(2);
        jphasx(i) = 1/sqrt(2);
    % bit "00"
    elseif (m_signal(i) == 0)
        phasx(i) = 1/sqrt(2);
        jphasx(i) = 1/sqrt(2);
    end;
end;

M_bitsample = round((length(m_signal)/bitRate)*fd*time_model);
k = 0;
bit_index = 1;
for i = 1 : fd*time_model
    for k = 1 : M_bitsample
        %
        cosx(i)     = cos(2*pi*fs*t(i) + phasx(bit_index));
        jsinx(i)    = sin(2*pi*fs*t(i) + jphasx(bit_index));
        phasex(i)   = phasx(bit_index);
        jphasex(i)  = jphasx(bit_index);
    end;
    bit_index = bit_index + 1;
end;

