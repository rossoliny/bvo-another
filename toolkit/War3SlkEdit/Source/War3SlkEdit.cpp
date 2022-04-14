//+-----------------------------------------------------------------------------
//| File:    War3SlkEdit
//| Version: 1.05
//| Date:    2003-06-06
//| Author:  Magos (Magnus Östberg)
//| Mail:    MagnusOstberg@Hotmail.com
//| Url:     http://www20.brinkster.com/magos818/
//|
//| Description:
//|
//|          A program to edit SLK files.
//|
//| Version history:
//|
//|         1.00 (2003-06-06)
//|         The first version is finished.
//|
//|         1.01 (2003-06-07)
//|         Added support for adding/removing groups. Fixed some bugs.
//|
//|         1.02 (2003-06-07)
//|         Added support for opening files by associating the filename
//|         with this program.
//|
//|         1.03 (2003-06-09)
//|         A bug with the new/copy group function has been solved,
//|         making some data not appear with surrounding " ".
//|
//|         1.04 (2003-06-17)
//|         I found out that the pick-icon list didn't pick the proper icon.
//|         Wonder why I haven't found out until now...
//|
//|         1.05 (2003-09-27)
//|         Added support for sorting the list alphabetically. Some of the
//|         official Warcraft 3 SLK files will give an error thanks to
//|         some ID fields being left empty (an entire object actually), but
//|         the rest of the list should be sorted properly. 
//|
//+-----------------------------------------------------------------------------


//+-----------------------------------------------------------------------------
//| Included files
//+-----------------------------------------------------------------------------
#include "IncludeAll.h"
#include "StringList.h"


//+-----------------------------------------------------------------------------
//| Global data
//+-----------------------------------------------------------------------------
HINSTANCE MainInstance = NULL;
HWND MainWindow = NULL;
HWND ItemList = NULL;
SLK Slk;
BOOL ProperReturnValue = TRUE;
ITEM* ItemToBeModified = NULL;
CHAR TempString[STRINGSIZE + 1] = "";
CHAR CurrentFileName[STRINGSIZE + 1] = "Unnamed";
BOOL FileLoaded = FALSE;
BOOL FileSaved = FALSE;
BOOL FirstTimeSaving = TRUE;


//+-----------------------------------------------------------------------------
//| ### TEMP FUNCTIONS ###
//| Converts TXT files to a list
//+-----------------------------------------------------------------------------
/*
VOID HandleLists()
{
	//Data
	INT i;
	INT c = 0;
	CHAR Buffer[1024];
	ifstream ReadFile;
	ofstream WriteFile;

	//Open the infile
	ReadFile.open("Sfxlist.txt", ios::in | ios::nocreate);
	if(ReadFile.fail())
	{
		MessageBox(NULL, "SfxList.txt failed!", "Message", MB_ICONERROR);
		return;
	}

	//Open the outfile
	WriteFile.open("Output.txt", ios::out | ios::trunc);
	if(WriteFile.fail())
	{
		ReadFile.close();
		MessageBox(NULL, "Output.txt failed!", "Message", MB_ICONERROR);
		return;
	}

	//Read all lines
	while(!ReadFile.getline(Buffer, 1023).eof())
	{
		c++;
		Buffer[strlen(Buffer) - 1] = 'l';
		if(Buffer[0] == '*')
		{
			for(i=0; i<strlen(Buffer); i++)
			{
				Buffer[i] = Buffer[i + 1];
			}
		}

		WriteFile << "\t\t\t\t\t\t\t \"" << Buffer << "\",\n";
	}


	//Read all lines
	while(!ReadFile.getline(Buffer, 1023).eof())
	{
		c++;
		if(Buffer[0] == '*')
		{
			for(i=0; i<strlen(Buffer); i++)
			{
				Buffer[i] = Buffer[i + 1];
			}
		}

		WriteFile << "\t\t\t\t\t\t   \"" << Buffer << "\",\n";
	}

	WriteFile << endl << endl << c << endl;

	//Close files
	ReadFile.close();
	WriteFile.close();
}
*/


//+-----------------------------------------------------------------------------
//| Removes some ""
//+-----------------------------------------------------------------------------
VOID FixArgName(CHAR* FileName)
{
	//Data
	INT i;
	INT Length = strlen(FileName);

	//Check if the first character is a "
	if(FileName[0] == '"')
	{
		//Shift all characters 1 step to the left
		for(i = 0; i < Length; i++)
		{
			FileName[i] = FileName[i + 1];
		}

		//Fix the last NULL terminator
		FileName[Length - 2] = '\0';
	}
}


//+-----------------------------------------------------------------------------
//| Updates the caption header
//+-----------------------------------------------------------------------------
VOID UpdateHeader()
{
	//Data
	CHAR CaptionHeader[STRINGSIZE + 1];

	//Make a proper header
	strcpy(CaptionHeader, "War3 SLK Edit v1.05 - ");
	if(FileLoaded == TRUE)
	{
		strcat(CaptionHeader, CurrentFileName);
		if(FileSaved == FALSE)
		{
			strcat(CaptionHeader, " (*)");
		}
	}
	else
	{
		strcat(CaptionHeader, "No file loaded");
	}

	//Set the header
	SetWindowText(MainWindow, CaptionHeader);
}


//+-----------------------------------------------------------------------------
//| Dialog SAVE AS
//+-----------------------------------------------------------------------------
BOOL DialogSaveAs()
{
	OPENFILENAME Ofn;
	ZeroMemory(&Ofn, sizeof(OPENFILENAME));

	Ofn.lStructSize = sizeof(OPENFILENAME);
	Ofn.hwndOwner = MainWindow;
	Ofn.lpstrFilter = "SLK Files (*.slk)\0*.slk\0All Files (*.*)\0*.*\0\0";
	Ofn.lpstrFile = TempString;
	Ofn.nMaxFile = STRINGSIZE;
	Ofn.lpstrInitialDir = NULL;
	Ofn.lpstrTitle = "Save As:";
	Ofn.Flags = OFN_OVERWRITEPROMPT | OFN_HIDEREADONLY;

	return GetSaveFileName(&Ofn);
}

//+-----------------------------------------------------------------------------
//| Dialog OPEN
//+-----------------------------------------------------------------------------
BOOL DialogOpen()
{
	OPENFILENAME Ofn;
	ZeroMemory(&Ofn, sizeof(OPENFILENAME));

	Ofn.lStructSize = sizeof(OPENFILENAME);
	Ofn.hwndOwner = MainWindow;
	Ofn.lpstrFilter = "SLK Files (*.slk)\0*.slk\0All Files (*.*)\0*.*\0\0";
	Ofn.lpstrFile = TempString;
	Ofn.nMaxFile = STRINGSIZE;
	Ofn.lpstrInitialDir = NULL;
	Ofn.lpstrTitle = "Open:";
	Ofn.Flags = OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;

	return GetOpenFileName(&Ofn);
}


