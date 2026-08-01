function scr_define_addressing_modes() {
    global.AM_DN         = 1;      // Data register direct
    global.AM_AN         = 2;      // Address register direct
    global.AM_AN_IND     = 4;      // (An)
    global.AM_AN_POSTINC = 8;      // (An)+
    global.AM_AN_PREDEC  = 16;     // -(An)
    global.AM_AN_DISP    = 32;     // d16(An)
    global.AM_AN_INDEX   = 64;     // d8(An,Xn)
    global.AM_ABS_W      = 128;    // absolute short
    global.AM_ABS_L      = 256;    // absolute long
    global.AM_PC_DISP    = 512;    // d16(PC)
    global.AM_PC_INDEX   = 1024;   // d8(PC,Xn)
    global.AM_IMM        = 2048;   // #immediate

    // Common groupings
    global.AM_DATA_ALTERABLE = global.AM_DN + global.AM_AN_IND + global.AM_AN_POSTINC + global.AM_AN_PREDEC + global.AM_AN_DISP + global.AM_AN_INDEX + global.AM_ABS_W + global.AM_ABS_L;
    global.AM_MEMORY_ALTERABLE = global.AM_DATA_ALTERABLE - global.AM_DN;
    global.AM_DATA = global.AM_DATA_ALTERABLE + global.AM_PC_DISP + global.AM_PC_INDEX + global.AM_IMM;
    global.AM_CONTROL = global.AM_AN_IND + global.AM_AN_DISP + global.AM_AN_INDEX + global.AM_ABS_W + global.AM_ABS_L + global.AM_PC_DISP + global.AM_PC_INDEX;
    global.AM_ALTERABLE_ALL = global.AM_DATA_ALTERABLE + global.AM_AN;
}