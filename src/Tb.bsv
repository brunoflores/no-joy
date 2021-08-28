import Proc1Cyc :: *;

(* synthesize *)
module mkTb(Empty);

    rule start;
        $display("Start");
        $finish(0);
    endrule

endmodule