//+-----------------------------------------------------------------------------
//| Turns the target selection into a string with selections
//+-----------------------------------------------------------------------------
VOID GetTargetFlags(HWND Handle)
{
	//Data
	INT Length;
	INT Flags = 0;

	//Get the flags
	strcpy(TempString, "");
	if(IsDlgButtonChecked(Handle, PickTargetGround) == BST_CHECKED) strcat(TempString, "Ground,");
	if(IsDlgButtonChecked(Handle, PickTargetAir) == BST_CHECKED) strcat(TempString, "Air,");
	if(IsDlgButtonChecked(Handle, PickTargetTerrain) == BST_CHECKED) strcat(TempString, "Terrain,");
	if(IsDlgButtonChecked(Handle, PickTargetStructure) == BST_CHECKED) strcat(TempString, "Structure,");
	if(IsDlgButtonChecked(Handle, PickTargetOrganic) == BST_CHECKED) strcat(TempString, "Organic,");
	if(IsDlgButtonChecked(Handle, PickTargetUndead) == BST_CHECKED) strcat(TempString, "Undead,");
	if(IsDlgButtonChecked(Handle, PickTargetDead) == BST_CHECKED) strcat(TempString, "Dead,");
	if(IsDlgButtonChecked(Handle, PickTargetAlive) == BST_CHECKED) strcat(TempString, "Alive,");
	if(IsDlgButtonChecked(Handle, PickTargetHero) == BST_CHECKED) strcat(TempString, "Hero,");
	if(IsDlgButtonChecked(Handle, PickTargetNonhero) == BST_CHECKED) strcat(TempString, "Nonhero,");
	if(IsDlgButtonChecked(Handle, PickTargetSapper) == BST_CHECKED) strcat(TempString, "Sapper,");
	if(IsDlgButtonChecked(Handle, PickTargetNonsapper) == BST_CHECKED) strcat(TempString, "Nonsapper,");
	if(IsDlgButtonChecked(Handle, PickTargetSelf) == BST_CHECKED) strcat(TempString, "Self,");
	if(IsDlgButtonChecked(Handle, PickTargetNotself) == BST_CHECKED) strcat(TempString, "Notself,");
	if(IsDlgButtonChecked(Handle, PickTargetPlayer) == BST_CHECKED) strcat(TempString, "Player,");
	if(IsDlgButtonChecked(Handle, PickTargetEnemy) == BST_CHECKED) strcat(TempString, "Enemy,");
	if(IsDlgButtonChecked(Handle, PickTargetAllied) == BST_CHECKED) strcat(TempString, "Allied,");
	if(IsDlgButtonChecked(Handle, PickTargetNeutral) == BST_CHECKED) strcat(TempString, "Neutral,");
	if(IsDlgButtonChecked(Handle, PickTargetFriend) == BST_CHECKED) strcat(TempString, "Friend,");
	if(IsDlgButtonChecked(Handle, PickTargetItem) == BST_CHECKED) strcat(TempString, "Item,");
	if(IsDlgButtonChecked(Handle, PickTargetTree) == BST_CHECKED) strcat(TempString, "Tree,");
	if(IsDlgButtonChecked(Handle, PickTargetWard) == BST_CHECKED) strcat(TempString, "Ward,");
	if(IsDlgButtonChecked(Handle, PickTargetDebris) == BST_CHECKED) strcat(TempString, "Debris,");
	if(IsDlgButtonChecked(Handle, PickTargetWall) == BST_CHECKED) strcat(TempString, "Wall,");
	if(IsDlgButtonChecked(Handle, PickTargetAncient) == BST_CHECKED) strcat(TempString, "Ancient,");
	if(IsDlgButtonChecked(Handle, PickTargetNonancient) == BST_CHECKED) strcat(TempString, "Nonancient,");
	if(IsDlgButtonChecked(Handle, PickTargetVuln) == BST_CHECKED) strcat(TempString, "Vuln,");
	if(IsDlgButtonChecked(Handle, PickTargetInvu) == BST_CHECKED) strcat(TempString, "Invu,");
	if(IsDlgButtonChecked(Handle, PickTargetNone) == BST_CHECKED) strcat(TempString, "None,");

	//Fix the last comma
	Length = strlen(TempString);
	if(Length > 0)
	{
		TempString[Length - 1] = '\0';
	}
}


