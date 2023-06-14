function isSlotDownlink = AK_func_LTE_isSlotDownlink(SlotNum, UD_Configuration)

            %    0    1    2    3    4    5    6    7    8    9
    UD_Table = ['D', 'S', 'U', 'U', 'U', 'D', 'S', 'U', 'U', 'U';   % 0 ( 5 ms)
                'D', 'S', 'U', 'U', 'D', 'D', 'S', 'U', 'U', 'D';   % 1 ( 5 ms)
                'D', 'S', 'U', 'D', 'D', 'D', 'S', 'U', 'D', 'D';   % 2 ( 5 ms)
                'D', 'S', 'U', 'U', 'U', 'D', 'D', 'D', 'D', 'D';   % 3 (10 ms)
                'D', 'S', 'U', 'U', 'D', 'D', 'D', 'D', 'D', 'D';   % 4 (10 ms)
                'D', 'S', 'U', 'D', 'D', 'D', 'D', 'D', 'D', 'D';   % 5 (10 ms)
                'D', 'S', 'U', 'U', 'U', 'D', 'S', 'U', 'U', 'D'];  % 6 (5 ms)


    isSlotDownlink = ones(size(SlotNum));% used "1" for default FDD config
    
    if ~isempty(UD_Configuration)
        for idx = 1:length(SlotNum)
            if (SlotNum(idx) >= 0) && (SlotNum(idx) <= 19) && (UD_Configuration >= 0) && (UD_Configuration <= 6)
                Subframe_Num = floor(SlotNum(idx) /2);
    %             isSlotDownlink(idx) = ( UD_Table(UD_Configuration+1, Subframe_Num+1) == 'D' ) + 0.5*( UD_Table(UD_Configuration+1, Subframe_Num+1) == 'S' );
                isSlotDownlink(idx) = ( UD_Table(UD_Configuration+1, Subframe_Num+1) == 'D' );
            end
        end
    end

end