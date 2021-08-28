import ProcTypes :: *;
import RFile :: *;
import IMemory :: *;
import DMemory :: *;
import Cop :: *;
import Exec :: *;
import Decode :: *;

module mkProc(IProc);

    // The state
    Reg#(Addr) pc <- mkRegU;
    IRegFile rf <- mkRFile;
    IMemory iMem <- mkIMemory;
    DMemory dMem <- mkDMemory;
    ICop cop <- mkCop;

    rule doProc(cop.started);
        // fetch
        let inst = iMem.req(pc);

        // decode
        let dInst = decode(inst);

        // trace - print the instruction
        $display("pc: %h inst: (%h) expanded: ", pc, inst, showInst(inst));

        // read register values
        let rVal1 = rf.rd1(validRegValue(dInst.src1));
        let rVal2 = rf.rd2(validRegValue(dInst.src2));

        // Co-processor read for debugging
        // let copVal = cop.rd(validRegValue(dInst.src1));

        // execute
        // The fifth argument is the predicted pc, to detect if it was
        // mispredicted (future). Since there is no branch prediction yet,
        // this field is sent with an unspecified value.
        let eInst = exec(dInst, rVal1, rVal2, pc, ?, ?);

        // Executing unsupported instruction. Exiting
        if (eInst.iType == Unsupported) begin
            $fwrite(stderr, "Unsupported instruction at pc: %x. Exiting\n", pc);
            $finish;
        end

        // memory
        if (eInst.iType == Ld) begin
            eInst.data <- dMem.req(MemReq{op: Ld, addr: eInst.addr, data: ?});
        end else if (eInst.iType == St) begin
            let d <- dMem.req(MemReq{op: St, addr: eInst.addr, data: eInst.data});
        end

        // write back
        if (isValid(eInst.dst) && validValue(eInst.dst).regType == Normal) begin
            rf.wr(validRegValue(eInst.dst), eInst.data);
        end

        // update the pc depending on whether the branch is taken or not
        pc <= eInst.brTaken ? eInst.addr : pc + 4;
        // Co-processor write for debugging and stats
        // cop.wr(eInst.dst, eInst.data);
    endrule

    // method ActionValue#(Tuple2#(RIndx, Data)) cpuToHost;
    //     let ret <- cop.cpuToHost;
    //     $display("sending %d %d", tpl_1(ret), tpl_2(ret));
    //     return ret;
    // endmethod

    method Action hostToCpu(Bit#(32) startpc) if (!cop.started);
        cop.start;
        pc <= startpc;
    endmethod
endmodule