//+-----------------------------------------------------------------------------
//| Setup function
//+-----------------------------------------------------------------------------
BOOL Setup()
{
	//Data
	INT ScreenWidth = GetSystemMetrics(SM_CXSCREEN);
	INT ScreenHeight = GetSystemMetrics(SM_CYSCREEN);
	LV_COLUMN ListColumn;
	CHAR* TempString[] = {"Item",
						  "Data"};

	//Create the main dialog
	MainWindow = CreateDialog(MainInstance, MAKEINTRESOURCE(MainDialog), NULL, (DLGPROC)MainMessageHandler);

	//Abort if creation failed
	if(MainWindow == NULL)
	{
		return FALSE;
	}

	//Load an icon
	SetClassLong(MainWindow, GCL_HICON, (LONG)LoadIcon(MainInstance, MAKEINTRESOURCE(ProgramIcon)));
	ShowWindow(MainWindow, SW_HIDE);
	ShowWindow(MainWindow, SW_SHOW);

	//Sets the position of the window
	SetWindowPos(MainWindow, HWND_TOP, ((ScreenWidth - DEFAULTWIDTH) / 2), ((ScreenHeight - DEFAULTHEIGHT) / 2), DEFAULTWIDTH, DEFAULTHEIGHT, 0);

	//Ensures that the common control DLL is loaded
	INITCOMMONCONTROLSEX InitControls;
	InitControls.dwSize = sizeof(INITCOMMONCONTROLSEX);
	InitControls.dwICC  = ICC_LISTVIEW_CLASSES;
	InitCommonControlsEx(&InitControls);

	//Creates the item list
	//  | LVS_NOCOLUMNHEADER | LVS_EDITLABELS
	ItemList = CreateWindow(WC_LISTVIEW, "ItemList", WS_CHILD | LVS_REPORT | LVS_NOCOLUMNHEADER, 0, 0, 400, 400, MainWindow, (HMENU)ItemListNotify, MainInstance, NULL);

	//Abort if creation failed
	if(ItemList == NULL)
	{
		return FALSE;
	}

	//Prepare data for the column
	ListColumn.mask = LVCF_FMT	| LVCF_WIDTH | LVCF_TEXT;
	ListColumn.fmt = LVCFMT_LEFT;
	ListColumn.cx = 100;
	ListColumn.iSubItem = 0;

	//Create column 1
	ListColumn.pszText = TempString[0];
	ListColumn.cchTextMax = sizeof(TempString[0]) + 1;
	SendMessage(ItemList, LVM_INSERTCOLUMN, 0, (LPARAM)&ListColumn);

	//Create column 2
	ListColumn.pszText = TempString[1];
	ListColumn.cchTextMax = sizeof(TempString[1]) + 1;
	SendMessage(ItemList, LVM_INSERTCOLUMN, 1, (LPARAM)&ListColumn);

	//Makes the list visible
	ShowWindow(ItemList, SW_SHOW);

	//Sets the position of the window
	SetWindowPos(MainWindow, HWND_TOP, ((ScreenWidth - DEFAULTWIDTH) / 2), ((ScreenHeight - DEFAULTHEIGHT) / 2), DEFAULTWIDTH, DEFAULTHEIGHT, 0);

	//Disables the list (initially)
	EnableWindow(GetDlgItem(MainWindow, GroupList), FALSE);
	EnableWindow(ItemList, FALSE);
	EnableMenuItem(GetMenu(MainWindow), FileClose, MF_GRAYED);
	EnableMenuItem(GetMenu(MainWindow), FileSave, MF_GRAYED);
	EnableMenuItem(GetMenu(MainWindow), FileSaveAs, MF_GRAYED);
	EnableMenuItem(GetMenu(MainWindow), EditNew, MF_GRAYED);
	EnableMenuItem(GetMenu(MainWindow), EditCopy, MF_GRAYED);
	EnableMenuItem(GetMenu(MainWindow), EditRemove, MF_GRAYED);
	EnableMenuItem(GetMenu(MainWindow), EditSort, MF_GRAYED);

	//Updates the header
	UpdateHeader();

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Shutdown function
//+-----------------------------------------------------------------------------
VOID Shutdown()
{
	//Unloads the lists
	UnloadGroupList();
	UnloadItemList();
}


//+-----------------------------------------------------------------------------
//| Loads the group list, using the first element in the groups
//+-----------------------------------------------------------------------------
BOOL LoadGroupList(INT GroupNumber)
{
	//Data
	INT i;
	GROUP* TempGroup = NULL;
	ITEM* TempItem = NULL;
	CHAR* TempData = NULL;
	CHAR DummyData[] = "";

	//Unloads eventual earlier data
	UnloadGroupList();

	//Loop though all groups
	for(i = 1; i < Slk.GetNrOfGroups(); i++)
	{
		//Attempt to get the group
		TempGroup = Slk.GetGroup(i);

		//Abort if it failed
		if(TempGroup == NULL)
		{
			return FALSE;
		}

		//Get the first item
		TempItem = TempGroup->GetItem(0);

		//Abort if it failed
		if(TempItem == NULL)
		{
			return FALSE;
		}

		//Get the data
		TempData = TempItem->GetData();

		//Use dummy data if real data doesn't exist
		if(TempData == NULL)
		{
			TempData = DummyData;
		}

		//Add the group to the list
		SendMessage(GetDlgItem(MainWindow, GroupList), LB_ADDSTRING, 0, (LPARAM)TempData);
	}

	//Select the first item (or another one)
	SendMessage(GetDlgItem(MainWindow, GroupList), LB_SETCURSEL, GroupNumber, 0);

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Loads the item list from a specific group
//+-----------------------------------------------------------------------------
BOOL LoadItemList(INT GroupNumber)
{
	//Data
	INT i;
	LV_ITEM ListItem;
	GROUP* TempGroup = NULL;
	ITEM* TempItem = NULL;
	CHAR* TempData = NULL;
	CHAR DummyData[] = "";

	//Increase index since the first group specifies the names
	GroupNumber++;

	//Unloads eventual earlier data
	UnloadItemList();

	//Default data
	ListItem.mask = LVIF_TEXT;
	ListItem.state = 0;
	ListItem.stateMask = 0;
	ListItem.iImage = 0;
	ListItem.lParam = 0;

	//Attempt to get the group
	TempGroup = Slk.GetGroup(GroupNumber);

	//Abort if it failed
	if(TempGroup == NULL)
	{
		return FALSE;
	}

	//Loop though all items
	for(i = 0; i < TempGroup->GetNrOfItems(); i++)
	{
		//Get the item
		TempItem = TempGroup->GetItem(i);

		//Abort if it failed
		if(TempItem == NULL)
		{
			UnloadItemList();
			return FALSE;
		}

		//Get the name
		TempData = TempItem->GetName();

		//Use dummy data if real data doesn't exist
		if(TempData == NULL)
		{
			TempData = DummyData;
		}

		//Add the item to the list, and set the name
		ListItem.iItem = i;
		ListItem.iSubItem = 0;
		ListItem.pszText = TempData;
		ListItem.cchTextMax = strlen(TempData) + 1;
		SendMessage(ItemList, LVM_INSERTITEM, 0, (LPARAM)&ListItem);

		//Get the data
		TempData = TempItem->GetData();

		//Use dummy data if real data doesn't exist
		if(TempData == NULL)
		{
			TempData = DummyData;
		}

		//Set the data
		ListItem.iItem = i;
		ListItem.iSubItem = 1;
		ListItem.pszText = TempData;
		ListItem.cchTextMax = strlen(TempData) + 1;
		SendMessage(ItemList, LVM_SETITEMTEXT, i, (LPARAM)&ListItem);
	}

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Unloads the group list
//+-----------------------------------------------------------------------------
VOID UnloadGroupList()
{
	SendMessage(GetDlgItem(MainWindow, GroupList), LB_RESETCONTENT, 0, 0);
}


//+-----------------------------------------------------------------------------
//| Unloads the item list
//+-----------------------------------------------------------------------------
VOID UnloadItemList()
{
	SendMessage(ItemList, LVM_DELETEALLITEMS, 0, 0);
}


//+-----------------------------------------------------------------------------
//| Makes a new copy of a group
//+-----------------------------------------------------------------------------
BOOL CopyGroup(INT GroupNr, BOOL CopyData)
{
	//Data
	INT i;
	ITEM* TempItem = NULL;
	ITEM* NewItem = NULL;
	GROUP* TempGroup = NULL;
	GROUP* NewGroup = NULL;
	CONST CHAR* TempName = "Enter an ID";

	//Group numbers start at 1
	GroupNr++;

	//Let the user enter an ID
	ProperReturnValue = TRUE;
	if(DialogBoxParam(MainInstance, MAKEINTRESOURCE(NameDialog), MainWindow, (DLGPROC)NameMessageHandler, (LPARAM)TempName) != 1)
	{
		ProperReturnValue = FALSE;
		return FALSE;
	}

	//Get the group
	TempGroup = Slk.GetGroup(GroupNr);

	//Abort if no group was found
	if(TempGroup == NULL)
	{
		return FALSE;
	}

	//Create a new group
	NewGroup = new GROUP;

	//Abort if allocation failed
	if(NewGroup == NULL)
	{
		return FALSE;
	}

/* EDIT: Group name is never used

	//Copy group name
	if(NewGroup->SetName(TempString) == FALSE)
	{
		SafeDelete(TempGroup);
		return FALSE;
	}
	NewGroup->NameIsString = TempGroup->NameIsString;
*/

	//Duplicate all items
	for(i = 0; i < TempGroup->GetNrOfItems(); i++)
	{
		TempItem = TempGroup->GetItem(i);

		//Abort if item could not be found
		if(TempItem == NULL)
		{
			NewGroup->DeleteAllItems();
			SafeDelete(NewGroup);
			return FALSE;
		}

		//Create a new item
		NewItem = new ITEM;

		//Abort if allocation failed
		if(NewItem == NULL)
		{
			return FALSE;
		}

		//Copy item name
		if(NewItem->SetName(TempItem->GetName()) == FALSE)
		{
			NewGroup->DeleteAllItems();
			SafeDelete(NewGroup);
			return FALSE;
		}
		NewItem->NameIsString = TempItem->NameIsString;

		//Copy item data
		if(i == 0)
		{
			if(NewItem->SetData(TempString) == FALSE)
			{
				NewGroup->DeleteAllItems();
				SafeDelete(NewGroup);
				return FALSE;
			}
		}
		else if(CopyData == TRUE)
		{
			if(NewItem->SetData(TempItem->GetData()) == FALSE)
			{
				NewGroup->DeleteAllItems();
				SafeDelete(NewGroup);
				return FALSE;
			}
		}
		else
		{
			if(NewItem->SetData("") == FALSE)
			{
				NewGroup->DeleteAllItems();
				SafeDelete(NewGroup);
				return FALSE;
			}
		}
		NewItem->DataIsString = TempItem->DataIsString;

		//Add the item to the group
		if(NewGroup->AddItem(NewItem) == FALSE)
		{
			NewGroup->DeleteAllItems();
			SafeDelete(NewGroup);
			return FALSE;
		}
	}

	//Add the group
	if(Slk.AddGroup(NewGroup) == FALSE)
	{
		NewGroup->DeleteAllItems();
		SafeDelete(NewGroup);
		return FALSE;
	}

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Removes a specific group
//+-----------------------------------------------------------------------------
BOOL RemoveGroup(INT GroupNr)
{
	return Slk.DeleteGroup(GroupNr + 1);
}


//+-----------------------------------------------------------------------------
//| Retrieves a specific item in a specific group
//+-----------------------------------------------------------------------------
ITEM* GetItem(INT GroupNr, INT ItemNr)
{
	//Data
	ITEM* TempItem = NULL;
	GROUP* TempGroup = NULL;

	//Get the group
	TempGroup = Slk.GetGroup(GroupNr);

	//Abort if no group was found
	if(TempGroup == NULL)
	{
		return NULL;
	}

	//Get the item
	TempItem = TempGroup->GetItem(ItemNr);

	//Return the result
	return TempItem;
}


//+-----------------------------------------------------------------------------
//| Pick model message handler
//+-----------------------------------------------------------------------------
LRESULT PickModelMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam)
{
	//Data
	INT i = 0;

	//Select a proper event
	switch(Message)
	{
		//Control actions
		case WM_COMMAND:
			switch(LOWORD(wParam))
			{
				case PickModelOk:
					ProperReturnValue = TRUE;
					i = SendDlgItemMessage(Handle, PickModelList, LB_GETCURSEL, 0, 0);
					EndDialog(Handle, i);
					break;

				case PickModelCancel:
					ProperReturnValue = FALSE;
					EndDialog(Handle, 0);
					break;
			}
			break;

		//Loads all elements in the list
		case WM_INITDIALOG:
			SendDlgItemMessage(Handle, PickModelList, LB_RESETCONTENT, 0, 0);
			for(i = 0; i < NROFMODELS; i++)
			{
				SendDlgItemMessage(Handle, PickModelList, LB_ADDSTRING, 0, (LPARAM)StringModel[i]);
			}
			SendDlgItemMessage(Handle, PickModelList, LB_SETCURSEL, 0, 0);
			break;

		//Close dialog
		case WM_CLOSE:
			ProperReturnValue = FALSE;
			EndDialog(Handle, 0);
			break;
	}

	//Return
	return 0;
}


//+-----------------------------------------------------------------------------
//| Pick icon message handler
//+-----------------------------------------------------------------------------
LRESULT PickIconMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam)
{
	//Data
	INT i = 0;

	//Select a proper event
	switch(Message)
	{
		//Control actions
		case WM_COMMAND:
			switch(LOWORD(wParam))
			{
				case PickIconOk:
					ProperReturnValue = TRUE;
					i = SendDlgItemMessage(Handle, PickIconList, LB_GETCURSEL, 0, 0);
					EndDialog(Handle, i);
					break;

				case PickIconCancel:
					ProperReturnValue = FALSE;
					EndDialog(Handle, 0);
					break;
			}
			break;

		//Loads all elements in the list
		case WM_INITDIALOG:
			SendDlgItemMessage(Handle, PickIconList, LB_RESETCONTENT, 0, 0);
			for(i = 0; i < NROFICONS; i++)
			{
				SendDlgItemMessage(Handle, PickIconList, LB_ADDSTRING, 0, (LPARAM)StringIcon[i]);
			}
			SendDlgItemMessage(Handle, PickIconList, LB_SETCURSEL, 0, 0);
			break;

		//Close dialog
		case WM_CLOSE:
			ProperReturnValue = FALSE;
			EndDialog(Handle, 0);
			break;
	}

	//Return
	return 0;
}


//+-----------------------------------------------------------------------------
//| Pick target message handler
//+-----------------------------------------------------------------------------
LRESULT PickTargetMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam)
{
	//Select a proper event
	switch(Message)
	{
		//Control actions
		case WM_COMMAND:
			switch(LOWORD(wParam))
			{
				case PickTargetOk:
					ProperReturnValue = TRUE;
					GetTargetFlags(Handle);
					EndDialog(Handle, 0);
					break;

				case PickTargetCancel:
					ProperReturnValue = FALSE;
					EndDialog(Handle, 0);
					break;
			}
			break;

		//Loads all elements in the list
		case WM_INITDIALOG:
			break;

		//Close dialog
		case WM_CLOSE:
			ProperReturnValue = FALSE;
			EndDialog(Handle, 0);
			break;
	}

	//Return
	return 0;
}


//+-----------------------------------------------------------------------------
//| Edit field message handler
//+-----------------------------------------------------------------------------
LRESULT EditMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam)
{
	//Data
	INT i = 0;
	CHAR Buffer[MAXBUFFERSIZE + 1];

	//Select a proper event
	switch(Message)
	{
		//Control actions
		case WM_COMMAND:
			switch(LOWORD(wParam))
			{
				case EditOk:
					GetDlgItemText(Handle, EditText, Buffer, MAXBUFFERSIZE);
					ItemToBeModified->SetData(Buffer);
					EndDialog(Handle, 1);
					break;

				case EditCancel:
					EndDialog(Handle, 0);
					break;

				case EditModel:
					i = DialogBoxParam(MainInstance, MAKEINTRESOURCE(PickModelDialog), Handle, (DLGPROC)PickModelMessageHandler, i);
					if(ProperReturnValue == TRUE)
					{
						SetDlgItemText(Handle, EditText, StringModel[i]);
					}
					SetFocus(GetDlgItem(Handle, EditText));
					SendDlgItemMessage(Handle, EditText, EM_SETSEL, 0, -1);
					break;

				case EditIcon:
					i = DialogBoxParam(MainInstance, MAKEINTRESOURCE(PickIconDialog), Handle, (DLGPROC)PickIconMessageHandler, i);
					if(ProperReturnValue == TRUE)
					{
						SetDlgItemText(Handle, EditText, StringIcon[i]);
					}
					SetFocus(GetDlgItem(Handle, EditText));
					SendDlgItemMessage(Handle, EditText, EM_SETSEL, 0, -1);
					break;

				case EditTarget:
					i = DialogBoxParam(MainInstance, MAKEINTRESOURCE(PickTargetDialog), Handle, (DLGPROC)PickTargetMessageHandler, i);
					if(ProperReturnValue == TRUE)
					{
						SetDlgItemText(Handle, EditText, TempString);
					}
					SetFocus(GetDlgItem(Handle, EditText));
					SendDlgItemMessage(Handle, EditText, EM_SETSEL, 0, -1);
					break;
			}
			break;

		//Sets a default value
		case WM_INITDIALOG:
			SetDlgItemText(Handle, EditText, (CONST CHAR*)lParam);
			SetFocus(GetDlgItem(Handle, EditText));
			SendDlgItemMessage(Handle, EditText, EM_SETSEL, 0, -1);
			break;

		//Close dialog
		case WM_CLOSE:
			EndDialog(Handle, 0);
			break;
	}

	//Return
	return 0;
}


