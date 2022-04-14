#ifndef _MAGOS_WAR3SLKEDIT_H_
#define _MAGOS_WAR3SLKEDIT_H_


//+-----------------------------------------------------------------------------
//| Function declarations
//+-----------------------------------------------------------------------------
VOID FixArgName(CHAR* FileName);
VOID UpdateHeader();
BOOL DialogSaveAs();
BOOL DialogOpen();
VOID GetTargetFlags(HWND Handle);
BOOL Setup();
VOID Shutdown();
BOOL LoadGroupList(INT GroupNumber = 0);
BOOL LoadItemList(INT GroupNumber);
VOID UnloadGroupList();
VOID UnloadItemList();
BOOL CopyGroup(INT GroupNr, BOOL CopyData);
BOOL RemoveGroup(INT GroupNr);
ITEM* GetItem(INT GroupNr, INT ItemNr);
LRESULT PickModelMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam);
LRESULT PickIconMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam);
LRESULT PickTargetMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam);
LRESULT EditMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam);
LRESULT NameMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam);
//LRESULT SortMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam);
LRESULT MainMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam);


#endif
