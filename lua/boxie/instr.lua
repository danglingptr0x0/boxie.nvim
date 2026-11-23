local err = require("boxie.err")

local boxie_instr = {
    BOXIE_INSTR_NAME_SEP = " = ",
    BOXIE_INSTR_QUOTE = "\"",
    BOXIE_INSTR_DOES_SEP = ": ",
    BOXIE_INSTR_FIELD_SEP = "; ",
    BOXIE_INSTR_ARG_PREFIX = "args: ",
    BOXIE_INSTR_TABLE = {
        mov = { "Move", "dst = src", "reg/mem, reg/mem/imm", "no mem-to-mem; flags kept" },
        xchg = { "Exchange", "swap dst, src", "reg/mem, reg", nil },
        push = { "Push", "SP -= 2; [SP] = src", "reg16/mem16/imm/seg", nil },
        pop = { "Pop", "dst = [SP]; SP += 2", "reg16/mem16/seg", "no POP CS" },
        pusha = { "Push All General Registers", "push AX CX DX BX SP BP SI DI", "none", "186+" },
        popa = { "Pop All General Registers", "pop DI SI BP BX DX CX AX", "none", "saved SP skipped; 186+" },
        pushf = { "Push Flags", "push FLAGS", "none", nil },
        popf = { "Pop Flags", "FLAGS = pop", "none", nil },
        lea = { "Load Effective Address", "dst = addr of src", "reg16, mem", "no mem rd" },
        lds = { "Load Far Pointer Using DS", "dst = [src]; DS = [src + 2]", "reg16, mem32", nil },
        les = { "Load Far Pointer Using ES", "dst = [src]; ES = [src + 2]", "reg16, mem32", nil },
        ["in"] = { "Input from Port", "AL/AX = port", "AL/AX, imm8/DX", "port > 255 needs DX" },
        out = { "Output to Port", "port = AL/AX", "imm8/DX, AL/AX", "port > 255 needs DX" },
        xlat = { "Table Look-up Translation", "AL = [BX + AL]", "none", nil },
        cbw = { "Convert Byte to Word", "AX = sign-extended AL", "none", nil },
        cwd = { "Convert Word to Doubleword", "DX:AX = sign-extended AX", "none", "use before IDIV" },
        add = { "Add", "dst += src", "reg/mem, reg/mem/imm", "CF on carry; OF on signed overflow" },
        adc = { "Add with Carry", "dst += src + CF", "reg/mem, reg/mem/imm", nil },
        sub = { "Subtract", "dst -= src", "reg/mem, reg/mem/imm", "CF on borrow; OF on signed overflow" },
        sbb = { "Integer Subtraction with Borrow", "dst -= src + CF", "reg/mem, reg/mem/imm", nil },
        inc = { "Increment", "dst += 1", "reg/mem", "CF kept" },
        dec = { "Decrement", "dst -= 1", "reg/mem", "CF kept" },
        neg = { "Two's Complement Negation", "dst = 0 - dst", "reg/mem", "CF = 1 unless dst was 0" },
        cmp = { "Compare Two Operands", "flags = dst - src", "reg/mem, reg/mem/imm", "dst kept; pair with Jcc" },
        mul = { "Unsigned Multiply", "DX:AX = AX * src", "reg/mem; 8-bit: AX = AL * src", "CF OF set if high half != 0" },
        imul = { "Signed Multiply", "DX:AX = AX * src", "reg/mem; 8-bit: AX = AL * src", "CF OF set if high half != sign" },
        div = { "Unsigned Divide", "AX = DX:AX / src; DX = mod", "reg/mem; 8-bit: AL = AX / src, AH = mod", "src 0 or quotient too big -> #DE; zero DX first" },
        idiv = { "Signed Divide", "AX = DX:AX / src; DX = mod", "reg/mem; 8-bit: AL = AX / src, AH = mod", "src 0 or quotient too big -> #DE; CWD first" },
        ["and"] = { "Logical AND", "dst &= src", "reg/mem, reg/mem/imm", "CF OF = 0" },
        ["or"] = { "Logical Inclusive OR", "dst |= src", "reg/mem, reg/mem/imm", "CF OF = 0" },
        xor = { "Logical Exclusive OR", "dst ^= src", "reg/mem, reg/mem/imm", "XOR reg, reg zeroes reg" },
        ["not"] = { "One's Complement Negation", "dst = ~dst", "reg/mem", "flags kept" },
        test = { "Logical Compare", "flags = dst & src", "reg/mem, reg/imm", "dst kept; pair with Jcc" },
        shl = { "Shift Logical Left", "dst <<= count", "reg/mem, 1/CL/imm8", "CF = last bit out; imm8 186+" },
        sal = { "Shift Arithmetic Left", "dst <<= count", "reg/mem, 1/CL/imm8", "same as SHL" },
        shr = { "Shift Logical Right", "dst >>= count, 0 in", "reg/mem, 1/CL/imm8", "CF = last bit out" },
        sar = { "Shift Arithmetic Right", "dst >>= count, sign in", "reg/mem, 1/CL/imm8", "CF = last bit out" },
        rol = { "Rotate Left", "dst rotated left", "reg/mem, 1/CL/imm8", "CF = last bit rotated" },
        ror = { "Rotate Right", "dst rotated right", "reg/mem, 1/CL/imm8", "CF = last bit rotated" },
        rcl = { "Rotate through Carry Left", "CF:dst rotated left", "reg/mem, 1/CL/imm8", nil },
        rcr = { "Rotate through Carry Right", "CF:dst rotated right", "reg/mem, 1/CL/imm8", nil },
        jmp = { "Jump", "IP = tgt", "label/reg/mem; far: seg:off", nil },
        je = { "Jump if Equal", "jmp if ZF = 1", "label", nil },
        jne = { "Jump if Not Equal", "jmp if ZF = 0", "label", nil },
        ja = { "Jump if Above", "jmp if CF = 0 and ZF = 0", "label", "unsigned" },
        jae = { "Jump if Above or Equal", "jmp if CF = 0", "label", "unsigned" },
        jb = { "Jump if Below", "jmp if CF = 1", "label", "unsigned" },
        jbe = { "Jump if Below or Equal", "jmp if CF = 1 or ZF = 1", "label", "unsigned" },
        jg = { "Jump if Greater", "jmp if ZF = 0 and SF = OF", "label", "signed" },
        jge = { "Jump if Greater or Equal", "jmp if SF = OF", "label", "signed" },
        jl = { "Jump if Less", "jmp if SF != OF", "label", "signed" },
        jle = { "Jump if Less or Equal", "jmp if ZF = 1 or SF != OF", "label", "signed" },
        js = { "Jump if Sign", "jmp if SF = 1", "label", nil },
        jns = { "Jump if Not Sign", "jmp if SF = 0", "label", nil },
        jo = { "Jump if Overflow", "jmp if OF = 1", "label", nil },
        jno = { "Jump if Not Overflow", "jmp if OF = 0", "label", nil },
        jp = { "Jump if Parity", "jmp if PF = 1", "label", nil },
        jnp = { "Jump if Not Parity", "jmp if PF = 0", "label", nil },
        jcxz = { "Jump if CX Zero", "jmp if CX = 0", "label", "flags not ck'd" },
        loop = { "Loop According to CX Count", "CX -= 1; jmp if CX != 0", "label", "flags kept" },
        loope = { "Loop while Equal", "CX -= 1; jmp if CX != 0 and ZF = 1", "label", nil },
        loopne = { "Loop while Not Equal", "CX -= 1; jmp if CX != 0 and ZF = 0", "label", nil },
        call = { "Call Procedure", "push ret addr; jmp tgt", "label/reg/mem", nil },
        ret = { "Return from Procedure", "IP = pop", "none/imm16", "imm16: SP += imm16 after" },
        retf = { "Far Return from Procedure", "IP = pop; CS = pop", "none/imm16", nil },
        int = { "Call to Interrupt Procedure", "push FLAGS CS IP; jmp vec n", "imm8", "vec n at IVT addr n * 4" },
        into = { "Call to Interrupt Procedure if Overflow", "INT 4 if OF = 1", "none", nil },
        iret = { "Interrupt Return", "IP, CS, FLAGS = pop", "none", nil },
        hlt = { "Halt", "stop until next irq or rst", "none", "after CLI only rst or NMI wakes" },
        nop = { "No Operation", "nothing", "none", nil },
        cli = { "Clear Interrupt Flag", "IF = 0; irqs masked", "none", "NMI still on" },
        sti = { "Set Interrupt Flag", "IF = 1; irqs on", "none", "on after next instr" },
        clc = { "Clear Carry Flag", "CF = 0", "none", nil },
        stc = { "Set Carry Flag", "CF = 1", "none", nil },
        cmc = { "Complement Carry Flag", "CF = !CF", "none", nil },
        cld = { "Clear Direction Flag", "DF = 0; string ops inc", "none", nil },
        std = { "Set Direction Flag", "DF = 1; string ops dec", "none", nil },
        movsb = { "Move Data from String to String", "[ES:DI] = [DS:SI]; SI, DI += 1", "none", "REP: CX times; DF = 1: dec" },
        movsw = { "Move Data from String to String", "[ES:DI] = [DS:SI]; SI, DI += 2", "none", "REP: CX times; DF = 1: dec" },
        stosb = { "Store String", "[ES:DI] = AL; DI += 1", "none", "REP: CX times" },
        stosw = { "Store String", "[ES:DI] = AX; DI += 2", "none", "REP: CX times" },
        lodsb = { "Load String", "AL = [DS:SI]; SI += 1", "none", nil },
        lodsw = { "Load String", "AX = [DS:SI]; SI += 2", "none", nil },
        cmpsb = { "Compare String Operands", "flags = [DS:SI] - [ES:DI]", "none", "REPE/REPNE: while eq/neq" },
        scasb = { "Scan String", "flags = AL - [ES:DI]", "none", "REPE/REPNE: while eq/neq" },
        rep = { "Repeat String Operation Prefix", "repeat next string op CX times", "string op", "CX = 0: skipped" },
        repe = { "Repeat while Equal Prefix", "repeat while CX != 0 and ZF = 1", "CMPS/SCAS", nil },
        repne = { "Repeat while Not Equal Prefix", "repeat while CX != 0 and ZF = 0", "CMPS/SCAS", nil },
    },
    BOXIE_INSTR_ALIAS = {
        jz = "je",
        jnz = "jne",
        jnbe = "ja",
        jnb = "jae",
        jnc = "jae",
        jnae = "jb",
        jc = "jb",
        jna = "jbe",
        jnle = "jg",
        jnl = "jge",
        jnge = "jl",
        jng = "jle",
        jpe = "jp",
        jpo = "jnp",
        loopz = "loope",
        loopnz = "loopne",
        repz = "repe",
        repnz = "repne",
    },
    BOXIE_INSTR_NAME_IDX = 1,
    BOXIE_INSTR_DOES_IDX = 2,
    BOXIE_INSTR_ARG_IDX = 3,
    BOXIE_INSTR_COND_IDX = 4,
}