//+-----------------------------------------------------------------------------
//| Edit field message handler
//+-----------------------------------------------------------------------------
LRESULT NameMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam)
{
	//Select a proper event
	switch(Message)
	{
		//Control actions
		case WM_COMMAND:
			switch(LOWORD(wParam))
			{
				case NameOk:
					GetDlgItemText(Handle, NameEdit, TempString, MAXBUFFERSIZE);
					if(strlen(TempString) > 0)
					{
						EndDialog(Handle, 1);
					}
					else
					{
						MessageBox(Handle, "You must specify an ID!", "Message", MB_ICONERROR);
					}
					break;

				case NameCancel:
					EndDialog(Handle, 0);
					break;
			}
			break;

		//Sets a default value
		case WM_INITDIALOG:
			SetDlgItemText(Handle, NameEdit, (CONST CHAR*)lParam);
			SetFocus(GetDlgItem(Handle, NameEdit));
			SendDlgItemMessage(Handle, NameEdit, EM_SETSEL, 0, -1);
			break;

		//Close dialog
		case WM_CLOSE:
			EndDialog(Handle, 0);
			break;
	}

	//Return
	return 0;
}


//+-----------------------------------------------------------------------------
//| Sort message handler
//+-----------------------------------------------------------------------------
/*
LRESULT SortMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam)
{
	//Data
	INT CurrentGroup = *((INT*)lParam);

	//Select a proper event
	switch(Message)
	{
		//Control actions
		case WM_COMMAND:
			switch(LOWORD(wParam))
			{
				case 9999:
					UnloadGroupList();
					UnloadItemList();
					UpdateHeader();
					if(Slk.SortByName() == FALSE)
					{
						EndDialog(Handle, 0);
					}
					FileSaved = FALSE;
					LoadGroupList(CurrentGroup);
					LoadItemList(CurrentGroup);
					UpdateHeader();
					EndDialog(Handle, 1);
					break;
			}
			break;

		//Sets a default value
		case WM_INITDIALOG:
			UnloadGroupList();
			UnloadItemList();
			UpdateHeader();
			if(Slk.SortByName() == FALSE)
			{
				EndDialog(Handle, 0);
			}
			FileSaved = FALSE;
			LoadGroupList(CurrentGroup);
			LoadItemList(CurrentGroup);
			UpdateHeader();
			EndDialog(Handle, 1);
			break;

		//Close dialog
		case WM_CLOSE:
			EndDialog(Handle, 0);
			break;
	}

	//Return
	return 0;
}
*/

