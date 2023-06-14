function [max_SSS_ID, max_SSS_Amp, Threshold] = AK_func_SSS_Search(Data, SSS_coefs, CORDIC_ABS_ITERATION_QTY, TB_write_enable)
% Computing maximal SSS response for Data
% Data - 128 complex samples (The excess tail will be ignored)
% SSS_Coefs - signed coefs [-1; 1]. Must be (168 or 336, 62) size array (idx, SSS_ID)
%
% max_SSS_ID       - SSD_ID [0..167] of maximal response
% max_SSS_Amp      - Amplitude of maximal (for all SSS_ID and both SubFrame types) response

    nFFT = 128;
    NDLRB = 6; % we assign 6 Resource Blocks
    totalActiveSC = NDLRB*12;
    firstActiveSC = nFFT/2 - totalActiveSC/2 + 1;

    fftOutput = fft(Data);
    
    processed_FFT = fftshift( fftOutput );
    % Extract the active subcarriers for each antenna from the
    % FFT output, removing the DC subcarrier (which is unused).
    activeSCs = processed_FFT(firstActiveSC : firstActiveSC+totalActiveSC);
    activeSCs(totalActiveSC/2+1,:) = []; % remove DC response
    
    SSS_Grid = activeSCs(6:6+62-1);
    
%     SSS_Grid = round(SSS_Grid / nFFT);
%     SSS_Grid = round(SSS_Grid / 2);
    
    
    SSS_Responses = zeros(size(SSS_coefs, 1), 1);
    for sss_i = 1:size(SSS_coefs, 1)
        SSS_i_vect = SSS_Grid.*conj(SSS_coefs(sss_i, :)).';
        SSS_Responses(sss_i) = sum(SSS_i_vect);
    end
    SSS_Responses = floor( SSS_Responses./64 );
    
    SSS_Amps = round( CORDIC_abs2( SSS_Responses, CORDIC_ABS_ITERATION_QTY) );
    [max_SSS_Amp, max_idx] = max( SSS_Amps );
    max_SSS_ID = max_idx -1;
    
    Threshold = CORDIC_abs2( floor( sum( complex(abs(real(SSS_Grid)), abs(imag(SSS_Grid))))/64), CORDIC_ABS_ITERATION_QTY );
   
    if nargin >3 
        if TB_write_enable == 1
            fftOutput_rounded = round( fftOutput );
            fo = fopen('LTE_SSS_Detector_FFT_Data_out.txt', 'a');
            for idx = 1:length(fftOutput_rounded)
                B = de2bi(idx-1, 7);
                bro_idx = bi2de(B(end:-1:1)) ;
                fprintf( fo, '%d %d %d\n', real(fftOutput_rounded(bro_idx +1)), imag(fftOutput_rounded(bro_idx +1)), bro_idx);
            end
            fclose(fo);
            
            Idxs = [0:167 0:167 168];
            SF_Markers = [zeros(1, 168) ones(1, 168) 2];
            fo = fopen('LTE_SSS_Detector_All_Amps_out.txt', 'a');
            for idx = 1:length(SSS_Amps)
                fprintf( fo, '%d %d %d\n', SSS_Amps(idx), Idxs(idx), SF_Markers(idx) );
            end
            fprintf( fo, '%d %d %d\n', Threshold, Idxs(337), SF_Markers(337) );
            fclose(fo);
            
        end
    end
end