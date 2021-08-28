import RegFile :: *;

import ProcTypes :: *;

module mkRFile(IRegFile);
    RegFile#(RIndx, Data) rf <- mkRegFile (1, 31);

    method Data rd1(RIndx r);
        return r == 0 ? extend(1'b0) : rf.sub(r);
    endmethod

    method Data rd2(RIndx r);
        return r == 0 ? extend(1'b0) : rf.sub(r);
    endmethod

    method Action wr (RIndx r, Data d);
        if (r != 0) begin
            rf.upd(r, d);
        end
    endmethod
endmodule