//+-----------------------------------------------------------------------------
//| Windows message handler
//+-----------------------------------------------------------------------------
LRESULT MainMessageHandler(HWND Handle, UINT Message, WPARAM wParam, LPARAM lParam)
{
	//Data
	INT i;
	INT TempInt;
	WINDOWPOS* WindowPosition;
	INT TempWidth;
	INT TempWidth2;
	INT TempHeight;
	POINT MousePosition;
	RECT ListRect;
	RECT ItemRect;
	NMHDR* NotificationMessage;
	BOOL Looping = TRUE;
	ITEM* TempItem;
	INT CurrentGroup = 0;
	BOOL Proceed = FALSE;
	BOOL MinorError;

	//Select a proper event
	switch(Message)
	{
		//Control actions
		case WM_COMMAND:
			switch(LOWORD(wParam))
			{
				case GroupList:
					switch(HIWORD(wParam))
					{
						case LBN_SELCHANGE:
							TempInt = SendDlgItemMessage(Handle, GroupList, LB_GETCURSEL, 0, 0);
							if(TempInt != LB_ERR)
							{
								LoadItemList(TempInt);
							}
							SetFocus(ItemList);
							break;
					}
					break;

				case FileNew:
					//
					// Currently disabled, since you cannot add or remove groups/items
					//
					break;

				case FileClose:
					if((FileLoaded == TRUE) && (FileSaved == FALSE))
					{
						i = MessageBox(Handle, "File has not been saved. Save now?", "Message", MB_YESNOCANCEL);
						if(i == IDYES)
						{
							if(FirstTimeSaving == TRUE)
							{
								strcpy(TempString, CurrentFileName);
								if(DialogSaveAs() == TRUE)
								{
									strcpy(CurrentFileName, TempString);
									if(Slk.SaveFile(CurrentFileName) == FALSE)
									{
										Proceed = FALSE;
										MessageBox(Handle, "Unable to save the file!", "Message", MB_ICONERROR);
									}
									else
									{
										FileSaved = TRUE;
										FirstTimeSaving = FALSE;
										Proceed = TRUE;
										UpdateHeader();
									}
								}
								else
								{
									Proceed = FALSE;
								}
							}
							else
							{
								if(Slk.SaveFile(CurrentFileName) == FALSE)
								{
									Proceed = FALSE;
									MessageBox(Handle, "Unable to save the file!", "Message", MB_ICONERROR);
								}
								else
								{
									FileSaved = TRUE;
									FirstTimeSaving = FALSE;
									Proceed = TRUE;
									UpdateHeader();
								}
							}
						}
						else if(i == IDNO)
						{
							Proceed = TRUE;
						}
						else
						{
							Proceed = FALSE;
						}
					}
					else
					{
						Proceed = TRUE;
					}
					if(Proceed == TRUE)
					{
						FileSaved = FALSE;
						FileLoaded = FALSE;
						FirstTimeSaving = TRUE;
						UnloadItemList();
						UnloadGroupList();
						EnableWindow(GetDlgItem(Handle, GroupList), FALSE);
						EnableWindow(ItemList, FALSE);
						EnableMenuItem(GetMenu(Handle), FileClose, MF_GRAYED);
						EnableMenuItem(GetMenu(Handle), FileSave, MF_GRAYED);
						EnableMenuItem(GetMenu(Handle), FileSaveAs, MF_GRAYED);
						EnableMenuItem(GetMenu(Handle), EditNew, MF_GRAYED);
						EnableMenuItem(GetMenu(Handle), EditCopy, MF_GRAYED);
						EnableMenuItem(GetMenu(Handle), EditRemove, MF_GRAYED);
						EnableMenuItem(GetMenu(Handle), EditSort, MF_GRAYED);
						UpdateHeader();
					}
					break;

				case FileOpen:
					if((FileLoaded == TRUE) && (FileSaved == FALSE))
					{
						i = MessageBox(Handle, "File has not been saved. Save now?", "Message", MB_YESNOCANCEL);
						if(i == IDYES)
						{
							if(FirstTimeSaving == TRUE)
							{
								if(DialogSaveAs() == TRUE)
								{
									strcpy(CurrentFileName, TempString);
									if(Slk.SaveFile(CurrentFileName) == FALSE)
									{
										Proceed = FALSE;
										MessageBox(Handle, "Unable to save the file!", "Message", MB_ICONERROR);
									}
									else
									{
										FileSaved = TRUE;
										FirstTimeSaving = FALSE;
										Proceed = TRUE;
										UpdateHeader();
									}
								}
								else
								{
									Proceed = FALSE;
								}
							}
							else
							{
								if(Slk.SaveFile(CurrentFileName) == FALSE)
								{
									Proceed = FALSE;
									MessageBox(Handle, "Unable to save the file!", "Message", MB_ICONERROR);
								}
								else
								{
									FileSaved = TRUE;
									FirstTimeSaving = FALSE;
									Proceed = TRUE;
									UpdateHeader();
								}
							}
						}
						else if(i == IDNO)
						{
							Proceed = TRUE;
						}
						else
						{
							Proceed = FALSE;
						}
					}
					else
					{
						Proceed = TRUE;
					}
					if(Proceed == TRUE)
					{
						strcpy(TempString, CurrentFileName);
						if(DialogOpen() == TRUE)
						{
							strcpy(CurrentFileName, TempString);
							UnloadItemList();
							UnloadGroupList();
							if(Slk.LoadFile(CurrentFileName) == FALSE)
							{
								UnloadItemList();
								UnloadGroupList();
								EnableWindow(GetDlgItem(Handle, GroupList), FALSE);
								EnableWindow(ItemList, FALSE);
								EnableMenuItem(GetMenu(Handle), FileClose, MF_GRAYED);
								EnableMenuItem(GetMenu(Handle), FileSave, MF_GRAYED);
								EnableMenuItem(GetMenu(Handle), FileSaveAs, MF_GRAYED);
								EnableMenuItem(GetMenu(Handle), EditNew, MF_GRAYED);
								EnableMenuItem(GetMenu(Handle), EditCopy, MF_GRAYED);
								EnableMenuItem(GetMenu(Handle), EditRemove, MF_GRAYED);
								EnableMenuItem(GetMenu(Handle), EditSort, MF_GRAYED);
								FileLoaded = FALSE;
								FileSaved = FALSE;
								FirstTimeSaving = TRUE;
								MessageBox(Handle, "Unable to load the file!", "Message", MB_ICONERROR);
								UpdateHeader();
							}
							else
							{
								LoadGroupList();
								LoadItemList(0);
								EnableWindow(GetDlgItem(Handle, GroupList), TRUE);
								EnableWindow(ItemList, TRUE);
								EnableMenuItem(GetMenu(Handle), FileClose, MF_ENABLED);
								EnableMenuItem(GetMenu(Handle), FileSave, MF_ENABLED);
								EnableMenuItem(GetMenu(Handle), FileSaveAs, MF_ENABLED);
								EnableMenuItem(GetMenu(Handle), EditNew, MF_ENABLED);
								EnableMenuItem(GetMenu(Handle), EditCopy, MF_ENABLED);
								EnableMenuItem(GetMenu(Handle), EditRemove, MF_ENABLED);
								EnableMenuItem(GetMenu(Handle), EditSort, MF_ENABLED);
								FileLoaded = TRUE;
								FileSaved = TRUE;
								FirstTimeSaving = FALSE;
								UpdateHeader();
								SetFocus(ItemList);
							}
						}
					}
					break;

				case FileSave:
					if(FileLoaded == TRUE)
					{
						if(FirstTimeSaving == TRUE)
						{
							strcpy(TempString, CurrentFileName);
							if(DialogSaveAs() == TRUE)
							{
								strcpy(CurrentFileName, TempString);
								if(Slk.SaveFile(CurrentFileName) == FALSE)
								{
									MessageBox(Handle, "Unable to save the file!", "Message", MB_ICONERROR);
								}
								else
								{
									FileSaved = TRUE;
									FirstTimeSaving = FALSE;
									UpdateHeader();
								}
							}
						}
						else
						{
							if(Slk.SaveFile(CurrentFileName) == FALSE)
							{
								MessageBox(Handle, "Unable to save the file!", "Message", MB_ICONERROR);
							}
							else
							{
								FileSaved = TRUE;
								FirstTimeSaving = FALSE;
								UpdateHeader();
							}
						}
					}
					break;

				case FileSaveAs:
					if(FileLoaded == TRUE)
					{
						strcpy(TempString, CurrentFileName);
						if(DialogSaveAs() == TRUE)
						{
							strcpy(CurrentFileName, TempString);
							if(Slk.SaveFile(CurrentFileName) == FALSE)
							{
								MessageBox(Handle, "Unable to save the file!", "Message", MB_ICONERROR);
							}
							else
							{
								FileSaved = TRUE;
								FirstTimeSaving = FALSE;
								UpdateHeader();
							}
						}
					}
					break;

				case FileExit:
					SendMessage(Handle, WM_CLOSE, 0 ,0);
					break;

				case EditNew:
					if(CopyGroup(-1, FALSE) == TRUE)
					{
						FileSaved = FALSE;
						CurrentGroup = Slk.GetNrOfGroups() - 2;
						LoadGroupList(CurrentGroup);
						LoadItemList(CurrentGroup);
						UpdateHeader();
					}
					else
					{
						if(ProperReturnValue == TRUE)
						{
							MessageBox(Handle, "Unable to create new group!", "Message", MB_ICONERROR);
						}
					}
					break;

				case EditCopy:
					CurrentGroup = SendDlgItemMessage(Handle, GroupList, LB_GETCURSEL, 0, 0);
					if((CurrentGroup != LB_ERR) && (CopyGroup(CurrentGroup, TRUE) == TRUE))
					{
						FileSaved = FALSE;
						CurrentGroup = Slk.GetNrOfGroups() - 2;
						LoadGroupList(CurrentGroup);
						LoadItemList(CurrentGroup);
						UpdateHeader();
					}
					else
					{
						if(ProperReturnValue == TRUE)
						{
							MessageBox(Handle, "Unable to copy group!", "Message", MB_ICONERROR);
						}
					}
					break;

				case EditRemove:
					CurrentGroup = SendDlgItemMessage(Handle, GroupList, LB_GETCURSEL, 0, 0);
					if((CurrentGroup != LB_ERR) && (RemoveGroup(CurrentGroup) == TRUE))
					{
						CurrentGroup--;
						if(CurrentGroup < 0) CurrentGroup = 0;
						FileSaved = FALSE;
						LoadGroupList(CurrentGroup);
						LoadItemList(CurrentGroup);
						UpdateHeader();
					}
					else
					{
						MessageBox(Handle, "Unable to remove group!", "Message", MB_ICONERROR);
					}
					break;

				case EditSort:
					UnloadGroupList();
					UnloadItemList();
					UpdateWindow(Handle);
					if(Slk.SortByName(&MinorError) == FALSE)
					{
						if(MinorError == FALSE)
						{
							MessageBox(Handle, "Failed to sort the list!", "Message", MB_ICONERROR);
						}
					}
					if(MinorError == TRUE)
					{
						MessageBox(Handle, "A minor sorting error occured!\nThis could be due to missing data in the ID field.\nThe rest of the list is sorted though!", "Message", MB_ICONERROR);
					}
					FileSaved = FALSE;
					LoadGroupList(CurrentGroup);
					LoadItemList(CurrentGroup);
					UpdateHeader();
					break;

				case HelpAbout:
					MessageBox(Handle, "War3SlkEdit v1.05\nMade by Magos (Magnus Östberg) 2003\nMagnusOstberg@Hotmail.com\nhttp://www20.brinkster.com/magos818/", "About", MB_ICONINFORMATION);
					break;
			}
			break;

		//Notify the main window when the user clicks the left mouse button
		case WM_NOTIFY:
			if(wParam == ItemListNotify)
			{
				NotificationMessage = (NMHDR*)lParam;
				if(NotificationMessage->code == NM_CLICK)
				{
					//Get the mouse position
					GetCursorPos(&MousePosition);

					//Get the width of the two columns
					TempWidth = SendMessage(ItemList, LVM_GETCOLUMNWIDTH, 0, 0);

					//Get the item list position and dimension
					GetWindowRect(ItemList, &ListRect);
					//ListRect.left += TempWidth;

					//Check if the mouse is inside the correct column
					if((MousePosition.x >= ListRect.left) && (MousePosition.x < ListRect.right))
					{
						if((MousePosition.y >= ListRect.top) &&(MousePosition.y < ListRect.bottom))
						{
							//Retrieve the first item index
							i = SendMessage(ItemList, LVM_GETTOPINDEX, 0, 0);

							//Retrieve the number of items
							TempWidth2 = SendMessage(ItemList, LVM_GETITEMCOUNT, 0, 0);

							//Retrieve the last item index
							TempHeight = i + SendMessage(ItemList, LVM_GETCOUNTPERPAGE, 0, 0);

							//Loop though all items to see which one the mouse pointer hovers over
							Looping = TRUE;
							while((i < TempHeight) && (i < TempWidth2) && (Looping == TRUE))
							{
								//Retrieve the current item's rect
								ItemRect.left = LVIR_BOUNDS;
								SendMessage(ItemList, LVM_GETITEMRECT, i, (LPARAM)&ItemRect);
								TempWidth = (ItemRect.bottom - ItemRect.top);
								ItemRect.left += ListRect.left;
								ItemRect.top += ListRect.top;
								ItemRect.right += ListRect.left;
								ItemRect.bottom += ListRect.top;

								//Check if this is the correct item
								if((MousePosition.x >= ItemRect.left) && (MousePosition.x < ItemRect.right))
								{
									if((MousePosition.y >= ItemRect.top) &&(MousePosition.y < ItemRect.bottom))
									{
										Looping = FALSE;
									}
									else
									{
										i++;
									}
								}
								else
								{
									i++;
								}
							}

							//An item was found
							if(Looping == FALSE)
							{
								CurrentGroup = SendDlgItemMessage(Handle, GroupList, LB_GETCURSEL, 0, 0);
								TempItem = GetItem(CurrentGroup + 1, i);
								if(TempItem != NULL)
								{
									ItemToBeModified = TempItem;
									if(DialogBoxParam(MainInstance, MAKEINTRESOURCE(EditDialog), Handle, (DLGPROC)EditMessageHandler, (LPARAM)TempItem->GetData()) == 1)
									{
										FileSaved = FALSE;
										LoadGroupList(CurrentGroup);
										LoadItemList(CurrentGroup);
										UpdateHeader();
										//SendMessage(ItemList, LVM_SCROLL, 0, (TempWidth * ));
									}
								}
							}
						}
					}
				}
			}
			break;

		//Prevents the window from being too small
		case WM_WINDOWPOSCHANGING:
			WindowPosition = (WINDOWPOS*)lParam;
			if(!(WindowPosition->flags & SWP_NOSIZE))
			{
				//Prevent too small windows
				if(WindowPosition->cx < MINWINDOWWIDTH) WindowPosition->cx = MINWINDOWWIDTH;
				if(WindowPosition->cy < MINWINDOWHEIGHT) WindowPosition->cy = MINWINDOWHEIGHT;

				//Calculate the true width and height
				TempWidth = (WindowPosition->cx - OFFSETWIDTH);
				TempHeight = (WindowPosition->cy - OFFSETHEIGHT);
				TempWidth2 = (TempWidth / 3);
				if(TempWidth2 > 250) TempWidth2 = 250;

				//Fix control sizes
				//MoveWindow(GetDlgItem(Handle, GroupList), 0, 0, (WindowPosition->cx - OFFSETWIDTH), (WindowPosition->cy - OFFSETHEIGHT), TRUE);
				//MoveWindow(ItemList, 0, 0, (WindowPosition->cx - OFFSETWIDTH), (WindowPosition->cy - OFFSETHEIGHT), TRUE);
				MoveWindow(GetDlgItem(Handle, GroupList), 0, 0, TempWidth2, TempHeight, TRUE);
				MoveWindow(ItemList, TempWidth2 + 5, 0, TempWidth - TempWidth2 - 5, TempHeight - 1, TRUE);
				SendMessage(ItemList, LVM_SETCOLUMNWIDTH, 0, (((TempWidth - TempWidth2) / 2) - 11));
				SendMessage(ItemList, LVM_SETCOLUMNWIDTH, 1, (((TempWidth - TempWidth2) / 2) - 11));
			}
			break;

		//Destroy the window when the user presses the X
		case WM_CLOSE:
			if((FileLoaded == TRUE) && (FileSaved == FALSE))
			{
				i = MessageBox(Handle, "File has not been saved. Save now?", "Message", MB_YESNOCANCEL);
				if(i == IDYES)
				{
					if(FirstTimeSaving == TRUE)
					{
						strcpy(TempString, CurrentFileName);
						if(DialogSaveAs() == TRUE)
						{
							strcpy(CurrentFileName, TempString);
							if(Slk.SaveFile(CurrentFileName) == FALSE)
							{
								Proceed = FALSE;
								MessageBox(Handle, "Unable to save the file!", "Message", MB_ICONERROR);
							}
							else
							{
								FileSaved = TRUE;
								FirstTimeSaving = FALSE;
								Proceed = TRUE;
							}
						}
						else
						{
							Proceed = FALSE;
						}
					}
					else
					{
						if(Slk.SaveFile(CurrentFileName) == FALSE)
						{
							Proceed = FALSE;
							MessageBox(Handle, "Unable to save the file!", "Message", MB_ICONERROR);
						}
						else
						{
							FileSaved = TRUE;
							FirstTimeSaving = FALSE;
							Proceed = TRUE;
						}
					}
				}
				else if(i == IDNO)
				{
					Proceed = TRUE;
				}
				else
				{
					Proceed = FALSE;
				}
			}
			else
			{
				Proceed = TRUE;
			}
			if(Proceed == TRUE)
			{
				UnloadItemList();
				UnloadGroupList();
				EnableWindow(GetDlgItem(Handle, GroupList), FALSE);
				EnableWindow(ItemList, FALSE);
				EnableMenuItem(GetMenu(Handle), FileClose, MF_GRAYED);
				EnableMenuItem(GetMenu(Handle), FileSave, MF_GRAYED);
				EnableMenuItem(GetMenu(Handle), FileSaveAs, MF_GRAYED);
				EnableMenuItem(GetMenu(Handle), EditNew, MF_GRAYED);
				EnableMenuItem(GetMenu(Handle), EditCopy, MF_GRAYED);
				EnableMenuItem(GetMenu(Handle), EditRemove, MF_GRAYED);
				EnableMenuItem(GetMenu(Handle), EditSort, MF_GRAYED);
				DestroyWindow(Handle);
			}
			break;

		//Exit the program when the window has been destroyed
		case WM_DESTROY:
			PostQuitMessage(0);
			break;
	}

	//Return
	return 0;
}


