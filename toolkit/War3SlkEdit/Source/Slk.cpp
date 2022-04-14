//+-----------------------------------------------------------------------------
//| Included files
//+-----------------------------------------------------------------------------
#include "IncludeAll.h"


//+-----------------------------------------------------------------------------
//| Constructor
//+-----------------------------------------------------------------------------
ITEM::ITEM()
{
	Nullify(Name);
	Nullify(Data);
	DataIsString = FALSE;
	NameIsString = FALSE;
}


//+-----------------------------------------------------------------------------
//| Destructor
//+-----------------------------------------------------------------------------
ITEM::~ITEM()
{
	SetName(NULL);
	SetData(NULL);
}


//+-----------------------------------------------------------------------------
//| Sets a new name
//+-----------------------------------------------------------------------------
BOOL ITEM::SetName(CONST CHAR* NewName)
{
	//Deallocate the old name
	SafeArrayDelete(Name);

	//Abort if no name should be set
	if(NewName == NULL)
	{
		return TRUE;
	}

	//Allocate memory for the new name
	Name = new CHAR[strlen(NewName) + 1];

	//Abort if allocation failed
	if(Name == NULL)
	{
		return FALSE;
	}

	//Copy the string
	strcpy(Name, NewName);

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Returns the name
//+-----------------------------------------------------------------------------
CHAR* ITEM::GetName()
{
	return Name;
}


//+-----------------------------------------------------------------------------
//| Adds new data to the existing data
//+-----------------------------------------------------------------------------
BOOL ITEM::AddData(CONST CHAR* NewData)
{
	//Data
	CHAR* TempPointer = NULL;

	//Run SetData() if no data exists
	if(Data == NULL)
	{
		return SetData(NewData);
	}

	//Abort if no data should be set
	if(NewData == NULL)
	{
		return TRUE;
	}

	//Allocate memory for the new data
	TempPointer = new CHAR[strlen(Data) + strlen(NewData) + 1];

	//Abort if allocation failed
	if(TempPointer == NULL)
	{
		return FALSE;
	}

	//Copy the string
	strcpy(TempPointer, Data);
	strcat(TempPointer, NewData);

	//Deallocate the old data
	SafeArrayDelete(Data);

	//Update the pointers
	Data = TempPointer;

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Sets a new data
//+-----------------------------------------------------------------------------
BOOL ITEM::SetData(CONST CHAR* NewData)
{
	//Deallocate the old data
	SafeArrayDelete(Data);

	//Abort if no data should be set
	if(NewData == NULL)
	{
		return TRUE;
	}

	//Allocate memory for the new data
	Data = new CHAR[strlen(NewData) + 1];

	//Abort if allocation failed
	if(Data == NULL)
	{
		return FALSE;
	}

	//Copy the string
	strcpy(Data, NewData);

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Returns the data
//+-----------------------------------------------------------------------------
CHAR* ITEM::GetData()
{
	return Data;
}


//+-----------------------------------------------------------------------------
//| Eventually removes surrounding " "
//+-----------------------------------------------------------------------------
VOID ITEM::ConvertDataFromString()
{
	//Data
	INT i;
	INT TempLength;
	CHAR* TempData = NULL;

	//Abort if no data exists
	if(Data == NULL)
	{
		return;
	}

	//Abort if the length is too small
	TempLength = strlen(Data);
	if(TempLength < 2)
	{
		return;
	}

	//Abort if it's not a valid string
	if((Data[0] != '\"') || (Data[TempLength - 1] != '\"'))
	{
		return;
	}

	//Allocate memory for the new data
	TempData = new CHAR[TempLength - 1];

	//Abort if allocation failed
	if(TempData == NULL)
	{
		return;
	}

	//Remove the " "
	for(i = 0; i < (TempLength - 2); i++)
	{
		TempData[i] = Data[i + 1];
	}
	TempData[TempLength - 2] = '\0';

	//Set the new data as the real data
	delete[] Data;
	Data = TempData;
	DataIsString = TRUE;
}

//+-----------------------------------------------------------------------------
//| Eventually adds surrounding " "
//+-----------------------------------------------------------------------------
VOID ITEM::ConvertDataToString()
{
	//Data
	INT i;
	INT TempLength;
	CHAR* TempData = NULL;

	//Abort if no data exists
	if(Data == NULL)
	{
		return;
	}

	//Don't add if it's not a string
	if(DataIsString == FALSE)
	{
		return;
	}

	//Allocate memory for the new data
	TempLength = strlen(Data);
	TempData = new CHAR[TempLength + 3];

	//Abort if allocation failed
	if(TempData == NULL)
	{
		return;
	}

	//Add the " "
	for(i = 0; i < TempLength; i++)
	{
		TempData[i + 1] = Data[i];
	}
	TempData[0] = '\"';
	TempData[TempLength + 1] = '\"';
	TempData[TempLength + 2] = '\0';

	//Set the new data as the real data
	delete[] Data;
	Data = TempData;
	DataIsString = FALSE;
}


//+-----------------------------------------------------------------------------
//| Eventually removes surrounding " "
//+-----------------------------------------------------------------------------
VOID ITEM::ConvertNameFromString()
{
	//Data
	INT i;
	INT TempLength;
	CHAR* TempName = NULL;

	//Abort if no name exists
	if(Name == NULL)
	{
		return;
	}

	//Abort if the length is too small
	TempLength = strlen(Name);
	if(TempLength < 2)
	{
		return;
	}

	//Abort if it's not a valid string
	if((Name[0] != '\"') || (Name[TempLength - 1] != '\"'))
	{
		return;
	}

	//Allocate memory for the new name
	TempName = new CHAR[TempLength - 1];

	//Abort if allocation failed
	if(TempName == NULL)
	{
		return;
	}

	//Remove the " "
	for(i = 0; i < (TempLength - 2); i++)
	{
		TempName[i] = Name[i + 1];
	}
	TempName[TempLength - 2] = '\0';

	//Set the new data as the real data
	delete[] Name;
	Name = TempName;
	NameIsString = TRUE;
}

//+-----------------------------------------------------------------------------
//| Eventually adds surrounding " "
//+-----------------------------------------------------------------------------
VOID ITEM::ConvertNameToString()
{
	//Data
	INT i;
	INT TempLength;
	CHAR* TempName = NULL;

	//Abort if no data exists
	if(Name == NULL)
	{
		return;
	}

	//Don't add if it's not a string
	if(NameIsString == FALSE)
	{
		return;
	}

	//Allocate memory for the new data
	TempLength = strlen(Name);
	TempName = new CHAR[TempLength + 3];

	//Abort if allocation failed
	if(TempName == NULL)
	{
		return;
	}

	//Add the " "
	for(i = 0; i < TempLength; i++)
	{
		TempName[i + 1] = Name[i];
	}
	TempName[0] = '\"';
	TempName[TempLength + 1] = '\"';
	TempName[TempLength + 2] = '\0';

	//Set the new data as the real data
	delete[] Name;
	Name = TempName;
	NameIsString = FALSE;
}


//+-----------------------------------------------------------------------------
//| Constructor
//+-----------------------------------------------------------------------------
GROUP::GROUP()
{
	Nullify(Name);
	Item.DeleteAll();
	Item.SetFlags(M_AllowMultiples | M_InsertAtEnd);
	NameIsString = FALSE;
}


//+-----------------------------------------------------------------------------
//| Destructor
//+-----------------------------------------------------------------------------
GROUP::~GROUP()
{
	SetName(NULL);
	Item.DeleteAll();
}


//+-----------------------------------------------------------------------------
//| Sets a new name
//+-----------------------------------------------------------------------------
BOOL GROUP::SetName(CONST CHAR* NewName)
{
	//Deallocate the old name
	SafeArrayDelete(Name);

	//Abort if no name should be set
	if(NewName == NULL)
	{
		return TRUE;
	}

	//Allocate memory for the new name
	Name = new CHAR[strlen(NewName) + 1];

	//Abort if allocation failed
	if(Name == NULL)
	{
		return FALSE;
	}

	//Copy the string
	strcpy(Name, NewName);

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Returns the name
//+-----------------------------------------------------------------------------
CHAR* GROUP::GetName()
{
	return Name;
}


//+-----------------------------------------------------------------------------
//| Adds a new item
//+-----------------------------------------------------------------------------
BOOL GROUP::AddItem(ITEM* NewItem)
{
	return Item.Add(NewItem);
}


//+-----------------------------------------------------------------------------
//| Returns a specific item
//+-----------------------------------------------------------------------------
ITEM* GROUP::GetItem(INT Nr)
{
	return Item.GetNth(Nr);
}


//+-----------------------------------------------------------------------------
//| Returns the number of items in this group
//+-----------------------------------------------------------------------------
INT GROUP::GetNrOfItems()
{
	return Item.Length();
}


//+-----------------------------------------------------------------------------
//| Returns the index of a certain item name if it exists, otherwise -1
//+-----------------------------------------------------------------------------
INT GROUP::FindItem(CONST CHAR* ItemName)
{
	//Data
	INT Counter = 0;
	BOOL Status = TRUE;
	ITEM* TempItem = NULL;

	//Loop though the objects
	Status = Item.PointAtFirstNode();
	while(Status == TRUE)
	{
		//Get the data
		TempItem = Item.GetCurrentData();

		//Prevent dereference on a NULL pointer
		if(TempItem != NULL)
		{
			//Compare the data
			if(strcmp(ItemName, TempItem->GetName()) == 0)
			{
				return Counter;
			}
		}

		//Point at next node
		Counter++;
		Status = Item.PointAtNextNode();
	}

	//Return failure
	return -1;
}


//+-----------------------------------------------------------------------------
//| Returns the index of a certain item data if it exists, otherwise -1
//+-----------------------------------------------------------------------------
INT GROUP::FindData(CONST CHAR* DataName)
{
	//Data
	INT Counter = 0;
	BOOL Status = TRUE;
	ITEM* TempItem = NULL;

	//Loop though the objects
	Status = Item.PointAtFirstNode();
	while(Status == TRUE)
	{
		//Get the data
		TempItem = Item.GetCurrentData();

		//Prevent dereference on a NULL pointer
		if(TempItem != NULL)
		{
			//Compare the data
			if(strcmp(DataName, TempItem->GetData()) == 0)
			{
				return Counter;
			}
		}

		//Point at next node
		Counter++;
		Status = Item.PointAtNextNode();
	}

	//Return failure
	return -1;
}


//+-----------------------------------------------------------------------------
//| Deletes a specific item
//+-----------------------------------------------------------------------------
BOOL GROUP::DeleteItem(INT Nr)
{
	return Item.DeleteNth(Nr);
}


//+-----------------------------------------------------------------------------
//| Deletes all items in this group
//+-----------------------------------------------------------------------------
VOID GROUP::DeleteAllItems()
{
	Item.DeleteAll();
}


//+-----------------------------------------------------------------------------
//| Eventually removes surrounding " "
//+-----------------------------------------------------------------------------
VOID GROUP::ConvertNameFromString()
{
	//Data
	INT i;
	INT TempLength;
	CHAR* TempName = NULL;

	//Abort if no name exists
	if(Name == NULL)
	{
		return;
	}

	//Abort if the length is too small
	TempLength = strlen(Name);
	if(TempLength < 2)
	{
		return;
	}

	//Abort if it's not a valid string
	if((Name[0] != '\"') || (Name[TempLength - 1] != '\"'))
	{
		return;
	}

	//Allocate memory for the new name
	TempName = new CHAR[TempLength - 1];

	//Abort if allocation failed
	if(TempName == NULL)
	{
		return;
	}

	//Remove the " "
	for(i = 0; i < (TempLength - 2); i++)
	{
		TempName[i] = Name[i + 1];
	}
	TempName[TempLength - 2] = '\0';

	//Set the new data as the real data
	delete[] Name;
	Name = TempName;
	NameIsString = TRUE;
}

//+-----------------------------------------------------------------------------
//| Eventually adds surrounding " "
//+-----------------------------------------------------------------------------
VOID GROUP::ConvertNameToString()
{
	//Data
	INT i;
	INT TempLength;
	CHAR* TempName = NULL;

	//Abort if no data exists
	if(Name == NULL)
	{
		return;
	}

	//Don't add if it's not a string
	if(NameIsString == FALSE)
	{
		return;
	}

	//Allocate memory for the new data
	TempLength = strlen(Name);
	TempName = new CHAR[TempLength + 3];

	//Abort if allocation failed
	if(TempName == NULL)
	{
		return;
	}

	//Add the " "
	for(i = 0; i < TempLength; i++)
	{
		TempName[i + 1] = Name[i];
	}
	TempName[0] = '\"';
	TempName[TempLength + 1] = '\"';
	TempName[TempLength + 2] = '\0';

	//Set the new data as the real data
	delete[] Name;
	Name = TempName;
	NameIsString = FALSE;
}


//+-----------------------------------------------------------------------------
//| Constructor
//+-----------------------------------------------------------------------------
SLK::SLK()
{
	Nullify(Name);
	Nullify(Data);
	Length = 0;
	DeleteAllGroups();
	//Group.SetExternalComparator(CompareGroups);
	//Group.SetFlags(M_AllowMultiples | M_AutomaticSort | M_ExternalComparator);
	//Group.SetFlags(M_AllowMultiples | M_AutomaticSort);
	Group.SetFlags(M_AllowMultiples | M_InsertAtEnd);
}


//+-----------------------------------------------------------------------------
//| Destructor
//+-----------------------------------------------------------------------------
SLK::~SLK()
{
	SetName(NULL);
	SafeArrayDelete(Data);
	DeleteAllGroups();
}


//+-----------------------------------------------------------------------------
//| Sets a new name
//+-----------------------------------------------------------------------------
BOOL SLK::SetName(CONST CHAR* NewName)
{
	//Deallocate the old name
	SafeArrayDelete(Name);

	//Abort if no name should be set
	if(NewName == NULL)
	{
		return TRUE;
	}

	//Allocate memory for the new name
	Name = new CHAR[strlen(NewName) + 1];

	//Abort if allocation failed
	if(Name == NULL)
	{
		return FALSE;
	}

	//Copy the string
	strcpy(Name, NewName);

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Returns the name
//+-----------------------------------------------------------------------------
CHAR* SLK::GetName()
{
	return Name;
}


//+-----------------------------------------------------------------------------
//| Adds a new group
//+-----------------------------------------------------------------------------
BOOL SLK::AddGroup(GROUP* NewGroup)
{
	return Group.Add(NewGroup);
}


//+-----------------------------------------------------------------------------
//| Returns a specific group
//+-----------------------------------------------------------------------------
GROUP* SLK::GetGroup(INT Nr)
{
	return Group.GetNth(Nr);
}


//+-----------------------------------------------------------------------------
//| Returns the description group
//+-----------------------------------------------------------------------------
GROUP* SLK::GetDescription()
{
	return &Description;
}


//+-----------------------------------------------------------------------------
//| Returns the number of groups in this slk object
//+-----------------------------------------------------------------------------
INT SLK::GetNrOfGroups()
{
	return Group.Length();
}


//+-----------------------------------------------------------------------------
//| Returns the index of a certain group name if it exists, otherwise -1
//+-----------------------------------------------------------------------------
INT SLK::FindGroup(CONST CHAR* GroupName)
{
	//Data
	INT Counter = 0;
	BOOL Status = TRUE;
	GROUP* TempGroup = NULL;

	//Loop though the objects
	Status = Group.PointAtFirstNode();
	while(Status == TRUE)
	{
		//Get the data
		TempGroup = Group.GetCurrentData();

		//Prevent dereference on a NULL pointer
		if(TempGroup != NULL)
		{
			//Compare the data
			if(strcmp(GroupName, TempGroup->GetName()) == 0)
			{
				return Counter;
			}
		}

		//Point at next node
		Counter++;
		Status = Group.PointAtNextNode();
	}

	//Return failure
	return -1;
}


//+-----------------------------------------------------------------------------
//| Deletes a specific group
//+-----------------------------------------------------------------------------
BOOL SLK::DeleteGroup(INT Nr)
{
	return Group.DeleteNth(Nr);
}


//+-----------------------------------------------------------------------------
//| Deletes all groups in this slk object
//+-----------------------------------------------------------------------------
VOID SLK::DeleteAllGroups()
{
	Description.DeleteAllItems();
	Group.DeleteAll();
}


//+-----------------------------------------------------------------------------
//| Loads slk data from a file
//+-----------------------------------------------------------------------------
BOOL SLK::LoadFile(CONST CHAR* FileName)
{
	//Data
	GROUP* FirstGroup = NULL;
	ITEM* FirstGroupItem = NULL;
	GROUP* TempGroup = NULL;
	ITEM* TempItem = NULL;
	INT i;
	INT CurrentX = 0;
	INT CurrentY = 0;
	INT Width = 0;
	INT Height = 0;
	BOOL Status = TRUE;
	BOOL Looping = TRUE;
	BOOL InnerLooping = TRUE;
	BOOL ElementHasChanged = TRUE;
	CHAR TempLetter = 0;
	CHAR* CurrentPointer = NULL;
	CHAR* PeekPointer = NULL;
	CHAR Buffer[MAXBUFFERSIZE] = {0};
	ifstream ReadFile;

	//Attempt to open the file
	ReadFile.open(FileName, ios::in | ios::nocreate | ios::binary);

	//Abort if open failed
	if(ReadFile.fail())
	{
		return FALSE;
	}

	//Remove earlier data
	SetName(NULL);
	SafeArrayDelete(Data);
	DeleteAllGroups();

	//Get the length of the file
	ReadFile.seekg(0, ios::end);
	Length = ReadFile.tellg();
	ReadFile.seekg(0, ios::beg);

	//Allocate memory for the data
	Data = new CHAR[Length + 1];

	//Abort if allocation failed
	if(Data == NULL)
	{
		ReadFile.close();
		return FALSE;
	}

	//Copy the data into the buffer
	ReadFile.read(Data, Length * sizeof(CHAR));
	Data[Length] = '\0';

	//Close the file
	ReadFile.close();

	//Translates the SLK format into a GROUP - ITEM format
	CurrentPointer = Data;
	PeekPointer = Data;
	while(Looping == TRUE)
	{
		//Find the next breakpoint
		while(((*PeekPointer) != ';') && ((*PeekPointer) != '\n') && ((*PeekPointer) != '\0'))
		{
			PeekPointer++;
		}

		//Continue if a double semicolon is found
		if((*PeekPointer) == ';')
		{
			if((*(PeekPointer + 1)) == ';')
			{
				PeekPointer += 2;
				continue;
			}
		}

		//Abort if EOF is reached
		if((*PeekPointer) == '\0')
		{
			Looping = FALSE;
		}

		//Find out which RTD it is
		if(CompareStrings(CurrentPointer, (PeekPointer - 1), "C") == TRUE)
		{
			//Seek the next command
			PeekPointer++;
			CurrentPointer = PeekPointer;

			InnerLooping = TRUE;
			while(InnerLooping == TRUE)
			{
				//Find the next breakpoint
				while(((*PeekPointer) != ';') && ((*PeekPointer) != '\n') && ((*PeekPointer) != '\0'))
				{
					PeekPointer++;
				}

				//Continue if a double semicolon is found
				if((*PeekPointer) == ';')
				{
					if((*(PeekPointer + 1)) == ';')
					{
						PeekPointer += 2;
						continue;
					}
				}

				//Break the inner loop if a newline is found
				if((*PeekPointer) == '\n')
				{
					InnerLooping = FALSE;
				}

				//Abort if EOF is reached
				if((*PeekPointer) == '\0')
				{
					InnerLooping = FALSE;
					Looping = FALSE;
				}

				//Get the first letter (the FTD)
				TempLetter = (*CurrentPointer);

				//Get the rest of the string
				CopyString((CurrentPointer + 1), (PeekPointer - 1), Buffer);

				//Handle X & Y
				switch(TempLetter)
				{
					case 'K':
						//Get the proper group
						TempGroup = Group.GetNth(CurrentY - 1);

						//Abort if no valid group was found
						if(TempGroup == NULL)
						{
							DeleteAllGroups();
							SafeArrayDelete(Data);
							return FALSE;
						}

						//Get the proper item
						TempItem = TempGroup->GetItem(CurrentX - 1);

						//Abort if no valid item was found
						if(TempItem == NULL)
						{
							DeleteAllGroups();
							SafeArrayDelete(Data);
							return FALSE;
						}

						//Set the data of the item
						if(TempItem->SetData(Buffer) == FALSE)
						{
							DeleteAllGroups();
							SafeArrayDelete(Data);
							return FALSE;
						}

						ElementHasChanged = FALSE;
						break;

					case 'A':
						//Get the proper item
						TempItem = Description.GetItem(CurrentX - 1);

						//Abort if no valid item was found
						if(TempItem == NULL)
						{
							DeleteAllGroups();
							SafeArrayDelete(Data);
							return FALSE;
						}

						//Set the data of the item, or add data to the existing
						//string if no new row/column has been specified
						if(ElementHasChanged == TRUE)
						{
							if(TempItem->SetData(Buffer) == FALSE)
							{
								DeleteAllGroups();
								SafeArrayDelete(Data);
								return FALSE;
							}
						}
						else
						{
							if(TempItem->AddData(Buffer) == FALSE)
							{
								DeleteAllGroups();
								SafeArrayDelete(Data);
								return FALSE;
							}
						}

						ElementHasChanged = FALSE;
						break;

					case 'X':
						ElementHasChanged = TRUE;
						CurrentX = ConvertStringToInteger(Buffer);
						break;

					case 'Y':
						ElementHasChanged = TRUE;
						CurrentY = ConvertStringToInteger(Buffer);
						break;
				}

				//Seek the next command
				PeekPointer++;
				CurrentPointer = PeekPointer;
			}
		}

		//Format (No format is stored, but X and Y must still be processed)
		else if(CompareStrings(CurrentPointer, (PeekPointer - 1), "F") == TRUE)
		{
			//Seek the next command
			PeekPointer++;
			CurrentPointer = PeekPointer;

			InnerLooping = TRUE;
			while(InnerLooping == TRUE)
			{
				//Find the next breakpoint
				while(((*PeekPointer) != ';') && ((*PeekPointer) != '\n') && ((*PeekPointer) != '\0'))
				{
					PeekPointer++;
				}

				//Continue if a double semicolon is found
				if((*PeekPointer) == ';')
				{
					if((*(PeekPointer + 1)) == ';')
					{
						PeekPointer += 2;
						continue;
					}
				}

				//Break the inner loop if a newline is found
				if((*PeekPointer) == '\n')
				{
					InnerLooping = FALSE;
				}

				//Abort if EOF is reached
				if((*PeekPointer) == '\0')
				{
					InnerLooping = FALSE;
					Looping = FALSE;
				}

				//Get the first letter (the FTD)
				TempLetter = (*CurrentPointer);

				//Get the rest of the string
				CopyString((CurrentPointer + 1), (PeekPointer - 1), Buffer);

				//Handle X & Y
				switch(TempLetter)
				{
					case 'X':
						ElementHasChanged = TRUE;
						CurrentX = ConvertStringToInteger(Buffer);
						break;

					case 'Y':
						ElementHasChanged = TRUE;
						CurrentY = ConvertStringToInteger(Buffer);
						break;
				}

				//Seek the next command
				PeekPointer++;
				CurrentPointer = PeekPointer;
			}
		}

		//Boundary
		else if(CompareStrings(CurrentPointer, (PeekPointer - 1), "B") == TRUE)
		{
			//Seek the next command
			PeekPointer++;
			CurrentPointer = PeekPointer;

			InnerLooping = TRUE;
			while(InnerLooping == TRUE)
			{
				//Find the next breakpoint
				while(((*PeekPointer) != ';') && ((*PeekPointer) != '\n') && ((*PeekPointer) != '\0'))
				{
					PeekPointer++;
				}

				//Continue if a double semicolon is found
				if((*PeekPointer) == ';')
				{
					if((*(PeekPointer + 1)) == ';')
					{
						PeekPointer += 2;
						continue;
					}
				}

				//Break the inner loop if a newline is found
				if((*PeekPointer) == '\n')
				{
					InnerLooping = FALSE;
				}

				//Abort if EOF is reached
				if((*PeekPointer) == '\0')
				{
					InnerLooping = FALSE;
					Looping = FALSE;
				}

				//Get the first letter (the FTD)
				TempLetter = (*CurrentPointer);

				//Get the rest of the string
				CopyString((CurrentPointer + 1), (PeekPointer - 1), Buffer);

				//Handle X & Y
				switch(TempLetter)
				{
					case 'X':
						//Get the width and set the new dimension
						Width = ConvertStringToInteger(Buffer);
						SetDimension(Width, Height);
						break;

					case 'Y':
						//Get the height and set the new dimension
						Height = ConvertStringToInteger(Buffer);
						SetDimension(Width, Height);
						break;
				}

				//Seek the next command
				PeekPointer++;
				CurrentPointer = PeekPointer;
			}
		}

		//End of file
		else if(CompareStrings(CurrentPointer, (PeekPointer - 1), "E") == TRUE)
		{
			//Abort
			Looping = FALSE;
		}

		//Others
		else
		{
			//Seek the next command
			PeekPointer++;
			CurrentPointer = PeekPointer;

			//Skip until newline
			while(((*PeekPointer) != '\n') && ((*PeekPointer) != '\0'))
			{
				PeekPointer++;
			}

			//Abort if EOF is reached
			if((*PeekPointer) == '\0')
			{
				Looping = FALSE;
			}

			//Seek the next command
			PeekPointer++;
			CurrentPointer = PeekPointer;
		}
	}

	//Deallocate the buffer data
	SafeArrayDelete(Data);

	//Get the first group
	FirstGroup = Group.GetNth(0);

	//Abort if it failed
	if(FirstGroup == NULL)
	{
		DeleteAllGroups();
		return FALSE;
	}

	//Loop though all groups
	Status = Group.PointAtFirstNode();
	while(Status == TRUE)
	{
		//Get the group
		TempGroup = Group.GetCurrentData();

		//Abort if it failed
		if(TempGroup == NULL)
		{
			DeleteAllGroups();
			return FALSE;
		}

		//Loop though all items
		for(i = 0; i < FirstGroup->GetNrOfItems(); i++)
		{
			//Get the first group's item
			FirstGroupItem = FirstGroup->GetItem(i);

			//Abort if it failed
			if(FirstGroupItem == NULL)
			{
				DeleteAllGroups();
				return FALSE;
			}

			//Get the item
			TempItem = TempGroup->GetItem(i);

			//Abort if it failed
			if(TempItem == NULL)
			{
				DeleteAllGroups();
				return FALSE;
			}

			//Set the name of the item
			TempItem->SetName(FirstGroupItem->GetData());
		}

		//Point at the next node
		Status = Group.PointAtNextNode();
	}

	//Return success
	ConvertFromString();
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Saves the slk data to a file
//+-----------------------------------------------------------------------------
BOOL SLK::SaveFile(CONST CHAR* FileName)
{
	//Data
	INT i = 0;
	INT j = 0;
	INT NrOfGroups = 0;
	INT NrOfItems = 0;
	GROUP* TempGroup = NULL;
	ITEM* TempItem = NULL;
	BOOL Status = TRUE;
	BOOL PrintY = TRUE;
	ofstream WriteFile;

	//Convert back to string form during save
	ConvertToString();

	//Attempt to open the file
	WriteFile.open(FileName, ios::out | ios::trunc);

	//Abort if open failed
	if(WriteFile.fail())
	{
		return FALSE;
	}

	//Get the number of groups
	NrOfGroups = Group.Length();

	//Point at the first group
	Status = Group.PointAtFirstNode();

	//Abort if it failed
	if(Status == FALSE)
	{
		WriteFile.close();
		ConvertFromString();
		return FALSE;
	}

	//Get a pointer to the first group
	TempGroup = Group.GetCurrentData();

	//Abort if it failed
	if(TempGroup == NULL)
	{
		WriteFile.close();
		ConvertFromString();
		return FALSE;
	}

	//Get the number of items
	NrOfItems = TempGroup->GetNrOfItems();

	//Write the header
	WriteFile << "ID;PWXL;N;E\n";
	WriteFile << "B;Y" << NrOfGroups << ";X" << NrOfItems << ";D0 0 " << (NrOfGroups - 1) << " " << (NrOfItems - 1) << "\n";

	//Write the descriptions
	PrintY = TRUE;
	for(i = 0; i < Description.GetNrOfItems(); i++)
	{
		//Get the current item
		TempItem = Description.GetItem(i);

		//Abort if no valid item was returned
		if(TempItem == NULL)
		{
			WriteFile.close();
			ConvertFromString();
			return FALSE;
		}

		//Write this item's data
		if(TempItem->GetData() != NULL)
		{
			//Special case if it's the first item (Print the Y also)
			if(PrintY == TRUE)
			{
				PrintY = FALSE;
				WriteFile << "C;Y" << j << ";X" << (i + 1) << ";A" << TempItem->GetData() << "\n";
			}
			else
			{
				WriteFile << "C;X" << (i + 1) << ";A" << TempItem->GetData() << "\n";
			}
		}
	}

	//Loop though the groups
	Status = Group.PointAtFirstNode();
	j = 1;
	while(Status == TRUE)
	{
		//Get the current group
		TempGroup = Group.GetCurrentData();

		//Abort if no valid group was returned
		if(TempGroup == NULL)
		{
			WriteFile.close();
			ConvertFromString();
			return FALSE;
		}

		//Loop though the items
		PrintY = TRUE;
		for(i = 0; i < TempGroup->GetNrOfItems(); i++)
		{
			//Get the current item
			TempItem = TempGroup->GetItem(i);

			//Abort if no valid item was returned
			if(TempItem == NULL)
			{
				WriteFile.close();
				ConvertFromString();
				return FALSE;
			}

			//Write this item's data
			if(TempItem->GetData() != NULL)
			{
				//Special case if it's the first item (Print the Y also)
				if(PrintY == TRUE)
				{
					PrintY = FALSE;
					WriteFile << "C;Y" << j << ";X" << (i + 1) << ";K" << TempItem->GetData() << "\n";
				}
				else
				{
					WriteFile << "C;X" << (i + 1) << ";K" << TempItem->GetData() << "\n";
				}
			}
		}

		//Get the next group
		j++;
		Status = Group.PointAtNextNode();
	}

	//Write EOF marker
	WriteFile << "E\n";

	//Return success
	WriteFile.close();
	ConvertFromString();
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Eventually removes " "
//+-----------------------------------------------------------------------------
VOID SLK::ConvertFromString()
{
	//Data
	INT i;
	BOOL Status = TRUE;
	GROUP* TempGroup = NULL;
	ITEM* TempItem = NULL;

	//Fix description
	Description.ConvertNameFromString();

	//Loop though all groups
	Status = Group.PointAtFirstNode();
	while(Status == TRUE)
	{
		//Get the current group
		TempGroup = Group.GetCurrentData();

		//Proceed with next if a NULL pointer is returned
		if(TempGroup == NULL)
		{
			Status = Group.PointAtNextNode();
			continue;
		}

		//Fix strings
		TempGroup->ConvertNameFromString();

		//Loop though all items
		for(i = 0; i < Description.GetNrOfItems(); i++)
		{
			//Get the current item
			TempItem = TempGroup->GetItem(i);

			//Proceed with next if a NULL pointer is returned
			if(TempItem == NULL)
			{
				continue;
			}

			//Fix strings
			TempItem->ConvertDataFromString();
			TempItem->ConvertNameFromString();
		}

		//Get the next group
		Status = Group.PointAtNextNode();
	}
}


//+-----------------------------------------------------------------------------
//| Eventually adds " "
//+-----------------------------------------------------------------------------
VOID SLK::ConvertToString()
{
	//Data
	INT i;
	BOOL Status = TRUE;
	GROUP* TempGroup = NULL;
	ITEM* TempItem = NULL;

	//Fix description
	Description.ConvertNameToString();

	//Loop though all groups
	Status = Group.PointAtFirstNode();
	while(Status == TRUE)
	{
		//Get the current group
		TempGroup = Group.GetCurrentData();

		//Proceed with next if a NULL pointer is returned
		if(TempGroup == NULL)
		{
			Status = Group.PointAtNextNode();
			continue;
		}

		//Fix strings
		TempGroup->ConvertNameToString();

		//Loop though all items
		for(i = 0; i < Description.GetNrOfItems(); i++)
		{
			//Get the current item
			TempItem = TempGroup->GetItem(i);

			//Proceed with next if a NULL pointer is returned
			if(TempItem == NULL)
			{
				continue;
			}

			//Fix strings
			TempItem->ConvertDataToString();
			TempItem->ConvertNameToString();
		}

		//Get the next group
		Status = Group.PointAtNextNode();
	}
}


//+-----------------------------------------------------------------------------
//| Sorts all groups by name (except for the first one)
//+-----------------------------------------------------------------------------
BOOL SLK::SortByName(BOOL* MinorError)
{
	//Data
	GROUP* Group1;
	GROUP* Group2;
	ITEM* Item1;
	ITEM* Item2;
	INT Index1;
	INT Index2;
	INT GroupLength = Group.Length();

	//Flag that no error occured
	if(MinorError != NULL) (*MinorError) = FALSE;

	//Abort if the number of groups are 2 or less
	if(GroupLength <= 2)
	{
		return TRUE;
	}

	//Do a simple bubble sort
	for(Index1 = 1; Index1 < (GroupLength - 1); Index1++)
	{
		for(Index2 = Index1 + 1; Index2 < GroupLength; Index2++)
		{
			//Get one group
			Group1 = Group.GetNth(Index1);
			if(Group1 == NULL)
			{
				if(MinorError != NULL) (*MinorError) = TRUE;
				continue;
			}

			//Get one item
			Item1 = Group1->GetItem(0);
			if(Item1 == NULL)
			{
				if(MinorError != NULL) (*MinorError) = TRUE;
				continue;
			}

			//Get another group
			Group2 = Group.GetNth(Index2);
			if(Group2 == NULL)
			{
				if(MinorError != NULL) (*MinorError) = TRUE;
				continue;
			}

			//Get another item
			Item2 = Group2->GetItem(0);
			if(Item2 == NULL)
			{
				if(MinorError != NULL) (*MinorError) = TRUE;
				return FALSE;
			}

			//Don't sort if one of them miss a name
			if(Item1->GetData() == NULL)
			{
				if(MinorError != NULL) (*MinorError) = TRUE;
				continue;
			}
			if(Item2->GetData() == NULL)
			{
				if(MinorError != NULL) (*MinorError) = TRUE;
				continue;
			}

			//Swap them if neccessary
			if(strcmpi(Item1->GetData(), Item2->GetData()) > 0)
			{
				if(Group.SwapNodes(Index1, Index2) == FALSE)
				{
					return FALSE;
				}
			}
		}
	}

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Converts a string to an integer
//+-----------------------------------------------------------------------------
INT SLK::ConvertStringToInteger(CONST CHAR* String)
{
	//Data
	INT Result = 0;

	//Abort if String pointer is NULL
	if(String == NULL)
	{
		return 0;
	}

	//Traverse the string
	while((*String) != '\0')
	{
		//Shift the result
		Result *= 10;

		//Abort if it's not a digit
		if(((*String) < 48) || ((*String) > 57))
		{
			return 0;
		}

		//Add the digit to the result
		Result += (INT)((*String) - 48);

		//Get the next digit
		String++;
	}

	//Return success
	return Result;
}


//+-----------------------------------------------------------------------------
//| Preallocates memory for all groups and items
//+-----------------------------------------------------------------------------
BOOL SLK::SetDimension(INT NewWidth, INT NewHeight)
{
	//Data
	INT i;
	BOOL Status = TRUE;
	GROUP* TempGroup = NULL;
	ITEM* TempItem = NULL;

	//Abort if any of the dimensions are invalid
	if((NewWidth <= 0) || (NewHeight <= 0))
	{
		return FALSE;
	}

	//Remove eventual earlier data
	DeleteAllGroups();

	//Create all items for the description
	for(i = 0; i < NewWidth; i++)
	{
		//Allocate memory for a new item
		TempItem = new ITEM;

		//Abort if allocation failed
		if(TempItem == NULL)
		{
			DeleteAllGroups();
			return FALSE;
		}

		//Add the item
		if(Description.AddItem(TempItem) == FALSE)
		{
			DeleteAllGroups();
			return FALSE;
		}
	}

	//Create all groups
	for(i = 0; i < NewHeight; i++)
	{
		//Allocate memory for a new group
		TempGroup = new GROUP;

		//Abort if allocation failed
		if(TempGroup == NULL)
		{
			DeleteAllGroups();
			return FALSE;
		}

		//Add the group
		if(Group.Add(TempGroup) == FALSE)
		{
			DeleteAllGroups();
			return FALSE;
		}
	}

	//Loop though all groups
	Status = Group.PointAtFirstNode();
	while(Status == TRUE)
	{
		//Get the current group
		TempGroup = Group.GetCurrentData();

		//Abort if a NULL pointer is returned
		if(TempGroup == NULL)
		{
			DeleteAllGroups();
			return FALSE;
		}

		//Create all items
		for(i = 0; i < NewWidth; i++)
		{
			//Allocate memory for a new item
			TempItem = new ITEM;

			//Abort if allocation failed
			if(TempItem == NULL)
			{
				DeleteAllGroups();
				return FALSE;
			}

			//Add the item
			if(TempGroup->AddItem(TempItem) == FALSE)
			{
				DeleteAllGroups();
				return FALSE;
			}
		}

		//Get the next group
		Status = Group.PointAtNextNode();
	}

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Compares two strings. One string is specified by two pointers
//| (the letters between them)
//+-----------------------------------------------------------------------------
BOOL SLK::CompareStrings(CONST CHAR* StartString1, CONST CHAR* EndString1, CONST CHAR* String2)
{
	//Abort if any of the pointers are NULL pointers
	if((StartString1 == NULL) || (EndString1 == NULL) || (String2 == NULL))
	{
		return FALSE;
	}

	//Abort if the end-pointer is before the start-pointer
	if(StartString1 > EndString1)
	{
		return FALSE;
	}

	//Compare the strings
	while(StartString1 <= EndString1)
	{
		//Abort if the NULL character is reached
		if(((*StartString1) == '\0') || ((*String2) == '\0'))
		{
			return FALSE;
		}

		//Abort if the letters doesn't match
		if((*StartString1) != (*String2))
		{
			return FALSE;
		}

		//Check the next letters
		StartString1++;
		String2++;
	}

	//Return success
	return TRUE;
}


//+-----------------------------------------------------------------------------
//| Copies one stringinto a buffer. The string is specified by two pointers
//+-----------------------------------------------------------------------------
BOOL SLK::CopyString(CONST CHAR* StartString, CONST CHAR* EndString, CHAR* Buffer)
{
	//Abort if any of the pointers are NULL pointers
	if((StartString == NULL) || (EndString == NULL) || (Buffer == NULL))
	{
		return FALSE;
	}

	//Abort if the end-pointer is before the start-pointer
	if(StartString > EndString)
	{
		(*Buffer) = '\0';
		return FALSE;
	}

	//Copy the string
	while(StartString <= EndString)
	{
		if((*StartString) != (CHAR)13)
		{
			//Copy one letter
			(*Buffer) = (*StartString);

			//Increase the buffer pointer
			Buffer++;
		}

		//Check the next letter
		StartString++;
	}

	//Add a final NULL terminator
	(*Buffer) = '\0';

	//Return success
	return TRUE;
}

