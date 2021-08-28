import ProcTypes :: *;

function Maybe#(FullIndx) validReg (RIndx r);
    FullIndx out = ?;
    out.regType = Normal;
    out.idx = r;
    return Valid(out);
endfunction

function DecodedInst decode(Data inst);

    // Initially undefined.
    DecodedInst dInst = ?;

    let opcode = inst[ 31 : 26 ];
    let rs     = inst[ 25 : 21 ];
    let rt     = inst[ 20 : 16 ];
    let rd     = inst[ 15 : 11 ];
    let shamt  = inst[ 10 : 6  ];
    let funct  = inst[  5 : 0  ];
    let imm    = inst[ 15 : 0  ];
    let target = inst[ 25 : 0  ];

    case (opcode)
        // Load and Store Instructions
        opLW, opSW:
            begin
                dInst.aluFunc = Add;
                dInst.brFunc = NT;
                dInst.shamt = Invalid;
                // Effective address will be obtained by adding register rs
                // to the sign-extended immediate.
                dInst.imm = Valid(signExtend(imm));
                case (opcode)
                    opLW:
                        begin
                            dInst.iType = Ld;
                            // Loads place a value in register rt.
                            dInst.dst = validReg(rt);
                            dInst.src1 = validReg(rs);
                            dInst.src2 = Invalid;
                        end
                    opSW:
                        begin
                            dInst.iType = St;
                            // Stores write the value in register rt to memory.
                            dInst.dst = Invalid;
                            dInst.src1 = validReg(rs);
                            dInst.src2 = validReg(rt);
                        end
                endcase
            end
        // I-Type ALU (Computational)
        // ADDI (add immediate) and ADDIU (add immediate unsigned) add
        // the sign-extended 16-bit immediate to
        // register rs. The only difference between ADDI and ADDIU is that
        // ADDI generates an arithmetic overflow exception if the signed
        // result would overflow 32 bits.
        opADDIU,
        //
        // TODO bf: opADDI,
        //
        // SLTI (set less than immediate) places a 1 in the register rt
        // if register rs is strictly less than the sign-extended immediate
        // when both are treated as signed 32-bit numbers, else a 0 is written
        // to rt.
        opSLTI,
        // SLTIU (set less than immediate unsigned) compares values as
        // unsigned 32-bit numbers.
        opSLTIU,
        // ANDI, ORI and XORI are logical operations that perform bit-wise
        // AND, OR and XOR on register rs and the zero-extended 16-bit
        // immediate and place the result in rt.
        opANDI, opORI, opXORI,
        // LUI (load upper immediate) is used to build 32-bit immediates.
        // It shifts the 16-bit immediate into the high-order 16-bits,
        // shifting in 16 zeroes in the low order bits, then places the
        // result in regiter rt.
        opLUI:
            begin
                dInst.iType = Alu;
                dInst.shamt = Invalid;
                dInst.aluFunc = case (opcode)
                    opADDIU, opLUI: Add;
                    opSLTI: Slt;
                    opSLTIU: Sltu;
                    opANDI: And;
                    opORI: Or;
                    opXORI: Xor;
                endcase;
                dInst.dst = validReg(rt);
                dInst.src1 = validReg(rs);
                dInst.src2 = Invalid;
                dInst.imm = Valid(
                    case (opcode)
                        // NOTE: both ADDIU and SLTIU sign-extend the immediate,
                        // even though they operate on unsigned numbers.
                        opADDIU, opSLTI, opSLTIU: signExtend(imm);
                        opLUI: {imm, 16'b0};
                        opANDI, opORI, opXORI: zeroExtend(imm);
                    endcase
                );
                dInst.brFunc = NT;
            end
        // R-Type ALU (Computational)
        // Encoded with a zero value in the major opcode.
        // All operations read the rs and rt register as source operands and
        // write the result into register rd.
        // The 6-bit funct field selects the operation type.
        6'b000000:
            case (funct)
                fnSLL, fnSRL, fnSRA,
                fnSLLV, fnSRLV, fnSRAV:
                    begin
                        dInst.iType = Alu;
                        dInst.aluFunc = case (funct)
                            fnSLL, fnSLLV: LLShift;
                            fnSRL, fnSRLV: RLShift;
                            fnSRA, fnSRAV: RAShift;
                        endcase;
                        dInst.brFunc = NT;
                        dInst.dst = validReg(rd);
                        dInst.src1 = validReg(rt);
                        dInst.src2 = case (funct)
                            fnSLL, fnSRL, fnSRA: Invalid;
                            fnSLLV, fnSRLV, fnSRAV: validReg(rs);
                        endcase;
                        dInst.shamt = case (funct)
                            fnSLL, fnSRL, fnSRA: Valid(shamt);
                            fnSLLV, fnSRLV, fnSRAV: Invalid;
                        endcase;
                        dInst.imm = Invalid;
                    end
                //
                // TODO bf: ADD, SUB,
                //
                // ADDU and SUBU perform add and subtract respectively (no trap
                // is created on overflow).
                fnADDU, fnSUBU,
                // SLT and SLTU perform signed and unsigned compares
                // respectively, writing 1 to rd if rs < rt, 0 otherwise.
                fnSLT, fnSLTU,
                // AND, OR, XOR and NOR perform bitwise logical operations.
                // NOTE: NOR rd, rx, rx performs logical inversion (NOT) of
                //       register rx.
                fnAND, fnOR, fnXOR, fnNOR:
                    begin
                        dInst.iType = Alu;
                        dInst.aluFunc = case (funct)
                            fnADDU: Add;
                            fnSUBU: Sub;
                            fnAND : And;
                            fnOR : Or;
                            fnXOR : Xor;
                            fnNOR : Nor;
                            fnSLT : Slt;
                            fnSLTU: Sltu;
                        endcase;
                        dInst.dst = validReg(rd);
                        dInst.src1 = validReg(rs);
                        dInst.src2 = validReg(rt);
                        dInst.imm = Invalid;
                        dInst.shamt = Invalid;
                        dInst.brFunc = NT;
                    end
                // Indirect Jumps
                fnJR, fnJALR:
                    begin
                        dInst.iType = Jr;
                        dInst.dst = funct == fnJR ? Invalid : validReg(rd);
                        dInst.src1 = validReg(rs);
                        dInst.src2 = Invalid;
                        dInst.imm = Invalid;
                        dInst.shamt = Invalid;
                        dInst.brFunc = AT;
                    end
                default:
                    begin
                        dInst.iType = Unsupported;
                        dInst.dst = Invalid;
                        dInst.src1 = Invalid;
                        dInst.src2 = Invalid;
                        dInst.imm = Invalid;
                        dInst.shamt = Invalid;
                        dInst.brFunc = NT;
                    end
            endcase
        // Absolute Jumps
        opJ, opJAL:
            begin
                dInst.iType = J;
                dInst.dst = opcode == opJ ? Invalid :  validReg(31);
                dInst.src1 = Invalid;
                dInst.src2 = Invalid;
                dInst.imm = Valid(zeroExtend({target, 2'b00}));
                dInst.brFunc = AT;
                dInst.shamt = Invalid;
            end
        // Branch
        opBEQ, opBNE, opBLEZ, opBGTZ, opRT:
            begin
                dInst.iType = Br;
                dInst.brFunc = case(opcode)
                    opBEQ: Eq;
                    opBNE: Neq;
                    opBLEZ: Le;
                    opBGTZ: Gt;
                    opRT: case (rs)
                        5'b00000: Lt;
                        5'b00001: Ge;
                    endcase
                    // opRT: (rt == rtBLTZ ? Lt : Ge);
                endcase;
                dInst.dst = Invalid;
                dInst.src1 = validReg(rs);
                dInst.src2 = (opcode == opBEQ || opcode == opBNE) ? validReg(rt) : Invalid;
                dInst.imm = Valid(signExtend(imm) << 2);
                dInst.shamt = Invalid;
            end
        default:
            begin
                dInst.iType = Unsupported;
                dInst.dst = Invalid;
                dInst.src1 = Invalid;
                dInst.src2 = Invalid;
                dInst.imm = Invalid;
                dInst.shamt = Invalid;
                dInst.brFunc = NT;
            end
    endcase

    // Handle the case where the destination register has been specified as r0
    // in the instruction; we convert this into an "invalid" destination
    // (which will cause the write-back to ignore it).
    if (dInst.dst matches tagged Valid .dst
        &&& dst.regType == Normal
        &&& dst.idx == 0)
    begin
        dInst.dst = tagged Invalid;
    end

    return dInst;
endfunction
