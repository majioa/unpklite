ASSUME  CS:CGR,DS:CGR
CGR     GROUP   COD,DAT
COD     SEGMENT PARA
ORG     100H
LEN_    EQU     (EC-UN+ED-TYPE_OF_FILE_+15+100H)/16
HEAdER_ EQU     (ED-EXEC_DETECTION_+15)/16
UN      PROC    NEAR
        MOV     SP,100H
        LEA     SI,INTRO_
        CALL    WRITE_WORD
        MOV     AX,CS
        ADD     AX,LEN_
        MOV     CS:[LEAVE_BLOCK_1_],AX
        ADD     AX,HEADER_
        MOV     CS:[LEAVE_BLOCK_],AX
        ADD     AX,800H
        MOV     CS:[PSP_],AX
        ADD     AX,10H
        MOV     CS:[START_SEG_],AX
        PUSH    CS
        POP     DS
        MOV     SI,80H
        PUSH    CS
        POP     ES
        LEA     AX,FIRST_
        LEA     BX,SECOND_
        LEA     DX,NEW_
        CALL    READ_LINE
        JNC     READ_LINE_ERROR
        CMP     AX,3
        JNZ     READ_LINE_ERROR
READ_LINE_OK:
        DEC     SI
        DEC     SI
        DEC     BYTE PTR DS:[SI]
        PUSH    CS
        POP     ES
        MOV     AH,'/'
        CALL    READ_FILE_STRING
        JC      READ_FILE_STRING_ERROR

;LOAD_ANALIZING_FILE
        MOV     DS,CS:[LEAVE_BLOCK_]
        XOR     DX,DX
        MOV     CX,0FFFFH
        PUSH    CS
        POP     ES
        XOR     AX,AX
        DEC     AX
        MOV     CS:[FILE_NAME_ADRESS_],SI
        CALL    LOAD_FILE;BX:CX-LENGHT
        JC      LOAD_FILE_ERROR
        MOV     CS:[LEN_LAST_BLOCK_],CX
        MOV     CS:[NUMBER_OF_BLOCKS_],BX
        CALL    &DETECT_COM_OR_EXE

        ;bx:cx-len
        CALL    DETECT_PACKER

        JC      NO_PACKED
        PUSH    SI
        TEST    CS:[NEW_],00000001B
        JZ      UN_1
        CALL    SAVE_OLD_FILE
UN_1:
        CALL    WRITE_PACKER
        CALL    UNPACK
        JC      UN_2
        PUSH    CS
        POP     DS
        LEA     SI,FILE_
        CALL    WRITE_WORD
        POP     SI
        CALL    WRITE_WORD
        LEA     SI,UNPACKED_
        MOV     AX,CS:[METHOD_]
        OR      AH,AH
        JZ      UN_3
        LEA     SI,UNPROTECTED_
UN_3:
        CALL    WRITE_WORD
UN_2:
        MOV     AX,4C00H
        INT     21H
LOAD_FILE_ERROR:
        LEA     BX,UN_2
        PUSH    BX
        JMP     FILE_ERRORS
READ_LINE_ERROR:
        LEA     BX,PRINT_HELP
        PUSH    BX
        JMP     PRINT_POST_LINE_ERRORS
READ_FILE_STRING_ERROR:
        CALL    PRINT_FILE_STRING_ERROR
PRINT_HELP:
        LEA     SI,usage_
        CALL    WRITE_WORD
        JMP     SHORT   UN_2
NO_PACKED:
        PUSH    CS
        POP     DS
        PUSH    SI
        LEA     SI,FILE_
        CALL    WRITE_WORD
        POP     SI
        CALL    WRITE_WORD
        LEA     SI,NOT_PACKED_
        CALL    WRITE_WORD
        JMP     UN_2
ENDP
SAVE_OLD_FILE   PROC    NEAR
        PUSH    BX
        PUSH    SI
        PUSH    DI
        PUSH    DS
        PUSH    ES
        PUSH    CS
        POP     DS
        PUSH    CS
        POP     ES
        LEA     DI,FILE_BUFFER_
SAVE_OLD_FILE_2:
        LODSB
        CMP     AL,'.'
        JNE     SAVE_OLD_FILE_1
        LEA     SI,OLD_EXT_
