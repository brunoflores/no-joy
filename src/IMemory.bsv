import RegFile :: *;

import ProcTypes :: *;

module mkIMemory(IMemory);
    Reg#(Data) iMem[2**32];
    for (Integer j = 0; j < (2**32); j = j + 1) begin
        iMem[j] <- mkRegU;
    end

    method Data req (Addr a);
        return iMem[0];
    endmethod
endmodule