//+-----------------------------------------------------------------------------
//| Windows main function
//+-----------------------------------------------------------------------------
INT WINAPI WinMain(HINSTANCE CurInst, HINSTANCE PrevInst, LPSTR Args, INT Show)
{
	//Data
	MSG Message;

	//Store passed data
	MainInstance = CurInst;

	//Setup
	if(Setup() == FALSE)
	{
		Shutdown();
		return 0;
	}

	//Load the file on startup
	if(strcmp(Args, "") != 0)
	{
		strcpy(CurrentFileName, Args);
		FixArgName(CurrentFileName);
		strcpy(TempString, CurrentFileName);
		UnloadItemList();
		UnloadGroupList();
		if(Slk.LoadFile(CurrentFileName) == FALSE)
		{
			UnloadItemList();
			UnloadGroupList();
			EnableWindow(GetDlgItem(MainWindow, GroupList), FALSE);
			EnableWindow(ItemList, FALSE);
			EnableMenuItem(GetMenu(MainWindow), FileClose, MF_GRAYED);
			EnableMenuItem(GetMenu(MainWindow), FileSave, MF_GRAYED);
			EnableMenuItem(GetMenu(MainWindow), FileSaveAs, MF_GRAYED);
			EnableMenuItem(GetMenu(MainWindow), EditNew, MF_GRAYED);
			EnableMenuItem(GetMenu(MainWindow), EditCopy, MF_GRAYED);
			EnableMenuItem(GetMenu(MainWindow), EditRemove, MF_GRAYED);
			EnableMenuItem(GetMenu(MainWindow), EditSort, MF_GRAYED);
			FileLoaded = FALSE;
			FileSaved = FALSE;
			FirstTimeSaving = TRUE;
			MessageBox(MainWindow, "Unable to load the file!", "Message", MB_ICONERROR);
			UpdateHeader();
		}
		else
		{
			LoadGroupList();
			LoadItemList(0);
			EnableWindow(GetDlgItem(MainWindow, GroupList), TRUE);
			EnableWindow(ItemList, TRUE);
			EnableMenuItem(GetMenu(MainWindow), FileClose, MF_ENABLED);
			EnableMenuItem(GetMenu(MainWindow), FileSave, MF_ENABLED);
			EnableMenuItem(GetMenu(MainWindow), FileSaveAs, MF_ENABLED);
			EnableMenuItem(GetMenu(MainWindow), EditNew, MF_ENABLED);
			EnableMenuItem(GetMenu(MainWindow), EditCopy, MF_ENABLED);
			EnableMenuItem(GetMenu(MainWindow), EditRemove, MF_ENABLED);
			EnableMenuItem(GetMenu(MainWindow), EditSort, MF_ENABLED);
			FileLoaded = TRUE;
			FileSaved = TRUE;
			FirstTimeSaving = FALSE;
			UpdateHeader();
			SetFocus(ItemList);
		}
	}

	//Main message loop
	while(GetMessage(&Message, NULL, 0, 0))
	{
		TranslateMessage(&Message);
		DispatchMessage(&Message);
	}

	//Shutdown
	Shutdown();

	//Exit
	return 0;
}
