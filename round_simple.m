function R = round_simple(D)
% Simple round = round without correction.
% ������ �.�. 2015.08
% ������� ���������� ����� ��� ���������. ��������� ������������ ���
% ���������� ������������� �������� = 1 ��� > 4..6 .
% D - ������ ������. ����� ��������� �������������� ��� ����������� ��������.

    if isreal(D) 
        A = fix( mod(D, 1)*2);
        R = floor(D)+A;
    else
        % ��� ������ ������������ �������� (����������) ��������� ����������
        R = complex(round_simple( real(D) ), round_simple( imag(D) ) );
    end

end