SAVE_OLD_FILE_1:
        STOSB
        OR      AL,AL
        JNZ     SAVE_OLD_FILE_2
        LEA     SI,FILE_BUFFER_
        MOV     DS,CS:[LEAVE_BLOCK_]
        XOR     DX,DX
        MOV     CX,CS:[LEN_LAST_BLOCK_]
        MOV     BX,CS:[NUMBER_OF_BLOCKS_]
        CALL    SAVE_FILE
        POP     ES
        POP     DS
        POP     DI
        POP     SI
        POP     BX
        RET
ENDP
PRINT_WORD_OF_ERROR     PROC
        PUSH    AX
        PUSH    SI
        LEA     SI,ERROR_
        CALL    WRITE_WORD
        POP     SI
        POP     AX
        RET
ENDP
&DETECT_COM_OR_EXE      PROC
        PUSH    DS
        MOV     DS,CS:[LEAVE_BLOCK_]
        XOR     AL,AL
        CMP     DS:[0],'ZM'
        JE      DETECT_EXE
        INC     AL
DETECT_EXE:
        MOV     CS:[TYPE_OF_FILE_],AL
        POP     DS
        RET
ENDP

DETECT_PACKER   PROC
        PUSH    SI
        PUSH    DI
        PUSH    DS
        PUSH    ES
        CALL    DETECT_PKLITE
        JNC     DETECT_PACKER_1
        CALL    DETECT_RPS
DETECT_PACKER_1:
        MOV     CS:[METHOD_],AX
        POP     ES
        POP     DS
        POP     DI
        POP     SI
        RET
PKLITE_ DB      'PKLITE'
ENDP

DETECT_RPS      PROC
        PUSH    BX
        PUSH    CX
        CMP     CS:[TYPE_OF_FILE_],0
        JZ      DETECT_RPS_1
        SUB     CX,20H
        JNC     DETECT_RPS_2
        DEC     BX
DETECT_RPS_2:
        ADD     BX,CS:[LEAVE_BLOCK_]
        MOV     DS,BX
        MOV     SI,CX
        PUSH    CS
        POP     ES
        LEA     DI,RPS_STRING_
        MOV     BX,20H
        MOV     DX,3
        CALL    FIND_STRING
        MOV     AX,101H
DETECT_RPS_1:
        POP     CX
        POP     BX
        RET
RPS_STRING_     DB      'RPS'
ENDP
DETECT_PKLITE   PROC
        PUSH    BX
        PUSH    CX
        MOV     DS,CS:[LEAVE_BLOCK_]
        PUSH    CS
        POP     ES
        MOV     SI,1eH;(130H)
        LEA     DI,PKLITE_
        MOV     BX,60H
        MOV     DX,6
        CALL    FIND_STRING
        JC      DETECT_PKLITE_1
        DEC     SI
        DEC     SI
        MOV     AX,DS:[SI]
        AND     AH,0FH
        ADD     AL,CS:[TYPE_OF_FILE_]
        MOV     CS:[PACKER_VERSION_],AX
DETECT_PKLITE_1:
        MOV     AX,1
        POP     CX
        POP     BX
        RET
ENDP
COMPARE_STRING  PROC;DS:SI,ES:DI,CX-LEN
        PUSH    AX
        PUSH    SI
        PUSH    DI
COMPARE_STRING_1:
        LODSB
        CALL    COMPARE_CASE
        MOV     AH,AL
        MOV     AL,ES:[DI]
        INC     DI
        CALL    COMPARE_CASE
        CMP     AL,AH
        CLC
        JNZ     COMPARE_STRING_ERROR
        LOOP    COMPARE_STRING_1
        STC
COMPARE_STRING_ERROR:
        CMC
        POP     DI
        POP     SI
        POP     AX
        RET
COMPARE_FLAG_   DB      0
ENDP
COMPARE_CASE    PROC
        TEST    CS:[COMPARE_FLAG_],1
        JZ      COMPARE_CASE_1
        CMP     AL,'a'
        JB      COMPARE_CASE_1
        CMP     AL,'z'
        JA      COMPARE_CASE_1
        SUB     AL,20H
