#ifndef _MAGOS_SLK_H_
#define _MAGOS_SLK_H_


//+-----------------------------------------------------------------------------
//| Item class
//+-----------------------------------------------------------------------------
class ITEM
{
	public:
		//Constructor/Destructor
		explicit ITEM();
		~ITEM();

		//Name methods
		BOOL SetName(CONST CHAR* NewName);
		CHAR* GetName();

		//Data methods
		BOOL AddData(CONST CHAR* NewData);
		BOOL SetData(CONST CHAR* NewData);
		CHAR* GetData();

		//String methods and data
		VOID ConvertDataFromString();
		VOID ConvertDataToString();
		VOID ConvertNameFromString();
		VOID ConvertNameToString();
		BOOL DataIsString;
		BOOL NameIsString;

	private:
		//Data
		CHAR* Name;
		CHAR* Data;
};


//+-----------------------------------------------------------------------------
//| Groups class
//+-----------------------------------------------------------------------------
class GROUP
{
	public:
		//Constructor/Destructor
		explicit GROUP();
		~GROUP();

		//Name methods
		BOOL SetName(CONST CHAR* NewName);
		CHAR* GetName();

		//Item methods
		BOOL AddItem(ITEM* NewItem);
		ITEM* GetItem(INT Nr);
		INT GetNrOfItems();
		INT FindItem(CONST CHAR* ItemName);
		INT FindData(CONST CHAR* DataName);
		BOOL DeleteItem(INT Nr);
		VOID DeleteAllItems();

		//String methods and data
		VOID ConvertNameFromString();
		VOID ConvertNameToString();
		BOOL NameIsString;

	private:
		//Data
		CHAR* Name;
		MLinkedList<ITEM> Item;
};


//+-----------------------------------------------------------------------------
//| Slk class
//+-----------------------------------------------------------------------------
class SLK
{
	public:
		//Constructor/Destructor
		explicit SLK();
		~SLK();

		//Name methods
		BOOL SetName(CONST CHAR* NewName);
		CHAR* GetName();

		//Group methods
		BOOL AddGroup(GROUP* NewGroup);
		GROUP* GetGroup(INT Nr);
		GROUP* GetDescription();
		INT GetNrOfGroups();
		INT FindGroup(CONST CHAR* GroupName);
		BOOL DeleteGroup(INT Nr);
		VOID DeleteAllGroups();

		//File methods
		BOOL LoadFile(CONST CHAR* FileName);
		BOOL SaveFile(CONST CHAR* FileName);

		//String methods
		VOID ConvertFromString();
		VOID ConvertToString();

		//Sort methods
		BOOL SortByName(BOOL* MinorError = NULL);

	private:
		//Data
		CHAR* Name;
		GROUP Description;
		MLinkedList<GROUP> Group;

		//File data
		CHAR* Data;
		INT Length;

		//Conversion methods
		INT ConvertStringToInteger(CONST CHAR* String);

		//Specific methods
		BOOL SetDimension(INT NewWidth, INT NewHeight);
		BOOL CompareStrings(CONST CHAR* StartString1, CONST CHAR* EndString1, CONST CHAR* String2);
		BOOL CopyString(CONST CHAR* StartString, CONST CHAR* EndString, CHAR* Buffer);
};


#endif
