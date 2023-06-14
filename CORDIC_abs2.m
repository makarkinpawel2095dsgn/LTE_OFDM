function [Amp, Phase] = CORDIC_abs2(DI, iterations)
% Integer angle and amplitude computing by CORDIC algorithm 

    
    ABQ = 4;    % ���������� �������������� ��� (������� �����)
    
    CIQ = 18;   % ���������� �������� �������� ���������
    %CIQ = 16;   % ���������� �������� �������� ���������
    
    % ����������� ��������� CORDIC
    C = round( (2.^CIQ) / prod( (1 + 2.^(2*(1-(1:iterations)))).^0.5 ) );

    % ���������� ����������� �� ���� ���������� ���
    X = real(DI) .* (2.^ABQ);
    Y = imag(DI)  * (2.^ABQ);
    
    % 0-� ��������
    % ������� �� 2 � 3 ��������� � 4 � 1 ��������������
    Phase = 0 + pi .* (X < 0);
    CA = find(X < 0);
    X(CA) = -X(CA);
    Y(CA) = -Y(CA);

    % �������� ���� CORDIC
    for k = 1:iterations
        At = 2.^(1-k);
        s = 1-2.*(Y>=0);
        X_addon = -s .* floor( Y.* At);
        Y_addon =  s .* floor( X.* At);
        
        X_new = X + X_addon;
        Y_new = Y + Y_addon;
        
        Phase = Phase - s.*atan(At);
        
        X = X_new;
        Y = Y_new;
    end

    BC = de2bi(C, CIQ, 'left-msb');
    
    Y = X;
    X = 0;
    
    for k = 1:CIQ
        At = 2.^(1-k);
        X_addon = + floor( Y .* At .* BC(k) );
        X = X + X_addon;
    end
    Amp = round_simple( X/(2.^(ABQ+1)) );

end

% $HeadURL: https://qak/svn/SymLab/models/LTE_PSS_SSS_withAddr/CORDIC_abs2.m $
% $Author: korolev $
% $Date:: 2023-03-13 14:45#$
% $Rev: 53 $