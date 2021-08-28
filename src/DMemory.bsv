import ProcTypes :: *;

module mkDMemory(DMemory);
    Reg#(Data) dMem[2**32];
    for (Integer j = 0; j < (2**32); j = j + 1) begin
        dMem[j] <- mkRegU;
    end

    method ActionValue#(Data) req (MemReq r);
        return dMem[0];
    endmethod
endmodule