function boxie_instr.boxie_instr_known_is(op)
    if op == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    if boxie_instr.BOXIE_INSTR_TABLE[op] ~= nil or boxie_instr.BOXIE_INSTR_ALIAS[op] ~= nil then return err.LDG_TRUTH_TRUE end

    return err.LDG_TRUTH_FALSE
end

function boxie_instr.boxie_instr_text_get(op, op_raw, out)
    local entry = nil
    local key = ""

    if op == nil or op_raw == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.text = ""

    key = boxie_instr.BOXIE_INSTR_ALIAS[op] or op
    entry = boxie_instr.BOXIE_INSTR_TABLE[key]

    if entry == nil then return err.LDG_ERR_NOT_FOUND end

    out.text = op_raw .. boxie_instr.BOXIE_INSTR_NAME_SEP .. boxie_instr.BOXIE_INSTR_QUOTE .. entry[boxie_instr.BOXIE_INSTR_NAME_IDX] .. boxie_instr.BOXIE_INSTR_QUOTE .. boxie_instr.BOXIE_INSTR_DOES_SEP .. entry[boxie_instr.BOXIE_INSTR_DOES_IDX] .. boxie_instr.BOXIE_INSTR_FIELD_SEP .. boxie_instr.BOXIE_INSTR_ARG_PREFIX .. entry[boxie_instr.BOXIE_INSTR_ARG_IDX]

    if entry[boxie_instr.BOXIE_INSTR_COND_IDX] ~= nil then out.text = out.text .. boxie_instr.BOXIE_INSTR_FIELD_SEP .. entry[boxie_instr.BOXIE_INSTR_COND_IDX] end

    return err.LDG_ERR_AOK
end

return boxie_instr
