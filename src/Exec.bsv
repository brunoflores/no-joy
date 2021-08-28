import ProcTypes :: *;

function ExecInst exec(DecodedInst dInst, Data rVal1, Data rVal2, Addr pc,
                       Addr ppc, Data copVal);

    ExecInst eInst = ?;
    Data aluVal2 = isValid(dInst.imm) ? validValue(dInst.imm) : rVal2;

    let aluRes = alu(rVal1, aluVal2, dInst.aluFunc);

    eInst.iType = dInst.iType;

    eInst.data = dInst.iType == Mfc0 ?
                    copVal :
                 dInst.iType == Mtc0 ?
                    rVal1 :
                 dInst.iType == St ?
                    rVal2 :
                 (dInst.iType == J || dInst.iType == Jr) ?
                    (pc + 4) :
                 aluRes;

    let brTaken = aluBr(rVal1, rVal2, dInst.brFunc);
    let brAddr = brAddrCalc(pc, rVal1, dInst.iType,
                            validValue(dInst.imm), brTaken);
    eInst.mispredict = brAddr != ppc;

    eInst.brTaken = brTaken;
    eInst.addr = (dInst.iType == Ld || dInst.iType == St) ? aluRes : brAddr;

    eInst.dst = dInst.dst;

    return eInst;
endfunction

function Data alu(Data a, Data b, AluFunc func);
    Data res = case(func)
        Add : (a + b);
        Sub : (a - b);
        And : (a & b);
        Or : (a | b);
        Xor : (a ^ b);
        Nor : ~ (a | b);
        Slt : zeroExtend(pack(signedLT(a, b)));
        Sltu : zeroExtend(pack(a < b));
        LLShift: (a << b[4:0]);
        RLShift: (a >> b[4:0]);
        RAShift : signedShiftRight(a, b[4:0]);
    endcase;
    return res;
endfunction

function Bool aluBr(Data a, Data b, BrFunc brFunc);
    Bool brTaken = case(brFunc)
        Eq : (a == b);
        Neq : (a != b);
        Le : signedLE(a, 0);
        Lt : signedLT(a, 0);
        Ge : signedGE(a, 0);
        Gt : signedGT(a, 0);
        AT : True;
        NT : False;
    endcase;
    return brTaken;
endfunction

function Addr brAddrCalc(Addr pc, Data val, IType iType, Data imm, Bool taken);
    Addr pcPlus4 = pc + 4;
    Addr targetAddr = case (iType)
        J : {pcPlus4[31:28], imm[27:0]};
        Jr : val;
        Br : (taken? pcPlus4 + imm : pcPlus4);
        Alu, Ld, St, Mfc0, Mtc0, Unsupported: pcPlus4;
    endcase;
    return targetAddr;
endfunction
