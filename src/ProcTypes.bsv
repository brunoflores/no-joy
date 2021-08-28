interface IProc;
    method Action hostToCpu (Addr startpc);
    // method ActionValue#(Tuple2#(RIndx, Data)) cpuToHost;
endinterface

interface IRegFile;
    method Data rd1 (RIndx r);
    method Data rd2 (RIndx r);
    method Action wr (RIndx r, Data d);
endinterface

interface IMemory;
    method Data req (Addr a);
endinterface

interface DMemory;
    method ActionValue#(Data) req (MemReq req);
endinterface

interface ICop;
    method Bool started;
    method Action start;
    // method Data rd (RIndx r);
    // method Action wr (Tuple2#(Maybe#(FullIndx), Data) x);
    // method Tuple2#(RIndx, Data) cpuToHost;
endinterface

typedef Bit#(32) Data;
typedef Bit#(32) Addr;

typedef Bit#(5) RIndx; // Five bits needed to index 32 registers.

typedef struct {
    IType op;
    Addr addr;
    Data data;
} MemReq deriving (Bits, Eq);

typedef enum {Normal, CopReg} RegType
    deriving (Bits, Eq);

typedef struct {
    RegType regType;
    RIndx idx;
} FullIndx deriving (Bits, Eq);

typedef enum {Unsupported, Alu, Ld, St, J, Jr, Br, Mfc0, Mtc0} IType
    deriving(Bits, Eq);

typedef enum {Eq, Neq, Le, Lt, Ge, Gt, AT, NT} BrFunc
    deriving(Bits, Eq);

typedef enum {Add, Sub, And, Or, Xor, Nor,
              Slt, Sltu, LLShift, RLShift, RAShift} AluFunc
    deriving(Bits, Eq);

typedef struct {
    IType iType;
    AluFunc aluFunc;
    BrFunc brFunc;
    Maybe#(FullIndx) dst;
    Maybe#(FullIndx) src1;
    Maybe#(FullIndx) src2;
    Maybe#(Data) imm;
    Maybe#(Bit#(5)) shamt;
} DecodedInst deriving(Bits, Eq);

typedef struct {
    IType iType;
    Maybe#(FullIndx) dst;
    Data data;
    Addr addr;
    Bool mispredict;
    Bool brTaken;
} ExecInst deriving(Bits, Eq);

// Load and Store Instructions
Bit#(6) opLW    = 6'b100011;
Bit#(6) opSW    = 6'b101011;

// I-Type Computational Instructions
Bit#(6) opADDIU = 6'b001001;
Bit#(6) opSLTI  = 6'b001010;
Bit#(6) opSLTIU = 6'b001011;
Bit#(6) opANDI  = 6'b001100;
Bit#(6) opORI   = 6'b001101;
Bit#(6) opXORI  = 6'b001110;
Bit#(6) opLUI   = 6'b001111;

// R-Type Computational Instructions
Bit#(6) fnSLL     = 6'b000000;
Bit#(6) fnSRL     = 6'b000010;
Bit#(6) fnSRA     = 6'b000011;
Bit#(6) fnSLLV    = 6'b000100;
Bit#(6) fnSRLV    = 6'b000110;
Bit#(6) fnSRAV    = 6'b000111;
Bit#(6) fnADDU    = 6'b100001;
Bit#(6) fnSUBU    = 6'b100011;
Bit#(6) fnAND     = 6'b100100;
Bit#(6) fnOR      = 6'b100101;
Bit#(6) fnXOR     = 6'b100110;
Bit#(6) fnNOR     = 6'b100111;
Bit#(6) fnSLT     = 6'b101010;
Bit#(6) fnSLTU    = 6'b101011;

// Jump and Branch Instructions
Bit#(6) opJ     = 6'b000010;
Bit#(6) opJAL   = 6'b000011;
Bit#(6) opJR    = 6'b000000;
Bit#(6) opJALR  = 6'b000000;
Bit#(6) opBEQ   = 6'b000100;
Bit#(6) opBNE   = 6'b000101;
Bit#(6) opBLEZ  = 6'b000110;
Bit#(6) opBGTZ  = 6'b000111;
Bit#(6) opRT    = 6'b000001;
Bit#(6) fnJR    = 6'b001000;
Bit#(6) fnJALR  = 6'b001001;

// Sytem Coprocessor (COP0) Instructions
Bit#(5) rsMFC0 = 5'b00000;
Bit#(5) rsMTC0 = 5'b00100;

function Bit#(32) showInst(Data d);
    return d;
endfunction

function RIndx validRegValue (Maybe#(FullIndx) x);
    return case (x) matches
        tagged Valid .x: x.idx;
        Invalid: 0;
    endcase;
endfunction
