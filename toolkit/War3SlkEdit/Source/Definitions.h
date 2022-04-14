#ifndef _MAGOS_DEFINITIONS_H_
#define _MAGOS_DEFINITIONS_H_


//+-----------------------------------------------------------------------------
//| Constant definitions
//+-----------------------------------------------------------------------------
#define STRINGSIZE      4096
#define MAXBUFFERSIZE   2048
#define DEFAULTWIDTH    500 
#define DEFAULTHEIGHT   400
#define MINWINDOWWIDTH  300
#define MINWINDOWHEIGHT 150
#define OFFSETWIDTH     10
#define OFFSETHEIGHT    55
#define NROFMODELS      2048
#define NROFICONS       689
#define ItemListNotify  123


//+-----------------------------------------------------------------------------
//| Memory macros
//+-----------------------------------------------------------------------------
#define Nullify(Pointer) Pointer = NULL
#define SafeDelete(Pointer) if(Pointer != NULL) { delete Pointer; Pointer = NULL; }
#define SafeArrayDelete(Pointer) if(Pointer != NULL) { delete[] Pointer; Pointer = NULL; }


#endif