COMPARE_CASE_1:
        RET
ENDP
FIND_STRING     PROC;DS:SI,BX,DX-LEN OF STRING
        MOV     CX,BX
FIND_STRING_1:
        PUSH    CX
        MOV     CX,DX
        CALL    COMPARE_STRING
        POP     CX
        JNC     FIND_STRING_2
        INC     SI
        LOOP    FIND_STRING_1
        STC
FIND_STRING_2:
        RET
ENDP
COPY_HEADER     PROC    NEAR
        PUSH    CX
        PUSH    SI
        PUSH    DI
        PUSH    DS
        PUSH    ES
        LEA     SI,EXEC_DETECTION_
        PUSH    CS
        POP     DS
        XOR     DI,DI
        MOV     ES,CS:[LEAVE_BLOCK_1_]
        MOV     CX,HEADER_*8
        REP     MOVSW
        POP     ES
        POP     DS
        POP     DI
        POP     SI
        POP     CX
        RET
ENDP
ENT     PROC
        PUSH    AX
        PUSH    BX
        PUSH    DS

        PUSH    CS
        POP     DS
        LEA     SI,ENTING_
        CALL    WRITE_WORD

        POP     DS
        POP     BX
        POP     AX
        RET
ENTING_ DB      0dh,0ah,0
ENDP
include errors.lib
include ioerrors.lib
include setupan.lib
include readfstr.lib
include readline.lib
include io.lib
include wrword.lib
include analizer.lib
include unpack.lib
include wrpacker.lib
include prnt_h_d.lib
EC:
ENDS
DAT     SEGMENT PARA
TYPE_OF_FILE_   DB      ?
LEAVE_BLOCK_    DW      ?
LEAVE_BLOCK_1_  DW      ?
PSP_    DW      ?
START_SEG_      DW      ?
OLD_EXT_        DB      'PKL',0
FILE_BUFFER_    DB      14      DUP     (0)
OLD_SS_ DW      ?
OLD_SP_ DW      ?
LENght_ DW      ?
HIGH_LENGHT_    DB      ?
INTRO_  DB      'UNPKLITE 1.0 Copyright (C) 1996 by Pavel A. Skrylev',0dh,0ah
        db      'All Right Reserved',0DH,0AH,0
USAGE_  DB      'Usage: UNPKLITE.COM <Switch> <Filename>',0DH,0AH
        DB      '  Switch: /B - Create back up copy of file',0dh,0ah,0
UNPACKING_      DB      'Unpacking',0
UNPROTECTING_   DB      'Unprotecting',0
INCLUDE IOERRORS.LBX
INCLUDE ERRORS.LBX

FIRST_  DB      '/B',0FFH
SECOND_ DB      'B',0FFH
NEW_    DW      1       DUP     (0)
NO_STRING_      DB      0
METHOD_ DW      0
FILE_NAME_ADRESS_       DW      0

LEN_LAST_BLOCK_ DW      0
NUMBER_OF_BLOCKS_       DW      0

PACKER_VERSION_ DW      0;L-SUB VERSION,H-VERSION

ENDS
HEADER  SEGMENT PARA
EXEC_DETECTION_ DB      'MZ'
LAST_FIELD_     DW      ?
NUMBER_OF_FIELDS_       DW      ?
NUMBER_OF_ELEMENTS_IN_TABLE_OF_REMOVINGS_       DW      ?
LENGHT_OF_HEADER_       DW      ?
MIN_QUANTITY_OF_PARAGRAPHS_     DW      1000H
MAX_QUANTITY_OF_PARAGRAPHS_     DW      0FFFFH
BEGIN_SS_       DW      ?
BEGIN_SP_       DW      ?
CONTROL_SUMM_   DW      0
BEGIN_IP_       DW      ?
BEGIN_CS_       DW      ?
SHIFT_IN_TABLE_OF_REMOVINGS_    DW      (ed-exec_detection_)
NUMBER_OF_OVERLAY_      DW      0
IDENTIFICATION_ DB      0,1,'Unpklite by Pavel Skrylev Computing (C)1996. All Right Reserved'
LAST_ZERO:
                DB      3       DUP     (0)
ED:
ENDS
END     UN

