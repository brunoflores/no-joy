import ProcTypes :: *;

module mkCop(ICop);
    Reg#(Bool) s <- mkReg(False);

    method Bool started;
        return s;
    endmethod

    method Action start;
        s <= True;
    endmethod

    // method Tuple2#(RIndx, Data) cpuToHost;
    // endmethod

    // method Data rd (RIndx r);
    // endmethod

    // method Action wr (Tuple2#(Maybe#(FullIndx), Data) x);
    // endmethod
endmodule
