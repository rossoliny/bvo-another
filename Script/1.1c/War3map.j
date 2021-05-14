//W3x2lni Data: 2020-04-06 20:32:10.809
	//#ExportTo Scripts\Variables\Globals.j
	globals
		hashtable HashTable 		 = InitHashtable( )
		hashtable ItemPrices 		 = InitHashtable( )

		group SysGroup      		 = CreateGroup( )
		group Collector     		 = CreateGroup( )
		group SpellGroup    		 = CreateGroup( )
		group Pauser_Group  		 = CreateGroup( )
		timer EventTimer 			 = CreateTimer( )
		rect SysRect 				 = Rect( 0, 0, 0, 0 )
		item Rapire 				 = null
		item Rapire_2				 = null
		item SysItem 				 = null
		multiboard Multiboard		 = null
		multiboarditem mbitem 		 = null
		timerdialog EventTimerDialog = null
		unit BaseUnit				 = null
		unit SysUnit 				 = null
		unit Unr_Unit 				 = null
		unit Oz_Boss 				 = null
		unit Rapire_Owner 			 = null
		unit Rapire_2_Owner 		 = null
		unit Ring_Boss 				 = null
		unit Left_Boss				 = null
		unit Right_Boss				 = null
		unit Dummy				 	 = null
		unit DummyCaster			 = null

		sound array Sounds
		unit array PlayerUnit
		unit array WayGate_Arr
		
		weathereffect array Player_Weather
		integer g_ver = 126

		boolean Rapire_Stolen = false
		boolean Rapire_2_Stolen = false

		// item shop 2 items
		constant integer Item_Gloves_of_Haste 		= 'gcel'
		constant integer Item_Mask_of_Death 		= 'modt'
		constant integer Item_Hollow_Mask 			= 'rwiz'
		constant integer Item_Boots_of_Speed 		= 'bspd'
		constant integer Item_Shinigami_Cloak 		= 'brac'
		constant integer Item_Kuma_Unique_Book 		= 'desc'
		constant integer Item_Gem_of_True_Seeing	= -1
		// item shop 2 prices
		constant integer Price_Gloves_of_Haste 		= 610
		constant integer Price_Mask_of_Death 		= 900
		constant integer Price_Hollow_Mask 			= 400
		constant integer Price_Boots_of_Speed 		= 500
		constant integer Price_Shinigami_Cloak 		= 650
		constant integer Price_Kuma_Unique_Book 	= 2500
		constant integer Price_Gem_of_True_Seeing	= 750
	endglobals
	//#ExportEnd

	//#ExportTo Scripts\Misc\GetPatch.j
    function GetPatchLevel takes nothing returns integer
        local image img
        local string tmp
       
        // This icon wasn't introduced until 1.28a
        set img = CreateImage( "ReplaceableTextures\\WorldEditUI\\Editor-Toolbar-MapValidation.blp", 64, 64, 0, 0, 0, 0, 64, 64, 0, 1 )
        if GetHandleId( img ) == -1 then
            return 126 // 1.27b or lower
        endif
        call DestroyImage( img )

        // The array size limit was increased in 1.29, so if it's the same
        // then we are on 1.28.
        if JASS_MAX_ARRAY_SIZE <= 8192 then
            return 128
        endif

        // This string didn't exist until 1.30
        if GetLocalizedString( "DOWNLOADING_MAP" ) == "DOWNLOADING_MAP" then
            return 129
        endif
       
        // This string changed in 1.30.2.
        set tmp = GetLocalizedString( "ERROR_ID_CDKEY_INUSE" )
        if SubString( tmp, StringLength( tmp ) - 1, StringLength( tmp ) ) == ")" then // check the last character to presumably support all locales
            return 130
        endif
       
        set tmp = GetLocalizedString( "WINDOW_MODE_WINDOWED" )
       
        if tmp == "WINDOW_MODE_WINDOWED" then
            return 1302
        endif
       
        return 131 // or higher
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Unit_States.j
	function UnitMaxLife takes unit LocUnit returns real
		return GetUnitState( LocUnit, UNIT_STATE_MAX_LIFE )
	endfunction

	function UnitLife takes unit LocUnit returns real
		return GetUnitState( LocUnit, UNIT_STATE_LIFE )
	endfunction	

	function UnitLifePercent takes unit whichUnit returns real
		if UnitLife( whichUnit ) <= 0 then
			return .0
		endif

		return UnitLife( whichUnit ) / UnitMaxLife( whichUnit ) * 100.
	endfunction

	function IsUnitEnemy_v2 takes unit Source, unit Target returns boolean
		return IsUnitEnemy( Source, GetOwningPlayer( Target ) )
	endfunction

	function IsUnitInvulnerable takes unit Target returns boolean
		return LoadBoolean( HashTable, GetHandleId( Target ), StringHash( "Has_Invul" ) )
	endfunction

	function HasAbility takes unit Target, integer ID returns boolean
		return GetUnitAbilityLevel( Target, ID ) > 0
	endfunction

	function DefaultFilter takes unit Target returns boolean
		return not IsUnitType( Target, UNIT_TYPE_STRUCTURE ) and not IsUnitType( Target, UNIT_TYPE_MAGIC_IMMUNE ) and not IsUnitType( Target, UNIT_TYPE_MECHANICAL )
	endfunction

	function DefaultUnitFilter takes unit Target returns boolean
		return UnitLife( Target ) > 0 and not IsUnitHidden( Target ) and not HasAbility( Target, 'A01Q' ) and DefaultFilter( Target )
	endfunction

	function GetUnitOrder takes unit Source returns string
		return OrderId2String( GetUnitCurrentOrder( Source ) )
	endfunction

	function HasBlink takes unit Unit returns boolean
		if HasAbility( Unit, 'A00B' ) or HasAbility( Unit, 'A0BO' ) or HasAbility( Unit, 'A0D0' ) or HasAbility( Unit, 'A0D2' ) or HasAbility( Unit, 'A01G' ) or HasAbility( Unit, 'A02E' ) or HasAbility( Unit, 'A02W' ) then
			return true
		endif

		if HasAbility( Unit, 'A04Q' ) or HasAbility( Unit, 'A06G' ) or HasAbility( Unit, 'A06O' ) or HasAbility( Unit, 'A08K' ) or HasAbility( Unit, 'A08R' ) or HasAbility( Unit, 'A08S' ) or HasAbility( Unit, 'A0AS' ) then
			return true
		endif
		
		if HasAbility( Unit, 'A039' ) or HasAbility( Unit, 'A00K' ) or HasAbility( Unit, 'A06O' ) or HasAbility( Unit, 'A08K' ) or HasAbility( Unit, 'A08R' ) or HasAbility( Unit, 'A08S' ) or HasAbility( Unit, 'A0AS' ) then
			return true
		endif

		return false
	endfunction

	function IsUnitCCed takes unit Target returns boolean
		if HasAbility( Target, 'BSTN' ) or HasAbility( Target, 'BPSE' ) or HasAbility( Target, 'BOhx' ) or HasAbility( Target, 'BUsl' ) then
			return true
		endif
		
		if HasAbility( Target, 'B00X' ) or HasAbility( Target, 'B022' ) or HasAbility( Target, 'B023' ) or HasAbility( Target, 'B001' ) then 
			return true
		endif

		return false
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Functions.j
	function OutPutData takes string FilePath, string Text returns nothing
		call PreloadGenClear( )
		call PreloadGenStart( )
		call Preload( Text )
		call PreloadGenEnd( FilePath )
	endfunction

	function GetColour takes integer count returns string
		if count == 0 then
			return "|c00FF0303"
		elseif count == 1 then
			return "|c000042FF"
		elseif count == 2 then
			return "|c001CE6B9"
		elseif count == 3 then
			return "|c00540081"
		elseif count == 4 then
			return "|c00FFFc01"
		elseif count == 5 then
			return "|c00FF8000"
		elseif count == 6 then
			return "|c0020C000"
		elseif count == 7 then
			return "|c00e55BB0"
		elseif count == 8 then
			return "|c00959697"
		elseif count == 9 then
			return "|c007EBFF1"
		elseif count == 10 then
			return "|c00106246"
		elseif count == 11 then
			return "|c004E2A04"
		elseif count == 12 then //Gold ??? ??????????? ??????
			return "|c00FFD700"
		elseif count == 13 then //Red ??? ??????????? ???????
			return "|c00FF0000"
		elseif count == 14 then //Violet ??? ??????????? ???????
			return "|c007EBFF1"
		elseif count == 15 then //Aqua ??? ??????????? ???????
			return "|c0000FFFF"
		elseif count == 16 then //SlateGrey ??? ????????? ???????
			return "|c00708090"
		elseif count == 17 then //Red ??? ????? ??????? ???????
			return "|c00FF0000"
		elseif count == 18 then //Lime ??? ????? ??????? ???????
			return "|c0000FF00"
		elseif count == 19 then //IndianRed ??? ????? ???????? ???????
			return "|c00CD5C5C"
		elseif count == 20 then
			return "|cFFFFCC00" //Gold
		endif
		return "|c00FF0000" //Default Colour
	endfunction

	function Progress_Text takes integer Pos returns string
		local integer i = 0
		local string Progress = "|c000042FF"

		loop
			exitwhen i == 5
			set Progress = Progress + "II"
			if i == Pos then
				set Progress = Progress + "|r"
			endif
			set i = i + 1
		endloop

		return Progress
	endfunction

	function MakeTextTag takes string Text, real TargX, real TargY, real zOffset, real Angle, real Speed, real Size, integer Alpha, real Duration returns texttag
		set Speed = Speed * .071 / 128
		set Size  = Size  * .023 / 10
		set bj_lastCreatedTextTag = CreateTextTag( )
		call SetTextTagText( 	 	  bj_lastCreatedTextTag, Text, Size )
		call SetTextTagPos(   	 	  bj_lastCreatedTextTag, TargX, TargY, zOffset )
		call SetTextTagColor(		  bj_lastCreatedTextTag, 255, 255, 255, Alpha )
		if Speed > 0 then
			call SetTextTagVelocity(  bj_lastCreatedTextTag, Speed * Cos( Deg2Rad( Angle ) ), Speed * Sin( Deg2Rad( Angle ) ) )
		endif
		if Duration > 0 then
			call SetTextTagPermanent( bj_lastCreatedTextTag, false )
			call SetTextTagLifespan(  bj_lastCreatedTextTag, Duration )
		endif
		return bj_lastCreatedTextTag
	endfunction

	function TextTagAngled takes string Text, real TargX, real TargY, real Angle, real Speed, real Size, integer Alpha, real Duration returns texttag
		return MakeTextTag( Text, TargX, TargY, 0, Angle, Speed, Size, Alpha, Duration )
	endfunction

	function TextTagAngledUnit takes string Text, unit Targ, real Angle, real Speed, real Size, integer Alpha, real Duration returns texttag
		return TextTagAngled( Text, GetUnitX( Targ ), GetUnitY( Targ ), Angle, Speed, Size, Alpha, Duration )
	endfunction

	function TextTagSimple takes string Text, real TargX, real TargY, real Size, integer Alpha, real Duration returns texttag
		return TextTagAngled( Text, TargX, TargY, 90, 100, Size, Alpha, Duration )
	endfunction

	function TextTagSimpleUnit takes string Text, unit Targ, real Size, integer Alpha, real Duration returns texttag
		return TextTagAngledUnit( Text, Targ, 90, 100, Size, Alpha, Duration )
	endfunction

	function PlayerGold takes integer PID returns integer
		return GetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD )
	endfunction

	function ResetAbilityCD takes unit Target, integer AID returns nothing
		local integer ALvL = GetUnitAbilityLevel( Target, AID )
		call UnitRemoveAbility( Target, AID )
		call UnitAddAbility( Target, AID )
		call SetUnitAbilityLevel( Target, AID, ALvL )
	endfunction

	function Damage_Unit_Handler takes integer PID, unit Target, real DMG, attacktype AtkType, damagetype DmgType returns nothing
		call UnitDamageTarget( LoadUnitHandle( HashTable, GetHandleId( Player( PID ) ), StringHash( "Damage_Dummy" ) ), Target, DMG, true, false, AtkType, DmgType, WEAPON_TYPE_WHOKNOWS )
	endfunction

	function Damage_Unit takes unit Source, unit Target, real DMG, string Type returns boolean
		local integer PID = GetPlayerId( GetOwningPlayer( Source ) )
		if DMG > 0 then
			if DefaultUnitFilter( Target ) then
				if IsUnitVisible( Target, Player( PID ) ) and Type != "passive" then
					call TextTagAngledUnit( "|c0000FFFF" + I2S( R2I( DMG ) ) + "|r", Target, GetRandomReal( 45, 135 ), 100, 11, 255, 1.6 )
				endif
				if Type == "physical" then
					call Damage_Unit_Handler( PID, Target, DMG, ATTACK_TYPE_HERO,   DAMAGE_TYPE_NORMAL )
			elseif Type == "magical" then
					call Damage_Unit_Handler( PID, Target, DMG, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_MAGIC  )
				else
					call Damage_Unit_Handler( PID, Target, DMG, ATTACK_TYPE_HERO,   DAMAGE_TYPE_NORMAL )
				endif
			endif

			return UnitLife( Target ) > 0
		endif

		return false
	endfunction

	function Award_Team takes integer Team, integer Amount, string Type returns nothing
		local integer i = 0
		
		loop
			exitwhen i > 11
			if GetPlayerTeam( Player( i ) ) == Team then
				if Type == "Gold" then
					call SetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD ) + Amount )
			elseif Type == "XP" then
					call AddHeroXP( PlayerUnit[ i ], Amount, true )
				endif
			endif
			set i = i + 1
		endloop
	endfunction

	function Generate_Gold_Coins takes integer IID, integer Amount, real LocX, real LocY returns nothing
		local integer i = 1
        loop
            exitwhen i > Amount
            call CreateItem( IID, LocX, LocY )
            set i = i + 1
        endloop
    endfunction

	function CountPlayersInTeam takes integer Team returns integer
		local integer i = 0
		local integer Count = 0

		loop
			exitwhen i > 11
			if GetPlayerTeam( Player( i ) ) == Team and GetPlayerSlotState( Player( i ) ) == PLAYER_SLOT_STATE_PLAYING then
				set Count = Count + 1
			endif
			set i = i + 1
		endloop

		return Count
	endfunction

	function CountPlayers takes nothing returns integer
		local integer i = 0
		local integer Count = 0

		loop
			exitwhen i > 11
			if GetPlayerSlotState( Player( i ) ) == PLAYER_SLOT_STATE_PLAYING and GetPlayerController( Player( i ) ) == MAP_CONTROL_USER then
				set Count = Count + 1
			endif
			set i = i + 1
		endloop

		return Count
	endfunction

	function AdjustTeamGold takes integer PID, integer Team returns nothing
		local integer i = 0
		local integer limit = 5
		local integer LocGold = GetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD ) / CountPlayersInTeam( Team )

		if PID > 5 then
			set i = 6
			set limit = 11
		endif

		loop
			exitwhen i > limit
			if Player( i ) != Player( PID ) then
				call SetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD ) + LocGold )
			endif
			set i = i + 1
		endloop
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Coordinates.j
	function GetAxisAngle takes real FromX, real FromY, real TargetX, real TargetY returns real
		return Rad2Deg( Atan2( TargetY - FromY, TargetX - FromX ) )
	endfunction

	function GetUnitsAngle takes unit From, unit Target returns real
		return GetAxisAngle( GetUnitX( From ), GetUnitY( From ), GetUnitX( Target ), GetUnitY( Target ) )
	endfunction

	function GetAngleCast takes unit Caster, real TargetX, real TargetY returns real
		local real FromX = GetUnitX( Caster )
		local real FromY = GetUnitY( Caster )
		if FromX == TargetX and FromY == TargetY then
			return GetUnitFacing( Caster )
		endif
		return GetAxisAngle( FromX, FromY, TargetX, TargetY )
	endfunction

	function GetAxisDistance takes real FromX, real FromY, real TargetX, real TargetY returns real
		return SquareRoot( Pow( TargetX - FromX, 2 ) + Pow( FromY - TargetY, 2 ) )
	endfunction

	function GetUnitsDistance takes unit From, unit Target returns real
		return GetAxisDistance( GetUnitX( From ), GetUnitY( From ), GetUnitX( Target ), GetUnitY( Target ) )
	endfunction

	function NewX takes real LocX, real Dist, real Angle returns real
		return LocX + Dist * Cos( Deg2Rad( Angle ) )
	endfunction

	function NewY takes real LocY, real Dist, real Angle returns real
		return LocY + Dist * Sin( Deg2Rad( Angle ) )
	endfunction

	function GetMaxAllowedDistance takes real InitX, real InitY, real Angle, real Step, real Limit returns real
		local real MoveX = InitX
		local real MoveY = InitY
		local real Distance = 0

		loop
			exitwhen Distance >= Limit or IsTerrainPathable( MoveX, MoveY, PATHING_TYPE_WALKABILITY )
			set MoveX = NewX( MoveX, Step, Angle )
			set MoveY = NewY( MoveY, Step, Angle )
			set Distance = Distance + Step
		endloop

		if Distance > Limit then
			return Limit
		endif

		return Distance
	endfunction

	function SetUnitFacingUnit takes unit Source, unit Target returns nothing
		call SetUnitFacing( Source, GetUnitsAngle( Source, Target ) )
	endfunction
	
	function SetUnitXY takes unit Target, real ToX, real ToY returns nothing
		if GetUnitMoveSpeed( Target ) > 0 then 
			call SetUnitX( Target, ToX )
			call SetUnitY( Target, ToY )
		else
			call SetUnitPosition( Target, ToX, ToY )
		endif
	endfunction

	function SetUnitXY_1 takes unit Target, real ToX, real ToY, boolean Pathing returns nothing
		if Pathing and IsTerrainPathable( ToX, ToY, PATHING_TYPE_WALKABILITY ) then
			return
		endif
		call SetUnitXY( Target, ToX, ToY )
	endfunction

	function SetUnitXY_2 takes unit Target, real InitX, real InitY, real Dist, real Angle returns nothing
		call SetUnitXY_1( Target, InitX + Dist * Cos( Deg2Rad( Angle ) ), InitY + Dist * Sin( Deg2Rad( Angle ) ), false )
	endfunction

	function SetUnitXY_3 takes unit Target, real InitX, real InitY, real Dist, real Angle returns nothing
		call SetUnitXY_1( Target, InitX + Dist * Cos( Deg2Rad( Angle ) ), InitY + Dist * Sin( Deg2Rad( Angle ) ), true )
	endfunction

	function SetUnitXY_4 takes unit Target, real InitX, real InitY, real Dist, real Angle returns nothing
		call SetUnitXY_1( Target, InitX + Dist * Cos( Deg2Rad( Angle ) ), InitY + Dist * Sin( Deg2Rad( Angle ) ), true )
		call SetUnitFacing( Target, Angle )
	endfunction

	function IsUnitInArea takes unit Source, string Area returns boolean
		local real UnitX = GetUnitX( Source )
		local real UnitY = GetUnitY( Source )
		local real MinX = 0
		local real MaxX = 0
		local real MinY = 0
		local real MaxY = 0

		set Area = StringCase( Area, false )

		if Area == "base_1" then
			set MinX = -7392
			set MaxX = -5664
			set MinY = -1056
			set MaxY =  1792
		elseif Area == "base_2" then
			set MinX =  4224
			set MaxX =  6048
			set MinY = -1000
			set MaxY =  2000
		elseif Area == "rapire" then
			set MinX =  6784
			set MaxX =  7936
			set MinY = -1728
			set MaxY =  4320
		elseif Area == "forgotten_boss" then
			set MinX =  6144
			set MaxX =  7168
			set MinY =  5792
			set MaxY =  7040
		elseif Area == "golem_boss" then
			set MinX = -3648
			set MaxX =   384
			set MinY =  4736
			set MaxY =  7712
		elseif Area == "ring_boss" then
			set MinX =  3750
			set MaxX =  4600
			set MinY =  5100
			set MaxY =  7008
		elseif Area == "left_boss" then
			set MinX = -4400
			set MaxX = -3700
			set MinY =  2450
			set MaxY =  4050
		elseif Area == "right_boss" then
			set MinX =  2300
			set MaxX =  3050
			set MinY =  2450
			set MaxY =  4050
		endif

		return MinX <= UnitX and UnitX <= MaxX and MinY <= UnitY and UnitY <= MaxY
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Globals.j
	function LoadTrig takes string HashName returns trigger
		if LoadTriggerHandle( HashTable, GetHandleId( HashTable ), StringHash( HashName ) ) == null then
			call SaveTriggerHandle( HashTable, GetHandleId( HashTable ), StringHash( HashName ), CreateTrigger( ) )
		endif
		return LoadTriggerHandle( HashTable, GetHandleId( HashTable ), StringHash( HashName ) )
	endfunction

	function LoadBool takes string HashName returns boolean
		return LoadBoolean( HashTable, GetHandleId( EventTimer ), StringHash( HashName ) )
	endfunction

	function SaveBool takes string HashName, boolean Flag returns nothing
		call SaveBoolean( HashTable, GetHandleId( EventTimer ), StringHash( HashName ), Flag )
	endfunction
	
	function LoadString takes string HashName returns string
		return LoadStr( HashTable, GetHandleId( EventTimer ), StringHash( HashName ) )
	endfunction

	function SaveString takes string HashName, string Text returns nothing
		call SaveStr( HashTable, GetHandleId( EventTimer ), StringHash( HashName ), Text )
	endfunction

	function LoadInt takes string HashName returns integer
		return LoadInteger( HashTable, GetHandleId( EventTimer ), StringHash( HashName ) )
	endfunction

	function SaveInt takes string HashName, integer Value returns nothing
		call SaveInteger( HashTable, GetHandleId( EventTimer ), StringHash( HashName ), Value )
	endfunction

	function LoadFloat takes string HashName returns real
		return LoadReal( HashTable, GetHandleId( EventTimer ), StringHash( HashName ) )
	endfunction

	function SaveFloat takes string HashName, real Value returns nothing
		call SaveReal( HashTable, GetHandleId( EventTimer ), StringHash( HashName ), Value )
	endfunction

	function LoadUnit takes string HashName returns unit
		return LoadUnitHandle( HashTable, GetHandleId( EventTimer ), StringHash( HashName ) )
	endfunction

	function SaveUnit takes string HashName, unit Unit returns nothing
		call SaveUnitHandle( HashTable, GetHandleId( EventTimer ), StringHash( HashName ), Unit )
	endfunction

	function LoadEffect takes string HashName returns effect
		return LoadEffectHandle( HashTable, GetHandleId( EventTimer ), StringHash( HashName ) )
	endfunction

	function SaveEffect takes string HashName, effect Effect returns nothing
		call SaveEffectHandle( HashTable, GetHandleId( EventTimer ), StringHash( HashName ), Effect )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\MUI.j
	function NewMUITimer takes integer PID returns integer
		local integer MaxTimer = 100
		local integer Iterator = LoadInteger( HashTable, GetHandleId( Player( PID ) ), StringHash( "TimerIterator" ) )

		loop
			exitwhen not LoadBoolean( HashTable, GetHandleId( LoadTimerHandle( HashTable, GetHandleId( Player( PID ) ), StringHash( "Timer_Num_" + I2S( Iterator ) ) ) ), StringHash( "TimerStarted" ) ) and Iterator <= MaxTimer
			if Iterator > MaxTimer then
				set Iterator = 0
			else
				set Iterator = Iterator + 1
			endif
		endloop

		call SaveInteger( HashTable, GetHandleId( Player( PID ) ), StringHash( "TimerIterator" ), Iterator )

		if LoadTimerHandle( HashTable, GetHandleId( Player( PID ) ), StringHash( "Timer_Num_" + I2S( Iterator ) ) ) == null then
			call SaveTimerHandle( HashTable, GetHandleId( Player( PID ) ), StringHash( "Timer_Num_" + I2S( Iterator ) ), CreateTimer( ) )
		endif

		return GetHandleId( LoadTimerHandle( HashTable, GetHandleId( Player( PID ) ), StringHash( "Timer_Num_" + I2S( Iterator ) ) ) )
	endfunction

	function LoadMUITimer takes integer PID returns timer
		local integer Iterator = LoadInteger( HashTable, GetHandleId( Player( PID ) ), StringHash( "TimerIterator" ) )
		call SaveBoolean( HashTable, GetHandleId( LoadTimerHandle( HashTable, GetHandleId( Player( PID ) ), StringHash( "Timer_Num_" + I2S( Iterator ) ) ) ), StringHash( "TimerStarted" ), true )
		return LoadTimerHandle( HashTable, GetHandleId( Player( PID ) ), StringHash( "Timer_Num_" + I2S( Iterator ) ) )
	endfunction	

	function TimerPause takes timer LocTimer returns nothing
		if LoadBoolean( HashTable, GetHandleId( LocTimer ), StringHash( "TimerStarted" ) ) then
			call PauseTimer( LocTimer )
			call SaveBoolean( HashTable, GetHandleId( LocTimer ), StringHash( "TimerStarted" ), false )
		endif
	endfunction	

	function TimerResume takes timer LocTimer returns nothing
		if not LoadBoolean( HashTable, GetHandleId( LocTimer ), StringHash( "TimerStarted" ) ) then
			call ResumeTimer( LocTimer )
			call SaveBoolean( HashTable, GetHandleId( LocTimer ), StringHash( "TimerStarted" ), true )
		endif
	endfunction

	function CleanMUI takes timer Timer returns nothing
		call TimerPause( Timer )
		call FlushChildHashtable( HashTable, GetHandleId( Timer ) )
	endfunction

	function PTimer takes handle Target, string HashName returns integer
		if LoadTimerHandle( HashTable, GetHandleId( Target ), StringHash( HashName ) ) == null then
			call SaveTimerHandle( HashTable, GetHandleId( Target ), StringHash( HashName ), CreateTimer( ) )
		endif

		return GetHandleId( LoadTimerHandle( HashTable, GetHandleId( Target ), StringHash( HashName ) ) )
	endfunction

	function Ability_Handler takes integer AID, unit Source, unit Target, real TargX, real TargY, code Action returns integer
		local integer PID = GetPlayerId( GetOwningPlayer( Source ) )
		local integer ALvL = GetUnitAbilityLevel( Source, AID )
		local integer HandleID = NewMUITimer( PID )
		call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
		call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
		call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), Source )
		call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( Source ) )
		call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( Source ) )
		if Target == null then
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), TargX )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), TargY )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( Source, TargX, TargY ) )
		else
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), Target )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetUnitX( Target ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetUnitY( Target ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitsAngle( Source, Target ) )
		endif
		call TimerStart( LoadMUITimer( PID ), .01, true, Action )
		return HandleID
	endfunction

	function MUIHandle takes nothing returns integer
		return GetHandleId( GetExpiredTimer( ) )
	endfunction

	function GetItem takes string HashName returns item
		return LoadItemHandle( HashTable, MUIHandle( ), StringHash( HashName ) )
	endfunction	

	function GetPlayer takes string HashName returns player
		return LoadPlayerHandle( HashTable, MUIHandle( ), StringHash( HashName ) )
	endfunction	

	function GetUnit takes string HashName returns unit
		return LoadUnitHandle( HashTable, MUIHandle( ), StringHash( HashName ) )
	endfunction	
	
	function GetGroup takes string HashName returns group
		return LoadGroupHandle( HashTable, MUIHandle( ), StringHash( HashName ) )
	endfunction	

	function GetStr takes string HashName returns string
		return LoadStr( HashTable, MUIHandle( ), StringHash( HashName ) )
	endfunction

	function GetInt takes string HashName returns integer
		return LoadInteger( HashTable, MUIHandle( ), StringHash( HashName ) )
	endfunction	

	function GetReal takes string HashName returns real
		return LoadReal( HashTable, MUIHandle( ), StringHash( HashName ) )
	endfunction

	function GetBool takes string HashName returns boolean 
		return LoadBoolean( HashTable, MUIHandle( ), StringHash( HashName ) )
	endfunction	

	function GetEffect takes string HashName returns effect 
		return LoadEffectHandle( HashTable, MUIHandle( ), StringHash( HashName ) )
	endfunction

	function GetLightning takes string HashName returns lightning 
		return LoadLightningHandle( HashTable, MUIHandle( ), StringHash( HashName ) )
	endfunction	

	function Stop_Spells takes nothing returns boolean
		return LoadBoolean( HashTable, GetHandleId( HashTable ), StringHash( "Event_Stop_Spells" ) )
	endfunction

	function Stop_Spell takes integer Type returns boolean
		if Stop_Spells( ) then
			return true
		endif

		if Type == 0 then
			return UnitLife( GetUnit( "Caster" ) ) <= 0
	elseif Type == 1 then
			return UnitLife( GetUnit( "Target" ) ) <= 0
	elseif Type == 2 then
			return UnitLife( GetUnit( "Caster" ) ) <= 0 or UnitLife( GetUnit( "Target" ) ) <= 0
		endif

		return false
	endfunction	

	function Counter takes integer Num, integer Limit returns boolean
		if not GetBool( "FirstCounted" + I2S( Num ) ) then
			call SaveBoolean( HashTable, MUIHandle( ), StringHash( "FirstCounted" + I2S( Num ) ), true )
			return true
		endif

		call SaveInteger( HashTable, MUIHandle( ), StringHash( "Counter" + I2S( Num ) ), GetInt( "Counter" + I2S( Num ) ) + 1 )
		if GetInt( "Counter" + I2S( Num ) ) == Limit then
			call SaveInteger( HashTable, MUIHandle( ), StringHash( "Counter" + I2S( Num ) ), 0 )
			return true
		endif

		return false
	endfunction

	function StoreTime takes string Type, integer Time returns nothing
		call SaveInteger( HashTable, MUIHandle( ), StringHash( Type ), Time )
	endfunction

	function Add_Player_Int takes integer PID, string Stats returns nothing // ????????? "Kill"/"Death" ? ??????????/?????????? ?????,  ????????? +1 ? ?????????? ?? ????????? ?????????
		local integer HandleID = GetHandleId( Player( PID ) )
		local integer ChildKey = StringHash( "Player_" + I2S( PID ) + "_" + Stats )
		call SaveInteger( HashTable, HandleID, ChildKey, LoadInteger( HashTable, HandleID, ChildKey ) + 1 )
	endfunction
	
	function Sub_Player_Int takes integer PID, string Stats returns nothing
		local integer HandleID = GetHandleId( Player( PID ) )
		local integer ChildKey = StringHash( "Player_" + I2S( PID ) + "_" + Stats )
		call SaveInteger( HashTable, HandleID, ChildKey, LoadInteger( HashTable, HandleID, ChildKey ) - 1 )
	endfunction

	function Get_Player_Int takes integer PID, string Stats returns integer
		return LoadInteger( HashTable, GetHandleId( Player( PID ) ), StringHash( "Player_" + I2S( PID ) + "_" + Stats ) )
	endfunction

	function SpellTime takes nothing returns integer
		call SaveInteger( HashTable, MUIHandle( ), StringHash( "SpellTime" ), GetInt( "SpellTime" ) + 1 )
		return GetInt( "SpellTime" )
	endfunction

	function IsUnitIgnored takes unit Target returns boolean
		local integer Index = 0
		if LoadInteger( HashTable, MUIHandle( ), GetHandleId( Target ) ) == 0 then
			set Index = GetInt( "Last_Unit_Index" ) + 1
			call SaveInteger( HashTable, MUIHandle( ), StringHash( "Last_Unit_Index" ), Index )
			call SaveInteger( HashTable, MUIHandle( ), GetHandleId( Target ), Index )
		endif

		if Index != 0 then
			if not LoadBoolean( HashTable, MUIHandle( ), StringHash( "Unit_Damaged_" + I2S( Index ) ) ) then
				call SaveBoolean( HashTable, MUIHandle( ), StringHash( "Unit_Damaged_" + I2S( Index ) ), true )
				return false
			endif
		endif
		return true
	endfunction

	function SetUnitData takes unit Target, string HashName, integer Amount returns nothing
		call SaveInteger( HashTable, GetHandleId( Target ), StringHash( HashName ), Amount )
	endfunction 

	function GetUnitData takes unit Target, string HashName returns integer
		return LoadInteger( HashTable, GetHandleId( Target ), StringHash( HashName ) )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Dummy_Cast.j
	function DummyCast takes unit Owner, unit Caster, unit Target, real MoveX, real MoveY, real TargX, real TargY, boolean IsMoved, integer AID, integer ALvL, string Order, string TargType returns nothing
		local integer PID = GetPlayerId( GetOwningPlayer( Owner ) )
		if PID >= 0 and PID <= 15 then
			call SetUnitOwner( Caster, Player( PID ), false )
		endif
		if IsMoved then
			call SetUnitPosition( Caster, MoveX, MoveY )
		endif
		call UnitAddAbility( Caster, AID )
		call SetUnitAbilityLevel( Caster, AID, ALvL )
		if TargType == "aoe" then
			call IssueImmediateOrder( Caster, Order )
		elseif TargType == "target" then
			call IssueTargetOrder( Caster, Order, Target )
		elseif TargType == "point" then
			call IssuePointOrder( Caster, Order, TargX, TargY )
		endif
		call UnitRemoveAbility( Caster, AID )
		call SetUnitOwner( Caster, Player( PLAYER_NEUTRAL_AGGRESSIVE ), false )
	endfunction

	function TargetCastXY takes unit Source, unit Target, real MoveX, real MoveY, integer AID, integer ALvL, string Order returns nothing
		call DummyCast( Source, DummyCaster, Target, MoveX, MoveY, GetUnitX( Target ), GetUnitY( Target ), true, AID, ALvL, Order, "target" )
	endfunction

	function TargetCast takes unit Source, unit Target, integer AID, integer ALvL, string Order returns nothing
		call TargetCastXY( Source, Target, GetUnitX( Target ), GetUnitY( Target ), AID, ALvL, Order )
	endfunction

	function AoECastXY takes unit Caster, real TargX, real TargY, integer AID, integer ALvL, string Order returns nothing
		call DummyCast( Caster, DummyCaster, null, TargX, TargY, TargX, TargY, true, AID, ALvL, Order, "aoe" )
	endfunction

	function AoECast takes unit Caster, integer AID, integer ALvL, string Order returns nothing
		call AoECastXY( Caster, GetUnitX( Caster ), GetUnitY( Caster ), AID, ALvL, Order )
	endfunction

	function PointCast_XY takes real LocX, real LocY, real TargX, real TargY, integer AID, integer ALvL, string Order returns nothing
		if TargX == 0 and TargY == 0 then
			set TargX = LocX
			set TargY = LocY
		endif
		call DummyCast( null, DummyCaster, null, LocX, LocY, TargX, TargY, true, AID, ALvL, Order, "point" )
	endfunction

	function PointCast takes unit Source, integer AID, integer ALvL, string Order, real TargX, real TargY returns nothing
		call PointCast_XY( GetUnitX( Source ), GetUnitY( Source ), TargX, TargY, AID, ALvL, Order )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Events.j
	function UnitEvent takes trigger Trig, playerunitevent whichEvent, code Act returns trigger
		local integer index = 0

		loop
			call TriggerRegisterPlayerUnitEvent( Trig, Player( index ), whichEvent, null )
			set index = index + 1
			exitwhen index == bj_MAX_PLAYER_SLOTS
		endloop

		if Act != null then
			call TriggerAddAction( Trig, Act )
		endif
		
		return Trig
	endfunction

	function PlayerEvent takes trigger Trig, playerevent whichEvent, code Act returns trigger
		local integer index = 0

		loop
			call TriggerRegisterPlayerEvent( Trig, Player( index ), whichEvent )
			set index = index + 1
			exitwhen index == bj_MAX_PLAYER_SLOTS
		endloop

		if Act != null then
			call TriggerAddAction( Trig, Act )
		endif
		
		return Trig
	endfunction

	function ChatEvent takes trigger Trig, string Text, boolean Bool, code Act returns trigger
		local integer index = 0

		loop
			call TriggerRegisterPlayerChatEvent( Trig, Player( index ), Text, Bool )
			set index = index + 1
			exitwhen index == bj_MAX_PLAYER_SLOTS
		endloop

		if Act != null then
			call TriggerAddAction( Trig, Act )
		endif

		return Trig
	endfunction

	function TimedTrigger takes trigger Trig, real Time, boolean Flag, code Act returns trigger
		call TriggerRegisterTimerEvent( Trig, Time, Flag )

		if Act != null then
			call TriggerAddAction( Trig, Act )
		endif

		return Trig
	endfunction

	function Rect_Enter_Event takes trigger trig, real MinX, real MinY, real MaxX, real MaxY, code Act returns trigger
		local region rectRegion = CreateRegion( )
		call SetRect( SysRect, MinX, MinY, MaxX, MaxY )
		call RegionAddRect( rectRegion, SysRect )
		call TriggerRegisterEnterRegion( trig, rectRegion, null )
		if Act != null then
			call TriggerAddAction( trig, Act )
		endif
		set rectRegion = null
		return trig
	endfunction

	function Rect_Leave_Event takes trigger trig, real MinX, real MinY, real MaxX, real MaxY, code Act returns trigger
		local region rectRegion = CreateRegion( )
		call SetRect( SysRect, MinX, MinY, MaxX, MaxY )
		call RegionAddRect( rectRegion, SysRect )
		call TriggerRegisterLeaveRegion( trig, rectRegion, null )
		if Act != null then
			call TriggerAddAction( trig, Act )
		endif
		set rectRegion = null
		return trig
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Items.j
	function Move_Items_To_Center takes nothing returns nothing
		call SetItemPosition( GetEnumItem( ), -700, 300 )
	endfunction

	function Get_Item_Index takes unit whichUnit, integer itemId returns integer
		local integer index = 0

		loop
			set bj_lastCreatedItem = UnitItemInSlot( whichUnit, index )

			if bj_lastCreatedItem != null and GetItemTypeId( bj_lastCreatedItem ) == itemId then
				return index
			endif

			set index = index + 1
			exitwhen index >= bj_MAX_INVENTORY
		endloop

		return -1
	endfunction

	function GetItemById takes unit whichUnit, integer itemId returns item
		local integer index = Get_Item_Index( whichUnit, itemId )

		if index == -1 then
			return null
		else
			return UnitItemInSlot( whichUnit, index )
		endif
	endfunction

	function SwapItems takes unit FromUnit, unit ToUnit returns nothing
		local integer i = 0
		local integer ItemID1
		local integer ItemID2
		
		loop
			exitwhen i == 6
			set ItemID1 = GetItemTypeId( UnitItemInSlot( FromUnit, i ) )
			set ItemID2 = GetItemTypeId( UnitItemInSlot( ToUnit, i ) )
			call RemoveItem( UnitItemInSlot( FromUnit, i ) )
			call RemoveItem( UnitItemInSlot( ToUnit, i ) )
			call UnitAddItemById( FromUnit, ItemID2 )
			call UnitAddItemById( ToUnit, ItemID1 )
			set i = i + 1
		endloop
	endfunction

	function ConditionalItemCopy takes unit FromUnit, unit ToUnit returns nothing
		local integer i = 0
		local integer ItemID

		loop
			exitwhen i == 6
			set ItemID = GetItemTypeId( UnitItemInSlot( FromUnit, i ) )
			call RemoveItem( UnitItemInSlot( FromUnit, i ) )
			call RemoveItem( UnitItemInSlot( ToUnit, i ) )
			call UnitAddItemById( ToUnit, ItemID )
			set i = i + 1
		endloop
	endfunction

	function Unit_Remove_All_Items takes unit Target returns nothing
		local integer i = 0

		loop
			exitwhen i == 6
			call RemoveItem( UnitItemInSlot( Target, i ) )
			set i = i + 1
		endloop
	endfunction

	function Unit_Drop_All_Items takes unit Target returns nothing
		local integer i = 0
		loop
			exitwhen i == 6
			call UnitRemoveItemFromSlot( Target, i )
			set i = i + 1
		endloop
	endfunction

	function HasItem takes unit Unit, integer ItemID returns boolean
		return Get_Item_Index( Unit, ItemID ) >= 0
	endfunction
	
	function CombineItem takes unit SysUnit, integer ItemID, integer EffectType returns nothing
		if ItemID != 0 then
			call UnitAddItemById( SysUnit, ItemID )
		endif

		if EffectType == 0 then
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", SysUnit, "origin" ) )
		elseif EffectType == 1 then
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl", SysUnit, "origin" ) )
		elseif EffectType == 2 then
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl", SysUnit, "origin" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", SysUnit, "origin" ) )
		elseif EffectType == 3 then
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\ReviveHuman\\ReviveHuman.mdl", SysUnit, "origin" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\ReviveHuman\\ReviveHuman.mdl", SysUnit, "origin" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\ReviveHuman\\ReviveHuman.mdl", SysUnit, "origin" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\ReviveHuman\\ReviveHuman.mdl", SysUnit, "origin" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\ReviveHuman\\ReviveHuman.mdl", SysUnit, "origin" ) )
		elseif EffectType == 4 then
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", SysUnit, "origin" ) )
		endif
	endfunction

	function Allies_Have_Item takes integer ID, integer ItemID returns boolean
		local boolean ItemFound = false
		local integer i = 0
		loop
			exitwhen i > 11 or ItemFound
			if IsPlayerAlly( Player( ID ), Player( i ) ) and Player( ID ) != Player( i ) then
				set ItemFound = HasItem( PlayerUnit[ i ], ItemID )
			endif
			set i = i + 1
		endloop

		return ItemFound
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Groups.j
	function Add_To_Dummy_Group takes nothing returns nothing
		call GroupAddUnit( SpellGroup, GetEnumUnit( ) )
	endfunction

	function Make_Dummy_Group takes group sourceGroup returns nothing
		call GroupClear( SpellGroup )
		call ForGroup( sourceGroup, function Add_To_Dummy_Group )
	endfunction

	function EnumUnits_AOE takes group Group, real LocX, real LocY, real AoE returns group
		call GroupClear( Group )
		call GroupEnumUnitsInRange( Group, LocX, LocY, AoE, null )
		return Group
	endfunction
	
	function EnumUnits_Rect takes group Group, rect WhatRect returns group
		call GroupClear( Group )
		call GroupEnumUnitsInRect( Group, WhatRect, null )
		return Group
	endfunction

	function EnumUnits_Player takes group Group, integer PID returns group
		call GroupClear( Group )
		call GroupEnumUnitsOfPlayer( Group, Player( PID ), null )
		return Group
	endfunction

	function DestroyFilterDestruct takes nothing returns boolean
		if GetDestructableLife( GetFilterDestructable( ) ) > 0 then
			call KillDestructable( GetFilterDestructable( ) )
		endif
		return true
	endfunction

	function DestroyAoEDestruct takes real LocX, real LocY, real AoE returns nothing
		if AoE > 0 then
			call SetRect( SysRect, LocX - AoE, LocY - AoE, LocX + AoE, LocY + AoE )
			call EnumDestructablesInRect( SysRect, Filter( function DestroyFilterDestruct ), null )
		endif
	endfunction

	function IsGroupEmpty takes group Group returns boolean
		return FirstOfGroup( Group ) == null
	endfunction

	function Count_Player_Unit takes player WhatPlayer, integer UID returns integer
		local integer Unit_Count = 0
		call GroupClear( SysGroup )
		call GroupEnumUnitsOfPlayer( SysGroup, WhatPlayer, null )
		loop
			set SysUnit = FirstOfGroup( SysGroup )
			exitwhen SysUnit == null
			if GetUnitTypeId( SysUnit ) == UID or UID == -1 then
				set Unit_Count = Unit_Count + 1
			endif
			call GroupRemoveUnit( SysGroup, SysUnit )
		endloop

		return Unit_Count
	endfunction	

	function Count_Players_By_Control takes mapcontrol Controller returns integer
		local integer PID = 0
		local integer Count = 0
		loop
			if GetPlayerController( Player( PID ) ) == Controller then
				set Count = Count + 1
			endif
			set PID = PID + 1
			exitwhen PID == bj_MAX_PLAYER_SLOTS
		endloop
		return Count
	endfunction

	function RemoveUnitOfPlayerByID takes integer PID, integer UID returns nothing
		call GroupClear( SysGroup )
		call GroupEnumUnitsOfPlayer( SysGroup, Player( PID ), null )
		loop
			set SysUnit = FirstOfGroup( SysGroup )
			exitwhen SysUnit == null
			if GetUnitTypeId( SysUnit ) == UID then
				call RemoveUnit( SysUnit )
			endif
			call GroupRemoveUnit( SysGroup, SysUnit )
		endloop
	endfunction

	function Remove_By_UID_In_Rect takes integer UID, rect WhatRect returns nothing
		call EnumUnits_Rect( SysGroup, WhatRect )
		loop
			set Dummy = FirstOfGroup( SysGroup )
			exitwhen Dummy == null
			if GetUnitTypeId( Dummy ) == UID then
				call RemoveUnit( Dummy )
			endif
			call GroupRemoveUnit( SysGroup, Dummy )
		endloop	
	endfunction

	function CountUnitsInAoE takes integer PID, real LocX, real LocY, real AoE, string Type, boolean IsEnemy returns integer
		local integer UnitCount = 0
		local boolean Flag = false
		call GroupClear( Collector )
		call EnumUnits_AOE( SysGroup, LocX, LocY, AoE )
		loop
			set Dummy = FirstOfGroup( SysGroup )
			exitwhen Dummy == null
			if IsUnitEnemy( Dummy, Player( PID ) ) == IsEnemy then
				if DefaultUnitFilter( Dummy ) then
					if Type != "" then
						if Type == "hero" then
							if IsUnitType( Dummy, UNIT_TYPE_HERO ) then
								set Flag = true
							endif
						endif
					else
						set Flag = true
					endif

					if Flag then
						set UnitCount = UnitCount + 1
						call GroupAddUnit( Collector, Dummy )
						set Flag = false
					endif
				endif
			endif
			call GroupRemoveUnit( SysGroup, Dummy )
		endloop

		return UnitCount
	endfunction

	function GetRandomUnitInAoE takes integer PID, real LocX, real LocY, real AoE, string Type, boolean IsEnemy returns unit
		local integer UnitCount = CountUnitsInAoE( PID, LocX, LocY, AoE, Type, IsEnemy )
		local real Chance

		if UnitCount == 0 then
			return null
		endif

		set Chance = 1. / UnitCount
		loop
			set Dummy = FirstOfGroup( Collector )
			exitwhen Dummy == null
			if GetRandomReal( 0, 1 ) <= Chance or UnitCount == 1 then
				call GroupClear( Collector )
				return Dummy
			else
				set UnitCount = UnitCount - 1
			endif
			call GroupRemoveUnit( Collector, Dummy )
		endloop

		return null
	endfunction

	function GetRandomEnemyHeroInArea takes integer PID, real LocX, real LocY, real AoE returns unit
		return GetRandomUnitInAoE( PID, LocX, LocY, AoE, "hero", true )
	endfunction

	function GetRandomEnemyUnitInArea takes integer PID, real LocX, real LocY, real AoE returns unit
		return GetRandomUnitInAoE( PID, LocX, LocY, AoE, "", true )
	endfunction

	function IsEnemyUnitInAoE takes integer PID, real TargX, real TargY, real AoE returns boolean
		return CountUnitsInAoE( PID, TargX, TargY, AoE, "", true ) > 0
	endfunction

	function IsEnemyHeroInAoE takes integer PID, real TargX, real TargY, real AoE returns boolean
		return CountUnitsInAoE( PID, TargX, TargY, AoE, "hero", true ) > 0
	endfunction

	function BasicAoEDMG takes unit Source, real TargX, real TargY, real AoE, real DMG, string Type returns nothing
		if TargX == 0 and TargY == 0 then
			set TargX = GetUnitX( Source )
			set TargY = GetUnitY( Source )
		endif

		call DestroyAoEDestruct( TargX, TargY, AoE )
		call EnumUnits_AOE( SpellGroup, TargX, TargY, AoE )

		loop
			set SysUnit = FirstOfGroup( SpellGroup )
			exitwhen SysUnit == null

			if IsUnitEnemy_v2( Source, SysUnit ) then
				call Damage_Unit( Source, SysUnit, DMG, Type )
			endif

			call GroupRemoveUnit( SpellGroup, SysUnit )
		endloop
	endfunction

	function MUIAoEDMG takes unit Source, real TargX, real TargY, real AoE, real DMG, string Type returns nothing
		if TargX == 0 and TargY == 0 then
			set TargX = GetUnitX( Source )
			set TargY = GetUnitY( Source )
		endif

		call DestroyAoEDestruct( TargX, TargY, AoE )
		call EnumUnits_AOE( SpellGroup, TargX, TargY, AoE )

		loop
			set SysUnit = FirstOfGroup( SpellGroup )
			exitwhen SysUnit == null

			if IsUnitEnemy_v2( Source, SysUnit ) and not IsUnitIgnored( SysUnit ) then
				call Damage_Unit( Source, SysUnit, DMG, Type )
			endif

			call GroupRemoveUnit( SpellGroup, SysUnit )
		endloop
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Units.j
	function GetOwningId takes unit Unit returns integer
		return GetPlayerId( GetOwningPlayer( Unit ) )
	endfunction

	function PanCameraUnit takes unit WhatUnit returns nothing
		if GetLocalPlayer( ) == GetOwningPlayer( WhatUnit ) then
			call PanCameraToTimed( GetUnitX( WhatUnit ), GetUnitY( WhatUnit ), 0 )
		endif
	endfunction

	function SelectPlayerUnit takes unit WhatUnit, boolean IsPan returns nothing
		if GetLocalPlayer( ) == GetOwningPlayer( WhatUnit ) then
			call ClearSelection( )
			if IsPan then
				call PanCameraUnit( WhatUnit )
			endif
			if UnitLife( WhatUnit ) > 0 then
				call SelectUnit( WhatUnit, true )
			endif
		endif
	endfunction

	function SelectedUnit takes player Target returns unit
		set Unr_Unit = null
		call GroupEnumUnitsSelected( SysGroup, Target, null )
		set Unr_Unit = FirstOfGroup( SysGroup )
		call GroupClear( SysGroup )
		return Unr_Unit
	endfunction

	function RemoveUnitWithEffect takes unit Target, string Effect returns nothing
		if Target != null then
			call DestroyEffect( AddSpecialEffect( Effect, GetUnitX( Target ), GetUnitY( Target ) ) )
			call RemoveUnit( Target )
		endif
	endfunction

	function Init_DamagedCheck takes unit Target returns nothing
		if not LoadBoolean( HashTable, GetHandleId( Target ), StringHash( "Registered" ) ) then
			call SaveBoolean( HashTable, GetHandleId( Target ), StringHash( "Registered" ), true )
			call TriggerRegisterUnitEvent( LoadTrig( "Event_Damaged" ), Target, EVENT_UNIT_DAMAGED )
		endif
	endfunction

	function Remove_Buffs takes unit Target returns nothing
		call UnitRemoveAbility( Target, 'B00A' )
		call UnitRemoveAbility( Target, 'BNdo' )
		call UnitRemoveAbility( Target, 'BNdi' )
		call UnitRemoveAbility( Target, 'B00P' )
		call UnitRemoveAbility( Target, 'B02N' )
		call UnitRemoveAbility( Target, 'B02M' )
	endfunction
	
	function SetUnitInvul takes unit Target, boolean Flag returns nothing
		call SetUnitInvulnerable( Target, Flag )
		call SaveBoolean( HashTable, GetHandleId( Target ), StringHash( "Has_Invul" ), Flag )
	endfunction

	function ScaleUnit takes unit Target, real Size returns unit
		call SetUnitScale( Target, Size, Size, Size )
		return Target
	endfunction

	function PlaySoundOnUnit takes sound soundHandle, real volumePercent, unit whichUnit returns nothing
		call SetSoundPosition( soundHandle, GetUnitX( whichUnit ), GetUnitY( whichUnit ), 0 )
		call SetSoundVolume( soundHandle, PercentToInt( volumePercent, 127 ) )
		if soundHandle != null then
			call StartSound( soundHandle )
		endif
	endfunction

	function CreateUnit_S_L takes unit NewUnit, real TimeScale, real Life returns unit
		call SetUnitTimeScale( NewUnit, TimeScale )
		call UnitApplyTimedLife( NewUnit, 'BTLF', Life )
		return NewUnit
	endfunction

	function SwapUnits takes unit FromUnit, unit ToUnit, boolean WithOwner returns nothing
		local integer OwnerID = GetPlayerId( GetOwningPlayer( FromUnit ) )
		local integer TargetID = GetPlayerId( GetOwningPlayer( ToUnit ) )
		local real ToX = GetUnitX( ToUnit )
		local real ToY = GetUnitY( ToUnit )
		local real FromX = GetUnitX( FromUnit )
		local real FromY = GetUnitY( FromUnit )
		if WithOwner then
			call SetUnitOwner( ToUnit, Player( OwnerID ), true )
			call SetUnitOwner( FromUnit, Player( TargetID ), true )
		endif
		call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\Unsummon\\UnsummonTarget.mdl", GetUnitX( FromUnit ), GetUnitY( FromUnit ) ) )
		call PauseUnit( FromUnit, true )
        call SetUnitInvul( FromUnit, true )
		call PauseUnit( ToUnit, false )
        call SetUnitInvul( ToUnit, false )
		call UnitAddAbility( FromUnit, 'Agho' )
		call UnitRemoveAbility( ToUnit, 'Agho' )
		call UnitRemoveBuffs( FromUnit, false, true )
		call UnitRemoveBuffs( ToUnit,   false, true )
		call ConditionalItemCopy( FromUnit, ToUnit )
		call SetHeroXP( ToUnit, GetHeroXP( FromUnit ), false )
		call SetHeroLevel( ToUnit, GetHeroLevel( FromUnit ), false )
		call SetHeroStr( ToUnit, GetHeroStr( FromUnit, false ), true )
		call SetHeroAgi( ToUnit, GetHeroAgi( FromUnit, false ), true )
		call SetHeroInt( ToUnit, GetHeroInt( FromUnit, false ), true )
		call SetWidgetLife( ToUnit, GetWidgetLife( FromUnit ) )
		call SetUnitXY_1( ToUnit, FromX, FromY, true )
		call SetUnitFacing( ToUnit, GetUnitFacing( FromUnit ) )
		call SetUnitXY_1( FromUnit, ToX, ToY, true )
		set PlayerUnit[ OwnerID ] = ToUnit
		call SelectPlayerUnit( ToUnit, false )
	endfunction

	function MakeUnitAirborne takes unit AirUnit, real AirHeight, real AirRate returns nothing
		if not HasAbility( AirUnit, 'Amrf' ) then
			call UnitAddAbility( AirUnit, 'Amrf' )
		endif
		call SetUnitFlyHeight( AirUnit, AirHeight, AirRate )
	endfunction	
	//#ExportEnd

	//#ExportTo Scripts\API\CC_Engine.j
	function CC_Cast takes unit Target, string Order, string Type returns nothing
		local integer PID = 13

		if Order == "rejuvination" then
			set PID = GetOwningId( Target )
		endif

		call SetUnitOwner( LoadUnitHandle( HashTable, GetHandleId( HashTable ), StringHash( "CC_Dummy" ) ), Player( PID ), false )
		call UnitShareVision(  Target, Player( PID ), true )
		call SetUnitPosition(  LoadUnitHandle( HashTable, GetHandleId( HashTable ), StringHash( "CC_Dummy" ) ), GetUnitX( Target ), GetUnitY( Target ) )
		if Type == "Target" then
			call IssueTargetOrder( LoadUnitHandle( HashTable, GetHandleId( HashTable ), StringHash( "CC_Dummy" ) ), Order, Target )
	elseif Type == "AoE" then
			call IssuePointOrder( LoadUnitHandle( HashTable, GetHandleId( HashTable ), StringHash( "CC_Dummy" ) ), Order, GetUnitX( Target ), GetUnitY( Target ) )
		endif
		call UnitShareVision( Target, Player( PID ), false )
		call SetUnitOwner( LoadUnitHandle( HashTable, GetHandleId( HashTable ), StringHash( "CC_Dummy" ) ), Player( 13 ), false )
	endfunction

	function CC_Checker takes nothing returns nothing
		local integer Data = GetUnitData( GetUnit( "Target" ), GetStr( "Type" ) )

		if Data > 0 then
			call SetUnitData( GetUnit( "Target" ), GetStr( "Type" ), Data - 1 )
		else
			call UnitRemoveAbility( GetUnit( "Target" ), GetInt( "Buff" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function CC_Unit takes unit Target, real Time, string Type, boolean IsReduced returns nothing
		local string Order
		local string T_Type = "Target"
		local integer Buff = 0
		local integer PID = GetPlayerId( GetOwningPlayer( Target ) )
		local integer HandleID
		set Type = StringCase( Type, false )

		if IsReduced then // set Time = Time / CCMitigation
		endif

		if Type == "stun" then
			set Order = "thunderbolt"
			if not HasAbility( Target, 'BPSE' ) then
				set Buff = 'BPSE'
			endif
		endif

		if Type == "silence" then
			set Order = "silence"
			set T_Type = "AoE"
			if not HasAbility( Target, 'B02M' ) then
				set Buff = 'B02M'
			endif
		endif

		if Type == "sleep" then
			set Order = "sleep"
			if not HasAbility( Target, 'BUsl' ) then
				set Buff = 'BUsl'
			endif
		endif

		if Type == "slow" then
			set Order = "slow"
			if not HasAbility( Target, 'Bslo' ) then
				set Buff = 'Bslo'
			endif
		endif

		if Order != "" then
			call SetUnitData( Target, Type, R2I( Time * 100 ) + GetUnitData( Target, Type ) )
			if Buff != 0 then
				set HandleID = NewMUITimer( PID )
				call CC_Cast( Target, Order, T_Type )
				call SaveStr( HashTable, HandleID, StringHash( "Type" ), Type )
				call SaveInteger( HashTable, HandleID, StringHash( "Buff" ), Buff )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), Target )
				call TimerStart( LoadMUITimer( PID ), .01, true, function CC_Checker )
			endif
		endif
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Miscellaneous.j
	function TransformDisplace takes unit Caster returns nothing
		local integer PID = GetPlayerId( GetOwningPlayer( Caster ) )
		local integer UID = GetUnitTypeId( Caster )
		local integer ALvL
		local real LocDist = 100
		local real Angle
		local real MoveX
		local real MoveY

		if GetUnitTypeId( Caster ) != 'EC12' then
			call AoECast( Caster, 'A01B', 1, "thunderclap" )
		endif

		call DestroyAoEDestruct( GetUnitX( Caster ), GetUnitY( Caster ), 460 )
		call EnumUnits_AOE( SysGroup, GetUnitX( Caster ), GetUnitY( Caster ), 460 )
		loop
			set SysUnit = FirstOfGroup( SysGroup )
			exitwhen SysUnit == null

			if IsUnitEnemy_v2( Caster, SysUnit ) and DefaultUnitFilter( SysUnit ) then
				set Angle = GetUnitsAngle( Caster, SysUnit )
				set MoveX = NewX( GetUnitX( SysUnit ), LocDist, Angle )
				set MoveY = NewY( GetUnitY( SysUnit ), LocDist, Angle )
				if UID == 'EC12' then
					call TargetCast( Caster, SysUnit, 'A02H', 1, "frostnova" )
				endif
				call IssueImmediateOrder( SysUnit, "stop" )
				call SetUnitXY_1( SysUnit, MoveX, MoveY, true )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl", SysUnit, "origin" ) )
			endif

			call GroupRemoveUnit( SysGroup, SysUnit )
		endloop
	endfunction

	function Youruichi_Lightning takes unit Source, unit Target returns nothing
		call TargetCastXY( Source, Target, GetUnitX( Source ), GetUnitY( Source ), 'A07H', 1, "chainlightning" )
	endfunction

	function CircularEffect takes unit Target, real Distance, real Step, string Effect returns nothing
		local real i 	 = 1
		local real Limit = 360 / Step
		local real TargX = GetUnitX( Target )
		local real TargY = GetUnitY( Target )
		local real Angle = 0

        loop
            exitwhen i > Limit
            set Angle = Angle + Step
			call DestroyEffect( AddSpecialEffect( Effect, NewX( TargX, Distance, Angle ), NewY( TargY, Distance, Angle ) ) )
            set i = i + 1
        endloop
	endfunction

	function FindEmptyString takes integer Begin, string Text returns integer
		local integer i = Begin

		loop
			if SubString( Text, i, i + 1 ) == " " then
				return i
			endif
			exitwhen i == StringLength( Text )
			set i = i + 1
		endloop

		return StringLength( Text )
	endfunction

	function FindHeroInArray takes integer UID returns integer
		local integer i = 1
		loop
			if UID == LoadInt( "Hero_UID_" + I2S( i ) ) then
				return i
			endif
			set i = i + 1
		endloop
		return -1
	endfunction

	function FindRandomHero takes nothing returns integer
		local integer RandInt = GetRandomInt( 1, LoadInt( "Total_Heroes" ) )
		loop
			set RandInt = GetRandomInt( 1, LoadInt( "Total_Heroes" ) )
			exitwhen not LoadBool( "Hero_Selected_" + I2S( RandInt ) )
		endloop

		return RandInt
	endfunction

	function Pause_All takes boolean Flag returns nothing
		local integer UID = GetUnitTypeId( GetFilterUnit( ) )
		call EnumUnits_Rect( Pauser_Group, GetWorldBounds( ) )
		loop
			set SysUnit = FirstOfGroup( Pauser_Group )
			exitwhen SysUnit == null
			set UID = GetUnitTypeId( SysUnit )
			if GetPlayerId( GetOwningPlayer( SysUnit ) ) <= 11 and UID != 'nsgg' and not HasAbility( SysUnit, 'A01Q' ) then
				call SetUnitInvul( SysUnit, Flag )
				call PauseUnit( SysUnit, Flag )
				call IssueImmediateOrder( SysUnit, "stop" )
			endif
			call GroupRemoveUnit( Pauser_Group, SysUnit )
		endloop
	endfunction

	function MakeSound takes string SoundName returns sound
		return CreateSound( SoundName, false, false, false, 12700, 12700, "DefaultEAXON" )
	endfunction	

	function GetHint takes integer ID, string Name returns integer
		return ID
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Linear_Spell.j
	function Linear_Spell_Act takes nothing returns nothing
		local integer HandleID = GetHandleId( GetExpiredTimer( ) )
		local integer Time = SpellTime( )
		if Time == 1 then
			call SaveEffectHandle( HashTable, HandleID, StringHash( "DummyEff_1" ), AddSpecialEffectTarget( GetStr( "Projectile" ), GetUnit( "Dummy_1" ), "origin" ) )
			call ScaleUnit( GetUnit( "Dummy_1" ), GetReal( "Scale" ) )
			call SetUnitFlyHeight( GetUnit( "Dummy_1" ), 50, 999999 )
			call SetUnitPathing( GetUnit( "Dummy_1" ), false )
		endif

		if Time > 1 then
			call SaveReal( HashTable, HandleID, StringHash( "MoveDist" ), GetReal( "MoveDist" ) + GetReal( "Step" ) )
			call SaveReal( HashTable, HandleID, StringHash( "MoveX" ), NewX( GetUnitX( GetUnit( "Dummy_1" ) ), GetReal( "Step" ), GetReal( "Angle" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "MoveY" ), NewY( GetUnitY( GetUnit( "Dummy_1" ) ), GetReal( "Step" ), GetReal( "Angle" ) ) )
			call SetUnitXY_1( GetUnit( "Dummy_1" ), GetReal( "MoveX" ), GetReal( "MoveY" ), true )
			if GetStr( "Effect" ) != "" then
				call DestroyEffect( AddSpecialEffect( GetStr( "Effect" ), GetReal( "MoveX" ), GetReal( "MoveY" ) ) )
			endif
			if GetReal( "Damage" ) > 0 then
				call MUIAoEDMG( GetUnit( "Caster" ), GetReal( "MoveX" ), GetReal( "MoveY" ), GetReal( "AoE" ), GetReal( "Damage" ), "magical" )
			endif
			if GetReal( "MoveDist" ) >= GetReal( "MaxDistance" ) or Stop_Spells( ) then
				call KillUnit( GetUnit( "Dummy_1" ) )
				call DestroyEffect( GetEffect( "DummyEff_1" ) )
				call CleanMUI( GetExpiredTimer( ) )
			endif
		endif
	endfunction

	function Linear_Spell_XY takes unit Caster, real InitX, real InitY, real Angle, string Projectile, real Speed, real Distance, real AoE, real Scale, real Damage, string Effect, string DMG_Type returns unit
		local integer PID = GetPlayerId( GetOwningPlayer( Caster ) )
		local integer HandleID = NewMUITimer( PID )
		call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), Caster )
		call SaveStr(  HashTable, HandleID, StringHash( "Projectile" ), Projectile )
		call SaveStr(  HashTable, HandleID, StringHash( "Effect" ), Effect )
		call SaveStr(  HashTable, HandleID, StringHash( "DMG_Type" ), DMG_Type )
		call SaveReal( HashTable, HandleID, StringHash( "Scale" ), Scale )
		call SaveReal( HashTable, HandleID, StringHash( "AoE" ), AoE )
		call SaveReal( HashTable, HandleID, StringHash( "Step" ), R2I( SquareRoot( Speed ) / 2 ) )
		call SaveReal( HashTable, HandleID, StringHash( "MaxDistance" ), Distance )
		call SaveReal( HashTable, HandleID, StringHash( "Damage" ), Damage )
		call SaveReal( HashTable, HandleID, StringHash( "Angle" ),  Angle )
		call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'u999', InitX, InitY, Angle ) )
		call TimerStart( LoadMUITimer( PID ), .01, true, function Linear_Spell_Act )
		return LoadUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ) )
	endfunction

	function Linear_Spell takes unit Caster, real TargX, real TargY, string Projectile, real Speed, real Distance, real AoE, real Scale, real Damage, string Effect returns unit
		local real Angle = GetAngleCast( Caster, TargX, TargY )
		local real SetX  = NewX( GetUnitX( Caster ), 100, Angle )
		local real SetY  = NewY( GetUnitY( Caster ), 100, Angle )
		return Linear_Spell_XY( Caster, SetX, SetY, Angle, Projectile, Speed, Distance, AoE, Scale, Damage, Effect, "magical" )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Linear_Displacer.j
	function LinearDisplacementAction takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local real 	  MoveX    = GetUnitX( GetUnit( "Displaced" ) ) + GetReal( "MaxDistance" ) * GetReal( "AngleX" )
		local real 	  MoveY    = GetUnitY( GetUnit( "Displaced" ) ) + GetReal( "MaxDistance" ) * GetReal( "AngleY" )

		if GetReal( "Duration" ) > 0 and UnitLife( GetUnit( "Displaced" ) ) > 0 and not GetBool( "StopMovement" ) then
			if not GetBool( "Pathing" ) and IsTerrainPathable( MoveX, MoveY, PATHING_TYPE_WALKABILITY ) then
				call SaveBoolean( HashTable, HandleID, StringHash( "StopMovement" ), true )
			else
				call IssueImmediateOrder( GetUnit( "Displaced" ), "stop" )
				call SaveReal( HashTable, HandleID, StringHash( "Duration" ), GetReal( "Duration" ) - 1 )
				call SetUnitXY_1( GetUnit( "Displaced" ), MoveX, MoveY, true )
				call DestroyAoEDestruct( MoveX, MoveY, 150 )
				if GetStr( "Effect" ) != null and GetUnitFlyHeight( GetUnit( "Displaced" ) ) < 5. then
					call DestroyEffect( AddSpecialEffect( GetStr( "Effect" ), GetUnitX( GetUnit( "Displaced" ) ), GetUnitY( GetUnit( "Displaced" ) ) ) )
				endif
				call SaveReal( HashTable, HandleID, StringHash( "MaxDistance" ), GetReal( "MaxDistance" ) - GetReal( "MoveRate" ) )
			endif
		else
			call SaveBoolean( HashTable, GetHandleId( GetUnit( "Displaced" ) ), StringHash( "IsDisplaced" ), false )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function LinearDisplacement takes unit Target, real Facing, real Distance, real Time, real Rate, boolean DestrDoodad, boolean Pathing, string Attach, string Effect returns nothing
		local integer PID
		local integer HandleID

		if Target != null then
			set PID = GetPlayerId( GetOwningPlayer( Target ) )
			set HandleID = NewMUITimer( PID )
			call SaveReal( HashTable, HandleID, StringHash( "AngleX" ), Cos( Deg2Rad( Facing ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "AngleY" ), Sin( Deg2Rad( Facing ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "MaxDistance" ), 2 * Distance * Rate / Time )
			call SaveReal( HashTable, HandleID, StringHash( "MoveRate" ), ( 2 * Distance * Rate / Time ) * Rate / Time )
			call SaveReal( HashTable, HandleID, StringHash( "InitX" ), GetUnitX( Target ) )
			call SaveReal( HashTable, HandleID, StringHash( "InitY" ), GetUnitY( Target ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Displaced" ), Target )
		//	call SaveBoolean( HashTable, HandleID, StringHash( "DestroysDoodads" ), DestrDoodad )
			call SaveBoolean( HashTable, HandleID, StringHash( "Pathing" ), Pathing )
		//	call SaveStr( HashTable, HandleID, StringHash( "Attachment" ), Attach )
			call SaveStr( HashTable, HandleID, StringHash( "Effect" ), Effect )
			call SaveReal( HashTable, HandleID, StringHash( "Duration" ), Time / Rate )
			call SaveBoolean( HashTable, GetHandleId( Target ), StringHash( "IsDisplaced" ), true )
			call TimerStart( LoadMUITimer( PID ), Rate, true, function LinearDisplacementAction )
		endif
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\API\Arc_Displacer.j
	function DisplaceUnitAction takes nothing returns nothing
		local real Arc = ( -( 2 * GetReal( "InitSteep" ) * GetReal( "HeightStep" ) - 1 ) * ( 2 * GetReal( "InitSteep" ) * GetReal( "HeightStep" ) - 1 ) + 1 ) * GetReal( "MaxHeight" ) + GetReal( "DefaultHeight" )
		if GetReal( "InitSteep" ) < GetReal( "MaxSteep" ) and UnitLife( GetUnit( "Displaced" ) ) > 0 then
			call IssueImmediateOrder( GetUnit( "Displaced" ), "stop" )
			if not LoadBoolean( HashTable, GetHandleId( GetUnit( "Displaced" ) ), StringHash( "IsDisplaced" ) ) then
				call SetUnitXY_4( GetUnit( "Displaced" ), GetReal( "InitX" ), GetReal( "InitY" ), GetReal( "InitSteep" ) * GetReal( "MoveStep" ), GetReal( "Angle" ) )
			endif
			call SaveReal( HashTable, MUIHandle( ), StringHash( "InitSteep" ), GetReal( "InitSteep" ) + 1 )
			call SetUnitFlyHeight( GetUnit( "Displaced" ), Arc, 0 )
		else
			call SetUnitPathing( GetUnit( "Displaced" ), true )
			call SaveBoolean( HashTable, GetHandleId( GetUnit( "Displaced" ) ), StringHash( "IsDisplaced" ), false )
			call SetUnitFlyHeight( GetUnit( "Displaced" ), 0, 0 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function DisplaceUnitWithArgs takes unit LocTrigUnit, real LocAngle, real LocTotalDist, real LocTotalTime, real LocRate, real LocHeightMax returns nothing
		local integer LocPID
		local integer HandleID
		local integer LocSteepMax = R2I( LocTotalTime / LocRate )

		if LocTrigUnit != null then
			set LocPID = GetPlayerId( GetOwningPlayer( LocTrigUnit ) )
			set HandleID = NewMUITimer( LocPID )
			call UnitAddAbility( LocTrigUnit, 'Amrf' )
			call UnitRemoveAbility( LocTrigUnit, 'Amrf' )		
			call SetUnitPathing( LocTrigUnit, false )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Displaced" ), LocTrigUnit )	
			call SaveReal( HashTable, HandleID, StringHash( "CurrentHeight" ), GetUnitFlyHeight( LocTrigUnit ) )
			call SaveReal( HashTable, HandleID, StringHash( "DefaultHeight" ), GetUnitDefaultFlyHeight( LocTrigUnit ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), LocAngle )
			call SaveReal( HashTable, HandleID, StringHash( "MoveStep" ), LocTotalDist / LocSteepMax )
			call SaveReal( HashTable, HandleID, StringHash( "MaxHeight" ), LocHeightMax )
			call SaveReal( HashTable, HandleID, StringHash( "HeightStep" ), 1. / LocSteepMax )
			call SaveReal( HashTable, HandleID, StringHash( "InitX" ), GetUnitX( LocTrigUnit ) )
			call SaveReal( HashTable, HandleID, StringHash( "InitY" ), GetUnitY( LocTrigUnit ) )
			call SaveReal( HashTable, HandleID, StringHash( "InitSteep" ), 0 )
			call SaveReal( HashTable, HandleID, StringHash( "MaxSteep" ), LocTotalTime / LocRate )
			call SaveBoolean( HashTable, GetHandleId( LocTrigUnit ), StringHash( "IsDisplaced" ), false )
			call TimerStart( LoadMUITimer( LocPID ), LocRate, true, function DisplaceUnitAction )
		endif
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\Lightning.j
	function LightBetUnit_Actions takes nothing returns nothing
		local integer i = GetHandleId(GetExpiredTimer())
		
		call SaveReal(HashTable, i, 3, LoadReal(HashTable, i, 3) - 0.01)
		
		if LoadReal(HashTable, i, 3) <= 0 or LoadUnitHandle(HashTable, i, 1) == null or LoadUnitHandle(HashTable, i, 2) == null then
			call DestroyTimer(GetExpiredTimer())
			call DestroyLightning(LoadLightningHandle(HashTable, i, 0))
			call FlushChildHashtable(HashTable, i)
		elseif LoadBoolean(HashTable, i, 4) then
			if GetWidgetLife(LoadUnitHandle(HashTable, i, 1)) < 0.405 or GetWidgetLife(LoadUnitHandle(HashTable, i, 2)) < 0.405 then
				call DestroyTimer(GetExpiredTimer())
				call DestroyLightning(LoadLightningHandle(HashTable, i, 0))
				call FlushChildHashtable(HashTable, i)
			else
				call MoveLightningEx(LoadLightningHandle(HashTable, i, 0), true, GetUnitX(LoadUnitHandle(HashTable, i, 1)), GetUnitY(LoadUnitHandle(HashTable, i, 1)), GetUnitFlyHeight(LoadUnitHandle(HashTable, i, 1)) + 50, GetUnitX(LoadUnitHandle(HashTable, i, 2)), GetUnitY(LoadUnitHandle(HashTable, i, 2)), GetUnitFlyHeight(LoadUnitHandle(HashTable, i, 2)) + 50)
			endif
		else
			call MoveLightningEx(LoadLightningHandle(HashTable, i, 0), true, GetUnitX(LoadUnitHandle(HashTable, i, 1)), GetUnitY(LoadUnitHandle(HashTable, i, 1)), GetUnitFlyHeight(LoadUnitHandle(HashTable, i, 1)) + 50, GetUnitX(LoadUnitHandle(HashTable, i, 2)), GetUnitY(LoadUnitHandle(HashTable, i, 2)), GetUnitFlyHeight(LoadUnitHandle(HashTable, i, 2)) + 50)
		endif
	endfunction

	function LightBetUnit takes real period, unit target1, unit target2, string lightningtype, real time, boolean Break, real red, real green, real blue, real transparency returns nothing // LightBetUnit(period, target1, target2, "SPLK", time, true, 1, 1, 1, 1)
		local timer t = CreateTimer()
		local integer i = GetHandleId(t)
	   
		call SaveLightningHandle(HashTable, i, 0, AddLightningEx(lightningtype, true, GetUnitX(target1), GetUnitY(target1), GetUnitFlyHeight(target1) + 50, GetUnitX(target2), GetUnitY(target2), GetUnitFlyHeight(target2) + 50))
		call SetLightningColor(LoadLightningHandle(HashTable, i, 0), red, green, blue, transparency)
		
		call SaveUnitHandle(HashTable, i, 1, target1)
		call SaveUnitHandle(HashTable, i, 2, target2)
		call SaveReal(HashTable, i, 3, time)
		call SaveBoolean(HashTable, i, 4, Break)
		
		call TimerStart(t, period, true, function LightBetUnit_Actions)
		
		set t = null
		set target1 = null
		set target2 = null
	endfunction

	function LightUnitAndLoc_Actions takes nothing returns nothing
		local integer i = GetHandleId(GetExpiredTimer())
		
		call SaveReal(HashTable, i, 3, LoadReal(HashTable, i, 3) - 0.01)
		
		if LoadReal(HashTable, i, 3) <= 0 or LoadUnitHandle(HashTable, i, 1) == null then
			call DestroyTimer(GetExpiredTimer())
			call DestroyLightning(LoadLightningHandle(HashTable, i, 0))
			call FlushChildHashtable(HashTable, i)
		elseif LoadBoolean(HashTable, i, 4) then
			if GetWidgetLife(LoadUnitHandle(HashTable, i, 1)) < 0.405 then
				call DestroyTimer(GetExpiredTimer())
				call DestroyLightning(LoadLightningHandle(HashTable, i, 0))
				call FlushChildHashtable(HashTable, i)
			else
				call MoveLightningEx(LoadLightningHandle(HashTable, i, 0), true, GetUnitX(LoadUnitHandle(HashTable, i, 1)), GetUnitY(LoadUnitHandle(HashTable, i, 1)), GetUnitFlyHeight(LoadUnitHandle(HashTable, i, 1)) + 50, LoadReal(HashTable, i, StringHash("x")), LoadReal(HashTable, i, StringHash("y")), LoadReal(HashTable, i, StringHash("z")))
			endif
		else
			call MoveLightningEx(LoadLightningHandle(HashTable, i, 0), true, GetUnitX(LoadUnitHandle(HashTable, i, 1)), GetUnitY(LoadUnitHandle(HashTable, i, 1)), GetUnitFlyHeight(LoadUnitHandle(HashTable, i, 1)) + 50, LoadReal(HashTable, i, StringHash("x")), LoadReal(HashTable, i, StringHash("y")), LoadReal(HashTable, i, StringHash("z")))
		endif
	endfunction

	function LightUnitAndLoc takes real period, unit target, real corX, real corY, real corZ, string lightningtype, real time, boolean Break, real red, real green, real blue, real transparency returns nothing // LightUnitAndLoc(period, target, x, y, z, "SPLK", time, true, 1, 1, 1, 1)
		
		local timer t = CreateTimer()
		local integer i = GetHandleId(t)
		
		call SaveLightningHandle(HashTable, i, 0, AddLightningEx(lightningtype, true, GetUnitX(target), GetUnitY(target), GetUnitFlyHeight(target) + 50, corX, corY, corZ))
		call SetLightningColor(LoadLightningHandle(HashTable, i, 0), red, green, blue, transparency)
		
		call SaveUnitHandle(HashTable, i, 1, target)
		call SaveReal(HashTable, i, 3, time)
		call SaveBoolean(HashTable, i, 4, Break)
		
		call SaveReal(HashTable, i, StringHash("x"), corX)
		call SaveReal(HashTable, i, StringHash("y"), corY)
		call SaveReal(HashTable, i, StringHash("z"), corZ)
		
		call TimerStart(t, period, true, function LightUnitAndLoc_Actions)
		
		set t = null
		set target = null
		
	endfunction

	function LightAddTime_Remove takes nothing returns nothing
		call DestroyLightning(LoadLightningHandle(HashTable, GetHandleId(GetExpiredTimer()), 0))
		call FlushChildHashtable(HashTable, GetHandleId(GetExpiredTimer()))
		call DestroyTimer(GetExpiredTimer())
	endfunction

	function LightAddTime takes lightning l, real time returns nothing
		local timer t = CreateTimer()
		
		call SaveLightningHandle(HashTable, GetHandleId(t), 0, l)
		call TimerStart(t, time, false, function LightAddTime_Remove)
		
		set t = null
	endfunction

	function LightBetLoc takes string lightningtype, real red, real green, real blue, real transparency, real corX1, real corY1, real corZ1, real corX2, real corY2, real corZ2, real time returns nothing //call LightBetLoc("SPLK", 1, 1, 1, 1, x1, y1, z1, x2, y2, z2, time)
		set bj_lastCreatedLightning = AddLightningEx(lightningtype, true, corX1, corY1, corZ1, corX2, corY2, corZ2)
		call SetLightningColor(bj_lastCreatedLightning, red, green, blue, transparency)
		call LightAddTime(bj_lastCreatedLightning, time)
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\Multiboard.j
	function GetMB takes string HashName returns multiboard
		return LoadMultiboardHandle( HashTable, MUIHandle( ), StringHash( HashName ) )
	endfunction
	
	function MBSetItemStyle takes multiboard mb, integer col, integer row, boolean showValue, boolean showIcon returns nothing
		local integer curRow = 0
		local integer curCol = 0
		local integer numRows = MultiboardGetRowCount( mb )
		local integer numCols = MultiboardGetColumnCount( mb )
		
		loop // Loop over rows, using 1-based index
			set curRow = curRow + 1
			exitwhen curRow > numRows

			if ( row == 0 or row == curRow ) then // Apply setting to the requested row, or all rows (if row is 0)
				set curCol = 0 // Loop over columns, using 1-based index
				loop
					set curCol = curCol + 1
					exitwhen curCol > numCols
					if ( col == 0 or col == curCol ) then // Apply setting to the requested column, or all columns (if col is 0)
						set mbitem = MultiboardGetItem( mb, curRow - 1, curCol - 1 )
						call MultiboardSetItemStyle( mbitem, showValue, showIcon )
						call MultiboardReleaseItem( mbitem)
					endif
				endloop
			endif
		endloop
	endfunction

	function MBSetItemValue takes multiboard mb, integer col, integer row, string val returns nothing
		local integer curRow = 0
		local integer curCol = 0
		local integer numRows = MultiboardGetRowCount( mb )
		local integer numCols = MultiboardGetColumnCount( mb )

		loop
			set curRow = curRow + 1
			exitwhen curRow > numRows

			if ( row == 0 or row == curRow ) then
				set curCol = 0
				loop
					set curCol = curCol + 1
					exitwhen curCol > numCols
					if ( col == 0 or col == curCol ) then
						set mbitem = MultiboardGetItem( mb, curRow - 1, curCol - 1 )
						call MultiboardSetItemValue( mbitem, val )
						call MultiboardReleaseItem( mbitem)
					endif
				endloop
			endif
		endloop
	endfunction
	
	function MBSetItemColor takes multiboard mb, integer col, integer row, integer red, integer green, integer blue, integer transparency returns nothing
		local integer curRow = 0
		local integer curCol = 0
		local integer numRows = MultiboardGetRowCount( mb )
		local integer numCols = MultiboardGetColumnCount( mb )

		loop
			set curRow = curRow + 1
			exitwhen curRow > numRows
			if ( row == 0 or row == curRow ) then
				set curCol = 0
				loop
					set curCol = curCol + 1
					exitwhen curCol > numCols
					if ( col == 0 or col == curCol ) then
						set mbitem = MultiboardGetItem( mb, curRow - 1, curCol - 1 )
						call MultiboardSetItemValueColor( mbitem, red, green, blue, transparency )
						call MultiboardReleaseItem( mbitem )
					endif
				endloop
			endif
		endloop
	endfunction

	function MBSetItemWidth takes multiboard mb, integer col, integer row, real width returns nothing
		local integer curRow = 0
		local integer curCol = 0
		local integer numRows = MultiboardGetRowCount( mb )
		local integer numCols = MultiboardGetColumnCount( mb )

		loop
			set curRow = curRow + 1
			exitwhen curRow > numRows
			if ( row == 0 or row == curRow ) then
				set curCol = 0
				loop
					set curCol = curCol + 1
					exitwhen curCol > numCols
					if ( col == 0 or col == curCol ) then
						set mbitem = MultiboardGetItem( mb, curRow - 1, curCol - 1 )
						call MultiboardSetItemWidth( mbitem, width / 100. )
						call MultiboardReleaseItem( mbitem )
					endif
				endloop
			endif
		endloop
	endfunction

	function MBSetItemIcon takes multiboard mb, integer col, integer row, string iconFileName returns nothing
		local integer curRow = 0
		local integer curCol = 0
		local integer numRows = MultiboardGetRowCount( mb )
		local integer numCols = MultiboardGetColumnCount( mb )

		loop
			set curRow = curRow + 1
			exitwhen curRow > numRows

			if ( row == 0 or row == curRow ) then
				set curCol = 0
				loop
					set curCol = curCol + 1
					exitwhen curCol > numCols
					if ( col == 0 or col == curCol ) then
						set mbitem = MultiboardGetItem( mb, curRow - 1, curCol - 1 )
						call MultiboardSetItemIcon( mbitem, iconFileName )
						call MultiboardReleaseItem( mbitem )
					endif
				endloop
			endif
		endloop
	endfunction

	function GetTimeStr takes integer time returns string
		if time < 10 then
			return "0" + I2S( time )
		endif
		return I2S( time )
	endfunction

	function MultiBoardUpdate takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local string Time
		local string Name
		local integer i = 0
		local integer cols

		//??????? ?????
		if GetInt( "Seconds" ) == 59 then
			call StoreTime( "Seconds", 0 )
			call StoreTime( "Minutes", GetInt( "Minutes" ) + 1 )
		else
			call StoreTime( "Seconds", GetInt( "Seconds" ) + 1 )
		endif
		if GetInt( "Minutes" ) == 59 then
			call StoreTime( "Minutes", 0 )
			call StoreTime( "Hours", GetInt( "Hours" ) + 1 )
		endif
		set Time = GetTimeStr( GetInt( "Hours" ) ) + ":" + GetTimeStr( GetInt( "Minutes" ) ) + ":" + GetTimeStr( GetInt( "Seconds" ) )

		//?????????? ????????? ?????????? ? ?????? ??? ?????????
		call SaveInteger( HashTable, HandleID, StringHash( "Team1Kill" ), 0 )
		call SaveInteger( HashTable, HandleID, StringHash( "Team2Kill" ), 0 )
		call SaveInteger( HashTable, HandleID, StringHash( "Team1Death" ), 0 )
		call SaveInteger( HashTable, HandleID, StringHash( "Team2Death" ), 0 )
		call SaveInteger( HashTable, HandleID, StringHash( "Team1Level" ), 0 )
		call SaveInteger( HashTable, HandleID, StringHash( "Team2Level" ), 0 )
		call SaveInteger( HashTable, HandleID, StringHash( "Team1GPM" ), 0 )
		call SaveInteger( HashTable, HandleID, StringHash( "Team2GPM" ), 0 )

		// ???????? ????? ???????
		loop
			if GetBool( "Player_" + I2S( i ) ) and i != 5 then
				set cols = GetInt( "PlayerCell_" + I2S( i ) )

				//????????? ??? ??????, ???? ????? ?????, ?? ???????? ??? ????? ??????
				if GetPlayerSlotState( Player( i ) ) == PLAYER_SLOT_STATE_LEFT then
					call MBSetItemValue( Multiboard, 1, cols, GetColour( 16 ) + GetPlayerName( Player( i ) ) )
				else
					call MBSetItemValue( Multiboard, 1, cols, GetColour( i ) + GetPlayerName( Player( i ) ) )
				endif

				//????????? ?????
				call MBSetItemValue( Multiboard, 2, cols, GetColour( 13 ) + I2S( Get_Player_Int( i, "Kills" ) ) )
				if i < 5 then
					call SaveInteger( HashTable, HandleID, StringHash( "Team1Kill" ), GetInt( "Team1Kill" ) + Get_Player_Int( i, "Kills" ) )
				else
					call SaveInteger( HashTable, HandleID, StringHash( "Team2Kill" ), GetInt( "Team2Kill" ) + Get_Player_Int( i, "Kills" ) )
				endif

				//????????? ??????
				call MBSetItemValue( Multiboard, 3, cols, GetColour( 14 ) + I2S( Get_Player_Int( i, "Deaths" ) ) )
				if i < 5 then
					call SaveInteger( HashTable, HandleID, StringHash( "Team1Death" ), GetInt( "Team1Death" ) + Get_Player_Int( i, "Deaths" ) )
				else
					call SaveInteger( HashTable, HandleID, StringHash( "Team2Death" ), GetInt( "Team2Death" ) + Get_Player_Int( i, "Deaths" ) )
				endif

				//????????? ???
				call MBSetItemValue( Multiboard, 4, cols, GetColour( 15 ) + I2S( GetHeroLevel( PlayerUnit[i] ) ) )
				if i < 5 then
					call SaveInteger( HashTable, HandleID, StringHash( "Team1Level" ), GetInt( "Team1Level" ) + GetHeroLevel( PlayerUnit[i] ) )
				else
					call SaveInteger( HashTable, HandleID, StringHash( "Team2Level" ), GetInt( "Team2Level" ) + GetHeroLevel( PlayerUnit[i] ) )
				endif

				//????????? ???
				if GetInt( "Hours" ) != 0 or GetInt( "Minutes" ) != 0 then
					//??????? ?????????? ?????
					if GetInt( "Player_Gold_" + I2S( i ) ) > PlayerGold( i ) then
						call SaveInteger( HashTable, HandleID, StringHash( "Player_Gold_" + I2S( i ) ), PlayerGold( i ) )
					elseif GetInt( "Player_Gold_" + I2S( i ) ) < PlayerGold( i ) then
						call SaveInteger( HashTable, HandleID, StringHash( "Total_Player_Gold" + I2S( i ) ), GetInt( "Total_Player_Gold" + I2S( i ) ) + ( PlayerGold( i ) - GetInt( "Player_Gold_" + I2S( i ) ) ) )
						call SaveInteger( HashTable, HandleID, StringHash( "Player_Gold_" + I2S( i ) ), PlayerGold( i ) )
					endif

					//?????????? ????????? ? ?????????
					call SaveInteger( HashTable, HandleID, StringHash( "PlayerGPM" + I2S( i ) ), GetInt( "Total_Player_Gold" + I2S( i ) ) / ( GetInt( "Minutes" ) + GetInt( "Hours" ) * 60 ) )
					call MBSetItemValue( Multiboard, 5, cols, GetColour( 12 ) + I2S( GetInt( "PlayerGPM" + I2S( i ) ) ) )
					if i < 5 then
						call SaveInteger( HashTable, HandleID, StringHash( "Team1GPM" ), GetInt( "Team1GPM" ) + GetInt( "PlayerGPM" + I2S( i ) ) )
					else
						call SaveInteger( HashTable, HandleID, StringHash( "Team2GPM" ), GetInt( "Team2GPM" ) + GetInt( "PlayerGPM" + I2S( i ) ) )
					endif
				endif
			endif
			set i = i + 1
			exitwhen i > 10
		endloop

		//?????????? ????????? ???????????
		call MBSetItemValue( Multiboard, 2, 3, GetColour( 13 ) + I2S( GetInt( "Team1Kill" ) ) )
		call MBSetItemValue( Multiboard, 3, 3, GetColour( 14 ) + I2S( GetInt( "Team1Death" ) ) )
		call MBSetItemValue( Multiboard, 4, 3, GetColour( 15 ) + I2S( GetInt( "Team1Level" ) ) )
		call MBSetItemValue( Multiboard, 2, 6 + GetInt( "Team1" ), GetColour( 13 ) + I2S( GetInt( "Team2Kill" ) ) )
		call MBSetItemValue( Multiboard, 3, 6 + GetInt( "Team1" ), GetColour( 14 ) + I2S( GetInt( "Team2Death" ) ) )
		call MBSetItemValue( Multiboard, 4, 6 + GetInt( "Team1" ), GetColour( 15 ) + I2S( GetInt( "Team2Level" ) ) )
		if GetPlayerId( GetLocalPlayer( ) ) < 5 then
			call MBSetItemValue( Multiboard, 5, 3, GetColour( 12 ) + I2S( GetInt( "Team1GPM" ) ) )
		else
			call MBSetItemValue( Multiboard, 5, 6 + GetInt( "Team1" ), GetColour( 12 ) + I2S( GetInt( "Team2GPM" ) ) )
		endif

		call MBSetItemValue( Multiboard, 1, 1, GetColour( 12 ) + "Mode: |c0000ffff" + LoadString( "Game_Mode" ) + "|r" )
		set Name = "Team Score: " + GetColour( 17 ) + I2S( GetInt( "Team1Kill" ) ) + "|r / " + GetColour( 18 ) + I2S( GetInt( "Team2Kill" ) ) + " |r | Win = |c0000ffff" + I2S( LoadInt( "Kill_Limit" ) ) + "|r | " + "Time: |c0000ffff" + Time + "|r"
		call MultiboardSetTitleText( Multiboard, Name )

		//????????? ???????? ??????
		call MBSetItemValue( Multiboard, 1, 3, GetColour( 17 ) + GetStr( "Team1Name" ) )
		call MBSetItemValue( Multiboard, 1, 6 + GetInt( "Team1" ), GetColour( 18 ) + GetStr( "Team2Name" ) )
	endfunction

	function MultiBoardCreate takes nothing returns nothing
		local integer row = 7 + GetInt( "TotalNumberPlayers" )
		local integer cols = 5
		local integer i = 0

		//????????? ???????????
		set Multiboard = CreateMultiboardBJ( cols, row, "|c00CD5C5CMultiboard|r" )
		//??????? ????????? ?????
		call MBSetItemStyle( Multiboard, 0, 0, true, false )
		call MBSetItemColor( Multiboard, 0, 0, 255, 205, 50, 190 )

		//??????????????? ?????? ?????
		call MBSetItemWidth( Multiboard, 1, 0, 10.00 ) 	//??????? ? ?????? ???????
		call MBSetItemWidth( Multiboard, 2, 0, 2.2 ) 	//??????? ? ??????????
		call MBSetItemWidth( Multiboard, 3, 0, 2.2 ) 	//??????? ?? ????????
		call MBSetItemWidth( Multiboard, 4, 0, 2.2 ) 	//??????? ? ????????
		call MBSetItemWidth( Multiboard, 5, 0, 2.65 ) 	//??????? ? ???

		//????????? ?????? ?????
		call MBSetItemStyle( Multiboard, 5, 0, false, false )
		loop
			exitwhen i > 11
			if GetBool( "Player_" + I2S( i ) ) then
				set cols = GetInt( "PlayerCell_" + I2S( i ) )
				call MBSetItemStyle( Multiboard, 1, cols, true, true )
				call MBSetItemIcon( Multiboard, 1, cols, "UI\\Console\\Human\\human-transport-slot.blp" )
				call MBSetItemValue( Multiboard, 1, cols, GetColour( i ) + GetPlayerName( Player( i ) ) )
				call SaveInteger( HashTable, GetHandleId( Player( i ) ), StringHash( "Player_Gold_" + I2S( i ) ), PlayerGold( i ) )
			endif
			set i = i + 1
		endloop

		call MBSetItemStyle( Multiboard, 0, 2, false, false )
		call MBSetItemStyle( Multiboard, 0, 4, false, false )
		call MBSetItemStyle( Multiboard, 0, 5 + GetInt( "Team1" ), false, false )
		call MBSetItemStyle( Multiboard, 0, 7 + GetInt( "Team1" ), false, false )
		call MBSetItemStyle( Multiboard, 1, 1, true, false )
		call MBSetItemStyle( Multiboard, 5, 1, true, false )
		call MBSetItemStyle( Multiboard, 5, 3, true, false )
		call MBSetItemStyle( Multiboard, 5, 6 + GetInt( "Team1" ), true, false )

		// ?????? ??????? ?????    
		call MBSetItemValue( Multiboard, 2, 0, GetColour( 13 ) + "0|r" )
		call MBSetItemValue( Multiboard, 3, 0, GetColour( 14 ) + "0|r" )
		call MBSetItemValue( Multiboard, 4, 0, GetColour( 15 ) + "0|r" )
		call MBSetItemValue( Multiboard, 2, 1, GetColour( 13 ) + "K|r" )
		call MBSetItemValue( Multiboard, 3, 1, GetColour( 14 ) + "D|r" )
		call MBSetItemValue( Multiboard, 4, 1, GetColour( 15 ) + "L|r" )

		call MBSetItemValue( Multiboard, 1, 3, GetColour( 17 ) + GetStr( "Team1Name" ) )
		call MBSetItemValue( Multiboard, 1, 6 + GetInt( "Team1" ), GetColour( 18 ) + GetStr( "Team2Name" ) )
		call MBSetItemValue( Multiboard, 5, 1, GetColour( 12 ) + "GPM|r" )
		call MBSetItemValue( Multiboard, 1, 1, GetColour( 12 ) + "Mode: |c0000ffffTBD|r" )

		call MultiboardMinimize( Multiboard, true )
		call MultiboardMinimize( Multiboard, false )

		call TimerStart( GetExpiredTimer( ), 1, true, function MultiBoardUpdate )
	endfunction

	function Init_Multiboard takes nothing returns nothing
		local integer HandleID
		local integer i = 0

		//???????? ??????? ??????
		call SaveTimerHandle( HashTable, 0, StringHash( "MultiboardTimer" ), CreateTimer( ) )
		set HandleID = GetHandleId( LoadTimerHandle( HashTable, 0, StringHash( "MultiboardTimer" ) ) )

		// ???????? ?????? ???????
		call SaveStr( HashTable, HandleID, StringHash( "Team1Name" ), "Team 1" )
		// ???????? ?????? ???????
		call SaveStr( HashTable, HandleID, StringHash( "Team2Name" ), "Team 2" )

		//??????? ??????? ? ???????????? ??????? ?????? ??????
		loop
			exitwhen i > 11
			if GetPlayerSlotState( Player( i ) ) == PLAYER_SLOT_STATE_PLAYING and i != 5 then
				call SaveBoolean( HashTable, HandleID, StringHash( "Player_" + I2S( i ) ), true )
				call SaveInteger( HashTable, GetHandleId( Player( i ) ), StringHash( "Player_Kill"  + I2S( i ) ), 0 )
				call SaveInteger( HashTable, GetHandleId( Player( i ) ), StringHash( "Player_Death" + I2S( i ) ), 0 )
				call SaveInteger( HashTable, GetHandleId( Player( i ) ), StringHash( "Player_Gold"  + I2S( i ) ), 0 )

				if i <= 4 then
					call SaveInteger( HashTable, HandleID, StringHash( "Team1" ), 1 + LoadInteger( HashTable, HandleID, StringHash( "Team1" ) ) )
					call SaveInteger( HashTable, HandleID, StringHash( "PlayerCell_" + I2S( i ) ), 4 + LoadInteger( HashTable, HandleID, StringHash( "Team1" ) ) )
				else
					call SaveInteger( HashTable, HandleID, StringHash( "Team2" ), 1 + LoadInteger( HashTable, HandleID, StringHash( "Team2" ) ) )
					call SaveInteger( HashTable, HandleID, StringHash( "PlayerCell_" + I2S( i ) ), 7 + LoadInteger( HashTable, HandleID, StringHash( "Team1" ) ) + LoadInteger( HashTable, HandleID, StringHash( "Team2" ) ) )
				endif
			endif
			set i = i + 1
		endloop
		call SaveInteger( HashTable, HandleID, StringHash( "TotalNumberPlayers" ), LoadInteger( HashTable, HandleID, StringHash( "Team1" ) ) + LoadInteger( HashTable, HandleID, StringHash( "Team2" ) ) )

		//?????? ??????? ?? ????????, ????????? ???????, ?????? ??????? ???????
		call TimerStart( LoadTimerHandle( HashTable, 0, StringHash( "MultiboardTimer" ) ), .01, false, function MultiBoardCreate )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\AI\Actions.j
	function AI_Buy_items_Action takes unit Target returns nothing
		local integer PID = GetPlayerId( GetOwningPlayer( Target ) )
		local integer LvL
		local integer HasGold

		if UnitInventoryCount( Target ) != 6 then
			set LvL = GetHeroLevel( Target )
			set HasGold = GetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD )
			if LvL >= 1 and not HasItem( Target, 'bspd' ) and not HasItem( Target, 'I00C' ) and HasGold >= 500 then
				call UnitAddItemById( Target, 'bspd' )
				call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 500 )
			endif

			if LvL >= 1 and not HasItem( Target, 'I011' ) and not HasItem( Target, 'I01R' ) and not HasItem( Target, 'I01E' ) and not HasItem( Target, 'I00B' ) and HasGold >= 300 then
				call UnitAddItemById( Target, 'I011' )
				call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 300 )
			endif
			
			if LvL >= 4 and not HasItem( Target, 'I00C' ) and HasGold >= 1060 then
				call RemoveItem( GetItemById( Target, 'bspd' ) )
				call CombineItem( Target, 'I00C', 0 )
				call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 1060 )
			endif
			
			if LvL >= 6 and not HasItem( Target, 'I01R' ) and not HasItem( Target, 'I01E' ) and not HasItem( Target, 'I00B' ) and HasGold >= 1975 and GetAIDifficulty( GetOwningPlayer( Target ) ) != AI_DIFFICULTY_INSANE then
				call RemoveItem( GetItemById( Target, 'I011' ) )
				call CombineItem( Target, 'I01R', 0 )
				call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 1975 )
			endif

			if LvL >= 8 and not HasItem( Target, 'I01X' ) and not HasItem( Target, 'I00M' ) and not Allies_Have_Item( PID, 'I01X' ) and HasGold >= 1500 then
				call CombineItem( Target, 'I01X', 0 )
				call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 1500 )
			endif

			if LvL >= 20 and not HasItem( Target, 'I01R' ) and HasItem( Target, 'I01E' ) and not HasItem( Target, 'I00B' ) and HasGold >= 5000 and GetAIDifficulty( GetOwningPlayer( Target ) ) == AI_DIFFICULTY_INSANE then
				call RemoveItem( GetItemById( Target, 'I01E' ) )
				call CombineItem( Target, 'I00B', 1 )
				call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 5000 )
			endif

			if LvL >= 24 and not HasItem( Target, 'I00M' ) and not HasItem( Target, 'I01X' ) and HasGold >= 5500 then //and not Allies_Have_Item( PID, 'I00M' )
				call CombineItem( Target, 'I00M', 1 )
				call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 5500 )
			endif

			if IsUnitType( Target, UNIT_TYPE_RANGED_ATTACKER ) then
				if LvL >= 6 and not HasItem( Target, 'I01R' ) and HasGold >= 1975 and GetAIDifficulty( GetOwningPlayer( Target ) ) == AI_DIFFICULTY_INSANE then
					call RemoveItem( GetItemById( Target, 'I011' ) )
					call CombineItem( Target, 'I01R', 0 )
					call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 1975 )
				endif

				if LvL >= 13 and not HasItem( Target, 'I004' ) and HasGold >= 6000 then
					call CombineItem( Target, 'I004', 1 )
					call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 6000 )
				endif

				if LvL >= 20 and not HasItem( Target, 'I00B' ) and not HasItem( Target, 'I007' ) and HasGold >= 7000 then
					if GetRandomInt( 1, 100 ) > 30 then
						call CombineItem( Target, 'I007', 1 )
					else
						call CombineItem( Target, 'I00B', 1 )
					endif
					call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 7000 )
				endif

				if LvL >= 30 and not HasItem( Target, 'I01V' ) and HasGold >= 22000 then
					call CombineItem( Target, 'I01V', 2 )
					call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 22000 )
				endif

				if LvL >= 41 and not HasItem( Target, 'I01U' ) and HasGold >= 20000 then
					call CombineItem( Target, 'I01U', 2 )
					call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 20000 )
				endif
			endif

			if IsUnitType( Target, UNIT_TYPE_MELEE_ATTACKER ) then
				if LvL >= 6 and not HasItem( Target, 'I01R' ) and not HasItem( Target, 'I01E' ) and not HasItem( Target, 'I00B' ) and HasGold >= 1850 and GetAIDifficulty( GetOwningPlayer( Target ) ) == AI_DIFFICULTY_INSANE then
					call RemoveItem( GetItemById( Target, 'I011' ) )
					call CombineItem( Target, 'I01E', 0 )
					call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 1850 )
				endif

				if LvL >= 13 and not HasItem( Target, 'I000' ) and not HasItem( Target, 'I01U' ) and HasGold >= 7800 then
					call CombineItem( Target, 'I000', 1 )
					call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 7800 )
				endif

				if LvL >= 18 and not HasItem( Target, 'I01C' ) and not HasItem( Target, 'I00N' ) and HasGold >= 5000 then
					if GetRandomInt( 1, 100 ) > 60 then
						call CombineItem( Target, 'I01C', 1 )
					else
						call CombineItem( Target, 'I00N', 1 )
					endif
					call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 5000 )
				endif

				if LvL >= 30 and HasItem( Target, 'I000' ) and not HasItem( Target, 'I01U' ) and HasGold >= 13200 then
					call RemoveItem( GetItemById( Target, 'I000' ) )
					call CombineItem( Target, 'I01U', 2 )
					call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 13200 )
				endif

				if LvL >= 41 and not HasItem( Target, 'I01V' ) and HasGold >= 22000 then
					call CombineItem( Target, 'I01V', 2 )
					call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, HasGold - 22000 )
				endif
			endif
		endif
    endfunction

	function AI_Order_Move takes nothing returns nothing
		local real Angle
		set SysUnit = GetTriggerUnit( )
		if IsUnitType( SysUnit, UNIT_TYPE_HERO ) and GetPlayerController( GetOwningPlayer( SysUnit ) ) == MAP_CONTROL_COMPUTER then
			set Angle = GetAngleCast( SysUnit, -704., 64. )
			call IssuePointOrder( SysUnit, "attack", NewX( GetUnitX( SysUnit ), 400, Angle ), NewY( GetUnitY( SysUnit ), 400, Angle ) )
		endif
		set SysUnit = null
    endfunction

	function Reset_AI_Order_CD takes nothing returns nothing
		call SaveBoolean( HashTable, GetHandleId( GetUnit( "AI_Unit" ) ), StringHash( "AI_Help_CD" ), false )
		call CleanMUI( GetExpiredTimer( ) )
	endfunction
	
	function AI_Attack_Handler takes unit Source, unit Target returns nothing
		local integer i = 0
		local integer HandleID
		local real TargX
		local real TargY
		local integer Team
		local string Order
		local boolean Flag = false

		if GetPlayerController( GetOwningPlayer( Target ) ) == MAP_CONTROL_COMPUTER and IsUnitType( Target, UNIT_TYPE_HERO ) then
			if not IsUnitCCed( Target ) and IsUnitEnemy_v2( Source, Target ) then
				set TargX = GetUnitX( Source )
				set TargY = GetUnitY( Source )
				set Team = GetPlayerTeam( GetOwningPlayer( Target ) )

				if not Flag then
					set Flag = IssueImmediateOrder( Target, "berserk" )
				endif

				if not Flag then
					set Flag = IssueImmediateOrder( Target, "windwalk" )
				endif

				if not Flag then
					set Flag = IssueImmediateOrder( Target, "chemicalrage" )
				endif

				loop
					exitwhen i > 5 or Flag
					if i == 0 then
						set Order = "drain"
				elseif i == 1 then
						set Order = "shockwave"
				elseif i == 2 then
						set Order = "roar"
				elseif i == 3 then
						set Order = "stampede"
				elseif i == 4 then
						set Order = "banish"
				elseif i == 5 then
						set Order = "cripple"
					endif

					if not Flag then
						set Flag = IssueTargetOrder( Target, Order, Source )
					endif

					if not Flag then
						set Flag = IssueImmediateOrder( Target, Order )
					endif

					if not Flag then
						set Flag = IssuePointOrder( Target, Order, TargX, TargY )
					endif

					set i = i + 1
				endloop

				if not LoadBoolean( HashTable, GetHandleId( Target ), StringHash( "AI_Help_CD" ) ) and UnitLifePercent( Target ) >= 30 then
					set i = 0
					loop
						exitwhen i > 11
						if IsPlayerAlly( Player( i ), GetOwningPlayer( Target ) ) and GetPlayerController( Player( i ) ) == MAP_CONTROL_COMPUTER and not LoadBoolean( HashTable, GetHandleId( Player( i ) ), StringHash( "PickedForEvent" ) ) then
							call GroupEnumUnitsOfPlayer( SysGroup, Player( i ), null )
							loop
								set SysUnit = FirstOfGroup( SysGroup )
								exitwhen SysUnit == null
								if UnitLifePercent( SysUnit ) >= 30 then
									call IssuePointOrder( SysUnit, "attack", TargX, TargY )
								endif
								call GroupRemoveUnit( SysGroup, SysUnit )
							endloop
						endif
						set i = i + 1
					endloop
					set HandleID = NewMUITimer( PLAYER_NEUTRAL_AGGRESSIVE )
					call SaveBoolean( HashTable, GetHandleId( Target ), StringHash( "AI_Help_CD" ), true )
					call SaveUnitHandle( HashTable, HandleID, StringHash( "AI_Unit" ), Target )
					call TimerStart( LoadMUITimer( PLAYER_NEUTRAL_AGGRESSIVE ), 5, false, function Reset_AI_Order_CD )
				endif
			endif
		endif
	endfunction

	function AI_Order_Periodic takes nothing returns nothing
		local integer i = 0
		loop
			exitwhen i > 11
			if GetPlayerController( Player( i ) ) == MAP_CONTROL_COMPUTER then
				call GroupEnumUnitsOfPlayer( SysGroup, Player( i ), null )
				loop
					set SysUnit = FirstOfGroup( SysGroup )
					exitwhen SysUnit == null
					if not LoadBoolean( HashTable, GetHandleId( HashTable  ), StringHash( "Event_Started" ) ) then
						if UnitLifePercent( SysUnit ) >= 30 then
							call IssuePointOrder( SysUnit, "attack", GetRandomReal( -4480, 3104 ), GetRandomReal( -2720, 2432 ) )
						else
							call IssuePointOrder( SysUnit, "move", GetStartLocationX( GetPlayerStartLocation( Player( i ) ) ), GetStartLocationY( GetPlayerStartLocation( Player( i ) ) ) )
						endif
					else
						if LoadBoolean( HashTable, GetHandleId( Player( i ) ), StringHash( "PickedForEvent" ) ) then
							call IssuePointOrder( SysUnit, "attack", NewX( GetUnitX( SysUnit ), 500, GetUnitFacing( SysUnit ) ), NewY( GetUnitY( SysUnit ), 500, GetUnitFacing( SysUnit ) ) )
						endif
					endif
					call GroupRemoveUnit( SysGroup, SysUnit )
				endloop
			endif
			set i = i + 1
		endloop
	endfunction

	function Init_AI takes nothing returns nothing
		//local trigger Trigger = null
		
		if Count_Players_By_Control( MAP_CONTROL_COMPUTER ) != 0 then
			//set Trigger = CreateTrigger( )
			call TimerStart( CreateTimer( ), 2.5, true, function AI_Order_Periodic )
			// call Rect_Leave_Event( Trigger, -5760., 288., -4448., 896., function AI_Order_Move )
			// call Rect_Leave_Event( Trigger, 2976., 128., 4576., 896., null )
		endif
		
		//set Trigger = null
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\Revive.j
	function ReviveHeroCustom takes integer PID, unit WhatUnit, real WhereX, real WhereY returns nothing
		local integer Team = GetPlayerTeam( GetOwningPlayer( WhatUnit ) )
		local integer RandInt = GetRandomInt( 1, 8 )
		local real Angle
		call UnitRemoveAbility( WhatUnit, 'A090' )
		call ReviveHero( WhatUnit, WhereX, WhereY, true )
		call SetUnitState( WhatUnit, UNIT_STATE_MANA, GetUnitState( WhatUnit, UNIT_STATE_MAX_MANA ) )
		
		if LoadBoolean( HashTable, GetHandleId( Player( PID ) ), StringHash( "PickedForEvent" ) ) then
			call PauseUnit( WhatUnit, true )
		endif

		if GetPlayerController( GetOwningPlayer( WhatUnit ) ) == MAP_CONTROL_COMPUTER then
			if RandInt == 1 and Team == 0 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 0 ] )
			endif
			if RandInt == 1 and Team == 1 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 1 ] )
			endif
			if RandInt == 2 and Team == 0 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 2 ] )
			endif
			if RandInt == 2 and Team == 1 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 3 ] )
			endif
			if RandInt == 3 and Team == 0 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 4 ] )
			endif
			if RandInt == 3 and Team == 1 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 5 ] )
			endif
			if RandInt == 4 and Team == 0 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 4 ] )
			endif
			if RandInt == 4 and Team == 1 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 5 ] )
			endif
			if RandInt == 5 and Team == 0 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 6 ] )
			endif
			if RandInt == 5 and Team == 1 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 7 ] )
			endif
			if RandInt == 6 and Team == 0 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 8 ] )
			endif
			if RandInt == 6 and Team == 1 then
				call IssueTargetOrder( WhatUnit, "smart", WayGate_Arr[ 9 ] )
			endif
			if RandInt == 7 or RandInt == 8 then
				set Angle = GetAngleCast( WhatUnit, -704., 64. )
				call IssuePointOrder( WhatUnit, "attack", NewX( -704, 900, Angle ), NewY( 64., 900, Angle ) )
			endif
			call AI_Buy_items_Action( WhatUnit )
		endif
		call SelectPlayerUnit( WhatUnit, true )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\CreepCreation.j
	function Spawn_Random_Creep takes integer Amount, integer Level, real LocX, real LocY returns nothing
		local integer i = 0
		local integer UID = 0
		local integer Random

		if Count_Player_Unit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), -1 ) <= 300 then
			if Level == 1 then
				set Random = GetRandomInt( 1, 2 )
				
				if Random == 1 then
					set UID = 'nwiz' // Apprentice Wizard
				else
					set UID = 'nban' // Bandit
				endif
		elseif Level == 2 then
				set Random = GetRandomInt( 1, 4 )
				
				if Random == 1 then
					set UID = 'ngrk' // Mud Golem
			elseif Random == 2 then
					set UID = 'nwwf' // Wolf
			elseif Random == 3 then
					set UID = 'nbrg' // Brigand
				else
					set UID = 'nmrr' // Murloc Huntsman
				endif
		elseif Level == 3 then
				set Random = GetRandomInt( 1, 5 )
				
				if Random == 1 then
					set UID = 'nhdc' // Deceiver
			elseif Random == 2 then
					set UID = 'nenp' // Poison Treant
			elseif Random == 3 then
					set UID = 'nwzr' // Rogue Wizard
			elseif Random == 4 then
					set UID = 'nmrm' // Murloc Nightcrawler
				else
					set UID = 'nrog' // Rogue
				endif
		elseif Level == 4 then
				set Random = GetRandomInt( 1, 2 )
				
				if Random == 1 then
					set UID = 'ncim' // Centaur Impaler
				else
					set UID = 'nass' // Assassin
				endif
		elseif Level == 5 then
				set Random = GetRandomInt( 1, 3 )
				
				if Random == 1 then
					set UID = 'nenf' // Enforcer
			elseif Random == 2 then
					set UID = 'nhhr' // Heretic
				else
					set UID = 'nwzg' // Renegade Wizard
				endif
		elseif Level == 6 then
				set UID = 'ngst' // Rock Golem
		elseif Level == 7 then
				set Random = GetRandomInt( 1, 2 )

				if Random == 1 then
					set UID = 'nbld' // Bandit Lord
				else
					set UID = 'nhrq' // Harpy Queen
				endif
		elseif Level == 8 then
				set UID = 'nsoc' // Skeletal Orc Champion
		elseif Level == 9 then
				set UID = 'nggr' // Granite Golem
		elseif Level == 10 then
				set Random = GetRandomInt( 1, 2 )
				if Random == 1 then
					set UID = 'nahy' // Ancient Hydra
				else
					set UID = 'nhrq' // Black Dragon
				endif
			endif

			if UID != 0 then
				loop
					exitwhen i > Amount
					set SysUnit = CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), UID, LocX, LocY, GetRandomReal( 0, 360 ) )
					call UnitRemoveAbility( SysUnit, 'Aprg' )
					call UnitRemoveAbility( SysUnit, 'Apg2' )
					call UnitRemoveAbility( SysUnit, 'ACpu' )
					call UnitRemoveAbility( SysUnit, 'ACmi' )
					call UnitRemoveAbility( SysUnit, 'ACrk' )
					call UnitRemoveAbility( SysUnit, 'ACsk' )
					call UnitRemoveAbility( SysUnit, 'ACds' )
					call UnitRemoveAbility( SysUnit, 'ACbh' )
					call UnitRemoveAbility( SysUnit, 'ANbh' )
					call UnitRemoveAbility( SysUnit, 'ACf2' )
					call UnitRemoveAbility( SysUnit, 'ACfu' )
					call UnitRemoveAbility( SysUnit, 'ACfa' )
					call UnitRemoveAbility( SysUnit, 'ACca' )
					call UnitRemoveAbility( SysUnit, 'ACcs' )
					call UnitRemoveAbility( SysUnit, 'ACsw' )
					call UnitRemoveAbility( SysUnit, 'Apiv' )
					call UnitRemoveAbility( SysUnit, 'Ashm' )
					call UnitRemoveAbility( SysUnit, 'Sshm' )
					call UnitRemoveAbility( SysUnit, 'Apoi' )
					call UnitRemoveAbility( SysUnit, 'Aspo' )
					call UnitRemoveAbility( SysUnit, 'ACvs' )
					call UnitRemoveAbility( SysUnit, 'ACdm' )
					call UnitRemoveAbility( SysUnit, 'ACd2' )
					call UnitRemoveAbility( SysUnit, 'Andm' )
					call UnitRemoveAbility( SysUnit, 'Aadm' )
					call UnitRemoveAbility( SysUnit, 'Adsm' )
					call UnitRemoveAbility( SysUnit, 'Apig' )
					call UnitRemoveAbility( SysUnit, 'ACtb' )
					call UnitAddSleep( SysUnit, false )
					set SysUnit = null
					set i = i + 1
				endloop
			endif
		endif
	endfunction
    
	function Spawn_Creeps takes nothing returns nothing
		local integer B_UID = 0
		local real LocX = -704
		local real LocY = 64.
		local real Angle
		if not Stop_Spells( ) then
			call Spawn_Random_Creep( 8, GetRandomInt( 1, 3 ), -105, 65 )
			call Spawn_Random_Creep( 8, GetRandomInt( 1, 3 ), -705, 665 )
			call Spawn_Random_Creep( 8, GetRandomInt( 1, 3 ), -1305, 65 )
			call Spawn_Random_Creep( 8, GetRandomInt( 1, 3 ), -705, -535 )

			call Spawn_Random_Creep( 4, GetRandomInt( 4, 6 ), 795, 65 )
			call Spawn_Random_Creep( 4, GetRandomInt( 4, 6 ), -705, 1565 )
			call Spawn_Random_Creep( 4, GetRandomInt( 4, 6 ), -2205, 65 )
			call Spawn_Random_Creep( 4, GetRandomInt( 4, 6 ), -705, -1435 )
			
			call Spawn_Random_Creep( 6, GetRandomInt( 1, 4 ), 286, 1055 )
			call Spawn_Random_Creep( 6, GetRandomInt( 1, 4 ), -1695, 1055 )
			call Spawn_Random_Creep( 6, GetRandomInt( 1, 4 ), -1410, -645 )
			call Spawn_Random_Creep( 6, GetRandomInt( 1, 4 ), 5, -645 )

			call Spawn_Random_Creep( 6, GetRandomInt( 2, 4 ), -3090, 1785 )

			call Spawn_Random_Creep( 6, GetRandomInt( 2, 4 ), 1775, 1790 )

			call Spawn_Random_Creep( 6, GetRandomInt( 2, 4 ), -3095, -1500 )

			call Spawn_Random_Creep( 6, GetRandomInt( 2, 4 ), 1750, -1475 )
			
			call Spawn_Random_Creep( 6, GetRandomInt( 2, 4 ), -1410, 1730 )
			call Spawn_Random_Creep( 6, GetRandomInt( 2, 4 ), 130, 1730 )
			call Spawn_Random_Creep( 6, GetRandomInt( 2, 4 ), 95, -1760 )
			call Spawn_Random_Creep( 6, GetRandomInt( 2, 4 ), -1410, -1760 )

			if GetRandomInt( 1, 100 ) <= 40 then
				set Angle = GetAxisAngle( -704, 2384, LocX, LocY )
				call Spawn_Random_Creep( 3, GetRandomInt( 7, 10 ), -705, 2185 )
			endif

			if GetRandomInt( 1, 100 ) <= 40 then
				set Angle = GetAxisAngle( -704, -2512, LocX, LocY )
				call Spawn_Random_Creep( 3, GetRandomInt( 7, 10 ), -705, -2290 )
			endif
		endif
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\RapireArea.j
    function Create_Rapire_Golems takes nothing returns nothing
		local integer i = 1
		local real LocX = 7008 + 100
		local real LocY = 3456
		local real TempX = LocX
		local real TempY = LocY
		local real Facing = 0

		if not LoadBool( "Golems_Created" ) then
			set Rapire_Owner = null
			call SaveBool( "Golems_Created", true )

			loop
				exitwhen i > 18
				if i == 10 then
					set TempX = TempX + 550
					set TempY = LocY
					set Facing = 180
				endif
				set Dummy = CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), 'nsgg', TempX, TempY, Facing )
				call PauseUnit( Dummy, true )
				call SetUnitInvul( Dummy, true )
				call SetUnitTimeScale( Dummy, 0 )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", Dummy, "origin" ) )
				set TempY = TempY - 550
				set i = i + 1
			endloop
		endif
    endfunction

	function Create_Rapire_Doomguards takes nothing returns nothing
		local integer i = 1
		local unit trigUnit =  GetTriggerUnit( )

		if HasItem( trigUnit, 'I00A' ) then

			if not LoadBool( "Doomguards_Created" ) then
				set Rapire_Stolen = true
				set Rapire_2_Owner = null
				call SaveBool( "Doomguards_Created", true )
				call CreateItem( 'I06K', 7360, -1344 )
				loop
					exitwhen i > 6
					call CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), 'nbal', 7360, -1344 + 400, 90 )
					set i = i + 1
				endloop
			elseif trigUnit == Rapire_2_Owner then
				set Rapire_2_Stolen = true
			endif
		endif
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\CenterBoss.j
	function AILearnAbil takes unit Unit returns nothing
		local integer i = 1
		local integer ID = LoadInteger( HashTable, GetHandleId( Unit ), StringHash( "Hero_Index" ) )

		if ID > 0 then
			loop
				exitwhen i > 5
				call SelectHeroSkill( Unit, LoadInt( "Hero_Ability_" + I2S( ID ) + "_" + I2S( i ) ) )
				set i = i + 1
			endloop
		endif
	endfunction

	function Create_Basic_Boss takes nothing returns nothing
		local integer RandInt = GetRandomInt( 1, 8 )
		local integer UID

		if RandInt == 1 then
			set UID = 'Harf'
	elseif RandInt == 2 then
			set UID = 'Huth'
	elseif RandInt == 3 then
			set UID = 'Ocb2'
	elseif RandInt == 4 then
			set UID = 'Orex'
	elseif RandInt == 5 then
			set UID = 'Eevi'
	elseif RandInt == 6 then
			set UID = 'Ewrd'
	elseif RandInt == 7 then
			set UID = 'Uear'
	elseif RandInt == 8 then
			set UID = 'Utic'
		endif

		set Ring_Boss = CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), UID, 4200, 6900, 270 )
		call SetHeroLevel( Ring_Boss, 99, false )
		call SetHeroStr( Ring_Boss, 3333, true )
		call SetHeroAgi( Ring_Boss, 3333, true )
		call SetHeroInt( Ring_Boss, 3333, true )
		call UnitAddAbility( Ring_Boss, 'Apiv' )
		call UnitAddAbility( Ring_Boss, 'ACev' )
		call UnitAddAbility( Ring_Boss, 'ACce' )
		call UnitAddAbility( Ring_Boss, 'A03W' )
		call ScaleUnit( Ring_Boss, 1.3 )
		call UnitAddType( Ring_Boss, UNIT_TYPE_ANCIENT )
    endfunction

    function Create_Ring_Boss takes nothing returns nothing
		local integer i = 0
		local integer UID = LoadInt( "Hero_UID_" + I2S( FindRandomHero( ) ) )
		set Ring_Boss = CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), UID, 4200, 6900, 270 )
		call SetHeroLevel( Ring_Boss, 99, false )
		call SetHeroStr( Ring_Boss, 5000, true )
		call SetHeroAgi( Ring_Boss, 5000, true )
		call SetHeroInt( Ring_Boss, 5000, true )
		call UnitAddItemById( Ring_Boss, 'I02M' )
		call UnitAddItemById( Ring_Boss, 'I01V' )
		set i = 1
		loop
			exitwhen i > 6
			call AILearnAbil( Ring_Boss )
			set i = i + 1
		endloop
		call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", Ring_Boss, "origin" ) )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\Aizen.j
	function Reset_Aizen_AI_CD takes nothing returns nothing
		local integer AI_CD = LoadInteger( HashTable, GetHandleId( GetUnit( "Aizen" ) ), StringHash( "Aizen_AI_CD" ) )

		if AI_CD == 0 then
			call SaveInteger( HashTable, GetHandleId( GetUnit( "Aizen" ) ), StringHash( "Aizen_AI_CD" ), AI_CD - 1 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Aiezen_AI takes unit Source, unit Target returns nothing
		local real Angle
		local integer Random = GetRandomInt( 1, 3 )
		local integer HandleID
		local integer UID = GetUnitTypeId( Target )
		if IsUnitType( Source, UNIT_TYPE_HERO ) then
			if LoadInteger( HashTable, GetHandleId( Target ), StringHash( "Aizen_AI_CD" ) ) == 0 then
				if Random == 1 then
					call EnumUnits_AOE( SysGroup, GetUnitX( Target ), GetUnitY( Target ), 800 )
					loop
						set SysUnit = FirstOfGroup( SysGroup )
						exitwhen SysUnit == null
						if IsUnitEnemy_v2( Target, SysUnit ) and DefaultUnitFilter( SysUnit ) then
							if not HasItem( SysUnit, 'I04N' ) then
								call Damage_Unit( Target, SysUnit, 999999, "magical" )
								call TextTagSimpleUnit( "|c00FF0303DEATH!|r", SysUnit, 12, 255, 1.6 )
							else
								call TextTagSimpleUnit( "|c0000FFFFIMMUNE|r", SysUnit, 11, 255, 1.6 )
							endif
						endif
						call GroupRemoveUnit( SysGroup, SysUnit )
					endloop
					call PlaySoundOnUnit( Sounds[ GetHint( 10, "KyoukaSuigetsu" ) ], 100, Target )
					call TextTagSimpleUnit( "Kyoka Suigetsu", Target, 10., 255, 1 )
					call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\NightElf\\Taunt\\TauntCaster.mdl", Target, "origin" ) )
				endif
				if Random == 2 then
					if GetRandomInt( 1, 100 ) <= 50 then
						call UnitUseItemTarget( Target, UnitItemInSlot( Target, 0 ), Source )
					else
						call UnitUseItemTarget( Target, UnitItemInSlot( Target, 0 ), Target )
					endif
				endif
				if Random == 3 then
					set Angle = GetUnitsAngle( Target, Source )
					set SysUnit = CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), 'h00H', NewX( GetUnitX( Source ), 175, Angle ), NewY( GetUnitY( Source ), 175, Angle ), Angle )
					call UnitApplyTimedLife( SysUnit, 'BTLF', .6 )
					call SetUnitAnimation( Target, "attack" )
					call SetUnitAnimation( SysUnit, "attack" )
					if HasAbility( Target, 'B004' ) then
						call AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\Unsummon\\UnsummonTarget.mdl", SysUnit, "origin" )
					endif
					call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( Source ), GetUnitY( Source ) ) )
					if not HasItem( Source, 'I04N' ) then
						call Damage_Unit( Target, Source, 999999, "magical" )
						call TextTagSimpleUnit( "|c00FF0303DEATH!|r", Source, 12, 255, 1.6 )
					else
						call TextTagSimpleUnit( "|c0000FFFFBLOCK|r", Source, 11, 255, 1.6 )
					endif
					call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX( Target ), GetUnitY( Target ) ) )
					call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX( SysUnit ), GetUnitY( SysUnit ) ) )
					call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile_mini.mdl", SysUnit, "origin" ) )
					call RemoveUnit( SysUnit )
					if UnitLife( Target ) > 0 then
						call SetUnitXY_1( Target, NewX( GetUnitX( Source ), -100, Angle ) , NewY( GetUnitY( Source ), -100, Angle ), true )
						call DestroyAoEDestruct( GetUnitX( Source ), GetUnitY( Source ), 300 )
						call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX( Target ), GetUnitY( Target ) ) )
					endif
				endif
				call SaveInteger( HashTable, GetHandleId( Target ), StringHash( "Aizen_AI_CD" ), 7 )
				set HandleID = NewMUITimer( PLAYER_NEUTRAL_AGGRESSIVE )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Aizen" ), Target )
				call TimerStart( LoadMUITimer( PLAYER_NEUTRAL_AGGRESSIVE ), 1, true, function Reset_Aizen_AI_CD )
			endif
		endif
    endfunction

    function Summon_Aizen takes nothing returns nothing
		set Dummy = CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), 'NC03', -672, -288, bj_UNIT_FACING )
		call SetHeroLevel( Dummy, 99, false )
		call SetHeroStr( Dummy, 9999, true )
		call SetHeroAgi( Dummy, 9999, true )
		call SetHeroInt( Dummy, 9999, true )
		call UnitAddItemById( Dummy, 'I04P' )
		call UnitAddItemById( Dummy, 'I04O' )
		call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", Dummy, "origin" ) )
		call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 40., GetHeroProperName( Dummy ) + " has entered the Arena!!" )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Events\SkillPoints.j
    function Unit_Level_Up_Event takes nothing returns nothing
		local integer PID = GetPlayerId( GetTriggerPlayer( ) )
		local integer LvL
		set SysUnit = GetLevelingUnit( )

		if IsUnitType( SysUnit, UNIT_TYPE_HERO ) and GetHeroLevel( SysUnit ) < 41 then
			set LvL = GetHeroLevel( SysUnit )
			if SysUnit == PlayerUnit[ PID ] then
				if GetHeroSkillPoints( SysUnit ) >= 1 then
					call UnitModifySkillPoints( SysUnit, -1 )
				endif
				if LvL == 3 or LvL == 4 or LvL == 6 or LvL == 10 or LvL == 12 or LvL == 13 or LvL == 15 or LvL == 17 or LvL == 19 or LvL == 20 or LvL == 21 or LvL == 22 or LvL == 25 or LvL == 26 or LvL == 27 or LvL == 30 then
					call UnitModifySkillPoints( SysUnit, 1 )
			elseif LvL == 32 or LvL == 35 or LvL == 40 then
					call UnitModifySkillPoints( SysUnit, 1 )
			elseif LvL == 7 or LvL == 11 or LvL == 16 then
					call UnitModifySkillPoints( SysUnit, 2 )
				endif
			endif

			if GetPlayerController( GetOwningPlayer( SysUnit ) ) == MAP_CONTROL_COMPUTER then
				call AILearnAbil( SysUnit )

				if GetAIDifficulty( GetOwningPlayer( SysUnit ) ) == AI_DIFFICULTY_NORMAL then
					call SetHeroStr( SysUnit, GetHeroStr( SysUnit, false ) + 1, true )
					call SetHeroAgi( SysUnit, GetHeroAgi( SysUnit, false ) + 1, true )
					call SetHeroInt( SysUnit, GetHeroInt( SysUnit, false ) + 1, true )
				else
					if GetAIDifficulty( GetOwningPlayer( SysUnit ) ) == AI_DIFFICULTY_INSANE then
						call SetHeroStr( SysUnit, GetHeroStr( SysUnit, false ) + 2, true )
						call SetHeroAgi( SysUnit, GetHeroAgi( SysUnit, false ) + 2, true )
						call SetHeroInt( SysUnit, GetHeroInt( SysUnit, false ) + 2, true )
					endif
				endif
			endif
		endif
		set SysUnit = null
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Events\ItemPickUp.j
    function Item_Pick_Up_Event takes nothing returns nothing
		local integer AID
		local integer ItemID
		local integer UID
		local integer PID
		local string MainStat

		set SysItem = GetManipulatedItem( )
		set SysUnit = GetTriggerUnit( )
		set ItemID = GetItemTypeId( SysItem )
		set UID = GetUnitTypeId( SysUnit )
		set PID = GetPlayerId( GetOwningPlayer( SysUnit ) )

		if SysItem == Rapire or SysItem == Rapire_2 then
			if SysItem == Rapire then
				set Rapire_Owner = SysUnit
			elseif SysItem == Rapire_2 then
				set Rapire_2_Owner = SysUnit
			endif

			if IsUnitInArea( SysUnit, "rapire" ) then
				call SetUnitManaBJ( SysUnit, 0 )
				call SetUnitLifePercentBJ( SysUnit, 40. )

				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\HowlOfTerror\\HowlCaster.mdl", SysUnit, "origin" ) )

				call EnumUnits_Rect( SysGroup, GetWorldBounds( ) )
				loop
					set SysUnit = FirstOfGroup( SysGroup )
					exitwhen SysUnit == null
					if GetUnitTypeId( SysUnit ) == 'nsgg' then
						call PauseUnit( SysUnit, false )
						call SetUnitInvul( SysUnit, false )
						call SetUnitTimeScale( SysUnit, 1 )
					endif
					call GroupRemoveUnit( SysGroup, SysUnit )
				endloop
			endif
		endif

		if ItemID == 'I06K' then
			if not LoadBool( "Mimic_Spawned" ) then
				call CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), 'n012', GetItemX( SysItem ), GetItemY( SysItem ), bj_UNIT_FACING )
				call SaveBool( "Mimic_Spawned", true )
			endif
		endif

		if HasItem( SysUnit, 'bpsd' ) and HasItem( SysUnit, 'gcel' ) and ( HasItem( SysUnit, 'belv' ) or HasItem( SysUnit, 'bgst' ) or HasItem( SysUnit, 'ciri' ) ) then
			call RemoveItem( GetItemById( SysUnit, 'bspd' ) )
			call RemoveItem( GetItemById( SysUnit, 'gcel' ) )
			if HasItem( SysUnit, 'belv' ) then
				call RemoveItem( GetItemById( SysUnit, 'belv' ) )
		elseif HasItem( SysUnit, 'bgst' ) then
				call RemoveItem( GetItemById( SysUnit, 'bgst' ) )
		elseif HasItem( SysUnit, 'ciri' ) then
				call RemoveItem( GetItemById( SysUnit, 'ciri' ) )
			endif

			call CombineItem( SysUnit, 'I00C', 0 )
		endif

		if HasItem( SysUnit, 'cnob' ) and HasItem( SysUnit, 'rst1' ) then
			call RemoveItem( GetItemById( SysUnit, 'cnob' ) )
			call RemoveItem( GetItemById( SysUnit, 'rst1' ) )

			call CombineItem( SysUnit, 'I002', 0 )
		endif
		
		if HasItem( SysUnit, 'cnob' ) and HasItem( SysUnit, 'rag1' ) then
			call RemoveItem( GetItemById( SysUnit, 'cnob' ) )
			call RemoveItem( GetItemById( SysUnit, 'rag1' ) )

			call CombineItem( SysUnit, 'I003', 0 )
		endif
		
		if HasItem( SysUnit, 'cnob' ) and HasItem( SysUnit, 'rin1' ) then
			call RemoveItem( GetItemById( SysUnit, 'cnob' ) )
			call RemoveItem( GetItemById( SysUnit, 'rin1' ) )

			call CombineItem( SysUnit, 'I005', 0 )
		endif
		
		if HasItem( SysUnit, 'rwiz' ) and HasItem( SysUnit, 'rde2' ) then
			call RemoveItem( GetItemById( SysUnit, 'rwiz' ) )
			call RemoveItem( GetItemById( SysUnit, 'rde2' ) )
		
			call CombineItem( SysUnit, 'I01P', 0 )
		endif

		if HasItem( SysUnit, 'I00O' ) and HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I026' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00O' ) )
			call RemoveItem( GetItemById( SysUnit, 'I006' ) )
			call RemoveItem( GetItemById( SysUnit, 'I026' ) )

			call CombineItem( SysUnit, 'I007', 1 )
		endif
		
		if HasItem( SysUnit, 'I00V' ) and HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I02G' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00V' ) )
			call RemoveItem( GetItemById( SysUnit, 'I006' ) )
			call RemoveItem( GetItemById( SysUnit, 'I02G' ) )

			call CombineItem( SysUnit, 'I01N', 1 )
		endif
		
		if HasItem( SysUnit, 'I00Z' ) and HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I036' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00Z' ) )
			call RemoveItem( GetItemById( SysUnit, 'I006' ) )
			call RemoveItem( GetItemById( SysUnit, 'I036' ) )

			call CombineItem( SysUnit, 'I02S', 1 )
		endif

		if HasItem( SysUnit, 'I018' ) and HasItem( SysUnit, 'rde2' ) and HasItem( SysUnit, 'I02B' ) then
			call RemoveItem( GetItemById( SysUnit, 'I018' ) )
			call RemoveItem( GetItemById( SysUnit, 'rde2' ) )
			call RemoveItem( GetItemById( SysUnit, 'I02B' ) )

			call CombineItem( SysUnit, 'I00W', 0 )
		endif
		
		if HasItem( SysUnit, 'I00U' ) and HasItem( SysUnit, 'rat9' ) and HasItem( SysUnit, 'I024' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00U' ) )
			call RemoveItem( GetItemById( SysUnit, 'rat9' ) )
			call RemoveItem( GetItemById( SysUnit, 'I024' ) )

			call CombineItem( SysUnit, 'I01B', 0 )
		endif
		
		if HasItem( SysUnit, 'I00U' ) and HasItem( SysUnit, 'I04M' ) and HasItem( SysUnit, 'I052' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00U' ) )
			call RemoveItem( GetItemById( SysUnit, 'I04M' ) )
			call RemoveItem( GetItemById( SysUnit, 'I052' ) )

			call CombineItem( SysUnit, 'I04J', 0 )
		endif
		
		if HasItem( SysUnit, 'I018' ) and HasItem( SysUnit, 'I01A' ) and HasItem( SysUnit, 'I019' ) then
			call RemoveItem( GetItemById( SysUnit, 'I018' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01A' ) )
			call RemoveItem( GetItemById( SysUnit, 'I019' ) )

			call CombineItem( SysUnit, 'I02A', 0 )
		endif
		
		if HasItem( SysUnit, 'I00P' ) and HasItem( SysUnit, 'I01A' ) and HasItem( SysUnit, 'I011' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00P' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01A' ) )
			call RemoveItem( GetItemById( SysUnit, 'I011' ) )

			call CombineItem( SysUnit, 'I01R', 0 )
		endif

		if HasItem( SysUnit, 'I00X' ) and HasItem( SysUnit, 'bgst' ) and HasItem( SysUnit, 'I027' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00X' ) )
			call RemoveItem( GetItemById( SysUnit, 'bgst' ) )
			call RemoveItem( GetItemById( SysUnit, 'I027' ) )

			call CombineItem( SysUnit, 'I01G', 0 )
		endif
		
		if HasItem( SysUnit, 'I00Y' ) and HasItem( SysUnit, 'belv' ) and HasItem( SysUnit, 'I028' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00Y' ) )
			call RemoveItem( GetItemById( SysUnit, 'belv' ) )
			call RemoveItem( GetItemById( SysUnit, 'I028' ) )

			call CombineItem( SysUnit, 'I01H', 0 )
		endif
		
		if HasItem( SysUnit, 'I00Y' ) and HasItem( SysUnit, 'ciri' ) and HasItem( SysUnit, 'I02H' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00Y' ) )
			call RemoveItem( GetItemById( SysUnit, 'ciri' ) )
			call RemoveItem( GetItemById( SysUnit, 'I02H' ) )

			call CombineItem( SysUnit, 'I023', 0 )
		endif
		
		if HasItem( SysUnit, 'I013' ) and HasItem( SysUnit, 'modt' ) then
			call RemoveItem( GetItemById( SysUnit, 'I013' ) )
			call RemoveItem( GetItemById( SysUnit, 'modt' ) )

			call CombineItem( SysUnit, 'I01E', 0 )
		endif
		
		if HasItem( SysUnit, 'I029' ) and HasItem( SysUnit, 'modt' ) then
			call RemoveItem( GetItemById( SysUnit, 'I029' ) )
			call RemoveItem( GetItemById( SysUnit, 'modt' ) )

			call CombineItem( SysUnit, 'I01O', 0 )
		endif
		
		if HasItem( SysUnit, 'I035' ) and HasItem( SysUnit, 'modt' ) and HasItem( SysUnit, 'I01P' ) then
			call RemoveItem( GetItemById( SysUnit, 'I035' ) )
			call RemoveItem( GetItemById( SysUnit, 'modt' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01P' ) )

			call CombineItem( SysUnit, 'I01X', 0 )
		endif
		
		if HasItem( SysUnit, 'I013' ) and HasItem( SysUnit, 'I00P' ) and HasItem( SysUnit, 'brac' ) then
			call RemoveItem( GetItemById( SysUnit, 'I013' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00P' ) )
			call RemoveItem( GetItemById( SysUnit, 'brac' ) )

			call CombineItem( SysUnit, 'I01Q', 0 )
		endif
		
		if HasItem( SysUnit, 'I00P' ) and HasItem( SysUnit, 'I00Q' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00P' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00Q' ) )

			call CombineItem( SysUnit, 'I00O', 0 )
		endif
		
		if HasItem( SysUnit, 'I00O' ) and HasItem( SysUnit, 'I00U' ) and HasItem( SysUnit, 'I00V' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00O' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00U' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00V' ) )

			call CombineItem( SysUnit, 'I00N', 0 )
		endif
		
		if HasItem( SysUnit, 'I01G' ) and HasItem( SysUnit, 'I01H' ) then
			call RemoveItem( GetItemById( SysUnit, 'I01G' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01H' ) )

			call CombineItem( SysUnit, 'I014', 1 )
		endif
		
		if HasItem( SysUnit, 'I01B' ) and HasItem( SysUnit, 'I016' ) and HasItem( SysUnit, 'I00J' ) then
			call RemoveItem( GetItemById( SysUnit, 'I01B' ) )
			call RemoveItem( GetItemById( SysUnit, 'I016' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00J' ) )

			call CombineItem( SysUnit, 'I01C', 1 )
		endif
		
		if HasItem( SysUnit, 'I00W' ) and HasItem( SysUnit, 'I023' ) and HasItem( SysUnit, 'I038' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00W' ) )
			call RemoveItem( GetItemById( SysUnit, 'I023' ) )
			call RemoveItem( GetItemById( SysUnit, 'I038' ) )

			call CombineItem( SysUnit, 'I037', 1 )
		endif
		
		if HasItem( SysUnit, 'I00L' ) and HasItem( SysUnit, 'I01Y' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00L' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01Y' ) )

			call CombineItem( SysUnit, 'I00M', 1 )
		endif
		
		if HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I02A' ) and HasItem( SysUnit, 'I021' ) then
			call RemoveItem( GetItemById( SysUnit, 'I006' ) )
			call RemoveItem( GetItemById( SysUnit, 'I02A' ) )
			call RemoveItem( GetItemById( SysUnit, 'I021' ) )

			if IsUnitType( SysUnit, UNIT_TYPE_RANGED_ATTACKER ) then
				call CombineItem( SysUnit, 'I004', 1 )
			else
				call CombineItem( SysUnit, 'I008', 1 )
			endif
		endif
		
		if HasItem( SysUnit, 'I00S' ) and HasItem( SysUnit, 'I01A' ) and HasItem( SysUnit, 'I01Z' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00S' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01A' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01Z' ) )

			call CombineItem( SysUnit, 'I000', 1 )
		endif
		
		if HasItem( SysUnit, 'I00T' ) and HasItem( SysUnit, 'I010' ) and HasItem( SysUnit, 'I022' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00T' ) )
			call RemoveItem( GetItemById( SysUnit, 'I010' ) )
			call RemoveItem( GetItemById( SysUnit, 'I022' ) )

			call CombineItem( SysUnit, 'I01J', 1 )
		endif
		
		if HasItem( SysUnit, 'I00T' ) and HasItem( SysUnit, 'I016' ) and HasItem( SysUnit, 'I034' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00T' ) )
			call RemoveItem( GetItemById( SysUnit, 'I016' ) )
			call RemoveItem( GetItemById( SysUnit, 'I034' ) )

			call CombineItem( SysUnit, 'I02P', 1 )
		endif
		
		if HasItem( SysUnit, 'I00L' ) and HasItem( SysUnit, 'I016' ) and HasItem( SysUnit, 'I02V' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00L' ) )
			call RemoveItem( GetItemById( SysUnit, 'I016' ) )
			call RemoveItem( GetItemById( SysUnit, 'I02V' ) )

			call CombineItem( SysUnit, 'I02Q', 1 )
		endif
		
		if HasItem( SysUnit, 'I00L' ) and HasItem( SysUnit, 'I01N' ) and HasItem( SysUnit, 'I02T' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00L' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01N' ) )
			call RemoveItem( GetItemById( SysUnit, 'I02T' ) )

			call CombineItem( SysUnit, 'I02R', 1 )
		endif
		
		if HasItem( SysUnit, 'I02R' ) and HasItem( SysUnit, 'I01K' ) and HasItem( SysUnit, 'I04X' ) then
			call RemoveItem( GetItemById( SysUnit, 'I02R' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01K' ) )
			call RemoveItem( GetItemById( SysUnit, 'I04X' ) )

			call CombineItem( SysUnit, 'I04I', 1 )
		endif
		
		if HasItem( SysUnit, 'I00T' ) and HasItem( SysUnit, 'I02K' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00T' ) )
			call RemoveItem( GetItemById( SysUnit, 'I02K' ) )

			call CombineItem( SysUnit, 'I02J', 1 )
		endif
		
		if HasItem( SysUnit, 'I00S' ) and HasItem( SysUnit, 'I01E' ) and HasItem( SysUnit, 'I020' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00S' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01E' ) )
			call RemoveItem( GetItemById( SysUnit, 'I020' ) )

			call CombineItem( SysUnit, 'I00B', 1 )
		endif
		
		if HasItem( SysUnit, 'I01Q' ) and HasItem( SysUnit, 'I01E' ) and HasItem( SysUnit, 'I02C' ) then
			call RemoveItem( GetItemById( SysUnit, 'I01Q' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01E' ) )
			call RemoveItem( GetItemById( SysUnit, 'I02C' ) )

			call CombineItem( SysUnit, 'I01T', 1 )
		endif
		
		if HasItem( SysUnit, 'I00Z' ) and HasItem( SysUnit, 'I016' ) and HasItem( SysUnit, 'I025' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00Z' ) )
			call RemoveItem( GetItemById( SysUnit, 'I016' ) )
			call RemoveItem( GetItemById( SysUnit, 'I025' ) )

			call CombineItem( SysUnit, 'I01K', 1 )
		endif
		
		if HasItem( SysUnit, 'I000' ) and HasItem( SysUnit, 'I015' ) and HasItem( SysUnit, 'I02D' ) then
			call RemoveItem( GetItemById( SysUnit, 'I000' ) )
			call RemoveItem( GetItemById( SysUnit, 'I015' ) )
			call RemoveItem( GetItemById( SysUnit, 'I02D' ) )

			call CombineItem( SysUnit, 'I01U', 2 )
		endif
		
		if HasItem( SysUnit, 'I000' ) and HasItem( SysUnit, 'I039' ) and HasItem( SysUnit, 'I04W' ) then
			call RemoveItem( GetItemById( SysUnit, 'I000' ) )
			call RemoveItem( GetItemById( SysUnit, 'I039' ) )
			call RemoveItem( GetItemById( SysUnit, 'I04W' ) )

			call CombineItem( SysUnit, 'I04K', 2 )
		endif
		
		if HasItem( SysUnit, 'I039' ) and HasItem( SysUnit, 'I02A' ) then
			call RemoveItem( GetItemById( SysUnit, 'I039' ) )
			call RemoveItem( GetItemById( SysUnit, 'I02A' ) )

			call CombineItem( SysUnit, 'I03B', 1 )
		endif

		if UID != 'E004' and UID != 'E000' and UID != 'E002' and UID != 'E001' and UID != 'N00X' then
			if HasItem( SysUnit, 'I03B' ) or HasItem( SysUnit, 'I054' ) then
				if ItemID == 'I03B' then
					call RemoveItem( GetItemById( SysUnit, 'I03B' ) )
			elseif ItemID == 'I054' then
					call RemoveItem( GetItemById( SysUnit, 'I054' ) )
				endif
				call UnitAddItemById( SysUnit, 'I03D' )
			endif
		endif

		if UID == 'E004' or UID == 'E000' or UID == 'E002' or UID == 'E001' or UID == 'N00X' then
			if HasItem( SysUnit, 'I03D' ) then
				call RemoveItem( GetItemById( SysUnit, 'I03D' ) )
				if UID == 'E004' or UID == 'E000' or UID == 'E002' or UID == 'E001' then
					call UnitAddItemById( SysUnit, 'I03B' )
				elseif UID == 'N00X' then
					call UnitAddItemById( SysUnit, 'I054' )
				endif
			endif

			if HasItem( SysUnit, 'I03B' ) then
				if UID == 'N00X' then
					call RemoveItem( GetItemById( SysUnit, 'I03B' ) )
					call UnitAddItemById( SysUnit, 'I054' )
				endif
			endif

			if HasItem( SysUnit, 'I054' ) then
				if UID == 'E004' or UID == 'E000' or UID == 'E002' or UID == 'E001' then
					call RemoveItem( GetItemById( SysUnit, 'I054' ) )
					call UnitAddItemById( SysUnit, 'I03B' )
				endif
			endif
		endif

		if HasItem( SysUnit, 'I039' ) and HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I019' ) and HasItem( SysUnit, 'I00E' ) then
			call RemoveItem( GetItemById( SysUnit, 'I039' ) )
			call RemoveItem( GetItemById( SysUnit, 'I006' ) )
			call RemoveItem( GetItemById( SysUnit, 'I019' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00E' ) )

			call CombineItem( SysUnit, 'I00G', 2 )
		endif
		
		if HasItem( SysUnit, 'I01J' ) and HasItem( SysUnit, 'I017' ) and HasItem( SysUnit, 'I02E' ) then
			call RemoveItem( GetItemById( SysUnit, 'I01J' ) )
			call RemoveItem( GetItemById( SysUnit, 'I017' ) )
			call RemoveItem( GetItemById( SysUnit, 'I02E' ) )

			call CombineItem( SysUnit, 'I01V', 1 )
		endif
		
		if HasItem( SysUnit, 'I02F' ) and HasItem( SysUnit, 'I03F' ) and HasItem( SysUnit, 'I01C' ) and HasItem( SysUnit, 'I00M' ) then
			call RemoveItem( GetItemById( SysUnit, 'I02F' ) )
			call RemoveItem( GetItemById( SysUnit, 'I03F' ) )
			call RemoveItem( GetItemById( SysUnit, 'I01C' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00M' ) )

			call CombineItem( SysUnit, 'I01S', 2 )
		endif
		
		if HasItem( SysUnit, 'I01D' ) and HasItem( SysUnit, 'I03F' ) and HasItem( SysUnit, 'I00S' ) then
			call RemoveItem( GetItemById( SysUnit, 'I01D' ) )
			call RemoveItem( GetItemById( SysUnit, 'I03F' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00S' ) )

			call CombineItem( SysUnit, 'I00K', 1 )
		endif
		
		if HasItem( SysUnit, 'I03E' ) and HasItem( SysUnit, 'I03F' ) and HasItem( SysUnit, 'I017' ) then
			call RemoveItem( GetItemById( SysUnit, 'I03E' ) )
			call RemoveItem( GetItemById( SysUnit, 'I03F' ) )
			call RemoveItem( GetItemById( SysUnit, 'I017' ) )

			call CombineItem( SysUnit, 'I01F', 1 )
		endif
		
		if HasItem( SysUnit, 'I04E' ) and HasItem( SysUnit, 'I00N' ) and HasItem( SysUnit, 'I00A' ) then
			call RemoveItem( GetItemById( SysUnit, 'I04E' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00N' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00A' ) )

			call CombineItem( SysUnit, 'I04C', 2 )
		endif
		
		if HasItem( SysUnit, 'I012' ) and HasItem( SysUnit, 'I00A' ) then
			call RemoveItem( GetItemById( SysUnit, 'I012' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00A' ) )

			call CombineItem( SysUnit, 'I00R', 2 )
		endif
		
		if HasItem( SysUnit, 'I00D' ) and HasItem( SysUnit, 'I00A' ) then
			call RemoveItem( GetItemById( SysUnit, 'I00D' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00A' ) )

			call CombineItem( SysUnit, 'I009', 2 )
		endif
		
		if HasItem( SysUnit, 'I01W' ) and HasItem( SysUnit, 'ofro' ) and HasItem( SysUnit, 'I00A' ) and ( HasItem( SysUnit, 'I004' ) or HasItem( SysUnit, 'I008' ) ) then
			call RemoveItem( GetItemById( SysUnit, 'I01W' ) )
			call RemoveItem( GetItemById( SysUnit, 'ofro' ) )
			call RemoveItem( GetItemById( SysUnit, 'I00A' ) )
			call RemoveItem( GetItemById( SysUnit, 'I004' ) )
			call RemoveItem( GetItemById( SysUnit, 'I008' ) )

			call CombineItem( SysUnit, 'I00I', 4 )
		endif
		
		if HasItem( SysUnit, 'I02L' ) and HasItem( SysUnit, 'I007' ) and HasItem( SysUnit, 'I001' ) then
			call RemoveItem( GetItemById( SysUnit, 'I02L' ) )
			call RemoveItem( GetItemById( SysUnit, 'I007' ) )
			call RemoveItem( GetItemById( SysUnit, 'I001' ) )

			call CombineItem( SysUnit, 0, 2 )
			call CombineItem( SysUnit, 'I02M', 3 )
		endif
		
		if ItemID == 'moon' then
			call RemoveItem( SysItem )
		endif

		if IsUnitType( SysUnit, UNIT_TYPE_HERO ) then
			if ItemID == 'I01I' then
				if HasAbility( SysUnit, 'A03Y' ) or HasAbility( SysUnit, 'A00L' ) or HasAbility( SysUnit, 'A028' ) then
					call DisplayTimedTextToPlayer( GetTriggerPlayer( ), 0, 0, 4, "|cffffcc00This item works only once|r" )
					call AdjustPlayerStateBJ( 30, GetOwningPlayer( SysUnit ), PLAYER_STATE_RESOURCE_LUMBER )
				else
					if GetHeroLevel( SysUnit ) < 50 then
						call DisplayTimedTextToPlayer( GetTriggerPlayer( ), 0, 0, 4, "|cffffcc00Your level is too low|r" )
						call AdjustPlayerStateBJ( 30, GetOwningPlayer( SysUnit ), PLAYER_STATE_RESOURCE_LUMBER )
				elseif GetHeroLevel( SysUnit ) >= 50 then
						if GetHeroSkillPoints( SysUnit ) != 0 then
							call DisplayTimedTextToPlayer( GetTriggerPlayer( ), 0, 0, 4, "|cffffcc00You still have unlearned ability|r" )
							call AdjustPlayerStateBJ( 30, GetOwningPlayer( SysUnit ), PLAYER_STATE_RESOURCE_LUMBER )
						else
							set MainStat = LoadString( "Hero_Main_Stat_" + I2S( LoadInteger( HashTable, GetHandleId( SysUnit ), StringHash( "Hero_Index" ) ) ) )
							if MainStat == "STR" or MainStat == "AGI" or MainStat == "INT" then
								if MainStat == "STR" then
									set AID = 'A028'
								elseif MainStat == "AGI" then
									set AID = 'A03Y'
								elseif MainStat == "INT" then
									set AID = 'A00L'
								endif
								call UnitAddAbility( SysUnit, AID )
								call UnitMakeAbilityPermanent( SysUnit, true, AID )
								call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", SysUnit, "origin" ) )
								call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\NightElf\\Taunt\\TauntCaster.mdl", SysUnit, "origin" ) )
							endif
						endif
					endif
				endif
			endif
			
			if ItemID == 'tkno' then
				if GetHeroLevel( SysUnit ) < 50 then
					call UnitAddItemById( SysUnit, 'I02I' )
			elseif GetHeroLevel( SysUnit ) >= 50 then
					call DisplayTimedTextToPlayer( GetTriggerPlayer( ), 0, 0, 4, "|cffffcc00Your level is too high to use this item|r" )
					call AdjustPlayerStateBJ( 10, GetOwningPlayer( SysUnit ), PLAYER_STATE_RESOURCE_LUMBER )
				endif
			endif

			if ItemID == 'I04Z' then
				if HasBlink( SysUnit ) then
					call DisplayTimedTextToPlayer( GetTriggerPlayer( ), 0, 0, 4, "|cffffcc00Your hero cannot use this item|r" )
					call AdjustPlayerStateBJ( 2500, GetOwningPlayer( SysUnit ), PLAYER_STATE_RESOURCE_GOLD )
				else
					call UnitAddItemById( SysUnit, 'desc' )
				endif
			endif
			
			if ItemID == 'desc' then
				if HasBlink( SysUnit ) then
					call UnitRemoveItem( SysUnit, SysItem )
				endif
			endif
		endif
    endfunction
	//#ExportEnd

	function IsUnitAtBase takes unit hero returns boolean
		if GetPlayerTeam( GetOwningPlayer(hero) ) == 1 and IsUnitInArea( SysUnit, "base_2" ) then
			return true
		elseif GetPlayerTeam( GetOwningPlayer(hero) ) == 0 and IsUnitInArea( SysUnit, "base_1" ) then
			return true
		else 
			return false
		endif
	endfunction

	function GetItemPriceInGold takes integer ItemID returns integer
		return LoadInteger( ItemPrices, ItemID, StringHash( I2S(ItemID) ) )
	endfunction

	function SetItemPriceInGold takes integer ItemID, integer Price returns nothing
		call SaveInteger( ItemPrices, ItemID, StringHash( I2S(ItemID) ), Price)
	endfunction

	function Init_ItemPrices takes nothing returns nothing
		// init item shop 2
		call SetItemPriceInGold(Item_Gloves_of_Haste, Price_Gloves_of_Haste)
		call SetItemPriceInGold(Item_Mask_of_Death, Price_Mask_of_Death)
		call SetItemPriceInGold(Item_Hollow_Mask, Price_Hollow_Mask)
		call SetItemPriceInGold(Item_Boots_of_Speed, Price_Boots_of_Speed)
		call SetItemPriceInGold(Item_Shinigami_Cloak, Price_Shinigami_Cloak)
		call SetItemPriceInGold(Item_Kuma_Unique_Book, Price_Kuma_Unique_Book)
		// call SetItemPriceInGold(Item_Gem_of_True_Seeing, Price_Kuma_Unique_Book)


	endfunction

	function UnitAddBoughtItem takes unit Unit, integer BoughtItemID returns nothing
		if not IsUnitAtBase(Unit) then
			call AdjustPlayerStateBJ( GetItemPriceInGold(BoughtItemID), GetOwningPlayer( SysUnit ), PLAYER_STATE_RESOURCE_GOLD )
			call DisplayTimedTextToPlayer(GetOwningPlayer(SysUnit), 0, 0, 4, "|cffffcc00Your hero must be at base|r" )
		else
			call UnitAddItemById(Unit, BoughtItemID)
		endif
	endfunction

	function ItemShop3_Do_Sell takes unit BuyingUnit, unit SellingUnit, integer SoldItemID returns nothing 
		set SysUnit = BuyingUnit
		// item shop 2
		if SoldItemID == 'I07L' then
			if ( HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'belv' ) ) or ( HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'bgst' ) ) or ( HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'ciri' ) ) then
				if HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'belv' ) then
					call RemoveItem( GetItemById( SysUnit, 'bspd' ) )
					call RemoveItem( GetItemById( SysUnit, 'belv' ) )
				elseif HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'bgst' ) then
					call RemoveItem( GetItemById( SysUnit, 'bspd' ) )
					call RemoveItem( GetItemById( SysUnit, 'bgst' ) )
				elseif HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'ciri' ) then
					call RemoveItem( GetItemById( SysUnit, 'bspd' ) )
					call RemoveItem( GetItemById( SysUnit, 'ciri' ) )
				endif
				call CombineItem( SysUnit, 'I00C', 0 )
			else
				call UnitAddBoughtItem( SysUnit, 'gcel' )
			endif
		endif
		
		if SoldItemID == 'I07E' then
			if HasItem( SysUnit, 'I013' ) or HasItem( SysUnit, 'I029' ) then
				if HasItem( SysUnit, 'I013' ) then
					call RemoveItem( GetItemById( SysUnit, 'I013' ) )
					call CombineItem( SysUnit, 'I01E', 0 )
				else
					if HasItem( SysUnit, 'I029' ) then
						call RemoveItem( GetItemById( SysUnit, 'I029' ) )
						call CombineItem( SysUnit, 'I01O', 0 )
					endif
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'modt' )
			endif
		endif
		
		if SoldItemID == 'I07K' then
			if HasItem( SysUnit, 'rde2' ) then
				call RemoveItem( GetItemById( SysUnit, 'rde2' ) )
				call CombineItem( SysUnit, 'I01P', 0 )
			else
				call UnitAddBoughtItem( SysUnit, 'rwiz' )
			endif
		endif
		
		if SoldItemID == 'I07P' then
			if ( HasItem( SysUnit, 'gcel' ) and HasItem( SysUnit, 'belv' ) ) or ( HasItem( SysUnit, 'gcel' ) and HasItem( SysUnit, 'bgst' ) ) or ( HasItem( SysUnit, 'gcel' ) and HasItem( SysUnit, 'ciri' ) ) then
				if HasItem( SysUnit, 'gcel' ) and HasItem( SysUnit, 'belv' ) then
					call RemoveItem( GetItemById( SysUnit, 'gcel' ) )
					call RemoveItem( GetItemById( SysUnit, 'belv' ) )
			elseif HasItem( SysUnit, 'gcel' ) and HasItem( SysUnit, 'bgst' ) then
					call RemoveItem( GetItemById( SysUnit, 'gcel' ) )
					call RemoveItem( GetItemById( SysUnit, 'bgst' ) )
			elseif HasItem( SysUnit, 'gcel' ) and HasItem( SysUnit, 'ciri' ) then
					call RemoveItem( GetItemById( SysUnit, 'gcel' ) )
					call RemoveItem( GetItemById( SysUnit, 'ciri' ) )
				endif
				call CombineItem( SysUnit, 'I00C', 0 )
			else
				call UnitAddBoughtItem( SysUnit, 'bspd' )
			endif
		endif
		
		if SoldItemID == 'I07G' then
			if HasItem( SysUnit, 'I013' ) and HasItem( SysUnit, 'I00P' ) then
				call RemoveItem( GetItemById( SysUnit, 'I013' ) )
				call RemoveItem( GetItemById( SysUnit, 'I00P' ) )
				call CombineItem( SysUnit, 'I01Q', 0 )
			else
				call UnitAddBoughtItem( SysUnit, 'brac' )
			endif
		endif
	endfunction

	function ItemShop4_Do_Sell takes unit BuyingUnit, unit SellingUnit, integer SoldItemID returns nothing 
		set SysUnit = BuyingUnit

		if SoldItemID == 'I07U' then
			if ( HasItem( SysUnit, 'I01B' ) and HasItem( SysUnit, 'I00J' ) ) or ( HasItem( SysUnit, 'I00L' ) and HasItem( SysUnit, 'I02V' ) ) or ( HasItem( SysUnit, 'I00T' ) and HasItem( SysUnit, 'I034' ) ) or ( HasItem( SysUnit, 'I00Z' ) and HasItem( SysUnit, 'I025' ) ) then
				if HasItem( SysUnit, 'I01B' ) and HasItem( SysUnit, 'I00J' ) then
					call RemoveItem( GetItemById( SysUnit, 'I01B' ) )
					call RemoveItem( GetItemById( SysUnit, 'I00J' ) )
					call CombineItem( SysUnit, 'I01C', 1 )
			elseif HasItem( SysUnit, 'I00L' ) and HasItem( SysUnit, 'I02V' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00L' ) )
					call RemoveItem( GetItemById( SysUnit, 'I02V' ) )
					call CombineItem( SysUnit, 'I02Q', 1 )
			elseif HasItem( SysUnit, 'I00T' ) and HasItem( SysUnit, 'I034' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00T' ) )
					call RemoveItem( GetItemById( SysUnit, 'I034' ) )
					call CombineItem( SysUnit, 'I02P', 1 )
			elseif HasItem( SysUnit, 'I00Z' ) and HasItem( SysUnit, 'I025' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00Z' ) )
					call RemoveItem( GetItemById( SysUnit, 'I025' ) )
					call CombineItem( SysUnit, 'I01K', 1 )
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'I016' )
			endif
		endif
		
		if SoldItemID == 'I07T' then
			if ( HasItem( SysUnit, 'I010' ) and HasItem( SysUnit, 'I022' ) ) or ( HasItem( SysUnit, 'I016' ) and HasItem( SysUnit, 'I034' ) ) or HasItem( SysUnit, 'I02K' ) then
				if HasItem( SysUnit, 'I010' ) and HasItem( SysUnit, 'I022' ) then
					call RemoveItem( GetItemById( SysUnit, 'I010' ) )
					call RemoveItem( GetItemById( SysUnit, 'I022' ) )
					call CombineItem( SysUnit, 'I01J', 1 )
			elseif HasItem( SysUnit, 'I016' ) and HasItem( SysUnit, 'I034' ) then
					call RemoveItem( GetItemById( SysUnit, 'I016' ) )
					call RemoveItem( GetItemById( SysUnit, 'I034' ) )
					call CombineItem( SysUnit, 'I02P', 1 )
			elseif HasItem( SysUnit, 'I02K' ) then
					call RemoveItem( GetItemById( SysUnit, 'I02K' ) )
					call CombineItem( SysUnit, 'I02J', 1 )
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'I00T' )
			endif
		endif
		
		if SoldItemID == 'I078' then
			if ( HasItem( SysUnit, 'I01A' ) and HasItem( SysUnit, 'I01Z' ) ) or ( HasItem( SysUnit, 'I01E' ) and HasItem( SysUnit, 'I020' ) ) or ( HasItem( SysUnit, 'I03F' ) and HasItem( SysUnit, 'I01D' ) ) then
				if HasItem( SysUnit, 'I01A' ) and HasItem( SysUnit, 'I01Z' ) then
					call RemoveItem( GetItemById( SysUnit, 'I01A' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01Z' ) )
					call CombineItem( SysUnit, 'I000', 1 )
			elseif HasItem( SysUnit, 'I01E' ) and HasItem( SysUnit, 'I020' ) then
					call RemoveItem( GetItemById( SysUnit, 'I01E' ) )
					call RemoveItem( GetItemById( SysUnit, 'I020' ) )
					call CombineItem( SysUnit, 'I00B', 1 )
			elseif HasItem( SysUnit, 'I03F' ) and HasItem( SysUnit, 'I01D' ) then
					call RemoveItem( GetItemById( SysUnit, 'I03F' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01D' ) )
					call CombineItem( SysUnit, 'I00K', 2 )
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'I00S' )
			endif
		endif
		
		if SoldItemID == 'I06Y' then
			if HasItem( SysUnit, 'I01Y' ) or ( HasItem( SysUnit, 'I01N' ) and HasItem( SysUnit, 'I02T' ) ) or ( HasItem( SysUnit, 'I016' ) and HasItem( SysUnit, 'I02V' ) ) then
				if HasItem( SysUnit, 'I01Y' ) then
					call RemoveItem( GetItemById( SysUnit, 'I01Y' ) )
					call CombineItem( SysUnit, 'I00M', 1 )
			elseif HasItem( SysUnit, 'I016' ) and HasItem( SysUnit, 'I02V' ) then
					call RemoveItem( GetItemById( SysUnit, 'I016' ) )
					call RemoveItem( GetItemById( SysUnit, 'I02V' ) )
					call CombineItem( SysUnit, 'I02Q', 1 )
			elseif HasItem( SysUnit, 'I01N' ) and HasItem( SysUnit, 'I02T' ) then
					call RemoveItem( GetItemById( SysUnit, 'I01N' ) )
					call RemoveItem( GetItemById( SysUnit, 'I02T' ) )
					call CombineItem( SysUnit, 'I02R', 1 )
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'I00L' )
			endif
		endif
		
		if SoldItemID == 'I074' then
			if ( HasItem( SysUnit, 'I01J' ) and HasItem( SysUnit, 'I02E' ) ) or ( HasItem( SysUnit, 'I03F' ) and HasItem( SysUnit, 'I03E' ) ) then
				if HasItem( SysUnit, 'I01J' ) and HasItem( SysUnit, 'I02E' ) then
					call RemoveItem( GetItemById( SysUnit, 'I01J' ) )
					call RemoveItem( GetItemById( SysUnit, 'I02E' ) )
					call CombineItem( SysUnit, 'I01V', 2 )
			elseif HasItem( SysUnit, 'I03F' ) and HasItem( SysUnit, 'I03E' ) then
					call RemoveItem( GetItemById( SysUnit, 'I03F' ) )
					call RemoveItem( GetItemById( SysUnit, 'I03E' ) )
					call CombineItem( SysUnit, 'I01F', 2 )
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'I017' )
			endif
		endif
		
		if SoldItemID == 'I06U' then
			if HasItem( SysUnit, 'I00Q' ) or ( HasItem( SysUnit, 'I013' ) and HasItem( SysUnit, 'brac' ) ) or ( HasItem( SysUnit, 'I011' ) and HasItem( SysUnit, 'I01A' ) ) then
				if HasItem( SysUnit, 'I00Q' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00Q' ) )
					call CombineItem( SysUnit, 'I00O', 0 )
			elseif HasItem( SysUnit, 'I013' ) and HasItem( SysUnit, 'brac' ) then
					call RemoveItem( GetItemById( SysUnit, 'I013' ) )
					call RemoveItem( GetItemById( SysUnit, 'brac' ) )
					call CombineItem( SysUnit, 'I01Q', 0 )
			elseif HasItem( SysUnit, 'I011' ) and HasItem( SysUnit, 'I01A' ) then
					call RemoveItem( GetItemById( SysUnit, 'I011' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01A' ) )
					call CombineItem( SysUnit, 'I01R', 0 )
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'I00P' )
			endif
		endif
		
		if SoldItemID == 'I06V' then
			if HasItem( SysUnit, 'I00P' ) then
				call RemoveItem( GetItemById( SysUnit, 'I00P' ) )
				call CombineItem( SysUnit, 'I00O', 0 )
			else
				call UnitAddBoughtItem( SysUnit, 'I00Q' )
			endif
		endif
		
		if SoldItemID == 'I070' then
			if HasItem( SysUnit, 'I02A' ) or ( HasItem( SysUnit, 'I019' ) and HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I00E' ) ) or ( HasItem( SysUnit, 'I000' ) and HasItem( SysUnit, 'I04W' ) ) then
				if HasItem( SysUnit, 'I02A' ) then
					call RemoveItem( GetItemById( SysUnit, 'I02A' ) )
					call CombineItem( SysUnit, 'I03D', 1 )
			elseif HasItem( SysUnit, 'I019' ) and HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I00E' ) then
					call RemoveItem( GetItemById( SysUnit, 'I019' ) )
					call RemoveItem( GetItemById( SysUnit, 'I006' ) )
					call RemoveItem( GetItemById( SysUnit, 'I00E' ) )
					call CombineItem( SysUnit, 'I00G', 1 )
			elseif HasItem( SysUnit, 'I000' ) and HasItem( SysUnit, 'I04W' ) then
					call RemoveItem( GetItemById( SysUnit, 'I000' ) )
					call RemoveItem( GetItemById( SysUnit, 'I04W' ) )
					call CombineItem( SysUnit, 'I04K', 1 )
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'I039' )
			endif
		endif
		
		if SoldItemID == 'I06W' then
			if ( HasItem( SysUnit, 'rde2' ) and HasItem( SysUnit, 'I02B' ) ) or ( HasItem( SysUnit, 'I01A' ) and HasItem( SysUnit, 'I019' ) ) then
				if HasItem( SysUnit, 'rde2' ) and HasItem( SysUnit, 'I02B' ) then
					call RemoveItem( GetItemById( SysUnit, 'rde2' ) )
					call RemoveItem( GetItemById( SysUnit, 'I02B' ) )
					call CombineItem( SysUnit, 'I00W', 0 )
			elseif HasItem( SysUnit, 'I01A' ) and HasItem( SysUnit, 'I019' ) then
					call RemoveItem( GetItemById( SysUnit, 'I01A' ) )
					call RemoveItem( GetItemById( SysUnit, 'I019' ) )
					call CombineItem( SysUnit, 'I02A', 0 )
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'I018' )
			endif
		endif
		
		if SoldItemID == 'I06X' then
			if ( HasItem( SysUnit, 'I018' ) and HasItem( SysUnit, 'I01A' ) ) or ( HasItem( SysUnit, 'I039' ) and HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I00E' ) ) then
				if HasItem( SysUnit, 'I018' ) and HasItem( SysUnit, 'I01A' ) then
					call RemoveItem( GetItemById( SysUnit, 'I018' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01A' ) )
					call CombineItem( SysUnit, 'I02A', 0 )
			elseif HasItem( SysUnit, 'I039' ) and HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I00E' ) then
					call RemoveItem( GetItemById( SysUnit, 'I039' ) )
					call RemoveItem( GetItemById( SysUnit, 'I006' ) )
					call RemoveItem( GetItemById( SysUnit, 'I00E' ) )
					call CombineItem( SysUnit, 'I00G', 1 )
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'I019' )
			endif
		endif
		
		if SoldItemID == 'I06R' then
			if ( HasItem( SysUnit, 'I00P' ) and HasItem( SysUnit, 'I011' ) ) or ( HasItem( SysUnit, 'I018' ) and HasItem( SysUnit, 'I019' ) ) or ( HasItem( SysUnit, 'I00S' ) and HasItem( SysUnit, 'I01Z' ) ) then
				if HasItem( SysUnit, 'I00P' ) and HasItem( SysUnit, 'I011' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00P' ) )
					call RemoveItem( GetItemById( SysUnit, 'I011' ) )
					call CombineItem( SysUnit, 'I01R', 0 )
			elseif HasItem( SysUnit, 'I018' ) and HasItem( SysUnit, 'I019' ) then
					call RemoveItem( GetItemById( SysUnit, 'I018' ) )
					call RemoveItem( GetItemById( SysUnit, 'I019' ) )
					call CombineItem( SysUnit, 'I02A', 0 )
			elseif HasItem( SysUnit, 'I00S' ) and HasItem( SysUnit, 'I01Z' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00S' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01Z' ) )
					call CombineItem( SysUnit, 'I000', 1 )
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'I01A' )
			endif
		endif
		
		if SoldItemID == 'I076' then
		  if ( HasItem( SysUnit, 'I017' ) and HasItem( SysUnit, 'I03E' ) ) or ( HasItem( SysUnit, 'I00S' ) and HasItem( SysUnit, 'I01D' ) ) or ( HasItem( SysUnit, 'I01C' ) and HasItem( SysUnit, 'I00M' ) and HasItem( SysUnit, 'I02F' ) ) then
				if HasItem( SysUnit, 'I017' ) and HasItem( SysUnit, 'I03E' ) then
					call RemoveItem( GetItemById( SysUnit, 'I017' ) )
					call RemoveItem( GetItemById( SysUnit, 'I03E' ) )
					call CombineItem( SysUnit, 'I01F', 2 )
			elseif HasItem( SysUnit, 'I00S' ) and HasItem( SysUnit, 'I01D' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00S' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01D' ) )
					call CombineItem( SysUnit, 'I00K', 2 )
			elseif HasItem( SysUnit, 'I01C' ) and HasItem( SysUnit, 'I00M' ) and HasItem( SysUnit, 'I02F' ) then
					call RemoveItem( GetItemById( SysUnit, 'I01C' ) )
					call RemoveItem( GetItemById( SysUnit, 'I00M' ) )
					call RemoveItem( GetItemById( SysUnit, 'I02F' ) )
					call CombineItem( SysUnit, 'I01S', 3 )
				endif
			else
				call UnitAddBoughtItem( SysUnit, 'I03F' )
			endif
		endif
	endfunction

	//#ExportTo Scripts\Events\ItemSell.j
    function Item_Sell_Event takes nothing returns nothing
    	local unit SellingUnit = GetSellingUnit( )
    	local item SoldItem =  GetSoldItem( )
		local integer SellingID = GetUnitTypeId( SellingUnit )
		local integer SoldItemID = GetItemTypeId( SoldItem )
		local integer ItemPrice

		set SysUnit = GetBuyingUnit( )

		if not IsUnitAtBase(SysUnit) then
			call DisplayTimedTextToPlayer(GetOwningPlayer(SysUnit), 0, 0, 4, "|cffffcc00Долбоёб иди на своей базе закупайся. А голду не верну.|r" )
			return
		endif

		if SellingID == 'hars' then
			call ItemShop3_Do_Sell(SysUnit, SellingUnit, SoldItemID)
		endif

		if SellingID == 'hlum' then
			call ItemShop4_Do_Sell(SysUnit, SellingUnit, SoldItemID)
		endif
		
		if SellingID == 'n001' then
			call BJDebugMsg("seller n001")
			if SoldItemID == 'I07S' then
				if HasItem( SysUnit, 'cnob' ) then
					call RemoveItem( GetItemById( SysUnit, 'cnob' ) )
					call CombineItem( SysUnit, 'I002', 0 )
				else
					call UnitAddItemById( SysUnit, 'rst1' )
				endif
			endif
			
			if SoldItemID == 'I07F' then
				if HasItem( SysUnit, 'cnob' ) then
					call RemoveItem( GetItemById( SysUnit, 'cnob' ) )
					call CombineItem( SysUnit, 'I003', 0 )
				else
					call UnitAddItemById( SysUnit, 'rag1' )
				endif
			endif
			
			if SoldItemID == 'I07I' then
				if HasItem( SysUnit, 'cnob' ) then
					call RemoveItem( GetItemById( SysUnit, 'cnob' ) )
					call CombineItem( SysUnit, 'I005', 0 )
				else
					call UnitAddItemById( SysUnit, 'rin1' )
				endif
			endif
			
			if SoldItemID == 'I07Q' then
				if ( HasItem( SysUnit, 'I00X' ) and HasItem( SysUnit, 'I027' ) ) or ( HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'gcel' ) ) then
					if HasItem( SysUnit, 'I00X' ) and HasItem( SysUnit, 'I027' ) then
						call RemoveItem( GetItemById( SysUnit, 'I00X' ) )
						call RemoveItem( GetItemById( SysUnit, 'I027' ) )
						call CombineItem( SysUnit, 'I01G', 0 )
				elseif HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'gcel' ) then
						call RemoveItem( GetItemById( SysUnit, 'bspd' ) )
						call RemoveItem( GetItemById( SysUnit, 'gcel' ) )
						call CombineItem( SysUnit, 'I00C', 0 )
					endif
				else
					call UnitAddItemById( SysUnit, 'bgst' )
				endif
			endif
			
			if SoldItemID == 'I07O' then
				if ( HasItem( SysUnit, 'I00Y' ) and HasItem( SysUnit, 'I028' ) ) or ( HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'gcel' ) ) then
					if HasItem( SysUnit, 'I00Y' ) and HasItem( SysUnit, 'I028' ) then
						call RemoveItem( GetItemById( SysUnit, 'I00Y' ) )
						call RemoveItem( GetItemById( SysUnit, 'I028' ) )
						call CombineItem( SysUnit, 'I01H', 0 )
				elseif HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'gcel' ) then
						call RemoveItem( GetItemById( SysUnit, 'bspd' ) )
						call RemoveItem( GetItemById( SysUnit, 'gcel' ) )
						call CombineItem( SysUnit, 'I00C', 0 )
					endif
				else
					call UnitAddItemById( SysUnit, 'belv' )
				endif
			endif
			
			if SoldItemID == 'I07H' then
				if ( HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'gcel' ) ) or ( HasItem( SysUnit, 'I00Y' ) and HasItem( SysUnit, 'I02H' ) ) then
					if HasItem( SysUnit, 'bspd' ) and HasItem( SysUnit, 'gcel' ) then
						call RemoveItem( GetItemById( SysUnit, 'bspd' ) )
						call RemoveItem( GetItemById( SysUnit, 'gcel' ) )
						call CombineItem( SysUnit, 'I00C', 0 )
				elseif HasItem( SysUnit, 'I00Y' ) and HasItem( SysUnit, 'I02H' ) then
						call RemoveItem( GetItemById( SysUnit, 'I00Y' ) )
						call RemoveItem( GetItemById( SysUnit, 'I02H' ) )
						call CombineItem( SysUnit, 'I023', 0 )
					endif
				else
					call UnitAddItemById( SysUnit, 'ciri' )
				endif
			endif
			
			if SoldItemID == 'I07N' then
				if HasItem( SysUnit, 'rag1' ) or HasItem( SysUnit, 'rst1' ) or HasItem( SysUnit, 'rin1' ) then
					if HasItem( SysUnit, 'rst1' ) then
						call RemoveItem( GetItemById( SysUnit, 'rst1' ) )
						call CombineItem( SysUnit, 'I002', 0 )
				elseif HasItem( SysUnit, 'rag1' ) then
						call RemoveItem( GetItemById( SysUnit, 'rag1' ) )
						call CombineItem( SysUnit, 'I003', 0 )
				elseif HasItem( SysUnit, 'rin1' ) then
						call RemoveItem( GetItemById( SysUnit, 'rin1' ) )
						call CombineItem( SysUnit, 'I005', 0 )
					endif
				else
					call UnitAddItemById( SysUnit, 'cnob' )
				endif
			endif
			
			if SoldItemID == 'I075' then
				if HasItem( SysUnit, 'bgst' ) and HasItem( SysUnit, 'I027' ) then
					call RemoveItem( GetItemById( SysUnit, 'bgst' ) )
					call RemoveItem( GetItemById( SysUnit, 'I027' ) )
					call CombineItem( SysUnit, 'I01G', 0 )
				else
					call UnitAddItemById( SysUnit, 'I00X' )
				endif
			endif
			
			if SoldItemID == 'I079' then
				if ( HasItem( SysUnit, 'I028' ) and HasItem( SysUnit, 'belv' ) ) or ( HasItem( SysUnit, 'I02H' ) and HasItem( SysUnit, 'ciri' ) ) then
					if HasItem( SysUnit, 'I028' ) and HasItem( SysUnit, 'belv' ) then
						call RemoveItem( GetItemById( SysUnit, 'I028' ) )
						call RemoveItem( GetItemById( SysUnit, 'belv' ) )
						call CombineItem( SysUnit, 'I01H', 0 )
				elseif HasItem( SysUnit, 'I02H' ) and HasItem( SysUnit, 'ciri' ) then
						call RemoveItem( GetItemById( SysUnit, 'I02H' ) )
						call RemoveItem( GetItemById( SysUnit, 'ciri' ) )
						call CombineItem( SysUnit, 'I023', 0 )
					endif
				else
					call UnitAddItemById( SysUnit, 'I00Y' )
				endif
			endif
			
			if SoldItemID == 'I06S' then
				if ( HasItem( SysUnit, 'I016' ) and HasItem( SysUnit, 'I025' ) ) or ( HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I036' ) ) or ( HasItem( SysUnit, 'I010' ) and HasItem( SysUnit, 'I04Y' ) ) then
					if HasItem( SysUnit, 'I016' ) and HasItem( SysUnit, 'I025' ) then
						call RemoveItem( GetItemById( SysUnit, 'I016' ) )
						call RemoveItem( GetItemById( SysUnit, 'I025' ) )
						call CombineItem( SysUnit, 'I01K', 1 )
				elseif HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I036' ) then
						call RemoveItem( GetItemById( SysUnit, 'I006' ) )
						call RemoveItem( GetItemById( SysUnit, 'I036' ) )
						call CombineItem( SysUnit, 'I02S', 1 )
				elseif HasItem( SysUnit, 'I010' ) and HasItem( SysUnit, 'I04Y' ) then
						call RemoveItem( GetItemById( SysUnit, 'I010' ) )
						call RemoveItem( GetItemById( SysUnit, 'I04Y' ) )
						call CombineItem( SysUnit, 'I04H', 1 )
					endif
				else
					call UnitAddItemById( SysUnit, 'I00Z' )
				endif
			endif
			
			if SoldItemID == 'I06T' then
				if ( HasItem( SysUnit, 'I02A' ) and HasItem( SysUnit, 'I021' ) ) or ( HasItem( SysUnit, 'I00O' ) and HasItem( SysUnit, 'I026' ) ) or ( HasItem( SysUnit, 'I00Z' ) and HasItem( SysUnit, 'I036' ) ) or ( HasItem( SysUnit, 'I00V' ) and HasItem( SysUnit, 'I02G' ) ) or ( HasItem( SysUnit, 'I019' ) and HasItem( SysUnit, 'I039' ) and HasItem( SysUnit, 'I00E' ) ) then
					if HasItem( SysUnit, 'I02A' ) and HasItem( SysUnit, 'I021' ) then
						call RemoveItem( GetItemById( SysUnit, 'I02A' ) )
						call RemoveItem( GetItemById( SysUnit, 'I021' ) )
						if IsUnitType( SysUnit, UNIT_TYPE_RANGED_ATTACKER ) then
							call CombineItem( SysUnit, 'I004', 1 )
						else
							call CombineItem( SysUnit, 'I008', 1 )
						endif
				elseif HasItem( SysUnit, 'I00O' ) and HasItem( SysUnit, 'I026' ) then
						call RemoveItem( GetItemById( SysUnit, 'I00O' ) )
						call RemoveItem( GetItemById( SysUnit, 'I026' ) )
						call CombineItem( SysUnit, 'I007', 1 )
				elseif HasItem( SysUnit, 'I00Z' ) and HasItem( SysUnit, 'I036' ) then
						call RemoveItem( GetItemById( SysUnit, 'I00Z' ) )
						call RemoveItem( GetItemById( SysUnit, 'I036' ) )
						call CombineItem( SysUnit, 'I02S', 1 )
				elseif HasItem( SysUnit, 'I00V' ) and HasItem( SysUnit, 'I02G' ) then
						call RemoveItem( GetItemById( SysUnit, 'I00V' ) )
						call RemoveItem( GetItemById( SysUnit, 'I02G' ) )
						call CombineItem( SysUnit, 'I01N', 1 )
				elseif HasItem( SysUnit, 'I019' ) and HasItem( SysUnit, 'I039' ) and HasItem( SysUnit, 'I00E' ) then
						call RemoveItem( GetItemById( SysUnit, 'I019' ) )
						call RemoveItem( GetItemById( SysUnit, 'I039' ) )
						call RemoveItem( GetItemById( SysUnit, 'I00E' ) )
						call CombineItem( SysUnit, 'I00G', 1 )
					endif
				else
					call UnitAddItemById( SysUnit, 'I006' )
				endif
			endif
		endif
		
		if SellingID == 'hvlt' then
			call BJDebugMsg("seller hvlt")
			if SoldItemID == 'I07J' then
				if HasItem( SysUnit, 'I00U' ) and HasItem( SysUnit, 'I024' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00U' ) )
					call RemoveItem( GetItemById( SysUnit, 'I024' ) )
					call CombineItem( SysUnit, 'I01B', 0 )
				else
					call UnitAddItemById( SysUnit, 'rat9' )
				endif
			endif
			
			if SoldItemID == 'I07R' then
				if ( HasItem( SysUnit, 'rat9' ) and HasItem( SysUnit, 'I024' ) ) or ( HasItem( SysUnit, 'I00O' ) and HasItem( SysUnit, 'I00V' ) ) or ( HasItem( SysUnit, 'I04M' ) and HasItem( SysUnit, 'I052' ) ) then
					if HasItem( SysUnit, 'rat9' ) and HasItem( SysUnit, 'I024' ) then
						call RemoveItem( GetItemById( SysUnit, 'rat9' ) )
						call RemoveItem( GetItemById( SysUnit, 'I024' ) )
						call CombineItem( SysUnit, 'I01B', 0 )
				elseif HasItem( SysUnit, 'I00O' ) and HasItem( SysUnit, 'I00V' ) then
						call RemoveItem( GetItemById( SysUnit, 'I00O' ) )
						call RemoveItem( GetItemById( SysUnit, 'I00V' ) )
						call CombineItem( SysUnit, 'I00N', 1 )
				elseif HasItem( SysUnit, 'I04M' ) and HasItem( SysUnit, 'I052' ) then
						call RemoveItem( GetItemById( SysUnit, 'I04M' ) )
						call RemoveItem( GetItemById( SysUnit, 'I052' ) )
						call CombineItem( SysUnit, 'I04J', 1 )
					endif
				else
					call UnitAddItemById( SysUnit, 'I00U' )
				endif
			endif
			
			if SoldItemID == 'I06Z' then
				if ( HasItem( SysUnit, 'I00T' ) and HasItem( SysUnit, 'I022' ) ) or ( HasItem( SysUnit, 'I00Z' ) and HasItem( SysUnit, 'I04Y' ) ) then
					if HasItem( SysUnit, 'I00T' ) and HasItem( SysUnit, 'I022' ) then
						call RemoveItem( GetItemById( SysUnit, 'I00T' ) )
						call RemoveItem( GetItemById( SysUnit, 'I022' ) )
						call CombineItem( SysUnit, 'I01J', 1 )
					else
						if HasItem( SysUnit, 'I00Z' ) and HasItem( SysUnit, 'I04Y' ) then
							call RemoveItem( GetItemById( SysUnit, 'I00Z' ) )
							call RemoveItem( GetItemById( SysUnit, 'I04Y' ) )
							call CombineItem( SysUnit, 'I04H', 1 )
						endif
					endif
				else
					call UnitAddItemById( SysUnit, 'I010' )
				endif
			endif
			
			if SoldItemID == 'I072' then
				if ( HasItem( SysUnit, 'I00O' ) and HasItem( SysUnit, 'I00U' ) ) or ( HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I02G' ) ) then
					if HasItem( SysUnit, 'I00O' ) and HasItem( SysUnit, 'I00U' ) then
						call RemoveItem( GetItemById( SysUnit, 'I00O' ) )
						call RemoveItem( GetItemById( SysUnit, 'I00U' ) )
						call CombineItem( SysUnit, 'I00N', 1 )
				elseif HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I02G' ) then
						call RemoveItem( GetItemById( SysUnit, 'I006' ) )
						call RemoveItem( GetItemById( SysUnit, 'I02G' ) )
						call CombineItem( SysUnit, 'I01N', 1 )
					endif
				else
					call UnitAddItemById( SysUnit, 'I00V' )
				endif
			endif
			
			if SoldItemID == 'I07M' then
				if ( HasItem( SysUnit, 'I018' ) and HasItem( SysUnit, 'I02B' ) ) or HasItem( SysUnit, 'rwiz' ) then
					if HasItem( SysUnit, 'I018' ) and HasItem( SysUnit, 'I02B' ) then
						call RemoveItem( GetItemById( SysUnit, 'I018' ) )
						call RemoveItem( GetItemById( SysUnit, 'I02B' ) )
						call CombineItem( SysUnit, 'I00W', 0 )
				elseif HasItem( SysUnit, 'rwiz' ) then
						call RemoveItem( GetItemById( SysUnit, 'rwiz' ) )
						call CombineItem( SysUnit, 'I01P', 0 )
					endif
				else
					call UnitAddItemById( SysUnit, 'rde2' )
				endif
			endif
			
			if SoldItemID == 'I073' then
				if HasItem( SysUnit, 'I00P' ) and HasItem( SysUnit, 'I01A' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00P' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01A' ) )
					call CombineItem( SysUnit, 'I01R', 0 )
				else
					call UnitAddItemById( SysUnit, 'I011' )
				endif
			endif
			
			if SoldItemID == 'I071' then
				if HasItem( SysUnit, 'I00P' ) and HasItem( SysUnit, 'brac' ) then
					if HasItem( SysUnit, 'I00P' ) and HasItem( SysUnit, 'brac' ) then
						call RemoveItem( GetItemById( SysUnit, 'I00P' ) )
						call RemoveItem( GetItemById( SysUnit, 'brac' ) )
						call CombineItem( SysUnit, 'I01Q', 0 )
				elseif HasItem( SysUnit, 'modt' ) then
						call RemoveItem( GetItemById( SysUnit, 'modt' ) )
						call CombineItem( SysUnit, 'I01E', 0 )
					endif
				else
					call UnitAddItemById( SysUnit, 'I013' )
				endif
			endif
			
			if SoldItemID == 'I04V' then
				if HasItem( SysUnit, 'I00U' ) and HasItem( SysUnit, 'I052' ) then
					if HasItem( SysUnit, 'I00U' ) and HasItem( SysUnit, 'I052' ) then
						call RemoveItem( GetItemById( SysUnit, 'I00U' ) )
						call RemoveItem( GetItemById( SysUnit, 'I052' ) )
						call CombineItem( SysUnit, 'I04J', 1 )
					endif
				else
					call UnitAddItemById( SysUnit, 'I04M' )
				endif
			endif
			
			if SoldItemID == 'I077' then
				if HasItem( SysUnit, 'I000' ) and HasItem( SysUnit, 'I02D' ) then
					call RemoveItem( GetItemById( SysUnit, 'I000' ) )
					call RemoveItem( GetItemById( SysUnit, 'I02D' ) )
					call CombineItem( SysUnit, 'I01U', 2 )
				else
					call UnitAddItemById( SysUnit, 'I015' )
				endif
			endif
		endif

		if SellingID == 'hhou' then
			call BJDebugMsg("seller hhou")
			if SoldItemID == 'I03I' then
				if HasItem( SysUnit, 'I018' ) and HasItem( SysUnit, 'rde2' ) then
					call RemoveItem( GetItemById( SysUnit, 'I018' ) )
					call RemoveItem( GetItemById( SysUnit, 'rde2' ) )
					call CombineItem( SysUnit, 'I00W', 0 )
				else
					call UnitAddItemById( SysUnit, 'I02B' )
				endif
			endif
		endif
		
		if SellingID == 'nC16' then
			call BJDebugMsg("seller nC16")
			if SoldItemID == 'I04A' then
				if HasItem( SysUnit, 'I019' ) and HasItem( SysUnit, 'I039' ) and HasItem( SysUnit, 'I006' ) then
					call RemoveItem( GetItemById( SysUnit, 'I019' ) )
					call RemoveItem( GetItemById( SysUnit, 'I039' ) )
					call RemoveItem( GetItemById( SysUnit, 'I006' ) )
					call CombineItem( SysUnit, 'I00G', 1 )
				else
					call UnitAddItemById( SysUnit, 'I00E' )
				endif
			endif
		endif
		
		if SellingID == 'hbla' then
			call BJDebugMsg("seller hbla")
			if SoldItemID == 'I03M' then
				if HasItem( SysUnit, 'I01B' ) and HasItem( SysUnit, 'I016' ) then
					call RemoveItem( GetItemById( SysUnit, 'I01B' ) )
					call RemoveItem( GetItemById( SysUnit, 'I016' ) )
					call CombineItem( SysUnit, 'I01C', 1 )
				else
					call UnitAddItemById( SysUnit, 'I00J' )
				endif
			endif
			
			if SoldItemID == 'I046' then
				if HasItem( SysUnit, 'I006' ) and HasItem( SysUnit, 'I02A' ) then
					call RemoveItem( GetItemById( SysUnit, 'I006' ) )
					call RemoveItem( GetItemById( SysUnit, 'I02A' ) )
					if IsUnitType( SysUnit, UNIT_TYPE_RANGED_ATTACKER ) then
						call CombineItem( SysUnit, 'I004', 1 )
					else
						call CombineItem( SysUnit, 'I008', 1 )
					endif
				else
					call UnitAddItemById( SysUnit, 'I021' )
				endif
			endif
			
			if SoldItemID == 'I02U' then
				if HasItem( SysUnit, 'I00S' ) and HasItem( SysUnit, 'I01A' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00S' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01A' ) )
					call CombineItem( SysUnit, 'I000', 1 )
				else
					call UnitAddItemById( SysUnit, 'I01Z' )
				endif
			endif

			if SoldItemID == 'I03H' then
				if HasItem( SysUnit, 'I00L' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00L' ) )
					call CombineItem( SysUnit, 'I00M', 1 )
				else
					call UnitAddItemById( SysUnit, 'I01Y' )
				endif
			endif
			
			if SoldItemID == 'I03S' then
				if HasItem( SysUnit, 'I00L' ) and HasItem( SysUnit, 'I016' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00L' ) )
					call RemoveItem( GetItemById( SysUnit, 'I016' ) )
					call CombineItem( SysUnit, 'I02Q', 1 )
				else
					call UnitAddItemById( SysUnit, 'I02V' )
				endif
			endif
			
			if SoldItemID == 'I04B' then
				if HasItem( SysUnit, 'I00T' ) and HasItem( SysUnit, 'I016' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00T' ) )
					call RemoveItem( GetItemById( SysUnit, 'I016' ) )
					call CombineItem( SysUnit, 'I02P', 1 )
				else
					call UnitAddItemById( SysUnit, 'I034' )
				endif
			endif
			
			if SoldItemID == 'I043' then
				if HasItem( SysUnit, 'I00L' ) and HasItem( SysUnit, 'I01N' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00L' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01N' ) )
					call CombineItem( SysUnit, 'I02R', 1 )
				else
					call UnitAddItemById( SysUnit, 'I02T' )
				endif
			endif
			
			if SoldItemID == 'I04F' then
				if HasItem( SysUnit, 'I023' ) and HasItem( SysUnit, 'I00W' ) then
					call RemoveItem( GetItemById( SysUnit, 'I023' ) )
					call RemoveItem( GetItemById( SysUnit, 'I00W' ) )
					call CombineItem( SysUnit, 'I037', 1 )
				else
					call UnitAddItemById( SysUnit, 'I038' )
				endif
			endif
			
			if SoldItemID == 'I049' then
				if HasItem( SysUnit, 'I00S' ) and HasItem( SysUnit, 'I01E' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00S' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01E' ) )
					call CombineItem( SysUnit, 'I00B', 1 )
				else
					call UnitAddItemById( SysUnit, 'I020' )
				endif
			endif

			if SoldItemID == 'I03U' then
				if HasItem( SysUnit, 'I00T' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00T' ) )
					call CombineItem( SysUnit, 'I02J', 1 )
				else
					call UnitAddItemById( SysUnit, 'I02K' )
				endif
			endif
			
			if SoldItemID == 'I03J' then
				if HasItem( SysUnit, 'I00T' ) and HasItem( SysUnit, 'I010' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00T' ) )
					call RemoveItem( GetItemById( SysUnit, 'I010' ) )
					call CombineItem( SysUnit, 'I01J', 1 )
				else
					call UnitAddItemById( SysUnit, 'I022' )
				endif
			endif
		endif
		
		if SellingID == 'harm' then
			call BJDebugMsg("seller harm")
			if SoldItemID == 'I03O' then
				if HasItem( SysUnit, 'I00U' ) and HasItem( SysUnit, 'rat9' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00U' ) )
					call RemoveItem( GetItemById( SysUnit, 'rat9' ) )
					call CombineItem( SysUnit, 'I01B', 1 )
				else
					call UnitAddItemById( SysUnit, 'I024' )
				endif
			endif
			
			if SoldItemID == 'I04T' then
				if HasItem( SysUnit, 'I00U' ) and HasItem( SysUnit, 'I04M' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00U' ) )
					call RemoveItem( GetItemById( SysUnit, 'I04M' ) )
					call CombineItem( SysUnit, 'I04J', 0 )
				else
					call UnitAddItemById( SysUnit, 'I052' )
				endif
			endif
			
			if SoldItemID == 'I03N' then
				if HasItem( SysUnit, 'I00Z' ) and HasItem( SysUnit, 'I016' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00Z' ) )
					call RemoveItem( GetItemById( SysUnit, 'I016' ) )
					call CombineItem( SysUnit, 'I01K', 1 )
				else
					call UnitAddItemById( SysUnit, 'I025' )
				endif
			endif
			
			if SoldItemID == 'I048' then
				if HasItem( SysUnit, 'I00O' ) and HasItem( SysUnit, 'I006' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00O' ) )
					call RemoveItem( GetItemById( SysUnit, 'I006' ) )
					call CombineItem( SysUnit, 'I007', 1 )
				else
					call UnitAddItemById( SysUnit, 'I026' )
				endif
			endif
			
			if SoldItemID == 'I04G' then
				if HasItem( SysUnit, 'I00Z' ) and HasItem( SysUnit, 'I006' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00Z' ) )
					call RemoveItem( GetItemById( SysUnit, 'I006' ) )
					call CombineItem( SysUnit, 'I02S', 1 )
				else
					call UnitAddItemById( SysUnit, 'I036' )
				endif
			endif
			
			if SoldItemID == 'I01M' then
				if HasItem( SysUnit, 'I00V' ) and HasItem( SysUnit, 'I006' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00V' ) )
					call RemoveItem( GetItemById( SysUnit, 'I006' ) )
					call CombineItem( SysUnit, 'I01N', 1 )
				else
					call UnitAddItemById( SysUnit, 'I02G' )
				endif
			endif
		endif
		
		if SellingID == 'hwtw' then
			call BJDebugMsg("seller hwtw")
			if SoldItemID == 'I04D' then
				if HasItem( SysUnit, 'I00Y' ) and HasItem( SysUnit, 'ciri' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00Y' ) )
					call RemoveItem( GetItemById( SysUnit, 'ciri' ) )
					call CombineItem( SysUnit, 'I023', 0 )
				else
					call UnitAddItemById( SysUnit, 'I02H' )
				endif
			endif
			
			if SoldItemID == 'I045' then
				if HasItem( SysUnit, 'modt' ) then
					call RemoveItem( GetItemById( SysUnit, 'modt' ) )
					call CombineItem( SysUnit, 'I01O', 0 )
				else
					call UnitAddItemById( SysUnit, 'I029' )
				endif
			endif
			
			if SoldItemID == 'I047' then
				if HasItem( SysUnit, 'I00X' ) and HasItem( SysUnit, 'bgst' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00X' ) )
					call RemoveItem( GetItemById( SysUnit, 'bgst' ) )
					call CombineItem( SysUnit, 'I01G', 0 )
				else
					call UnitAddItemById( SysUnit, 'I027' )
				endif
			endif
			
			if SoldItemID == 'I03T' then
				if HasItem( SysUnit, 'modt' ) and HasItem( SysUnit, 'I01P' ) then
					call RemoveItem( GetItemById( SysUnit, 'modt' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01P' ) )
					call CombineItem( SysUnit, 'I01X', 0 )
				else
					call UnitAddItemById( SysUnit, 'I035' )
				endif
			endif
			
			if SoldItemID == 'I03K' then
				if HasItem( SysUnit, 'I00Y' ) and HasItem( SysUnit, 'belv' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00Y' ) )
					call RemoveItem( GetItemById( SysUnit, 'belv' ) )
					call CombineItem( SysUnit, 'I01H', 0 )
				else
					call UnitAddItemById( SysUnit, 'I028' )
				endif
			endif
		endif
		
		if SellingID == 'nC16' then
			call BJDebugMsg("seller nC16")
			if SoldItemID == 'I03Q' then
				if HasItem( SysUnit, 'I000' ) and HasItem( SysUnit, 'I015' ) then
					call RemoveItem( GetItemById( SysUnit, 'I000' ) )
					call RemoveItem( GetItemById( SysUnit, 'I015' ) )
					call CombineItem( SysUnit, 'I01U', 2 )
				else
					call UnitAddItemById( SysUnit, 'I02D' )
				endif
			endif
			
			if SoldItemID == 'I04U' then
				if HasItem( SysUnit, 'I000' ) and HasItem( SysUnit, 'I039' ) then
					call RemoveItem( GetItemById( SysUnit, 'I000' ) )
					call RemoveItem( GetItemById( SysUnit, 'I039' ) )
					call CombineItem( SysUnit, 'I04K', 2 )
				else
					call UnitAddItemById( SysUnit, 'I04W' )
				endif
			endif
			
			if SoldItemID == 'I03L' then
				if HasItem( SysUnit, 'I01Q' ) and HasItem( SysUnit, 'I01E' ) then
					call RemoveItem( GetItemById( SysUnit, 'I01Q' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01E' ) )
					call CombineItem( SysUnit, 'I01T', 1 )
				else
					call UnitAddItemById( SysUnit, 'I02C' )
				endif
			endif

			if SoldItemID == 'I03R' then
				if HasItem( SysUnit, 'I01J' ) and HasItem( SysUnit, 'I017' ) then
					call RemoveItem( GetItemById( SysUnit, 'I01J' ) )
					call RemoveItem( GetItemById( SysUnit, 'I017' ) )
					call CombineItem( SysUnit, 'I01V', 2 )
				else
					call UnitAddItemById( SysUnit, 'I02E' )
				endif
			endif
			
			if SoldItemID == 'I044' then
				if HasItem( SysUnit, 'I03F' ) and HasItem( SysUnit, 'I017' ) then
					call RemoveItem( GetItemById( SysUnit, 'I03F' ) )
					call RemoveItem( GetItemById( SysUnit, 'I017' ) )
					call CombineItem( SysUnit, 'I01F', 2 )
				else
					call UnitAddItemById( SysUnit, 'I03E' )
				endif
			endif
		endif
		
		if SellingID == 'n00Y' then
			call BJDebugMsg("seller n00Y")
			if SoldItemID == 'I040' then
				if HasItem( SysUnit, 'I03F' ) and HasItem( SysUnit, 'I00S' ) then
					call RemoveItem( GetItemById( SysUnit, 'I03F' ) )
					call RemoveItem( GetItemById( SysUnit, 'I00S' ) )
					call CombineItem( SysUnit, 'I00K', 2 )
				else
					call UnitAddItemById( SysUnit, 'I01D' )
				endif
			endif
			
			if SoldItemID == 'I03Y' then
				if HasItem( SysUnit, 'I03F' ) and HasItem( SysUnit, 'I01C' ) and HasItem( SysUnit, 'I00M' ) then
					call RemoveItem( GetItemById( SysUnit, 'I03F' ) )
					call RemoveItem( GetItemById( SysUnit, 'I01C' ) )
					call RemoveItem( GetItemById( SysUnit, 'I00M' ) )
					call CombineItem( SysUnit, 'I01S', 3 )
				else
					call UnitAddItemById( SysUnit, 'I02F' )
				endif
			endif
			
			if SoldItemID == 'I03V' then
				if HasItem( SysUnit, 'ofro' ) and HasItem( SysUnit, 'I00A' ) and ( HasItem( SysUnit, 'I008' ) or HasItem( SysUnit, 'I004' ) ) then
					call RemoveItem( GetItemById( SysUnit, 'ofro' ) )
					call RemoveItem( GetItemById( SysUnit, 'I00A' ) )
					call RemoveItem( GetItemById( SysUnit, 'I004' ) )
					call RemoveItem( GetItemById( SysUnit, 'I008' ) )
					call CombineItem( SysUnit, 'I00I', 4 )
				else
					call UnitAddItemById( SysUnit, 'I01W' )
				endif
			endif
			
			if SoldItemID == 'I041' then
				if HasItem( SysUnit, 'I00N' ) and HasItem( SysUnit, 'I00A' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00N' ) )
					call RemoveItem( GetItemById( SysUnit, 'I00A' ) )
					call CombineItem( SysUnit, 'I04C', 3 )
				else
					call UnitAddItemById( SysUnit, 'I04E' )
				endif
			endif
			
			if SoldItemID == 'I03W' then
				if HasItem( SysUnit, 'I00A' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00A' ) )
					call CombineItem( SysUnit, 'I009', 3 )
				else
					call UnitAddItemById( SysUnit, 'I00D' )
				endif
			endif
			
			if SoldItemID == 'I03Z' then
				if HasItem( SysUnit, 'I00A' ) then
					call RemoveItem( GetItemById( SysUnit, 'I00A' ) )
					call CombineItem( SysUnit, 'I00R', 3 )
				else
					call UnitAddItemById( SysUnit, 'I012' )
				endif
			endif
		endif
		
		if SellingID == 'n00Z' then
			call BJDebugMsg("seller hn00Z")
			if SoldItemID == 'I03X' then
				if HasItem( SysUnit, 'I001' ) and HasItem( SysUnit, 'I007' ) then
					call RemoveItem( GetItemById( SysUnit, 'I001' ) )
					call RemoveItem( GetItemById( SysUnit, 'I007' ) )
					call CombineItem( SysUnit, 0, 2 )
					call CombineItem( SysUnit, 'I02M', 3 )
				else
					call UnitAddItemById( SysUnit, 'I02L' )
				endif
			endif
		endif

		set SysUnit = null
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Events\Ability_Learnt.j
	function VastoLord_Checker takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer PID = GetInt( "PID" )

		if UnitLifePercent( GetUnit( "Ichigo" ) ) <= 40 and not LoadBoolean( HashTable, GetHandleId( GetUnit( "Ichigo" ) ), StringHash( "R_Channel" ) ) then
			if Count_Player_Unit( Player( PID ), 'orai' ) == 0 then
				call SetUnitOwner( GetUnit( "Checker" ), Player( PID ), false )
			endif
		else
			call SetUnitOwner( GetUnit( "Checker" ), Player( PLAYER_NEUTRAL_PASSIVE ), false )
		endif
	endfunction

    function Ability_Learnt_Event takes nothing returns nothing
		local integer AID = GetLearnedSkill( )
		local integer PID = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL = GetUnitAbilityLevel( GetLearningUnit( ), AID )
		local integer HandleID
		set SysUnit = GetLearningUnit( )

		if AID == 'A04A' then
			if GetUnitAbilityLevel( SysUnit, 'A04A' ) == 1 then
				set HandleID = PTimer( SysUnit, "VastoLord_Checker" )
				call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Ichigo" ), SysUnit )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Checker" ), CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'orai', 8000, 8000, 270 ) )
				call TimerStart( LoadTimerHandle( HashTable, GetHandleId( SysUnit ), StringHash( "VastoLord_Checker" ) ), .1, true, function VastoLord_Checker )
				set SysUnit = CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'H01F', 3136, -4560, 270 )
				call UnitAddAbility( SysUnit, 'Agho' )
				call PauseUnit( SysUnit, true )
				call SetUnitInvul( SysUnit, true )
				call SaveUnitHandle( HashTable, GetHandleId( GetLearningUnit( ) ), StringHash( "Vasto_Lord" ), SysUnit )
			endif
		endif

		if AID == 'A0CY' then
			if not HasAbility( SysUnit, 'A0CX' ) then
				call UnitAddAbility( SysUnit, 'A0CX' )
			else
				call SetUnitAbilityLevel( SysUnit, 'A0CX', ALvL )
			endif
		endif

		set SysUnit = null
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\Active_Items.j
	function Meteor_Action takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real MoveX
		local real MoveY
		
		if Time == 1 then
			set MoveX = NewX( GetReal( "CastX" ), 325, GetReal( "Angle" ) )
			set MoveY = NewY( GetReal( "CastY" ), 325, GetReal( "Angle" ) )
			set SysUnit = CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h00Q', MoveX, MoveY, GetReal( "Angle" ) )
			call SetUnitTimeScale( SysUnit, .4 )
			call UnitApplyTimedLife( SysUnit, 'BTLF', 2 )
		endif
		
		if Time == 200 then
			set MoveX = NewX( GetReal( "CastX" ), 325, GetReal( "Angle" ) )
			set MoveY = NewY( GetReal( "CastY" ), 325, GetReal( "Angle" ) )
			call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", MoveX, MoveY ) )
			set SysUnit = CreateUnit( GetPlayer( "Player" ), 'h00R', MoveX, MoveY, GetReal( "Angle" ) )
			call UnitApplyTimedLife( SysUnit, 'BTLF', 10 )
			call IssuePointOrder( SysUnit, "move", NewX( GetReal( "CastX" ), 1900, GetReal( "Angle" ) ), NewY( GetReal( "CastY" ), 1900, GetReal( "Angle" ) ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "MeteorDummy" ), SysUnit )
		endif
		
		if Time >= 200 and Time <= 450 then
			if Counter( 0, 25 ) then
				call SaveInteger( HashTable, HandleID, StringHash( "MeteorLife" ), GetInt( "MeteorLife" ) + 1 )
				set MoveX = GetUnitX( GetUnit( "MeteorDummy" ) )
				set MoveY = GetUnitY( GetUnit( "MeteorDummy" ) )
				call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", MoveX, MoveY ) )
				call MUIAoEDMG( GetUnit( "Caster" ), MoveX, MoveY, 400, GetHeroInt( GetUnit( "Caster" ), true ) * 2, "magical" )
				call DestroyAoEDestruct( MoveX, MoveY, 400 )
			endif
		endif
		
		if Time == 425 then
			call KillUnit( GetUnit( "MeteorDummy" ) )
		endif
		
		if Time == 450 then
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function ResetThornMail takes nothing returns nothing
		call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "ReturnDamageBool" ), false )
		call DestroyEffect( GetEffect( "ThornEffect" ) )
		call FlushChildHashtable( HashTable, GetHandleId( GetExpiredTimer( ) ) )
	endfunction

	function EyeStatConsumption takes nothing returns nothing
		local integer Time = SpellTime( )

		if Time == 1 then
			call SaveInteger( HashTable, MUIHandle( ), StringHash( "STR" ), R2I( .9 * GetHeroStr( GetUnit( "Caster" ), false ) ) )
			call SaveInteger( HashTable, MUIHandle( ), StringHash( "AGI" ), R2I( .9 * GetHeroAgi( GetUnit( "Caster" ), false ) ) )
			call SetHeroStr( GetUnit( "Caster" ), GetHeroStr( GetUnit( "Caster" ), false ) - GetInt( "STR" ), true )
			call SetHeroAgi( GetUnit( "Caster" ), GetHeroAgi( GetUnit( "Caster" ), false ) - GetInt( "AGI" ), true )
			call SetHeroInt( GetUnit( "Caster" ), GetHeroInt( GetUnit( "Caster" ), false ) + ( GetInt( "STR" ) + GetInt( "AGI" ) ), true )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\DeathPact\\DeathPactTarget.mdl", GetUnit( "Caster" ), "origin" ) )
			call SaveEffectHandle( HashTable, MUIHandle( ), StringHash( "EyeEffect" ), AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\UnholyAura\\UnholyAura.mdl", GetUnit( "Caster" ), "origin" ) )
		endif

		if Time >= 1500 then
			call SetHeroStr( GetUnit( "Caster" ), GetHeroStr( GetUnit( "Caster" ), false ) + GetInt( "STR" ), true )
			call SetHeroAgi( GetUnit( "Caster" ), GetHeroAgi( GetUnit( "Caster" ), false ) + GetInt( "AGI" ), true )
			call SetHeroInt( GetUnit( "Caster" ), GetHeroInt( GetUnit( "Caster" ), false ) - ( GetInt( "STR" ) + GetInt( "AGI" ) ), true )
			call DestroyEffect( LoadEffectHandle( HashTable, MUIHandle( ), StringHash( "EyeEffect" ) ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function ItemCooldownEnd takes nothing returns nothing
		call SetItemDroppable( GetItem( "SavedItem" ), true )
		call CleanMUI( GetExpiredTimer( ) )
	endfunction

    function Item_Use_Event takes nothing returns nothing
		local integer Time = 1
		local integer ItemID
		local integer PID = GetPlayerId( GetTriggerPlayer( ) )
		local integer HandleID
		local real Facing = GetUnitFacing( GetTriggerUnit( ) )
		set SysItem = GetManipulatedItem( )
		set ItemID = GetItemTypeId( SysItem )

		if ItemID == 'I04K' then
			set HandleID = NewMUITimer( PID )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function EyeStatConsumption )
		endif

		if ItemID == 'I00G' then
			call EnumUnits_Rect( SpellGroup, GetWorldBounds( ) )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if DefaultUnitFilter( SysUnit ) and IsUnitEnemy( SysUnit, Player( PID ) ) and IsUnitType( SysUnit, UNIT_TYPE_HERO ) then
					if not IsUnitInArea( SysUnit, "base_1" ) and not IsUnitInArea( SysUnit, "base_2" ) then
						call CC_Cast( SysUnit, "hex", "Target" )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if ItemID == 'I02S' then
			set HandleID = NewMUITimer( PID )
			call SavePlayerHandle( HashTable, HandleID, StringHash( "Player" ), GetTriggerPlayer( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), Facing )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Meteor_Action )
		endif

		if ItemID == 'I04J' then
			set HandleID = PTimer( GetTriggerUnit( ), "ThornTimer" )
			call Init_DamagedCheck( GetTriggerUnit( ) )
			call SaveBoolean( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "ReturnDamageBool" ), true )
			call DestroyEffect( LoadEffectHandle( HashTable, HandleID, StringHash( "ThornEffect" ) ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "ThornEffect" ), AddSpecialEffectTarget( "Abilities\\Spells\\Orc\\SpikeBarrier\\SpikeBarrier.mdl", GetTriggerUnit( ), "origin" ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadTimerHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "ThornTimer" ) ), 5, false, function ResetThornMail )
		endif

		if ItemID == 'I00G' or ItemID == 'I02S' or ItemID == 'I037' or ItemID == 'I00W' or ItemID == 'I01K' or ItemID == 'I02J' or ItemID == 'I01O' or ItemID == 'desc' or ItemID == 'I04J' or ItemID == 'I04K' or ItemID == 'I04P' then
			set HandleID = NewMUITimer( PID )
			call SetItemDroppable( SysItem, false )
			call SaveItemHandle( HashTable, HandleID, StringHash( "SavedItem" ), SysItem )

			if ItemID == 'I00G' then // Mythology Staff
				set Time = 70
			endif
			
			if ItemID == 'I02S' then // Orb of Fire
				set Time = 35
			endif
			
			if ItemID == 'I037' then // Horn of Mana
				set Time = 45
			endif
			
			if ItemID == 'I00W' then // Horn of Mana
				set Time = 45
			endif

			if ItemID == 'I01K' then // Soul Devourer Stones
				set Time = 60
			endif
			
			if ItemID == 'I02J' then // Windrunner
				set Time = 20
			endif
			
			if ItemID == 'I01O' then // Mask of Vizard
				set Time = 30
			endif
			
			if ItemID == 'desc' then // Kuma's Book
				set Time = 12
			endif
			
			if ItemID == 'I04J' then // Bladebane Armour
				set Time = 30
			endif
			
			if ItemID == 'I04K' then // Sacrificial Wand
				set Time = 75
			endif
			
			if ItemID == 'I04P' then // Sacrificial Wand
				set Time = 100
			endif

			call TimerStart( LoadMUITimer( PID ), Time, false, function ItemCooldownEnd )
		endif

		set SysItem = null
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Events\Unit_Damaged.j
	function Unit_Damaged_Handler takes unit Source, unit Target, real DMG returns nothing
		local integer S_PID  = GetPlayerId( GetOwningPlayer( Source ) )
		local integer PID    = GetPlayerId( GetOwningPlayer( Target ) )
		local integer S_UID  = GetUnitTypeId( Source )
		local integer T_UID  = GetUnitTypeId( Target )
		local real T_Life    = GetUnitState( Target, UNIT_STATE_LIFE )
		local integer Chance = GetRandomInt( 0, 100 )

		if IsUnitEnemy_v2( Source, Target ) then
			if HasAbility( Source, 'B01U' ) then
				call Damage_Unit( Source, Target, ( 1 + .3 * GetUnitAbilityLevel( Source, 'A02X' ) ) * GetHeroInt( Source, true ), "physical" )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\ManaFlare\\ManaFlareBoltImpact.mdl", Target, "chest" ) )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\StormBolt\\StormBoltMissile.mdl", Target, "chest" ) )
			endif

			if HasAbility( Target, 'A00K' ) then // UID == 'N002' or UID == 'N00C'
				call SetWidgetLife( Target, T_Life + .15 * DMG )
			endif

			if HasAbility( Target, 'B018' ) then
				if DMG < 30000. and S_UID != 'u995' then
					call SetWidgetLife( Target, T_Life + DMG )
					call SaveReal( HashTable, GetHandleId( Target ), StringHash( "Usopp_V_Damage" ), LoadReal( HashTable, GetHandleId( Target ), StringHash( "Usopp_V_Damage" ) ) + DMG )
					call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\PriestMissile\\PriestMissile.mdl", Target, "origin" ) )
				endif
			endif

			if DMG < 800. then
				if T_UID == 'UC13' and HasAbility( Target, 'A04V' ) and HasAbility( Target, 'B029' ) then
					if GetRandomInt( 1, 100 ) <= 20 then
						call SetWidgetLife( Target, T_Life + DMG )
						call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\VoidWalkerMissile\\VoidWalkerMissile.mdl", Target, "origin" ) )
					endif
				endif
			endif

			if DMG < 5000. then
				if HasAbility( Target, 'A0CY' ) then
					if not IsUnitType( Source, UNIT_TYPE_ANCIENT ) and IsUnitType( Source, UNIT_TYPE_MELEE_ATTACKER ) then
						call Damage_Unit( Target, Source, .15 * DMG, "passive" )
					endif
				endif

				if LoadBoolean( HashTable, GetHandleId( Target ), StringHash( "ReturnDamageBool" ) ) and HasItem( Target, 'I04J' ) then
					if S_PID <= 11 then
						call Damage_Unit( Target, PlayerUnit[ S_PID ], DMG * .75, "magical" )
					else
						call Damage_Unit( Target, Source, DMG * .75, "magical" )
					endif
				endif
			endif
			
			if Chance <= 12 then
				if HasAbility( Source, 'A045' ) then
					call SetUnitAnimation( Source, "attack slam" )
					call Damage_Unit( Source, Target, 150, "physical" )
					call CC_Unit( Target, 1, "stun", true )
				endif
			endif

			if DMG < LoadReal( HashTable, GetHandleId( Target ), StringHash( "Inoue_Damage_Blocked" ) ) then
				call SetWidgetLife( Target, T_Life + DMG )
			endif
		endif
	endfunction

    function Unit_Damaged_Function takes nothing returns nothing
		call DisableTrigger( LoadTrig( "Event_Damaged" ) )
		call Unit_Damaged_Handler( GetEventDamageSource( ), GetTriggerUnit( ), GetEventDamage( ) )
		call EnableTrigger( LoadTrig( "Event_Damaged" ) )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Events\Unit_Attacked.j
	function Mamaragan_Handler takes unit Target returns nothing
		local integer i      = 0
		local integer PID    = GetOwningId( Target )
		local integer Chance = 0
		local integer Random = GetRandomInt( 0, 100 )
		local real TargX     = GetUnitX( Target )
		local real TargY     = GetUnitY( Target )

		loop
			exitwhen i == 12
			if IsPlayerEnemy( Player( i ), Player( PID ) ) then
				set Chance = LoadInteger( HashTable, GetHandleId( Player( i ) ), StringHash( "Mamaragan_AP_Chance" ) )
				if Chance > 0 and Random <= Chance then
					call DestroyAoEDestruct( TargX, TargY, 250 )
					call Damage_Unit( PlayerUnit[ i ], Target, 2.5 * GetHeroInt( PlayerUnit[ i ], true ), "magical" )
					call DestroyEffect( AddSpecialEffect( "war3mapImported\\LightningWrath.mdx", TargX, TargY ) )
					call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", TargX, TargY ) )
				endif
			endif
			set i = i + 1
		endloop
	endfunction

	function Ginrei_Launch takes nothing returns nothing
		local integer i = 1
		local real ManaBurn = 70
		local real FromX
		local real FromY
		local real MoveX
		local real MoveY
		local real Angle = GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) )
		local real Random = 0
		local real DMG = 1.75 * GetHeroAgi( GetUnit( "Caster" ), false )
		local integer PID = GetPlayerId( GetOwningPlayer( GetUnit( "Caster" ) ) )

		if GetUnitTypeId( GetUnit( "Caster" ) ) != 'EC08' then
			set ManaBurn = 140
			set DMG = 2.1 * GetHeroAgi( GetUnit( "Caster" ), false )
		endif

		call SaveInteger( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "GinreiCount" ), LoadInteger( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "GinreiCount" ) ) + 1 )
		if GetUnitState( GetUnit( "Caster" ), UNIT_STATE_MANA ) >= ManaBurn then
			call SetUnitManaBJ( GetUnit( "Caster" ), GetUnitState( GetUnit( "Caster" ), UNIT_STATE_MANA ) - ManaBurn )
			loop
				exitwhen i > 6
				set Random = GetRandomReal( -15, 15 )
				set MoveX = NewX( GetUnitX( GetUnit( "Caster" ) ), 1000, Angle + Random )
				set MoveY = NewY( GetUnitY( GetUnit( "Caster" ) ), 1000, Angle + Random )
				set FromX = NewX( GetUnitX( GetUnit( "Caster" ) ),  100, Angle )
				set FromY = NewY( GetUnitY( GetUnit( "Caster" ) ),  100, Angle )
				call PointCast_XY( FromX, FromY, MoveX, MoveY, 'A04Z', 1, "clusterrockets" )
				call PointCast_XY( FromX, FromY, MoveX, MoveY, 'A04Z', 1, "clusterrockets" )
				call MUIAoEDMG( GetUnit( "Caster" ), NewX( GetUnitX( GetUnit( "Caster" ) ), 150 * i, Angle ), NewY( GetUnitY( GetUnit( "Caster" ) ), 150 * i, Angle ), 300, DMG, "magical" )
				set i = i + 1
			endloop
		endif
		if LoadInteger( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "GinreiCount" ) ) == 6 then
			call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "GinreiActive" ), false )
			call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "GinreiEff" ) ) )
		endif

		call CleanMUI( GetExpiredTimer( ) )
	endfunction

	function RukiaAttacked takes unit Source, unit Target returns nothing
		call SaveInteger( HashTable, GetHandleId( Source ), StringHash( "RukiaTCount" ), LoadInteger( HashTable, GetHandleId( Source ), StringHash( "RukiaTCount" ) ) + 1 )
		call TargetCast( Source, Target, 'A065', GetUnitAbilityLevel( Source, 'A06C' ), "frostnova" )
		call Damage_Unit( Source, Target, ( 3.75 + .25 * GetUnitAbilityLevel( Source, 'A06C' ) ) * GetHeroAgi( Source, true ), "magical" )
		if LoadInteger( HashTable, GetHandleId( Source ), StringHash( "RukiaTCount" ) ) == 10 then
			call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( Target ), StringHash( "WhiteDance" ) ) )
			call RemoveSavedHandle( HashTable, GetHandleId( Target ), StringHash( "WhiteDance" ) )
		endif
	endfunction

	function Ikkaku_Spin takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real AoE
		local real DMG

		if Time == 1 then
			if GetRandomInt( 1, 100 ) <= 6 + 3 * GetUnitAbilityLevel( GetUnit( "Caster" ), 'A03Z' ) then
				call SetUnitAnimation( GetUnit( "Caster" ), "spin" )
				if GetUnitTypeId( GetUnit( "Caster" ) ) != 'U00S' then
					set DMG = 175. + 3. * GetHeroStr( GetUnit( "Caster" ), true )
					set AoE = 410.
				else
					set DMG = 175. + 2. * GetHeroStr( GetUnit( "Caster" ), true )
					set AoE = 320.
				endif

				call DestroyAoEDestruct( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), AoE )
				call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), AoE )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "physical" )
						call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", SysUnit, "origin" ) )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
				call SaveInteger( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Spin_CD" ), 25 )
			endif
		endif

		if Time == 25 then
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
			call SaveInteger( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Spin_CD" ), 0 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Yoruichi_Riposte takes nothing returns nothing
		local integer Time 	   = SpellTime( )
		local integer HandleID = MUIHandle( )
		local string Eff
		local real Speed

		if Time == 1 then
			if GetReal( "Distance" ) > 600 then
				call SaveReal( HashTable, HandleID, StringHash( "Speed" ), 100 )
				call SaveStr(  HashTable, HandleID, StringHash( "Eff_1" ), "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl" )
				set SysUnit = CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h000', GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 270 )
				call ScaleUnit( SysUnit, 3 )
				call UnitApplyTimedLife( SysUnit, 'BTLF', 5 )
			else
				call SaveReal( HashTable, HandleID, StringHash( "Speed" ), 80 )
				call SaveStr(  HashTable, HandleID, StringHash( "Eff_1" ), "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl" )
			endif
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitFacing( GetUnit( "Caster" ), GetReal( "Angle" ) )
			call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
			call SetUnitXY_1( GetUnit( "Caster" ), NewX( GetUnitX( GetUnit( "Target" ) ), -80, GetReal( "Angle" ) ), NewY( GetUnitY( GetUnit( "Target" ) ), -80, GetReal( "Angle" ) ), true )
		endif

		if GetReal( "Travelled" ) < GetReal( "Distance" ) then
			if Counter( 0, 3 ) then
				call DestroyEffect( AddSpecialEffect( GetStr( "Eff_1" ), GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
				call DestroyAoEDestruct( GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 300 )
				call SetUnitXY_1( GetUnit( "Caster" ), NewX( GetUnitX( GetUnit( "Caster" ) ), GetReal( "Speed" ), GetReal( "Angle" ) ), NewY( GetUnitY( GetUnit( "Caster" ) ), GetReal( "Speed" ), GetReal( "Angle" ) ), true )
				call SetUnitXY_1( GetUnit( "Target" ), NewX( GetUnitX( GetUnit( "Target" ) ), GetReal( "Speed" ), GetReal( "Angle" ) ), NewY( GetUnitY( GetUnit( "Target" ) ), GetReal( "Speed" ), GetReal( "Angle" ) ), true )
				call SaveReal( HashTable, HandleID, StringHash( "Travelled" ), GetReal( "Travelled" ) + GetReal( "Speed" ) )
			endif
		else
            if GetReal( "Distance" ) > 600 then
				set SysUnit = CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h000', GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 270 )
				call ScaleUnit( SysUnit, 3 )
				call UnitApplyTimedLife( SysUnit, 'BTLF', 5 )
				call CC_Unit( GetUnit( "Target" ), 1.4, "stun", true )
			else
				call SaveStr(  HashTable, HandleID, StringHash( "Eff_1" ), "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl" )
				call CC_Unit( GetUnit( "Target" ), .85, "stun", true )
			endif
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), GetReal( "DMG" ), "magical" )
			call DestroyEffect( AddSpecialEffect( GetStr( "Eff_1" ), GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			call PauseUnit( GetUnit( "Caster" ), false )
			call PauseUnit( GetUnit( "Target" ), false )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function ResetBlinkAttackCD takes nothing returns nothing
		call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "HasAttacked" ), false )
		call CleanMUI( GetExpiredTimer( ) )
	endfunction
	
    function Blink_Strike takes unit Source, unit Target returns nothing
		local integer PID = GetPlayerId( GetTriggerPlayer( ) )
		local integer HandleID
		local real Angle
		local string Effect = ""
		if not LoadBoolean( HashTable, GetHandleId( Source ), StringHash( "HasAttacked" ) ) then
			if GetUnitAbilityLevel( Source, 'A03J' ) >= 3 then
				set Effect = "!Shunpo!.mdx"
		elseif GetUnitAbilityLevel( Source, 'A05V' ) >= 3 then
				set Effect = "!Sonido!.mdx"
			endif
			set HandleID = NewMUITimer( PID )
			set Angle = GetRandomReal( 0, 360 )
			call SetUnitXY_1( Source, NewX( GetUnitX( Target ), 100, Angle ), NewY( GetUnitY( Target ), 100, Angle ), true )
			call SetUnitFacing( Source, GetUnitsAngle( Source, Target ) )
			if UnitLife( Source ) > 0 then
				call IssueTargetOrder( Source, "attack", Target )
				call SetUnitAnimation( Source, "attack" )
			endif
			call DestroyEffect( AddSpecialEffect( Effect, GetUnitX( Source ), GetUnitY( Source ) ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), Source )
			call SaveBoolean( HashTable, GetHandleId( Source ), StringHash( "HasAttacked" ), true )
			call TimerStart( LoadMUITimer( PID ), .3, false, function ResetBlinkAttackCD )
		endif
    endfunction

	function Attack_Handler takes unit Source, unit Target returns nothing
		local integer i = 0
		local integer int_1 = 0
		local integer HandleID
		local integer S_PID = GetOwningId( Source )
		local integer T_PID = GetOwningId( Target )
		local integer S_UID = GetUnitTypeId( Source )
		local integer T_UID = GetUnitTypeId( Target )
		local boolean IsSuzumushi = false
		local real ManaGain = 25
		local integer Random = GetRandomInt( 1, 100 )

		if not IsUnitHidden( Source ) then
			if LoadBoolean( HashTable, GetHandleId( Source ), StringHash( "AttackDisabled" ) ) or not IsUnitEnemy_v2( Source, Target ) then
				call IssueImmediateOrder( Source, "stop" )
				return
			endif

			if DefaultFilter( Target ) then
				if HasAbility( Target, 'A03Z' ) then
					if LoadInteger( HashTable, GetHandleId( Target ), StringHash( "Spin_CD" ) ) <= 0 then
						set HandleID = NewMUITimer( GetPlayerId( GetOwningPlayer( Target ) ) )
						call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), Target )
						call TimerStart( LoadMUITimer( GetPlayerId( GetOwningPlayer( Target ) ) ), .01, true, function Ikkaku_Spin )
					endif
				endif

				if HasAbility( Target, 'A03E' ) then // Has Flame Skin
					if IsUnitType( Source, UNIT_TYPE_MELEE_ATTACKER ) then
						call Damage_Unit( Target, Source, .05 * UnitLife( Source ), "magical" )
						call DestroyEffect( AddSpecialEffectTarget( "Environment\\SmallBuildingFire\\SmallBuildingFire2.mdl", Source, "chest" ) )
					endif
				endif

				if HasAbility( Target, 'B00N' ) then // Has Tekkai Buff
					if Random <= 20 then
						call Damage_Unit( Target, Source, GetRandomReal( 150, 800 ), "physical" )
						call CC_Cast( Source, "slow", "Target" ) // 3 seconds, true for CC_Unit
						call LinearDisplacement( Source, GetUnitsAngle( Target, Source ), 100, .15, .01, false, false, "origin", "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl" )
					endif
				endif

				if IsUnitType( Source, UNIT_TYPE_HERO ) then
					if IsUnitType( Target, UNIT_TYPE_HERO ) then
						call Mamaragan_Handler( Source )
					endif

					if HasAbility( Source, 'B006' ) then // Usopp W Aura
						if Random <= 7 then
							if GetUnitAbilityLevel( Source, 'A035' ) < 5 then
								call TargetCast( Source, Source, 'A036', 1, "unholyfrenzy" )
							else
								call TargetCast( Source, Source, 'A036', 2, "unholyfrenzy" )
							endif
						endif
					endif

					if HasAbility( Source, 'B010' ) then // Mihawk Q Buff
						set int_1 = LoadInteger( HashTable, GetHandleId( Source ), StringHash( "Q_Hits" ) ) + 1
						call SaveInteger( HashTable, GetHandleId( Source ), StringHash( "Q_Hits" ), int_1 )
						call Damage_Unit( Source, Target, LoadReal( HashTable, GetHandleId( Source ), StringHash( "Q_Damage" ) ), "physical" )

						if not HasAbility( LoadUnitHandle( HashTable, GetHandleId( Player( S_PID ) ), StringHash( "Damage_Dummy" ) ), 'A08H' ) then
							call UnitAddAbility( LoadUnitHandle( HashTable, GetHandleId( Player( S_PID ) ), StringHash( "Damage_Dummy" ) ), 'A08H' )
						endif

						if Random <= 6 + 4 * GetUnitAbilityLevel( Source, 'A08A' ) then
							call IssueTargetOrder( LoadUnitHandle( HashTable, GetHandleId( Player( S_PID ) ), StringHash( "Damage_Dummy" ) ), "slow", Target )
						endif

						if int_1 == 3 then
							call UnitRemoveAbility( Source, 'B010' )
						endif
					endif

					if S_UID == 'N00R' then // Ice Saber
						if Random <= 20 then
							call TargetCast( Source, Target, 'A0A5', GetUnitAbilityLevel( Source, 'A09C' ), "frostnova" )
						endif
					endif

					if T_UID == 'n011' then
						call IssueImmediateOrder( Target, "stomp" )
						return
					endif

					if T_UID == 'NC03' then
						call Aiezen_AI( Source, Target )
					endif

					if GetPlayerController( GetOwningPlayer( Target ) ) == MAP_CONTROL_COMPUTER then
						call AI_Attack_Handler( Source, Target )
					endif

					if HasItem( Source, 'I023' ) then
						call SetUnitState( Target, UNIT_STATE_MANA, GetUnitState( Target, UNIT_STATE_MANA ) - 35 )
					endif
					
					if HasItem( Source, 'I037' ) then
						if GetRandomInt( 1, 100 ) <= 6 then
							if GetUnitState( Target, UNIT_STATE_MANA ) > 0 then
								call Damage_Unit( Source, Target, ( .85 * ( GetUnitState( Target, UNIT_STATE_MAX_MANA ) - GetUnitState( Target, UNIT_STATE_MANA ) ) ), "magical" )

								loop
									exitwhen i == 10
									call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\DragonHawkMissile\\DragonHawkMissile.mdl", GetTriggerUnit( ), "origin" ) )
									set i = i + 1
								endloop
							endif
						endif
						call SetUnitState( Target, UNIT_STATE_MANA, GetUnitState( Target, UNIT_STATE_MANA ) - 100 )
					endif
					
					if not IsUnitInArea( Source, "rapire" ) then
						if HasItem( Source, 'rwiz' ) then
							set ManaGain = ManaGain + 2
						endif
						if HasItem( Source, 'I00Q' ) then
							set ManaGain = ManaGain + 5
						endif
						if HasItem( Source, 'I00O' ) then
							set ManaGain = ManaGain + 6
						endif
						if HasItem( Source, 'I00N' ) then
							set ManaGain = ManaGain + 9
						endif
						if HasItem( Source, 'I007' ) then
							set ManaGain = ManaGain + 9
						endif
						if HasItem( Source, 'I02A' ) then
							set ManaGain = ManaGain + 2
						endif
						if HasItem( Source, 'I04C' ) then
							set ManaGain = ManaGain + 18
						endif
						if HasItem( Source, 'I02M' ) then
							set ManaGain = ManaGain + 999
						endif
						call SetUnitManaBJ( Source, GetUnitState( Source, UNIT_STATE_MANA ) + ManaGain )
					endif
					
					if HasAbility( Target, 'BUsl' ) then
						loop
							exitwhen i > 11
							if IsUnitInGroup( Target, LoadGroupHandle( HashTable, GetHandleId( Player( i ) ), StringHash( "Suzumushi_Group" ) ) ) then
								set IsSuzumushi = true
								exitwhen true
							endif
							set i = i + 1
						endloop

						if IsSuzumushi then
							call GroupRemoveUnit( LoadGroupHandle( HashTable, GetHandleId( Player( i ) ), StringHash( "Suzumushi_Group" ) ), Target )
							call Damage_Unit( Source, Target, 500, "magical" )
							call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", Target, "chest" ) )
						endif
					endif

					if LoadBoolean( HashTable, GetHandleId( Target ), StringHash( "Yoruichi_Riposte" ) ) then
						if GetUnitsDistance( Source, Target ) <= LoadReal( HashTable, GetHandleId( Target ), StringHash( "Yoruichi_Riposte_A_Distance" ) ) then
							set HandleID = NewMUITimer( GetPlayerId( GetOwningPlayer( Target ) ) )
							call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), Target )
							call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), Source )
							call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitsAngle( Target, Source ) )
							call SaveReal( HashTable, HandleID, StringHash( "Distance" ), LoadReal( HashTable, GetHandleId( Target ), StringHash( "Yoruichi_Riposte_T_Distance" ) ) )
							call SaveReal( HashTable, HandleID, StringHash( "DMG" ), LoadReal( HashTable, GetHandleId( Target ), StringHash( "Yoruichi_Riposte_DMG" ) ) )
							call TimerStart( LoadMUITimer( GetPlayerId( GetOwningPlayer( Target ) ) ), .01, true, function Yoruichi_Riposte )
						endif
					endif

					if HasAbility( Source, 'B01B' ) then
						if GetUnitAbilityLevel( Source, 'A03J' ) >= 3 or GetUnitAbilityLevel( Source, 'A05V' ) >= 3 then
							call Blink_Strike( Source, Target )
						endif
					endif

					if IsUnitIllusion( Source ) and Target == Ring_Boss then
						call SetWidgetLife( Source, GetUnitState( Source, UNIT_STATE_LIFE ) - .1 * GetUnitState( Source, UNIT_STATE_MAX_LIFE ) )
						call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", Source, "origin" ) )
					endif
					
					if GetRandomInt( 1, 100 ) <= 40 then
						if HasItem( Source, 'I00I' ) or HasItem( Source, 'ofro' ) then
							call TargetCast( Source, Target, 'A02H', 13, "frostnova" )
						endif
					endif

					if HasItem( Source, 'I009' ) and not HasAbility( Source, 'B004' ) then
						if GetUnitState( Source, UNIT_STATE_LIFE ) > .09 * GetUnitState( Source, UNIT_STATE_MAX_LIFE ) then
							call SetWidgetLife( Source, GetUnitState( GetAttacker( ), UNIT_STATE_LIFE ) - .09 * GetUnitState( Source, UNIT_STATE_MAX_LIFE ) )
						else
							call SetWidgetLife( Source, 1. )
						endif
					endif

					if HasAbility( Source, 'B00L' ) and LoadEffectHandle( HashTable, GetHandleId( Target ), StringHash( "WhiteDance" ) ) != null then
						call RukiaAttacked( Source, Target )
					endif

					if LoadBoolean( HashTable, GetHandleId( Source ), StringHash( "GinreiActive" ) ) then
						set HandleID = NewMUITimer( GetPlayerId( GetOwningPlayer( Source ) ) )
						call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), Source )
						call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), Target )
						call TimerStart( LoadMUITimer( GetPlayerId( GetOwningPlayer( Source ) ) ), 0, false, function Ginrei_Launch )
					endif

					if HasAbility( Source, 'B01X' ) and S_UID == 'U004' then
						call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", Source, "origin" ) )
						call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Human\\HumanBlood\\BloodElfSpellThiefBlood.mdl", Target, "origin" ) )
					endif
				endif
			endif
		endif
	endfunction

    function Unit_Attack_Event takes nothing returns nothing
		call Attack_Handler( GetAttacker( ), GetTriggerUnit( ) )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\Hero_Pick.j
	function RegisterHero takes string Name, integer UID, string Stat, integer AID_1, integer AID_2, integer AID_3, integer AID_4, integer AID_5 returns nothing
		local integer ID = LoadInt( "Total_Heroes" ) + 1
		call SaveInt( "Hero_UID_" + I2S( ID ), UID )
		call SaveString( "Hero_Name_" + I2S( ID ), Name )
		call SaveString( "Hero_Main_Stat_" + I2S( ID ), Stat )
		call SaveString( "Hero_Model_" + I2S( ID ), "Heroes\\" + Name + ".mdx" )
		call SaveString( "Hero_Icon_Model_" + I2S( ID ), "Icons\\" + Name + "_Icon.mdx" )
		call SaveString( "Hero_Icon_" + I2S( ID ), "ReplaceableTextures\\CommandButtons\\BTN" + Name + ".blp" )
		call SaveInt( "Hero_Ability_" + I2S( ID ) + "_1", AID_1 )
		call SaveInt( "Hero_Ability_" + I2S( ID ) + "_2", AID_2 )
		call SaveInt( "Hero_Ability_" + I2S( ID ) + "_3", AID_3 )
		call SaveInt( "Hero_Ability_" + I2S( ID ) + "_4", AID_4 )
		call SaveInt( "Hero_Ability_" + I2S( ID ) + "_5", AID_5 )
		call SaveInt( "Total_Heroes", ID )
	endfunction

	function Init_HeroPick takes nothing returns nothing
		local integer i = 1
		local integer iterator = 0
		local real SysIconX =  4032 - 700
		local real SysIconY = -6016 + 400

		//-----------------------------------------------BLEACH------------------------------------------------|
		call RegisterHero( "Ichigo", 	'H003', "STR", 'A008', 'A0AQ', 'A03J', 'A00C', 'A04A' ) // 'H00E' form |  1
		call RegisterHero( "Zangetsu",  'H00I', "STR", 'A05T', 'A05U', 'A05V', 'A05X', 'A060' ) // 'H00J' form |  2
		call RegisterHero( "Rukia", 	'O001', "AGI", 'A04D', 'A0AN', 'A062', 'A064', 'A06C' ) //             |  3
		call RegisterHero( "Chad", 		'H004', "STR", 'A03R', 'A03S', 'A03T', 'A08J', 'A043' ) // 'H00U' form |  4
		call RegisterHero( "Inoue", 	'E004', "INT", 'A07K', 'A063', 'A0AP', 'A07Q', 'A07N' ) //             |  5
		call RegisterHero( "Ishida", 	'EC08', "AGI", 'A0AV', 'A0D7', 'A04W', 'A04X', 'A0AT' ) //             |  6
		call RegisterHero( "Renji", 	'H01Q', "STR", 'A013', 'A014', 'A0BN', 'A0BP', 'A0BQ' ) //             |  7
		call RegisterHero( "Byakuya", 	'UC13', "AGI", 'A01M', 'A0AM', 'A04V', 'A01R', 'A0AL' ) //             |  8
		call RegisterHero( "Toshiro", 	'EC12', "AGI", 'A01F', 'A06F', 'A01H', 'A01J', 'A004' ) // 'E003' form |  9
		call RegisterHero( "Zaraki", 	'U004', "STR", 'A006', 'A081', 'A003', 'A01P', 'A00I' ) //             | 10
		call RegisterHero( "Genryusai", 'UC11', "STR", 'A038', 'A0AY', 'A04J', 'A04E', 'A098' ) //             | 11
		call RegisterHero( "Yoruichi", 	'OC10', "AGI", 'A00Y', 'A07W', 'A02D', 'A02C', 'A01C' ) // 'O000' form | 12
		call RegisterHero( "SoiFon", 	'O002', "AGI", 'A08U', 'A010', 'A095', 'A08V', 'A096' ) // 'O003' form | 13
		call RegisterHero( "Ikkaku", 	'U00S', "STR", 'A091', 'A03Z', 'A08Y', 'A093', 'A094' ) // 'U00T' form | 14
		call RegisterHero( "Kaname", 	'U00A', "AGI", 'A0C1', 'A0C2', 'A03D', 'A0C3', 'A03K' ) //             | 15

		//----------------------------------------------ONE PIECE----------------------------------------------|
		call RegisterHero( "Crocodile", 'N00U', "STR", 'A05P', 'A07F', 'A0C4', 'A0C9', 'A0BV' ) //			   | 16
		call RegisterHero( "Kuma",   	'N00X', "INT", 'A0BW', 'A0CY', 'A0BX', 'A0BY', 'A07M' ) //             | 17
		//call RegisterHero( "Brook",  	'N00T', "AGI", 'A0AA', 'A0AF', 'A0A9', 'A0AD', 'A0AE' ) //             | 18
		//call RegisterHero( "Moria",  	'N00S', "INT", 'A09N', 'A0AG', 'A09Y', 'A09X', 'A09Z' ) //             | 19
		call RegisterHero( "Aokiji", 	'N009', "STR", 'A09K', 'A09C', 'A09M', 'A01S', 'A09H' ) // 'N00R' form | 20
		call RegisterHero( "Lucci",  	'N006', "AGI", 'A06M', 'A079', 'A07D', 'A04U', 'A052' ) //             | 21
		call RegisterHero( "Zoro",   	'N003', "STR", 'A00T', 'A050', 'A00W', 'A00X', 'A00Z' ) //             | 22
		call RegisterHero( "Luffy",  	'N002', "AGI", 'A00H', 'A00M', 'A0BL', 'A00O', 'A00Q' ) // 'N00C' form | 23
		call RegisterHero( "Usopp",  	'N007', "AGI", 'A048', 'A035', 'A03P', 'A04C', 'A04B' ) //             | 24
		call RegisterHero( "Sanji",  	'N004', "AGI", 'A00J', 'A02K', 'A02M', 'A02P', 'A02Q' ) // 'N000' form | 25
		call RegisterHero( "Ace", 	 	'N005', "AGI", 'A031', 'A08F', 'A034', 'A033', 'A03A' ) //             | 26
		call RegisterHero( "Mihawk", 	'N008', "STR", 'A08A', 'A018', 'A03X', 'A03L', 'A04Y' ) //             | 27
		call RegisterHero( "Robin",  	'E000', "INT", 'A037', 'A00S', 'A01V', 'A021', 'A08P' ) //             | 28
		call RegisterHero( "Enel",   	'E002', "INT", 'A0BI', 'A02X', 'A02Y', 'A02U', 'A07G' ) //             | 29
		call RegisterHero( "Nami",   	'E001', "INT", 'A055', 'A059', 'A0AH', 'A05E', 'A05H' ) //             | 30

		loop
			exitwhen i > LoadInt( "Total_Heroes" )
			if iterator == 5 then
				set SysIconX = 4032 - 700
				set SysIconY = SysIconY - 100
				set iterator = 0
			endif
			call SaveUnit( "Hero_Picker_" + I2S( i ), CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'u997', SysIconX, SysIconY, 270 ) )
			call AddSpecialEffect( LoadString( "Hero_Icon_Model_" + I2S( i ) ), SysIconX, SysIconY )
			call SetUnitVertexColor( LoadUnit( "Hero_Picker_" + I2S( i ) ), 255, 255, 255, 0 )
			call SetUnitUserData( LoadUnit( "Hero_Picker_" + I2S( i ) ), i )
			call SetUnitInvul( LoadUnit( "Hero_Picker_" + I2S( i ) ), true )
			set i = i + 1
			set iterator = iterator + 1
			set SysIconX = SysIconX + 100
		endloop
	endfunction

    function Check_Entering_Unit takes unit Unit, integer Index returns nothing
		local integer UID = GetUnitTypeId( Unit )
		local integer PID = GetPlayerId( GetOwningPlayer( Unit ) )
		local real MoveX
		local real MoveY
		local string Hero_Name = LoadString( "Hero_Name_" + I2S( Index ) )

		if IsUnitType( Unit, UNIT_TYPE_HERO ) then
			call SetUnitFacing( Unit, GetRandomReal( 0, 360 ) )
			if GetPlayerTeam( Player( PID ) ) == 0 then
				set MoveX = -6736
				set MoveY = 432
			else
				set MoveX = 5232
				set MoveY = 448
			endif
			call SetUnitPosition( Unit, MoveX, MoveY )
			call SelectPlayerUnit( Unit, true )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportTarget.mdl", Unit, "origin" ) )
			if not LoadBoolean( HashTable, GetHandleId( EventTimer ), StringHash( "Initialized_" + I2S( Index ) ) ) then
				call Init_DamagedCheck( Unit )
				call SaveBoolean( HashTable, GetHandleId( EventTimer ), StringHash( "Initialized_" + I2S( Index ) ), true )
				call ExecuteFunc( "Init_" + Hero_Name )
				if Hero_Name == "Inoue" then
					call DisplayTimedTextToPlayer( Player( PID ), 0, 0, 30, "|c00ff0303Do not buy the following items for Orihime: Drake's Axe, Katen Kyoukotsu, Corrupted Desolator, Orb of Lightning, Orb of Frost, Mace of Zeus, and Frostmourne. The orb effects from these items will cause Orihime's attack to malfunction.|r" )
				endif
				if Hero_Name == "SoiFon" then
					call DisplayTimedTextToPlayer( Player( PID ), 0, 0, 30., "|c0021C795Type|r |cffc3dbff -chance|r |c0021C795or|r |cffc3dbff -c|r |c0021C795to view the Homonka success rate.|r" )
				endif
			endif
		endif
    endfunction
	
    function SetPlayerHeroIcon takes integer PID, integer ID returns nothing
		local integer HandleID = GetHandleId( LoadTimerHandle( HashTable, 0, StringHash( "MultiboardTimer" ) ) )
		call MBSetItemIcon( Multiboard, 1, LoadInteger( HashTable, HandleID, StringHash( "PlayerCell_" + I2S( PID ) ) ), LoadString( "Hero_Icon_" + I2S( ID ) ) )
    endfunction

	function PlacePickedHero takes integer PID, integer Index, string Text returns nothing
		call SaveBool( "Has_Hero_" + I2S( PID ), true )
		call SaveBool( "Hero_Selected_" + I2S( Index ), true )
		call SaveInteger( HashTable, GetHandleId( PlayerUnit[ PID ] ), StringHash( "Hero_Index" ), Index )
		call SetPlayerHeroIcon( PID, Index )
		call DisplayTextToPlayer( GetLocalPlayer( ), 0, 0, GetPlayerName( Player( PID ) ) + Text + GetHeroProperName( PlayerUnit[ PID ] ) )
		call Check_Entering_Unit( PlayerUnit[ PID ], Index )
		if GetPlayerController( GetOwningPlayer( PlayerUnit[ PID ] ) ) == MAP_CONTROL_COMPUTER then
			call AI_Buy_items_Action( PlayerUnit[ PID ] )
			call AILearnAbil( PlayerUnit[ PID ] )
		endif
		if GetLocalPlayer( ) == Player( PID ) then
			call SetCameraField( CAMERA_FIELD_ANGLE_OF_ATTACK, 305, 0 )
		endif
	endfunction
	
	function Hero_Selection_Action takes nothing returns nothing
		local integer TeamID	 = GetPlayerTeam( GetTriggerPlayer( ) )
		local integer PID 		 = GetPlayerId( GetTriggerPlayer( ) )
		local integer Index 	 = GetUnitUserData( GetTriggerUnit( ) )
		local string  Effect1 	 = ""

		if not LoadBool( "Has_Hero_" + I2S( PID ) ) and GetUnitTypeId( GetTriggerUnit( ) ) == 'u997' then
			if GetLocalPlayer( ) == Player( PID ) then
				set Effect1 = LoadString( "Hero_Model_" + I2S( Index ) )
				call ClearSelection( )
			endif

			call DestroyEffect( LoadEffect( "Hero_Model_Effect_" + I2S( PID ) ) )
			call RemoveUnit( LoadUnit( "Hero_Picker_Dummy_" + I2S( PID ) ) )
			call SaveUnit( "Hero_Picker_Dummy_" + I2S( PID ), CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'u996', 4032, -6016 - 100, 270 ) )
			call SetUnitTimeScale( LoadUnit( "Hero_Picker_Dummy_" + I2S( PID ) ), 1.5 )
			call SaveEffect( "Hero_Model_Effect_" + I2S( PID ), AddSpecialEffectTarget( Effect1, LoadUnit( "Hero_Picker_Dummy_" + I2S( PID ) ), "origin" ) )

			if LoadInt( "Hero_ID_Saved_" + I2S( PID ) ) != Index then
				call SaveInt( "Hero_ID_Saved_" + I2S( PID ), Index )
			else
				if LoadBool( "Pick_Enabled" ) and not LoadBool( "AR_Mode" ) then
					set PlayerUnit[ PID ] = CreateUnit( Player( PID ), LoadInt( "Hero_UID_" + I2S( Index ) ), 0, 0, 270. )
					call PlacePickedHero( PID, Index, " picked: " )
				endif
			endif
		endif
	endfunction

	function GetRandomHero takes integer PID, string Text returns nothing
		local integer ID

		if GetPlayerSlotState( Player( PID ) ) == PLAYER_SLOT_STATE_PLAYING then
			if not LoadBool( "Has_Hero_" + I2S( PID ) ) then
				set ID = FindRandomHero( )
				set PlayerUnit[ PID ] = CreateUnit( Player( PID ), LoadInt( "Hero_UID_" + I2S( ID ) ), 0, 0, 270. )
				call SaveBool( "Has_Hero_" + I2S( PID ), true )
				if Text == "Random" then
					call PlacePickedHero( PID, ID, " randomed: " )
			elseif Text == "Repick" then
					call PlacePickedHero( PID, ID, " repicked: " )
				endif
			endif
		endif
	endfunction
	
	function GivePlayersRandomHero takes nothing returns nothing
		local integer i = 0

		loop
			exitwhen i > 11
			call GetRandomHero( i, "Random" )
			set i = i + 1
		endloop
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Events\Player_Left.j
    function Player_Left_Action takes nothing returns nothing
		local integer i = 0
		local integer PID = GetPlayerId( GetTriggerPlayer( ) )
		local integer Team = GetPlayerTeam( Player( PID ) )
		local real MoveX = GetStartLocationX( GetPlayerStartLocation( Player( PID ) ) )
		local real MoveY = GetStartLocationY( GetPlayerStartLocation( Player( PID ) ) )

		call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 15, GetPlayerName( Player( PID ) ) + " |c00ff0303has left the game|r" )
		call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", GetUnitX( PlayerUnit[ PID ] ), GetUnitY( PlayerUnit[ PID ] ) ) )
		call SetUnitXY_1( PlayerUnit[ PID ], MoveX, MoveY, true )
		call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", MoveX, MoveY ) )
		call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", MoveX, MoveY ) )
		call Unit_Drop_All_Items( PlayerUnit[ PID ] )
		call EnumUnits_Rect( SysGroup, GetWorldBounds( ) )
		loop
			set SysUnit = FirstOfGroup( SysGroup )
			exitwhen SysUnit == null
			if GetOwningPlayer( SysUnit ) == Player( PID ) and GetUnitTypeId( SysUnit ) == 'n009' then
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", GetUnitX( SysUnit ), GetUnitY( SysUnit ) ) )
				call SetUnitXY_1( PlayerUnit[ PID ], MoveX, MoveY, true )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", MoveX, MoveY ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", MoveX, MoveY ) )
				call Unit_Drop_All_Items( SysUnit )
			endif
			call GroupRemoveUnit( SysGroup, SysUnit )
		endloop
		call RemoveUnit( PlayerUnit[ PID ] )
		call AdjustTeamGold( PID, Team )
		call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, 0 )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\StreakCounter.j
	function SoundForStreak takes integer Count, unit Killer returns nothing
        if Count == 2 then
            call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 2.6, GetPlayerName( GetOwningPlayer( Killer ) ) + " just got a |c000042ffDouble Kill|r!" )
			call StartSound( Sounds[ 5 ] )
        endif
        if Count == 3 then
            call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 2.6, GetPlayerName( GetOwningPlayer( Killer ) ) + " just got a |c0020c000Triple Kill|r!!!" )
            call StartSound( Sounds[ 0 ] )
        endif
        if Count == 4 then
            call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 2.6, GetPlayerName( GetOwningPlayer( Killer ) ) + " just got a |c0000FFFFUltra Kill|r!!!" )
            call StartSound( Sounds[ 1 ] )
        endif
        if Count == 5 then
            call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 2.6, GetPlayerName( GetOwningPlayer( Killer ) ) + " is on a |c0000A8FCRampage|r!!!" )
            call StartSound( Sounds[ 3 ] )
        endif
        if Count >= 6 then
            call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 2.6, GetPlayerName( GetOwningPlayer( Killer ) ) + " just did a complete |c000070A6Humiliation|r!!!!" )
            call StartSound( Sounds[ 4 ] )
        endif
	endfunction
	
	function ResetStreak takes nothing returns nothing
		local integer HandleID = GetHandleId( LoadUnitHandle( HashTable, GetHandleId( GetExpiredTimer( ) ), StringHash( "StreakOwner" ) ) )
		call SaveInteger( HashTable, HandleID, StringHash( "StreakCounter" ), 0 )
	endfunction
	
	function StreakCounter takes unit Killer returns nothing
		local integer HandleID
		local integer Count = LoadInteger( HashTable, GetHandleId( Killer ), StringHash( "StreakCounter" ) ) + 1
		call SaveInteger( HashTable, GetHandleId( Killer ), StringHash( "StreakCounter" ), Count )
		call SoundForStreak( Count, Killer )
		set HandleID = PTimer( Killer, "StreakTimer" )
		if LoadUnitHandle( HashTable, HandleID, StringHash( "StreakOwner" ) ) == null then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "StreakOwner" ), Killer )
		endif
		call TimerStart( LoadTimerHandle( HashTable, GetHandleId( Killer ), StringHash( "StreakTimer" ) ), 4, false, function ResetStreak )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\CameraHeight.j
	function CameraSetHeight takes nothing returns nothing
		if LoadBoolean( HashTable, GetHandleId( GetLocalPlayer( ) ), StringHash( "CamActive" ) ) then
			call SetCameraField( CAMERA_FIELD_TARGET_DISTANCE, LoadFloat( "Camera_Height" ), 0 )
		endif

		if not LoadBool( "Has_Hero_" + I2S( GetPlayerId( GetLocalPlayer( ) ) ) ) then
			if g_ver < 129 then
				call SetCameraPosition( 4032, -5950 )
			else
				call SetCameraPosition( 4032, -5850 )
			endif
			call SetCameraField( CAMERA_FIELD_ANGLE_OF_ATTACK, 270, 0 )
			call SetCameraField( CAMERA_FIELD_TARGET_DISTANCE, 1650, 0 )
		endif
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\Swap.j
	function SetSwapData takes integer PID, boolean Flag returns nothing
		local integer i = 1
		
		loop
			exitwhen i > 6
			call SaveBoolean( HashTable, GetHandleId( Player( PID ) ), StringHash( "GiveTo" + I2S( i ) ), Flag )
			set i = i + 1
		endloop
	endfunction
	
	function SwapOptions takes integer PID, integer Team returns nothing
		local integer ID = 1
		local integer i = 0

		call DisplayTextToPlayer( Player( PID ), 0, 0, "|cffc3dbffSwap Hero Options:|r\n" )

		loop
			exitwhen i == 12
			if GetPlayerTeam( Player( i ) ) == Team and PID != i then
				call DisplayTextToPlayer( Player( PID ), 0, 0, GetColour( ID ) + I2S( ID ) + "|r - " + "|cffc3dbff" + GetHeroProperName( PlayerUnit[ i ] ) + " |r" )
				set ID = ID + 1
			endif
			set i = i + 1
		endloop

		call DisplayTextToPlayer( Player( PID ), 0, 0, "\n\n|cffc3dbffType|r |cffff0000-swap #|r |cffc3dbffto make a choice or |cffff0000 -swap cancel|r |cffc3dbffto cancel swap requests|r" )
	endfunction

	function ResetSwapData takes nothing returns nothing
		call SetSwapData( GetInt( "PID" ), false )
		call DisplayTextToPlayer( Player( GetInt( "PID" ) ), 0, 0, "Swap Vote was reset!" )
		call FlushChildHashtable( HashTable, GetHandleId( GetExpiredTimer( ) ) )
	endfunction

	function SwapInfo takes integer S_PID, integer T_PID, integer Team returns nothing
		local integer HandleID
		local integer TempTrigID
		local integer TempTargID
		
		if Team == 0 then
			set TempTargID = T_PID - 1
			set TempTrigID = S_PID + 1
	elseif Team == 1 then
			set TempTrigID = S_PID - 5
			set TempTargID = T_PID + 5
		endif

		if LoadBoolean( HashTable, GetHandleId( Player( TempTargID ) ), StringHash( "GiveTo" + I2S( TempTrigID ) ) ) then
			call SetSwapData( S_PID, false )
			call SetSwapData( TempTargID, false )
			call SwapItems( PlayerUnit[ S_PID ], PlayerUnit[ TempTargID ] )
			call SetUnitOwner( PlayerUnit[ S_PID ], Player( TempTargID ), true )
			call SetUnitOwner( PlayerUnit[ TempTargID ], Player( S_PID ), true )
			call SelectPlayerUnit( PlayerUnit[ S_PID ], true )
			call SelectPlayerUnit( PlayerUnit[ TempTargID ], true )
			set SysUnit = PlayerUnit[ S_PID ]
			set PlayerUnit[ S_PID ] = PlayerUnit[ TempTargID ]
			set PlayerUnit[ TempTargID ] = SysUnit
		else
			call DisplayTextToPlayer( Player( TempTargID ), 0, 0, GetColour( S_PID ) + GetPlayerName( Player( S_PID ) ) + "|r requested to swap with you. Type -swap " + I2S( TempTrigID ) + " to accept.|r" )
			set HandleID = PTimer( Player( S_PID ), "SwapTimer" )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), S_PID )
			call TimerStart( LoadTimerHandle( HashTable, GetHandleId( Player( S_PID ) ), StringHash( "SwapTimer" ) ), 10, false, function ResetSwapData )
		endif
	endfunction
	//#ExportEnd

	function Return_Rapire takes item Which_Rapire returns nothing
		call SetItemPosition( Which_Rapire, 7360, -1344 )
	
		if Which_Rapire == Rapire then
			set Rapire_Owner = null
			call Remove_By_UID_In_Rect( 'nsgg', GetWorldBounds( ) )
			call SaveBool( "Golems_Created", false )
			call Create_Rapire_Golems( )
		elseif Which_Rapire == Rapire_2 then
			set Rapire_2_Owner = null
		endif
		call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl", 7360, -1344 ) )
	endfunction

	//#ExportTo Scripts\Events\PVP.j
	function GetUnitForEvent takes integer Team, real LocX, real LocY, real Facing returns nothing
		local boolean Found = false
		local effect teleport_effect
		local integer i

		loop
			if Team == 0 then
				set i = GetRandomInt( 0, 4 )
		elseif Team == 1 then
				set i = GetRandomInt( 5, 10 )
			endif
			exitwhen GetPlayerSlotState( Player( i ) ) == PLAYER_SLOT_STATE_PLAYING and not LoadBoolean( HashTable, GetHandleId( Player( i ) ), StringHash( "PickedForEvent" ) )
		endloop

		if IsUnitInArea(PlayerUnit[ i ], "rapire" ) then
			if PlayerUnit[ i ] == Rapire_Owner and not Rapire_Stolen then
				call Return_Rapire( Rapire )
			elseif PlayerUnit[ i ] == Rapire_2_Owner and not Rapire_2_Stolen then
				call Return_Rapire( Rapire_2 )
			endif
		endif

		call SaveBoolean( HashTable, GetHandleId( Player( i ) ), StringHash( "PickedForEvent" ), true )
		call SaveInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team" + I2S( Team ) + "Players" ), LoadInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team" + I2S( Team ) + "Players" ) ) + 1 )
		if UnitLife( PlayerUnit[ i ] ) <= 0 then
			call ReviveHero( PlayerUnit[ i ], LocX, LocY, false )
		else
			call SetUnitXY_1( PlayerUnit[ i ], LocX, LocY, true )
			call SetUnitState( PlayerUnit[ i ], UNIT_STATE_LIFE, GetUnitState( PlayerUnit[ i ], UNIT_STATE_MAX_LIFE ) )
			call SetUnitState( PlayerUnit[ i ], UNIT_STATE_MANA, GetUnitState( PlayerUnit[ i ], UNIT_STATE_MAX_MANA ) )
		endif
		call ShowUnit( PlayerUnit[ i ], true )
		call PauseUnit( PlayerUnit[ i ], true )
		call SelectPlayerUnit( PlayerUnit[ i ], false )
		call Remove_Buffs( PlayerUnit[ i ] )
		call SetUnitInvul( PlayerUnit[ i ], true )
		call SetUnitFacing( PlayerUnit[ i ], Facing )
		// try fix unshown effect 
		// call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", LocX, LocY ) )
		set teleport_effect = AddSpecialEffect( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", LocX, LocY )
		set teleport_effect = null
	endfunction

	function RestartEventData takes nothing returns nothing
		local integer Team = GetInt( "Winning_Team" )
		local integer TotalPlayers = LoadInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team" + I2S( Team ) + "Players" ) )
		local integer GoldAward
		local integer i = 0
		
		if Team == 0 or Team == 1 or Team == -1 then
			if Team == 0 or Team == 1 then
				if TotalPlayers > 1 then
					set GoldAward = 200 * TotalPlayers - 200 * LoadInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team" + I2S( Team ) + "Deaths" ) )
					call DisplayTextToPlayer( GetLocalPlayer( ), 0, 0, "Team " + I2S( Team + 1 ) + " has won the event!" + "\n" + "Winning team receives: " + I2S( GoldAward ) + " gold" )
				endif
			endif

			loop
				exitwhen i == 12
				if GetPlayerSlotState( Player( i ) ) == PLAYER_SLOT_STATE_PLAYING and LoadBoolean( HashTable, GetHandleId( Player( i ) ), StringHash( "PickedForEvent" ) ) then
					if GetPlayerTeam( Player( i ) ) == Team then
						if TotalPlayers == 1 then
							call DisplayTextToPlayer( GetLocalPlayer( ), 0, 0, GetPlayerName( Player( i ) ) + " has won the event!" + "\n" + "Winner receives: " + "+1000 gold, +3 medal, +400 exp" )
							call SetHeroXP( PlayerUnit[ i ], GetHeroXP( PlayerUnit[ i ] ) + 400, true )
							call SetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD ) + 1000 )
							call SetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_LUMBER ) + 3 )
						else
							call SetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD ) + GoldAward )
						endif
					endif
					if UnitLife( PlayerUnit[ i ] ) <= 0 then
						call ReviveHeroCustom( i, PlayerUnit[ i ], GetStartLocationX( GetPlayerStartLocation( Player( i ) ) ), GetStartLocationY( GetPlayerStartLocation( Player( i ) ) ) )
					else
						call SetUnitXY_1( PlayerUnit[ i ], GetStartLocationX( GetPlayerStartLocation( Player( i ) ) ), GetStartLocationY( GetPlayerStartLocation( Player( i ) ) ), true )
					endif
					if GetLocalPlayer( ) == Player( i ) then
						call PanCameraUnit( PlayerUnit[ i ] )
					endif
					call SetUnitTimeScale( PlayerUnit[ i ], 1 )
					call SaveBoolean( HashTable, GetHandleId( Player( i ) ), StringHash( "PickedForEvent" ), false )
				endif
				set i = i + 1
			endloop
			
			if Team == -1 then
				call DisplayTextToPlayer( GetLocalPlayer( ), 0, 0, "DRAW!" )
			endif
		endif

		call SaveBoolean( HashTable, GetHandleId( HashTable ), StringHash( "Event_Started" ), false )
		call SaveBoolean( HashTable, GetHandleId( HashTable ), StringHash( "Event_Stop_Spells" ), false )
		call Pause_All( false )
		call ExecuteFunc( "BeginEventTimed" )
	endfunction

	function DecideEventWinner takes integer Team returns nothing
		call Pause_All( true )
		call SaveInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Winning_Team" ), Team )
		call SaveBoolean( HashTable, GetHandleId( HashTable ), StringHash( "Event_Stop_Spells" ), true )
		call SetRect( SysRect, -7100,  4900, -4500,  7300 )
		call EnumItemsInRect( SysRect, null, function Move_Items_To_Center )
		call SetRect( SysRect, -7100, -6800, -4600, -4100 )
		call EnumItemsInRect( SysRect, null, function Move_Items_To_Center )
		call TimerStart( EventTimer, 2, false, function RestartEventData )
	endfunction

	function EventKilledUnit takes integer Team returns nothing
		local integer EventPlayers = LoadInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team" + I2S( Team ) + "Players" ) )
		local integer Deaths
		call SaveInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team" + I2S( Team ) + "Deaths" ), LoadInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team" + I2S( Team ) + "Deaths" ) ) + 1 )
		set Deaths = LoadInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team" + I2S( Team ) + "Deaths" ) )
		if Deaths == EventPlayers then
			if Team == 0 then
				call DecideEventWinner( 1 )
		elseif Team == 1 then
				call DecideEventWinner( 0 )
			endif
		endif
	endfunction

	function EndEvent takes nothing returns nothing
		local integer i = 0
		local real Team1HP = 0
		local real Team2HP = 0

		loop
			exitwhen i == 12
			if LoadBoolean( HashTable, GetHandleId( Player( i ) ), StringHash( "PickedForEvent" ) ) then
				if GetPlayerTeam( GetOwningPlayer( PlayerUnit[ i ] ) ) == 0 then
					set Team1HP = Team1HP + UnitLifePercent( PlayerUnit[ i ] )
			elseif GetPlayerTeam( GetOwningPlayer( PlayerUnit[ i ] ) ) == 1 then
					set Team2HP = Team2HP + UnitLifePercent( PlayerUnit[ i ] )
				endif
			endif
			set i = i + 1
		endloop

		if Team1HP != 0 then
			set Team1HP = R2I( Team1HP / LoadInt( "Event_Limit" ) )
		endif
		if Team2HP != 0 then
			set Team2HP = R2I( Team2HP / LoadInt( "Event_Limit" ) )
		endif

		if Team1HP > Team2HP then
			call DecideEventWinner( 0 )
	elseif Team2HP > Team1HP then
			call DecideEventWinner( 1 )
	elseif Team1HP == Team2HP then
			call DecideEventWinner( -1 )
		endif
	endfunction

	function DecideEventDelayed takes nothing returns nothing
		local integer i = 0
		local integer Time = SpellTime( )
		local string Event
		if Time <= 700 then
			if Counter( 0, 5 ) then
				call Pause_All( true )
			endif
		endif
		if Time == 300 then
			set Event = I2S( LoadInt( "Event_Limit" ) ) + "x" + I2S( LoadInt( "Event_Limit" ) )

			if Event == "1x1" then
				call GetUnitForEvent( 0, -6560, 6060, 0 )
				call GetUnitForEvent( 1, -5170, 6060, 180 )
		elseif Event == "2x2" then
				call GetUnitForEvent( 0, -6700, -4864, 0 )
				call GetUnitForEvent( 0, -6700, -5824, 0 )
				call GetUnitForEvent( 1, -5300, -4864, 180 )
				call GetUnitForEvent( 1, -5300, -5824, 180 )
		elseif Event == "3x3" then
				call GetUnitForEvent( 0, -6700, -4865, 0 )
				call GetUnitForEvent( 0, -6700, -5345, 0 )
				call GetUnitForEvent( 0, -6700, -5825, 0 )
				call GetUnitForEvent( 1, -5300, -4865, 180 )
				call GetUnitForEvent( 1, -5300, -5345, 180 )
				call GetUnitForEvent( 1, -5300, -5825, 180 )
		elseif Event == "4x4" then
				call GetUnitForEvent( 0, -6700, -4865, 0 )
				call GetUnitForEvent( 0, -6700, -5345, 0 )
				call GetUnitForEvent( 0, -6700, -5825, 0 )
				call GetUnitForEvent( 0, -7000, -5345, 0 )
				call GetUnitForEvent( 1, -5300, -4865, 180 )
				call GetUnitForEvent( 1, -5300, -5345, 180 )
				call GetUnitForEvent( 1, -5300, -5825, 180 )
				call GetUnitForEvent( 1, -5000, -5345, 180 )
		elseif Event == "5x5" then
				call GetUnitForEvent( 0, -6700, -4865, 0 )
				call GetUnitForEvent( 0, -6700, -5345, 0 )
				call GetUnitForEvent( 0, -6700, -5825, 0 )
				call GetUnitForEvent( 0, -7000, -5135, 0 )
				call GetUnitForEvent( 0, -7000, -5575, 0 )
				call GetUnitForEvent( 1, -5300, -4865, 180 )
				call GetUnitForEvent( 1, -5300, -5345, 180 )
				call GetUnitForEvent( 1, -5300, -5825, 180 )
				call GetUnitForEvent( 1, -5000, -5135, 180 )
				call GetUnitForEvent( 1, -5000, -5575, 180 )
			endif

			if Event == "1x1" then
				call PanCameraToTimed(  -5865, 6060, 0 )
			else
				call PanCameraToTimed( -6000, -4864, 0 )
			endif

			//call ClearTextMessages( )
			call Pause_All( true )
			call DisplayTextToPlayer( GetLocalPlayer( ), 0, 0, "Event: |c00fffc01" + Event + "|r" )
		endif
		
		if Time == 400 or Time == 500 or Time == 600 then
			call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 1, "Event starts in: |c00fffc01" + I2S( GetInt( "CountDown" ) ) + "|r" )
			call SaveInteger( HashTable, GetHandleId( EventTimer ), StringHash( "CountDown" ), GetInt( "CountDown" ) - 1 )
		endif
		
		if Time == 700 then
			call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 1, "|c00fffc01Event started!|r" )
			call SaveBoolean( HashTable, GetHandleId( HashTable ), StringHash( "Event_Stop_Spells" ), false )

			loop
				exitwhen i > 11
				if LoadBoolean( HashTable, GetHandleId( Player( i ) ), StringHash( "PickedForEvent" ) ) then
					call GroupEnumUnitsOfPlayer( SysGroup, Player( i ), null )
					loop
						set SysUnit = FirstOfGroup( SysGroup )
						exitwhen SysUnit == null
						call IssueImmediateOrder( SysUnit, "stop" )
						call SetUnitAnimation( SysUnit, "Attack" )
						call SetUnitState( SysUnit, UNIT_STATE_LIFE, GetUnitState( SysUnit, UNIT_STATE_MAX_LIFE ) )
						call SetUnitState( SysUnit, UNIT_STATE_MANA, GetUnitState( SysUnit, UNIT_STATE_MAX_MANA ) )
						call UnitRemoveBuffs( SysUnit, false, true )
						call SetUnitInvul( SysUnit, false )
						call PauseUnit( SysUnit, false )
						call Remove_Buffs( SysUnit )
						call GroupRemoveUnit( SysGroup, SysUnit )
					endloop
				endif
				set i = i + 1
			endloop
		endif

		if Time == 800 then
			call PauseTimer( EventTimer )
			call AI_Order_Periodic( )
			call TimerStart( EventTimer, 30, false, function EndEvent )
			call TimerDialogSetTitle( EventTimerDialog, "Event Ends in: " )
		endif
	endfunction

	function DecideEvent takes nothing returns nothing
		local integer i = 0
		local integer Team1Players = CountPlayersInTeam( 0 )
		local integer Team2Players = CountPlayersInTeam( 1 )
		local integer Limit = 0
		local integer Random = 0

		if Team1Players != 0 and Team2Players != 0 then
			set Limit = IMinBJ( Team1Players, Team2Players )
			if Limit >= 1 then
				loop
					set Random = GetRandomInt( 1, Limit ) // no 1v1 | no 3v3 | no 5v5 | no events
					exitwhen not ( ( Random == 1 and LoadBool( "ND_Mode" ) ) or ( Random == 3 and LoadBool( "N3_Mode" ) ) or ( Random == 5 and LoadBool( "N5_Mode" ) ) )
				endloop
				call SaveInt( "Event_Limit", Random )
				call SaveBoolean( HashTable, GetHandleId( HashTable  ), StringHash( "Event_Stop_Spells" ), true )
				call SaveBoolean( HashTable, GetHandleId( HashTable  ), StringHash( "Event_Started" ), true )
				call SaveInteger( HashTable, GetHandleId( EventTimer ), StringHash( "SpellTime" ), 0 )
				call SaveInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team0Players" ), 0 )
				call SaveInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team1Players" ), 0 )
				call SaveInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team0Deaths" ), 0 )
				call SaveInteger( HashTable, GetHandleId( EventTimer ), StringHash( "Team1Deaths" ), 0 )
				call SaveInteger( HashTable, GetHandleId( EventTimer ), StringHash( "CountDown" ), 3 )
				call TimerStart( EventTimer, .01, true, function DecideEventDelayed )
			endif
		endif
	endfunction

	function BeginEventTimed takes nothing returns nothing
		call TimerStart( EventTimer, 180, false, function DecideEvent )
		if EventTimerDialog == null then
			set EventTimerDialog = CreateTimerDialog( EventTimer )
		endif
		call TimerDialogSetTitle( EventTimerDialog, "Next Event: " )
		call TimerDialogDisplay( EventTimerDialog, true )
		call TimerDialogSetTitleColor( EventTimerDialog, 50, 200, 255, 255 )
		call TimerDialogSetTimeColor( EventTimerDialog, 50, 200, 255, 255 )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\User_Commands.j
	function Mode_Gen takes string Input returns nothing
		if LoadString( "Game_Mode_Text" ) != null then
			call SaveString( "Game_Mode_Text", LoadString( "Game_Mode_Text" ) + " / " )
		endif
		call SaveString( "Game_Mode_Text", LoadString( "Game_Mode_Text" ) + Input )
	endfunction
	
    function Game_Commands takes nothing returns nothing
		local integer i 	  = 0
		local integer ID 	  = 0
		local integer PID 	  = GetPlayerId( GetTriggerPlayer( ) )
		local integer UID 	  = GetUnitTypeId( PlayerUnit[ PID ] )
		local integer Team 	  = GetPlayerTeam( Player( PID ) )
		local integer C_Team  = 0
		local boolean Flag 	  = false
		local string Mode	  = ""
		local string Symbol   = SubString( GetEventPlayerChatString( ), 0, 1 )
		local string Text 	  = SubString( GetEventPlayerChatString( ), 1, StringLength( GetEventPlayerChatString( ) ) )
		local integer EmptyAt = FindEmptyString( 0, Text )
		local string Command  = StringCase( SubString( Text, 0, EmptyAt ), false )
		local string Payload  = SubString( Text, EmptyAt + 1, StringLength( GetEventPlayerChatString( ) ) )
		local real Value	  = 0
		local real Chance	  = 0

		if Symbol == "-" then
			if StringLength( Payload ) > 0 then
				if Command == "camera" then
					set Value = S2R( Payload )
					if GetLocalPlayer( ) == GetTriggerPlayer( ) then
						if Value < 50 then
							call SaveBoolean( HashTable, GetHandleId( GetTriggerPlayer( ) ), StringHash( "CamActive" ), false )
					elseif Value >= 50 and Value <= 200 then
							call SaveBoolean( HashTable, GetHandleId( GetTriggerPlayer( ) ), StringHash( "CamActive" ), true )
							call SaveFloat( "Camera_Height", 20 * Value )
						endif
					endif
				endif

				if Command == "swap" then
					if LoadBool( "Swap_Enabled" ) then
						set ID = S2I( Payload )
						if Text == "All" or Text == "all" then
							call SetSwapData( PID, true )
							call DisplayTextToPlayer( GetTriggerPlayer( ), 0, 0, "Swap with all!" )
						elseif Text == "cancel" or Text == "Cancel" then
								call SetSwapData( PID, false )
								call DisplayTextToPlayer( GetTriggerPlayer( ), 0, 0, "Swap Cancelled!" )
						elseif Text == "info" or Text == "Info" then
							call SwapOptions( PID, GetPlayerTeam( Player( PID ) ) )
						else
							if ( ID >= 1 and ID <= 6 ) and ( ID - 1 != PID and ID - 5 != PID ) then
								call DisplayTextToPlayer( GetTriggerPlayer( ), 0, 0, "You requested to swap with: " + I2S( ID ) )
								call SaveBoolean( HashTable, GetHandleId( Player( PID ) ), StringHash( "GiveTo" + I2S( ID ) ), true )
								call SwapInfo( PID, ID, GetPlayerTeam( Player( PID ) ) )
							endif
						endif
					endif
				endif
			else
				if PID == 0 and not LoadBool( "Mode_Selected" ) then
					if LoadString( "Game_Mode_Text" ) == null then
						loop
							exitwhen i > 16
							set Flag = false
							set Mode = SubString( Text, i, i + 2 )

							if Mode == "ar" and not LoadBool( "AR_Mode" ) then
								call SaveBool( "AR_Mode", true )
								call Mode_Gen( "|c007ebff1All Random|r" )
								set Flag = true
							endif

							if Mode == "ds" and not LoadBool( "DS_Mode" ) and not LoadBool( "HS_Mode" ) then
								call SaveBool( "DS_Mode", true )
								call Mode_Gen( "|c007ebff1Double Score|r" )
								call SaveInt( "Kill_Limit", LoadInt( "Kill_Limit" ) * 2 )
								set Flag = true
							endif

							if Mode == "hs" and not LoadBool( "DS_Mode" ) and not LoadBool( "HS_Mode" ) then
								call SaveBool( "HS_Mode", true )
								call Mode_Gen( "|c007ebff1Half Score|r" )
								call SaveInt( "Kill_Limit", LoadInt( "Kill_Limit" ) / 2 )
								set Flag = true
							endif

							if Mode == "fh" and not LoadBool( "FH_Mode" ) and not LoadBool( "SH_Mode" ) then
								call SaveBool( "FH_Mode", true )
								call Mode_Gen( "|c007ebff1Fast Hunt|r" )
								call SaveString( "Spawn_Type", "Fast" )
								set Flag = true
							endif

							if Mode == "sh" and not LoadBool( "FH_Mode" ) and not LoadBool( "SH_Mode" ) then
								call SaveBool( "SH_Mode", true )
								call Mode_Gen( "|c007ebff1Slow Hunt|r" )
								call SaveString( "Spawn_Type", "Slow" )
								set Flag = true
							endif

							if Mode == "nd" and not LoadBool( "ND_Mode" ) then
								call SaveBool( "ND_Mode", true )
								call Mode_Gen( "|c007ebff1No Duel|r" )
								set Flag = true
							endif

							if Mode == "n3" and not LoadBool( "N3_Mode" ) then
								call SaveBool( "N3_Mode", true )
								call Mode_Gen( "|c007ebff1No 3 vs 3 Battle|r" )
								set Flag = true
							endif

							if Mode == "n5" and not LoadBool( "N5_Mode" ) then
								call SaveBool( "N5_Mode", true )
								call Mode_Gen( "|c007ebff1No 5 vs 5 Battle|r" )
								set Flag = true
							endif

							if Mode == "ne" and not LoadBool( "NE_Mode" ) then
								call SaveBool( "NE_Mode", true )
								call Mode_Gen( "|c007ebff1No Events|r" )
								set Flag = true
							endif

							if Flag then
								call SaveString( "Game_Mode", LoadString( "Game_Mode" ) + Mode )
							endif

							set i = i + 2
						endloop
					endif

					if LoadString( "Game_Mode_Text" ) != null and LoadString( "Game_Mode_Text" ) != "No Mode" then
						call SaveBool( "Mode_Selected", true )
						call DisplayTextToPlayer( GetLocalPlayer( ), 0, 0, LoadString( "Player_Name_" + I2S( 0 ) ) + " has selected: " + LoadString( "Game_Mode_Text" ) )
						return 
					endif
				endif

				if Command == "random" then
					if LoadBool( "Random_Enabled" ) then
						call GetRandomHero( PID, "Random" )
					endif
				endif

				if Command == "repick" then
					if LoadBool( "Repick_Enabled" ) and not LoadBool( "Has_Repicked_" + I2S( PID ) ) and LoadBool( "Has_Hero_" + I2S( PID ) ) then
						call SaveBool( "Has_Repicked_" + I2S( PID ), true )
						call SaveBool( "Has_Hero_" + I2S( PID ), false )
						call RemoveUnit( PlayerUnit[ PID ] )
						if LoadBool( "AR_Mode" ) then
							call GetRandomHero( PID, "Repick" )
						endif
					endif
				endif

				if Command == "gameinfo" then
					set i = 1
					if LoadString( "Game_Mode_Text" ) == null or LoadString( "Game_Mode_Text" ) == "No Mode" then
						call DisplayTextToPlayer( Player( PID ), 0, 0, "|c007ebff1Normal Mode|r: No mode has been specified." )
					else
						if LoadBool( "AR_Mode" ) then
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c007ebff1AR|r: All Random, You will be given a random hero." )
						endif

						if LoadBool( "DS_Mode" ) then
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c007ebff1DS|r: Double Scores, kill scores has been doubled." )
						endif

						if LoadBool( "HS_Mode" ) then
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c007ebff1HS|r: Half Scores, kill scores reduced by half." )
						endif

						if LoadBool( "FH_Mode" ) then
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c007ebff1FH|r: Fast Hunt, creeps spawn more faster." )
						endif

						if LoadBool( "SH_Mode" ) then
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c007ebff1SH|r: Slow Hunt, creeps spawn more slower." )
						endif

						if LoadBool( "ND_Mode" ) then
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c007ebff1ND|r: No Duel, remove duel from random events." )
						endif

						if LoadBool( "N3_Mode" ) then
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c007ebff1N3|r: No 3 vs 3 battle, remove 3 vs 3 battle from random events." )
						endif

						if LoadBool( "N5_Mode" ) then
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c007ebff1N5|r: No 5 vs 5 battle, remove 5 vs 5 battle from random events." )
						endif

						if LoadBool( "NE_Mode" ) then
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c007ebff1NE|r: No Events, no event at all." )
						endif
					endif
				endif

				if Command == "so" then
					if Player( PID ) == GetLocalPlayer( ) then
						set Flag = LoadBoolean( HashTable, GetHandleId( Player( PID ) ), StringHash( "Selection_Disabled" ) )

						if not Flag then
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c00ff0000Selection UI disabled!|r" )
							call EnablePreSelect( false, true )
							call EnableSelect( true, false )
						else
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c0000FF00Selection UI enabled!|r" )
							call EnablePreSelect( true, true )
							call EnableSelect( true, true )
						endif

						call SaveBoolean( HashTable, GetHandleId( Player( PID ) ), StringHash( "Selection_Disabled" ), not Flag )
					endif
				endif

				if Command == "help" then
					call DisplayTextToPlayer( GetTriggerPlayer( ), 0, 0, "Supported Commands are:
-ms
-ma
-clear
-unstuck
-gameinfo
-text on / off
-camera XX ( where XX is a number from 50 to 250 )
-camera autolock ( -ca )" )
				endif
				
				if Command == "ma" then
					loop
						exitwhen i > 11
						if IsPlayerEnemy( Player( i ), GetTriggerPlayer( ) ) then
							call DisplayTextToPlayer( GetTriggerPlayer( ), 0, 0, LoadString( "Player_Name_" + I2S( i ) ) + " controls " + GetHeroProperName( PlayerUnit[ i ] ) + " ( level " + I2S( GetHeroLevel( PlayerUnit[ i ] ) ) + " )" )
						endif
						set i = i + 1
					endloop
				endif

				if Command == "ms" then
					set SysUnit = SelectedUnit( GetTriggerPlayer( ) )
					call DisplayTimedTextToPlayer( GetTriggerPlayer( ), 0, 0, 10, "|c0000ffff" + GetHeroProperName( SysUnit ) + " movement speed|r: " + "|cffffcc00" + "[" + R2SW( GetUnitMoveSpeed( SysUnit ), 0, 0 ) + "]|r" )
				endif

				if Command == "event" then
					call DecideEvent()
				endif

				if Command == "clear" then
					if GetTriggerPlayer( ) == GetLocalPlayer( ) then
						call ClearTextMessages( )
					endif
				endif
			
				if Command == "c" or Command == "chance" then
					if UID == 'O002' or UID == 'O003' then
						if Team == 0 then
							set C_Team = CountPlayersInTeam( 1 )
					elseif Team == 1 then
							set C_Team = CountPlayersInTeam( 0 )
						endif

						if C_Team > 0 then
							set Value = 95. - 5. * GetUnitAbilityLevel( PlayerUnit[ PID ], 'A096' )
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c0021C795Homonka success rate:|r" )

							loop
								exitwhen i > 12
								if PlayerUnit[ i ] != null and IsUnitEnemy_v2( PlayerUnit[ PID ], PlayerUnit[ i ] ) then
									if GetHeroAgi( PlayerUnit[ i ], true ) < GetHeroAgi( PlayerUnit[ PID ], true ) then
										set Chance = 100. - ( ( I2R( GetHeroAgi( PlayerUnit[ i ], true ) ) / I2R( GetHeroAgi( PlayerUnit[ PID ], true ) ) ) * Value )
									else
										set Chance = 100. - Value
									endif

									if GetHeroLevel( PlayerUnit[ i ] ) < GetHeroLevel( PlayerUnit[ PID ] ) then
										call DisplayTextToPlayer( Player( PID ), 0, 0, "|c0021C795" + GetHeroProperName( PlayerUnit[ i ] ) + " = " + I2S( R2I( Chance ) ) + "% success rate ( Certain Death )|r" )
									else
										call DisplayTextToPlayer( Player( PID ), 0, 0, "|c0021C795" + GetHeroProperName( PlayerUnit[ i ] ) + " = " + I2S( R2I( Chance ) ) + "% success rate|r " )
									endif
								endif
								set i = i + 1
							endloop
						else
							call DisplayTextToPlayer( Player( PID ), 0, 0, "|c0021C795You have no opponent.|r" )
						endif
					endif
				endif
			endif
		endif
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Events\Mobs_Handler.j
	function Set_CornerBoss takes unit Boss, integer Side, integer LvL returns unit
		local integer Stats = 100 + 100 * LvL
		call ScaleUnit( Boss, 1.3 )
		if LvL != 0 then
			call SetHeroLevel( Boss, 10 * LvL, false )
		endif
		call UnitAddAbility( Boss, 'ACev' )
		call UnitAddAbility( Boss, 'ACce' )
		call UnitAddAbility( Boss, 'AOcr' )
		call UnitAddAbility( Boss, 'AOmi' )
		call UnitAddAbility( Boss, 'AOww' )
		call SetHeroStr( Boss, Stats, true )
		call SetHeroAgi( Boss, Stats, true )
		call SetHeroInt( Boss, Stats, true )
		call UnitRemoveAbility( Boss, 'AInv' )
		call SetUnitAbilityLevel( Boss, 'AOcr', 3 )
		call UnitAddType( Boss, UNIT_TYPE_ANCIENT )
		call SaveInteger( HashTable, GetHandleId( Boss ), StringHash( "Boss_Num" ), LvL )
		call SaveInteger( HashTable, GetHandleId( Boss ), StringHash( "Boss_Side" ), Side )
		call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", Boss, "origin" ) )
		return Boss
	endfunction

	function New_CornerBoss takes integer Side, integer LvL returns nothing
		if Side == 1 then
			set Left_Boss  = Set_CornerBoss( CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), 'Ogrh', -4150, 3765, 270 ), Side, LvL )
	elseif Side == 2 then
			set Right_Boss = Set_CornerBoss( CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), 'Ogrh',  2760, 3765, 270 ), Side, LvL )
		endif
	endfunction

    function Create_New_Corner_Boss takes nothing returns nothing
		call New_CornerBoss( GetInt( "Boss_Side" ), GetInt( "Boss_Num" ) )
		call CleanMUI( GetExpiredTimer( ) )
    endfunction

	function Create_New_Golem takes nothing returns nothing
		local integer ID = LoadInteger( HashTable, GetHandleId( HashTable ), StringHash( "Golems_Killed" ) )
		local integer UID

		if ID == 1 then
			set UID = 'n00L'
		elseif ID == 2 then
				set UID = 'n00K'
		elseif ID == 3 then
				set UID = 'n00J'
		elseif ID == 4 then
				set UID = 'n00I'
		elseif ID == 5 then
				set UID = 'n00H'
		elseif ID == 6 then
				set UID = 'n00G'
		elseif ID == 7 then
				set UID = 'n00E'
		elseif ID == 8 then
				set UID = 'nfgl'
		elseif ID == 9 then
				set UID = 'n010'
		elseif ID == 10 then
			set UID = 'n011'
			call ShowUnit( WayGate_Arr[ 11 ], false )
			call ShowUnit( WayGate_Arr[ 16 ], false )
			call ShowUnit( WayGate_Arr[ 14 ], false )
			call ShowUnit( WayGate_Arr[ 15 ], false )
		endif

		if ID <= 10 then
			set Oz_Boss = CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), UID, -1600, 6144, 270 )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", Oz_Boss, "origin" ) )
		endif
		call CleanMUI( GetExpiredTimer( ) )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Events\PlayerUnitKill.j
	function AwardKillingUnit takes unit Killing, unit Dying, integer AwardXP, integer AwardGold, integer AwardLumber returns nothing
		local integer KID = GetOwningId( Killing )
		if Dying != null then
			if GetHeroLevel( Killing ) < GetHeroLevel( Dying ) then
				set AwardXP = 200
			endif

			call TextTagAngledUnit( "+ |c00FF9600" + I2S( AwardGold ) + "|r", Dying, 90, 64, 12, 255, 3 )
			if IsPlayerAlly( GetLocalPlayer( ), Player( KID ) ) then
				call SetTextTagVisibility( bj_lastCreatedTextTag, true )
			else
				call SetTextTagVisibility( bj_lastCreatedTextTag, false )
			endif
		endif

		call SetPlayerState( Player( KID ), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState( Player( KID ), PLAYER_STATE_RESOURCE_GOLD ) + AwardGold )
		call SetPlayerState( Player( KID ), PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState( Player( KID ), PLAYER_STATE_RESOURCE_LUMBER ) + AwardLumber )

		if GetUnitState( Killing, UNIT_STATE_LIFE ) > 0 then
			call AddHeroXP( Killing, AwardXP, true )
		endif
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Events\Death_Handler.j
	function Revive_Hero takes nothing returns nothing
		local integer HandleID = GetHandleId( GetExpiredTimer( ) )
		call ReviveHeroCustom( GetInt( "PlayerID" ), GetUnit( "Reviving" ), GetReal( "WhereX" ), GetReal( "WhereY" ) )
		call CleanMUI( GetExpiredTimer( ) )
	endfunction

	function DeadUnitClearData takes unit Dead returns nothing
		local integer PID = GetOwningId( Dead )
		call RemoveUnitOfPlayerByID( PID, 'oshm' )
		call RemoveUnitOfPlayerByID( PID, 'ospw' )
		call RemoveUnitOfPlayerByID( PID, 'otbr' )
		call RemoveUnitOfPlayerByID( PID, 'odoc' )
		call RemoveUnitOfPlayerByID( PID, 'ogru' )
	endfunction

	function Death_Handler takes unit Killing, unit Dying returns nothing
		local integer i = 0
		local integer Boss_Num = LoadInteger( HashTable, GetHandleId( Dying ), StringHash( "Boss_Num" ) )
		local integer Side = LoadInteger( HashTable, GetHandleId( Dying ), StringHash( "Boss_Side" ) )
		local integer Golems_Killed = LoadInteger( HashTable, GetHandleId( HashTable ), StringHash( "Golems_Killed" ) )
		local integer K_PID = GetOwningId( Killing )
		local integer D_PID = GetOwningId( Dying )
		local integer Team = GetPlayerTeam( Player( K_PID ) )
		local integer Team_Kills = LoadInt( "Team_" + I2S( Team + 1 ) + "_Kills" )
		local integer K_UID = GetUnitTypeId( Killing )
		local integer D_UID = GetUnitTypeId( Dying )
		local integer HandleID
		local integer UID
		local integer Coins = 10
		local integer RandInt = GetRandomInt( 1, 2 )
		local real Time = 60
		local real D_LocX = GetUnitX( Dying )
		local real D_LocY = GetUnitY( Dying )
		local string K_Name = LoadString( "Player_Name_" + I2S( K_PID ) )
		local string D_Name = LoadString( "Player_Name_" + I2S( D_PID ) )

		call SetUnitFlyHeight( Dying, 0, 0 )
		if D_PID <= 11 then
			if IsUnitType( Dying, UNIT_TYPE_HERO ) then
				call Add_Player_Int( D_PID, "Deaths" )

				if Dying == Rapire_Owner then
					if IsUnitInArea( Rapire_Owner, "rapire" ) and not Rapire_Stolen then
						call Return_Rapire( Rapire )
					endif
					set Rapire_Owner = null
				endif

				if Dying == Rapire_2_Owner then
					set Rapire_2_Owner = null
				endif


				if K_PID <= 11 then
					if Killing == Dying then
						set D_Name = "himself!"
					else
						call Add_Player_Int( K_PID, "Kills" )
						call StreakCounter( Killing )
						set Team_Kills = Team_Kills + 1
						call SaveInt( "Team_" + I2S( Team + 1 ) + "_Kills", Team_Kills )
						call AwardKillingUnit( PlayerUnit[ K_PID ], Dying, 50, 25 * GetHeroLevel( Dying ), 1 )
					endif
				endif

				if Team_Kills >= LoadInt( "Kill_Limit" ) then
					call DisplayTextToPlayer( GetLocalPlayer( ), 0, 0, "Team: " + I2S( Team + 1 ) + " has won the game!" )
					loop
						exitwhen i > 11
						if GetPlayerTeam( Player( i ) ) == Team then
							call CustomVictoryBJ( Player( i ), true, true )
						else
							call CustomDefeatBJ( Player( i ), "You have lost!" )
						endif
						set i = i + 1
					endloop
				else
					if LoadBoolean( HashTable, GetHandleId( Player( D_PID ) ), StringHash( "PickedForEvent" ) ) then
						call EventKilledUnit( GetPlayerTeam( Player( D_PID ) ) )
					endif
					call DeadUnitClearData( Dying )
					set HandleID = NewMUITimer( D_PID )
					call SaveUnitHandle( HashTable, HandleID, StringHash( "Reviving" ), Dying )
					call SaveInteger( HashTable, HandleID, StringHash( "PlayerID" ), D_PID )
					call SaveReal( HashTable, HandleID, StringHash( "WhereX" ), GetStartLocationX( GetPlayerStartLocation( Player( D_PID ) ) ) )
					call SaveReal( HashTable, HandleID, StringHash( "WhereY" ), GetStartLocationY( GetPlayerStartLocation( Player( D_PID ) ) ) )
					call TimerStart( LoadMUITimer( D_PID ), 3, false, function Revive_Hero )
					if K_Name != null and D_Name != null then
						call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 2., K_Name + " killed " + D_Name )
					endif
				endif
			endif
	elseif D_PID == 12 then
			if IsUnitType( Dying, UNIT_TYPE_HERO ) then
				if not LoadBool( "Side_" + I2S( Side ) + "_Clear" ) then
					if Side == 1 or Side == 2 then
						call AddHeroXP( PlayerUnit[ K_PID ], 1500, true )
						if RandInt == 1 then
							if Boss_Num > 1 then
								set Coins = 20
							endif
							call Generate_Gold_Coins( 'I01L', Coins, D_LocX, D_LocY )
						elseif RandInt == 2 then
							// elixir
							call CreateItem( 'pres', D_LocX, D_LocY )
						endif
						if Boss_Num < 9 then
							set HandleID = NewMUITimer( D_PID )
							call SaveInteger( HashTable, HandleID, StringHash( "Boss_Side" ), Side )
							call SaveInteger( HashTable, HandleID, StringHash( "Boss_Num" ), Boss_Num + 1 )
							call TimerStart( LoadMUITimer( D_PID ), 30, false, function Create_New_Corner_Boss )
						else
							call SaveBool( "Side_" + I2S( Side ) + "_Clear", true )
						endif
					endif
				endif

				if Dying == Ring_Boss then
					if not LoadBool( "Ring_Dropped" ) then
						set Team = GetPlayerTeam( GetOwningPlayer( Killing ) )
						call CreateItem( 'I001', D_LocX, D_LocY )
						call SaveBool( "Ring_Dropped", true )
						call AddHeroXP( PlayerUnit[ K_PID ], 9999, true )
						call Award_Team( Team, 9999, "Gold" )
						call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 35., GetHeroProperName( Ring_Boss ) + " ( level 99 ) has been slain by Team " + I2S( Team + 1 ) + " ( + 9999 gold each Player )!" )
						call TimerStart( CreateTimer( ), 20, false, function Create_Ring_Boss )
					else
						if not LoadBool( "Ring_Clear" ) then
							call SaveBool( "Ring_Clear", true )
							call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\Undead\\UndeadDissipate\\UndeadDissipate.mdl", D_LocX, D_LocY ) )
							call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 30, GetHeroProperName( Ring_Boss ) + " ( level 99 ) has been slain!!!" )
						endif
					endif
				endif

				if D_UID == 'NC03' then
					call UnitRemoveItemFromSlot( Dying, 0 )
					call UnitRemoveItemFromSlot( Dying, 1 )
					call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\Undead\\UndeadDissipate\\UndeadDissipate.mdl", GetUnitX( Dying ), GetUnitY( Dying ) ) )
					call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 45., GetHeroProperName( Dying ) + " has been slain!!!" )
				endif
			else
				if D_UID == 'nfgo' then
					call SaveBool( "Orb_Clear", true )
					call CreateItem( 'ofro', D_LocX, D_LocY )
					call AddHeroXP( Killing, 5000, true )
					call Generate_Gold_Coins( 'gold', 20, GetUnitX( Dying ), GetUnitY( Dying ) )
				endif

				if D_UID == 'ninf' then
					call CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), 'ninf', GetRandomReal( -3264, 64 ), GetRandomReal( 5056, 7232 ), GetRandomReal( 0, 360 ) )
				endif

				if D_UID == 'n012' then
					call SaveBool( "Mimic_Clear", true )
					set Rapire_2 = CreateItem( 'I00A', D_LocX, D_LocY )
				endif

				if Dying == Oz_Boss and Oz_Boss != null then
					set Golems_Killed = Golems_Killed + 1
					call SaveInteger( HashTable, GetHandleId( HashTable ), StringHash( "Golems_Killed" ), Golems_Killed )
					call Generate_Gold_Coins( 'I03G', 4 * Golems_Killed, D_LocX, D_LocY )
					if not LoadBool( "Oz_Clear" ) then
						if Golems_Killed <= 10 then
							set HandleID = NewMUITimer( D_PID )
							if Golems_Killed == 9 then
								set Time = Time + 45
							endif
							if Golems_Killed == 10 then
								set Time = Time + 100
							endif
							call TimerStart( LoadMUITimer( D_PID ), Time, false, function Create_New_Golem )
						else
							call SaveBool( "Oz_Clear", true )
							call CreateItem( 'I04N', D_LocX, D_LocY )
							set Dummy = CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'n00Z', -7024, 1104, 270 )
							call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", Dummy, "origin" ) )
							set Dummy = CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'n00Z',  5616, 1168, 270 )
							call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", Dummy, "origin" ) )
							call ShowUnit( WayGate_Arr[ 11 ], true )
							call ShowUnit( WayGate_Arr[ 16 ], true )
							call ShowUnit( WayGate_Arr[ 14 ], true )
							call ShowUnit( WayGate_Arr[ 15 ], true )
						endif
					endif
				endif
				
				if UnitLife( PlayerUnit[ K_PID ] ) > 0 then
					call AddHeroXP( PlayerUnit[ K_PID ], 3 * GetUnitLevel( Dying ), true )
				endif
			endif

			if not IsUnitType( Dying, UNIT_TYPE_STRUCTURE ) and not IsUnitType( Dying, UNIT_TYPE_MECHANICAL ) and HasItem( PlayerUnit[ K_PID ], 'I009' ) then
				call SetWidgetLife( PlayerUnit[ K_PID ], GetUnitState( PlayerUnit[ K_PID ], UNIT_STATE_LIFE ) + .3 * GetUnitState( Dying, UNIT_STATE_MAX_LIFE ) )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\DeathPact\\DeathPactCaster.mdl", PlayerUnit[ K_PID ], "origin" ) )
			endif

			if not LoadBool( "Aizen_Clear" ) and LoadBool( "Oz_Clear" ) and LoadBool( "Mimic_Clear" ) and LoadBool( "Orb_Clear" ) and LoadBool( "Side_1_Clear" ) and LoadBool( "Side_2_Clear" ) and LoadBool( "Ring_Clear" ) then
				call SaveBool( "Aizen_Clear", true )
				call TimerStart( CreateTimer( ), 90, false, function Summon_Aizen )
			endif
		endif
	endfunction

	function Death_Event takes nothing returns nothing
		call Death_Handler( GetKillingUnit( ), GetDyingUnit( ) )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Events\Entering.j
	function UnitEntersBase takes unit Target, integer Team returns nothing
		local integer PID = GetOwningId( Target )
        if GetPlayerTeam( Player( PID ) ) == Team then
			if not HasAbility( Target, 'B00A' ) then
				call CC_Cast( Target, "rejuvination", "Target" )
			endif
			if GetPlayerController( Player( PID ) ) == MAP_CONTROL_COMPUTER then
				call AI_Buy_items_Action( PlayerUnit[ PID ] )
				call AILearnAbil( PlayerUnit[ PID ] )
			endif
		else
			call SetUnitInvul( Target, false )
			if not HasItem( Target, 'I02M' ) then
				call UnitRemoveAbility( Target, 'Binv' )
				call UnitRemoveAbility( Target, 'Bivs' )
				call UnitRemoveAbility( Target, 'B00R' )
				call UnitRemoveAbility( Target, 'B00Q' )
				call CC_Cast( Target, "doom", "Target" )
				call CC_Cast( Target, "faeriefire", "Target" )
				if HasItem( Target, 'I007' ) then // I02M
					call CC_Cast( Target, "doom", "Target" )
					call CC_Cast( Target, "faeriefire", "Target" )
				endif
			endif
        endif
	endfunction

    function Enteting_Forgotten_One_Area takes nothing returns nothing
		if IsUnitType( GetTriggerUnit( ), UNIT_TYPE_HERO ) then
			call PanCameraUnit( GetTriggerUnit( ) )
		endif
    endfunction

    function Entering_Golem_Area takes nothing returns nothing
		local integer RandInt = GetRandomInt( 1, 4 )
		local real LocX 
		local real LocY 

		if IsUnitType( GetTriggerUnit( ), UNIT_TYPE_HERO ) then
			if RandInt == 1 then
				set LocX = GetUnitX( WayGate_Arr[ 16 ] )
				set LocY = GetUnitY( WayGate_Arr[ 16 ] )
			elseif RandInt == 2 then
					set LocX = GetUnitX( WayGate_Arr[ 11 ] )
					set LocY = GetUnitY( WayGate_Arr[ 11 ] )
			elseif RandInt == 3 then
					set LocX = GetUnitX( WayGate_Arr[ 14 ] )
					set LocY = GetUnitY( WayGate_Arr[ 14 ] )
			elseif RandInt == 4 then
				set LocX = GetUnitX( WayGate_Arr[ 15 ] )
				set LocY = GetUnitY( WayGate_Arr[ 15 ] )
			endif
			call WaygateSetDestination( WayGate_Arr[ 10 ], LocX, LocY )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", GetTriggerUnit( ), "origin" ) )
			call PanCameraUnit( GetTriggerUnit( ) )
		endif
    endfunction

    function Enter_Rapire_Area takes nothing returns nothing
		local integer i = 0
		set SysUnit = GetTriggerUnit( )
		if IsUnitType( SysUnit, UNIT_TYPE_HERO ) then
			if GetHeroLevel( SysUnit ) < 20 then
				call SetUnitPosition( SysUnit, -705, -3200 )
				call SetUnitFacing( SysUnit, 90 )
				call PanCameraUnit( SysUnit )
				call DestroyEffect( AddSpecialEffectTarget( "origin", SysUnit, "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl" ) )
				call DisplayTimedTextToPlayer( GetOwningPlayer( SysUnit ), 0, 0, 4., " |cffffcc00Area for hero above level 20|r" )
				return
			endif

			call Create_Rapire_Golems( )
			call PanCameraUnit( SysUnit )
			call DestroyEffect( AddSpecialEffectTarget( "origin", SysUnit, "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl" ) )
			call SetUnitManaBJ( SysUnit, 0 )
			// TODO: this removes spells like Ichigo's Bankai and must be fixed in future to remove only buffs but not forms
			// call UnitRemoveBuffs( SysUnit, true, false )
			call CC_Cast( SysUnit, "silence", "AoE" )

			loop
				exitwhen i > 5
				set SysItem = UnitItemInSlot( SysUnit, i )
				if GetItemTypeId( SysItem ) == 'pres' then
					// remove elixir
					call UnitRemoveItem( SysUnit, SysItem )
					call SetItemPosition( SysItem, -704, -2512 )
					call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl", -704, -2512 ) )
				endif
				set SysItem = null
				set i = i + 1
			endloop
		endif
		set SysUnit = null
    endfunction

	function Entering_Ring_Boss_Area takes nothing returns nothing
		set SysUnit = GetTriggerUnit( )
		if IsUnitType( SysUnit, UNIT_TYPE_HERO ) then
			if GetHeroLevel( SysUnit ) < 40 then
				call SetUnitPosition( SysUnit, -705, 3455 )
				call SetUnitFacing( SysUnit, 270 )
				call DisplayTimedTextToPlayer( GetOwningPlayer( SysUnit ), 0, 0, 4., " |cffffcc00Area for hero above level 40|r" )
			endif

			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", SysUnit, "origin" ) )
			call PanCameraUnit( SysUnit )
		endif
		set SysUnit = null
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Events\Leaving.j
	function Return_Boss takes unit Boss, real LocX, real LocY returns nothing
		call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\NightElf\\Blink\\BlinkTarget.mdl", GetUnitX( Boss ), GetUnitY( Boss ) ) )
		call SetUnitXY_1( Boss, LocX, LocY, true )
		call IssueImmediateOrder( Boss, "stop" )
		call SetUnitFacing( Boss, 270 )
		call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\NightElf\\Blink\\BlinkTarget.mdl", LocX, LocY ) )
	endfunction
	
	function Left_Boss_Left takes nothing returns nothing
		if GetTriggerUnit( ) == Left_Boss then
			call Return_Boss( Left_Boss, -4150, 3765 )
		endif
	endfunction
	
	function Right_Boss_Left takes nothing returns nothing
		if GetTriggerUnit( ) == Right_Boss then
			call Return_Boss( Right_Boss,  2760, 3765 )
		endif
	endfunction

	function Leaving_Any_Area takes nothing returns nothing
		set SysUnit = GetTriggerUnit( )

		if SysUnit == Ring_Boss then
			call Return_Boss( SysUnit,  4200, 6900 )
	elseif SysUnit == Oz_Boss then
			call Return_Boss( SysUnit, -1600, 6145 )
		endif

		if IsUnitType( SysUnit, UNIT_TYPE_HERO ) or IsUnitIllusion( SysUnit ) then
			call Remove_Buffs( SysUnit )
			if IsUnitType( SysUnit, UNIT_TYPE_HERO ) then
				call PanCameraUnit( SysUnit )
			endif
		endif
		set SysUnit = null
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\Game_Timer.j
	function Game_Timer takes nothing returns nothing
		local integer i = 0
		local integer Time = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real Delay = 0

		if Time == 1 then
			call SaveGroupHandle( HashTable, HandleID, StringHash( "Hero_Group" ), CreateGroup( ) )
		endif

		if Time >= 1 then
			call EnumUnits_Rect( GetGroup( "Hero_Group" ), GetWorldBounds( ) )

			loop
				set BaseUnit = FirstOfGroup( GetGroup( "Hero_Group" ) )
				exitwhen BaseUnit == null

				if IsUnitType( BaseUnit, UNIT_TYPE_HERO ) then
					if IsUnitInArea( BaseUnit, "base_1" ) then
						call UnitEntersBase( BaseUnit, 0 )
				elseif IsUnitInArea( BaseUnit, "base_2" ) then
						call UnitEntersBase( BaseUnit, 1 )
					endif
				endif

				call GroupRemoveUnit( GetGroup( "Hero_Group" ), BaseUnit )
			endloop
		endif

		if Time >= 15 then
			loop
				exitwhen i > 11
				call SetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD ) + 4 )
				set i = i + 1
			endloop
		endif

		if Time > 1000 then
			call SaveInteger( HashTable, HandleID, StringHash( "SpellTime" ), 205 )
		endif

		if Time <= 200 then
			if Time == 15 then // Mode Selection Over
				if not LoadBool( "NS_Mode" ) then
					call SaveBool( "Swap_Enabled", true )
					call SaveBool( "Repick_Enabled", true )
				endif
				if LoadString( "Game_Mode_Text" ) == null then
					call SaveString( "Game_Mode_Text", "No Mode" )
					call SaveString( "Game_Mode", "Normal" )
					call DisplayTextToPlayer( GetLocalPlayer( ), 0, 0, "No mode specified." )
				else
					call DisplayTimedTextToPlayer( GetLocalPlayer( ), 0, 0, 10., "For more information about the game modes use -gameinfo." )
				endif
				if not LoadBool( "AR_Mode" ) then
					call SaveBool( "Pick_Enabled", true )
					call SaveBool( "Random_Enabled", true )
				else
					call GivePlayersRandomHero( )
				endif

				if not LoadBool( "NH_Mode" ) then
					call TimerStart( EventTimer, 45, false, null )
					set EventTimerDialog = CreateTimerDialog( EventTimer )
					call TimerDialogSetTitle( EventTimerDialog, "Creep Spawn in:" )
					call TimerDialogDisplay( EventTimerDialog, true )
				endif
			endif

			if Time == 40 then // Disable Random Command
				call SaveBool( "Random_Enabled", false )
			endif

			if Time == 60 then // Map Init Over
				call Spawn_Creeps( )
				call Create_Basic_Boss( )
				call TimerDialogDisplay( EventTimerDialog, false )
				if not LoadBool( "NE_Mode" ) then
					call BeginEventTimed( )
				endif

				call ExecuteFunc( "GivePlayersRandomHero" )

				if LoadString( "Spawn_Type" ) == "Slow" then
					set Delay = 80
			elseif LoadString( "Spawn_Type" ) == "Fast" then
					set Delay = 30
			elseif LoadString( "Spawn_Type" ) == null then
					set Delay = 50
				endif

				if Delay != 0 then
					call TimerStart( CreateTimer( ), Delay, true, function Spawn_Creeps )
				endif

				call SetFloatGameState( GAME_STATE_TIME_OF_DAY, 6.)
				call SuspendTimeOfDay( false )
				call SetTimeOfDayScale( 2 )
				call StopMusic( false )
				call ClearMapMusic( )
				call SaveBool( "Swap_Enabled", false )
				call SaveBool( "Repick_Enabled", false )
				call GroupEnumUnitsOfType( SysGroup, UnitId2String( 'nwgt' ), null )
				loop
					set SysUnit = FirstOfGroup( SysGroup )
					exitwhen SysUnit == null
					call WaygateActivate( SysUnit, true )
					call GroupRemoveUnit( SysGroup, SysUnit )
				endloop
				call WaygateSetDestination( WayGate_Arr[ 10 ], GetUnitX( WayGate_Arr[ 16 ] ), GetUnitY( WayGate_Arr[ 16 ] ) )

				set i = 0
				loop
					exitwhen i > 18
					call CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), 'ninf', GetRandomReal( -3264, 64 ), GetRandomReal( 5056, 7232 ), GetRandomReal( 0, 360 ) )
					set i = i + 1
				endloop
			endif

			if Time == 140 then
				call New_CornerBoss( 1, 0 )
				call New_CornerBoss( 2, 0 )
			endif
		endif
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Ichigo.j
	function Ichigo_Q takes nothing returns nothing
		local integer Time = SpellTime( )
		if Time == 1 then
			if GetUnitTypeId( GetUnit( "Caster" ) ) == 'H003' then
				call PlaySoundOnUnit( Sounds[ 31 ], 100, GetUnit( "Caster" ) )
				call SaveReal( HashTable, MUIHandle( ), StringHash( "Distance" ), 800 )
				call SaveReal( HashTable, MUIHandle( ), StringHash( "Speed" ), 1500 )
				call SaveReal( HashTable, MUIHandle( ), StringHash( "Damage" ), 110 + 115 * GetInt( "ALvL" ) )
				call SaveInteger( HashTable, MUIHandle( ), StringHash( "DoubleChance" ), 6 * GetInt( "ALvL" ) )
				call SaveStr( HashTable, MUIHandle( ), StringHash( "Model" ), "!BlueGetsugaTenshou!.mdx" )
			else
				call PlaySoundOnUnit( Sounds[ 26 ], 100, GetUnit( "Caster" ) )
				call SaveReal( HashTable, MUIHandle( ), StringHash( "Distance" ), 900 )
				call SaveReal( HashTable, MUIHandle( ), StringHash( "Speed" ), 1500 )
				call SaveReal( HashTable, MUIHandle( ), StringHash( "Damage" ), 175 + 125 * GetInt( "ALvL" ) )
				call SaveInteger( HashTable, MUIHandle( ), StringHash( "DoubleChance" ), 8 * GetInt( "ALvL" ) )
				call SaveStr( HashTable, MUIHandle( ), StringHash( "Model" ), "!BlackGetsugaTenshou!.mdx" )
			endif
			call Linear_Spell( GetUnit( "Caster" ), GetReal( "TargX" ), GetReal( "TargY" ), GetStr( "Model" ), GetReal( "Speed" ), GetReal( "Distance" ), 200, 2, GetReal( "Damage" ), "" )
		endif

		if Time == 20 or Stop_Spells( ) then
			if GetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AI' ) > 1 then
				if GetRandomInt( 1, 100 ) <= GetInt( "DoubleChance" ) and not Stop_Spells( ) then
					call Linear_Spell( GetUnit( "Caster" ), GetReal( "TargX" ), GetReal( "TargY" ), GetStr( "Model" ), GetReal( "Speed" ), GetReal( "Distance" ), 200, 2, GetReal( "Damage" ), "" )
				endif
			endif
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Ichigo_W takes nothing returns nothing
		local integer Time = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 or GetUnitTypeId( GetUnit( "Caster" ) ) != GetInt( "CasterId" ) then
			call DestroyEffect( GetEffect( "BuffEff" ) )
			if GetUnitTypeId( GetUnit( "Caster" ) ) == 'H003' then
				if GetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AQ' ) <= 2 then
					call SetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AI', 2 )
				else
					call SetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AI', GetInt( "ALvL" ) )
				endif
				call SaveEffectHandle( HashTable, HandleID, StringHash( "BuffEff" ), AddSpecialEffectTarget( "!BlueGetsugaBlade!.mdx", GetUnit( "Caster" ), "weapon" ) )
			else
				if GetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AQ' ) <= 2 then
					call SetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AI', 3 )
				else
					call SetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AI', 1 + GetInt( "ALvL" ) )
				endif
				call SaveEffectHandle( HashTable, HandleID, StringHash( "BuffEff" ), AddSpecialEffectTarget( "!BlackGetsugaBlade!.mdx", GetUnit( "Caster" ), "hand right" ) )
			endif
			call SaveInteger( HashTable, HandleID, StringHash( "CasterId" ), GetUnitTypeId( GetUnit( "Caster" ) ) )
		endif

		if Time == 1800 or Stop_Spell( 0 ) or GetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AQ' ) == 1 then
			call SetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AI', 1 )
			call DestroyEffect( GetEffect( "BuffEff" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Ichigo_E takes integer PID, integer UID returns nothing
		if UID == 'H003' then
			call CreateUnit( Player( PID ), 'oshm', 8000, 8000, bj_UNIT_FACING )
			call DestroyEffect( AddSpecialEffectTarget( "war3mapImported\\DarkNova.mdx", GetTriggerUnit( ), "origin" ) )
			call PlaySoundOnUnit( Sounds[ 27 ], 100, GetTriggerUnit( ) )
			if GetUnitAbilityLevel( GetTriggerUnit( ), 'A03J' ) >= 3 then
				call DestroyEffect( AddSpecialEffectTarget( "war3mapImported\\darkblast.mdx", GetTriggerUnit( ), "origin" ) )
			endif
			call DestroyEffect( AddSpecialEffectTarget( "war3mapImported\\DarkLightningNova.mdx", GetTriggerUnit( ), "origin" ) )
			call TransformDisplace( GetTriggerUnit( ) )
		else
			call RemoveUnitOfPlayerByID( PID, 'oshm' )
		endif
	endfunction

	function Ichigo_R takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real MoveX
		local real MoveY
		local real Dist
		local real Angle

		if GetInt( "Executions" ) < GetInt( "ExecLimit" ) and Time <= GetInt( "TimeLimit" ) and not Stop_Spell( 0 ) then
			if Counter( 0, 30 ) then
				if GetUnit( "Target" ) != null then
					call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
					set Dist  = GetRandomReal( 70, 100 )
					set Angle = GetRandomReal(  0, 360 )
					set MoveX = NewX( GetUnitX( GetUnit( "Target" ) ), Dist, Angle )
					set MoveY = NewY( GetUnitY( GetUnit( "Target" ) ), Dist, Angle )
					call SetUnitXY_1( GetUnit( "Caster" ), MoveX, MoveY, true )
					call DestroyEffect( AddSpecialEffect( "!Shunpo!.mdx", MoveX, MoveY ) )
					call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", GetUnit( "Target" ), "chest" ) )
					call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), GetHeroStr( GetUnit( "Caster" ), true ) * 2, "physical" )
					call DestroyEffect( AddSpecialEffectTarget( "units\\nightelf\\SpiritOfVengeance\\SpiritOfVengeance.mdl", GetUnit( "Caster" ), "chest" ) )
					call Linear_Spell( GetUnit( "Caster" ), MoveX, MoveY, "!BlackGetsugaTenshou!.mdx", 1500, 900, 200, 2, 250 + 50 * GetInt( "ALvL" ), "" )
					call RemoveSavedHandle( HashTable, HandleID, StringHash( "Target" ) )
					call SaveInteger( HashTable, HandleID, StringHash( "Executions" ), GetInt( "Executions" ) + 1 )
				endif
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetRandomEnemyUnitInArea( GetInt( "PID" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 720 ) )
			endif
		else
			call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "R_Channel" ), false )
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 255 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Ichigo_T_Act takes unit Source, string Mode returns nothing
		local integer PID = GetInt( "PID" )
		set SysUnit = LoadUnitHandle( HashTable, GetHandleId( Source ), StringHash( "Vasto_Lord" ) )
		if Mode == "Init" then
			call SetHeroStr( Source, GetHeroStr( Source, false ) + 50, true )
			call SetHeroAgi( Source, GetHeroAgi( Source, false ) + 50, true )
			call SwapUnits( Source, SysUnit, true )
			call SetPlayerHandicapXP( Player( PID ), 0 )
			call PlaySoundOnUnit( Sounds[ 28 ], 100, Source )
			call RemoveUnitOfPlayerByID( PID, 'okod' )
			call SetUnitManaBJ( SysUnit, 0 )
		elseif Mode == "Remove" then
			call SwapUnits( SysUnit, Source, true )
			call SetPlayerHandicapXP( Player( PID ), 1 )
			call SetHeroStr( Source, GetHeroStr( Source, false ) - 50, true )
			call SetHeroAgi( Source, GetHeroAgi( Source, false ) - 50, true )
		endif
		set SysUnit = null
	endfunction

	function Ichigo_T takes nothing returns nothing
		local integer Time = SpellTime( )
		local integer HandleID = MUIHandle( )
		if Time == 1 then
			call Ichigo_T_Act( GetUnit( "Caster" ), "Init" )
		endif
		if Time >= GetInt( "TimeLimit" ) or UnitLife( GetUnit( "Form" ) ) <= 0 then
			if UnitLife( GetUnit( "Form" ) ) <= 0 then
				call ReviveHero( GetUnit( "Form" ), 3136, -4560, false )
				call Ichigo_T_Act( GetUnit( "Caster" ), "Remove" )
				call KillUnit( GetUnit( "Caster" ) )
			else
				call Ichigo_T_Act( GetUnit( "Caster" ), "Remove" )
			endif
			call UnitRemoveAbility( GetUnit( "Caster" ), 'B016' )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Ichigo_Spells takes nothing returns nothing
		local integer AID = GetSpellAbilityId( )
		local integer UID = GetUnitTypeId( GetTriggerUnit( ) )
		local integer PID = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL = GetUnitAbilityLevel( GetTriggerUnit( ), GetSpellAbilityId( ) )
		local integer HandleID

		if AID == 'A008' then
			call Ability_Handler( AID, GetTriggerUnit( ), null, GetSpellTargetX( ), GetSpellTargetY( ), function Ichigo_Q )
		endif

		if AID == 'A0AQ' then
			call PlaySoundOnUnit( Sounds[ 29 ], 100, GetTriggerUnit( ) )
			set HandleID = Ability_Handler( AID, GetTriggerUnit( ), null, GetSpellTargetX( ), GetSpellTargetY( ), function Ichigo_W )
			call SaveInteger( HashTable, HandleID, StringHash( "CasterId" ), GetUnitTypeId( GetTriggerUnit( ) ) )
		endif

		if AID == 'A03J' then
			call Ichigo_E( PID, UID )
		endif

		if AID == 'A00C' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 30 ], 100, GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SetUnitVertexColor( GetTriggerUnit( ), 255, 255, 255, 125 )
			if ALvL > 3 then
				call SaveInteger( HashTable, HandleID, StringHash( "ExecLimit" ), ALvL )
			else
				call SaveInteger( HashTable, HandleID, StringHash( "ExecLimit" ), 3 )
			endif
			call SaveInteger( HashTable, HandleID, StringHash( "TimeLimit" ), 40 * LoadInteger( HashTable, HandleID, StringHash( "ExecLimit" ) ) )
			call SaveBoolean( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "R_Channel" ), true )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ichigo_R )
		endif

		if AID == 'A04A' then
			set HandleID = NewMUITimer( PID )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Form" ), LoadUnitHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Vasto_Lord" ) ) )
			call SaveInteger( HashTable, HandleID, StringHash( "TimeLimit" ), ( 15 + ALvL ) * 100 )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ichigo_T )
		endif

		if AID == 'A0BS' then
			call PlaySoundOnUnit( Sounds[ 33 ], 100, GetTriggerUnit( ) )
			call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "", 1000, 1200, 300, 2, 1000. + 10. * GetHeroStr( GetTriggerUnit( ), true ), "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl" )
		endif

		if AID == 'A0BT' then
			call PlaySoundOnUnit( Sounds[ 32 ], 100, GetTriggerUnit( ) )
			call DestroyEffect( AddSpecialEffectTarget( "war3mapImported\\DarkLightningNova.mdx", GetTriggerUnit( ), "origin" ) )
			call DestroyEffect( AddSpecialEffectTarget( "war3mapImported\\DarkNova.mdx", GetTriggerUnit( ), "origin" ) )
			call BasicAoEDMG( GetTriggerUnit( ), GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ), 800, 2000. + 20. * GetHeroStr( GetTriggerUnit( ), true ), "physical" )
		endif
    endfunction

    function Init_Ichigo takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Ichigo_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Zangetsu.j
	function Zangetsu_W takes nothing returns nothing
		local integer Time = SpellTime( )
		local real Damage

		if Time == 1 then
			set Damage = 100 + 100 * GetInt( "ALvL" )
			if GetUnitTypeId( GetUnit( "Caster" ) ) != 'H00I' then
				set Damage = Damage + 110 * GetUnitAbilityLevel( GetUnit( "Caster" ), 'A05V' )
			endif
			call SaveReal( HashTable, MUIHandle( ), StringHash( "Angle" ), GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )
			call SaveReal( HashTable, MUIHandle( ), StringHash( "MoveX" ), NewX( GetUnitX( GetUnit( "Target" ) ), 100, GetReal( "Angle" ) ) )
			call SaveReal( HashTable, MUIHandle( ), StringHash( "MoveY" ), NewY( GetUnitY( GetUnit( "Target" ) ), 100, GetReal( "Angle" ) ) )

			if IsTerrainPathable( GetReal( "MoveX" ), GetReal( "MoveY" ), PATHING_TYPE_WALKABILITY ) then
				call SaveReal( HashTable, MUIHandle( ), StringHash( "MoveX" ), NewX( GetUnitX( GetUnit( "Target" ) ), -100, GetReal( "Angle" ) ) )
				call SaveReal( HashTable, MUIHandle( ), StringHash( "MoveY" ), NewY( GetUnitY( GetUnit( "Target" ) ), -100, GetReal( "Angle" ) ) )
			endif

			call SetUnitXY_1( GetUnit( "Caster" ), GetReal( "MoveX" ), GetReal( "MoveY" ), true )
			call SaveEffectHandle( HashTable, MUIHandle( ), StringHash( "CasterEff1" ), AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\Cripple\\CrippleTarget.mdl", GetUnit( "Caster" ), "origin" ) )
			call CC_Unit( GetUnit( "Target" ), .6, "stun", true )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), Damage, "physical" )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
		endif
		
		if Time == 50 or Stop_Spells( ) then
			call DestroyEffect( GetEffect( "CasterEff1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
    function Zangetsu_R takes nothing returns nothing
		local integer Time = SpellTime( )

		if Time == 1 then
			call SaveInteger( HashTable, MUIHandle( ), StringHash( "DefaultAlpha" ), 255 )
			call SaveInteger( HashTable, MUIHandle( ), StringHash( "DeltaAlpha" ), 10 )
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitPathing( GetUnit( "Caster" ), false )
			call SetUnitAnimation( GetUnit( "Caster" ), "Stand" )
			call SaveEffectHandle( HashTable, MUIHandle( ), StringHash( "Eff1" ), AddSpecialEffectTarget( "Abilities\\Weapons\\IllidanMissile\\IllidanMissile.mdl", GetUnit( "Caster" ), "weapon" ) )
			call SaveEffectHandle( HashTable, MUIHandle( ), StringHash( "Eff2" ), AddSpecialEffectTarget( "Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnit( "Caster" ), "origin" ) )
			call SaveEffectHandle( HashTable, MUIHandle( ), StringHash( "Eff3" ), AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\Cripple\\CrippleTarget.mdl", GetUnit( "Caster" ), "origin" ) )
		endif

		if Time >= 1 and Time <= 25 then
			call SaveInteger( HashTable, MUIHandle( ), StringHash( "DefaultAlpha" ), GetInt( "DefaultAlpha" ) - GetInt( "DeltaAlpha" ) )
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, GetInt( "DefaultAlpha" ) )
		endif

		if Time == 25 then
			call MakeUnitAirborne( GetUnit( "Caster" ), 4000., 9999. )
			call SetUnitAnimation( GetUnit( "Caster" ), "Attack" )
			call SetUnitXY_1( GetUnit( "Caster" ), GetReal( "TargX" ), GetReal( "TargY" ), true )
		endif

		if Time == 50 then
			call MakeUnitAirborne( GetUnit( "Caster" ), 0., 9999. )
		endif

		if Time == 75 or Stop_Spell( 0 ) then
			if Time == 75 then
				call DestroyAoEDestruct( GetReal( "TargX" ), GetReal( "TargY" ), 400 )
				call EnumUnits_AOE( SpellGroup, GetReal( "TargX" ), GetReal( "TargY" ), 400 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
						call CC_Unit( SysUnit, 2, "stun", true )
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, 800. + 200. * GetInt( "ALvL" ), "physical" )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
				call DestroyEffect( AddSpecialEffect( "war3mapImported\\explosion.mdx", GetReal( "TargX" ), GetReal( "TargY" ) ) )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", GetUnit( "Caster" ), "origin" ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetReal( "TargX" ), GetReal( "TargY" ) ) )
			endif
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitPathing( GetUnit( "Caster" ), true )
			call SelectPlayerUnit( GetUnit( "Caster" ), true )
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 255 )
			call DestroyEffect( GetEffect( "Eff1" ) )
			call DestroyEffect( GetEffect( "Eff2" ) )
			call DestroyEffect( GetEffect( "Eff3" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
    endfunction

    function Zangetsu_T takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real MoveX
		local real MoveY
		local real Dist
		local real Angle

		if GetInt( "Executions" ) < GetInt( "ExecLimit" ) and Time <= GetInt( "TimeLimit" ) and not Stop_Spell( 0 ) then
			if Counter( 0, 30 ) then
				if GetUnit( "Target" ) != null then
					call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
					set Dist  = GetRandomReal( 70, 100 )
					set Angle = GetRandomReal(  0, 360 )				
					set MoveX = NewX( GetUnitX( GetUnit( "Target" ) ), Dist, Angle )
					set MoveY = NewY( GetUnitY( GetUnit( "Target" ) ), Dist, Angle )
					call SetUnitXY_1( GetUnit( "Caster" ), MoveX, MoveY, true )
					call DestroyEffect( AddSpecialEffect( "!Sonido!.mdx", MoveX, MoveY ) )
					call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", GetUnit( "Target" ), "chest" ) )
					call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), GetHeroStr( GetUnit( "Caster" ), true ) * 3, "physical" )
					call DestroyEffect( AddSpecialEffectTarget( "units\\nightelf\\SpiritOfVengeance\\SpiritOfVengeance.mdl", GetUnit( "Caster" ), "chest" ) )
					call Linear_Spell( GetUnit( "Caster" ), MoveX, MoveY, "WhiteGetsuga.mdx", 1800, 1200, 300, 6, 105 + 195 * GetInt( "ALvL" ), "" )
					call RemoveSavedHandle( HashTable, HandleID, StringHash( "Target" ) )
					call SaveInteger( HashTable, HandleID, StringHash( "Executions" ), GetInt( "Executions" ) + 1 )
				endif
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetRandomEnemyUnitInArea( GetInt( "PID" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 720 ) )
			endif
		else
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 255 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
    endfunction

	function Zangetsu_Spells takes nothing returns nothing
		local integer AID = GetSpellAbilityId( )
		local integer UID = GetUnitTypeId( GetTriggerUnit( ) )
		local integer PID = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL = GetUnitAbilityLevel( GetTriggerUnit( ), GetSpellAbilityId( ) )
		local integer HandleID

		if AID == 'A05T' then
			call PlaySoundOnUnit( Sounds[ 78 ], 100, GetTriggerUnit( ) )
			if UID == 'H00I' then
				call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "!BlueGetsugaTenshou!.mdx", 1500, 800, 200, 2, 110 + 115 * ALvL, "" )
			else
				call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "WhiteGetsuga.mdx", 1800, 1200, 300, 6, 105 + 195 * ALvL, "" )
			endif
		endif

		if AID == 'A05V' then
			if UID == 'H00I' then
				call CreateUnit( Player( PID ), 'oshm', 8000, 8000, bj_UNIT_FACING )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetTriggerUnit( ), "origin" ) )
				call DestroyEffect( AddSpecialEffectTarget( "war3mapImported\\FrostNova.mdx", GetTriggerUnit( ), "origin" ) )
				call PlaySoundOnUnit( Sounds[ 79 ], 100, GetTriggerUnit( ) )
				call TransformDisplace( GetTriggerUnit( ) )
			else
				call RemoveUnitOfPlayerByID( PID, 'oshm' )
			endif
		endif

		if AID == 'A05U' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 81 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Zangetsu_W )
		endif

		if AID == 'A05X' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 77 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Zangetsu_R )
		endif

		if AID == 'A060' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 80 ], 100, GetTriggerUnit( ) )
			call SetUnitVertexColor( GetTriggerUnit( ), 255, 255, 255, 125 )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "ExecLimit" ), 3 + ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "TimeLimit" ), 40 * ( 3 + ALvL ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Zangetsu_T )
		endif
	endfunction

    function Init_Zangetsu takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Zangetsu_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Rukia.j
	function Rukia_Q takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time = SpellTime( )
		
		if Time == 1 then
			call DestroyEffect( AddSpecialEffect( "Tsukishiro.mdx", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\FreezingBreath\\FreezingBreathMissile.mdl", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call DestroyAoEDestruct( GetReal( "CastX" ), GetReal( "CastY" ), 400 )
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 400 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if UnitLife( SysUnit ) > 0 then
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
						call CC_Unit( SysUnit, 1.5, "stun", true )
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, 70 + 105 * GetInt( "ALvL" ), "magical" )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Rukia_W takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time = SpellTime( )

		if Time == 1 then
			call SaveReal( HashTable, HandleID, StringHash( "Distance" ), GetAxisDistance( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), GetReal( "TargX" ), GetReal( "TargY" ) ) )
			call SaveInteger( HashTable, HandleID, StringHash( "OrderID" ), GetUnitCurrentOrder( GetUnit( "Caster" ) ) )
			call SaveInteger( HashTable, HandleID, StringHash( "TimeLimit" ), R2I( GetReal( "Distance" ) / ( SquareRoot( 2500 ) / 2 ) ) )
		endif

		if Time == 120 then
			if GetInt( "OrderID" ) == GetUnitCurrentOrder( GetUnit( "Caster" ) ) then
				call SaveBoolean( HashTable, HandleID, StringHash( "CastBool" ), true )
				call Linear_Spell( GetUnit( "Caster" ), GetReal( "TargX" ), GetReal( "TargY" ), "Abilities\\Spells\\Undead\\AbsorbMana\\AbsorbManaBirthMissile.mdl", 2500, GetReal( "Distance" ), 0, 3, 0, "" )
			endif
		endif

		if GetBool( "CastBool" ) then
			if Time == GetInt( "TimeLimit" ) + 120 then
				call SaveEffectHandle( HashTable, HandleID, StringHash( "Eff1" ), AddSpecialEffect( "AncientExplode.mdx", GetReal( "TargX" ), GetReal( "TargY" ) ) )
				call DestroyAoEDestruct( GetReal( "TargX" ), GetReal( "TargY" ), 400 )
				call EnumUnits_AOE( SpellGroup, GetReal( "TargX" ), GetReal( "TargY" ), 400 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
						call CC_Unit( SysUnit, 1.4, "stun", true )
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, 500. + 100. * GetInt( "ALvL" ) + 20 * GetHeroLevel( GetUnit( "Caster" ) ), "magical" )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
			endif
		endif

		if Time == GetInt( "TimeLimit" ) + 220 or Stop_Spell( 0 ) then
			call DestroyEffect( GetEffect( "Eff1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function CreateNewHakuren takes real OldX, real OldY, real Dist, real Angle, real Change, boolean Damage returns nothing
		local real MoveX = NewX( OldX, Dist, Angle + Change )
		local real MoveY = NewY( OldY, Dist, Angle + Change )
		
		call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", MoveX, MoveY ) )
		if Damage then
			call EnumUnits_AOE( SpellGroup, MoveX, MoveY, 200 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) and not IsUnitIgnored( SysUnit ) then
					call CC_Unit( SysUnit, 3, "stun", true )
					call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", SysUnit, "origin" ) )
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, 150. + 150. * GetUnitAbilityLevel( GetUnit( "Caster" ), 'A062' ), "magical" )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif
	endfunction

	function Rukia_E takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if not Stop_Spell( 0 ) and not IsUnitPaused( GetUnit( "Caster" ) ) and Time <= 170 then
			if Time == 1 then
				call SaveReal( HashTable, HandleID, StringHash( "Change" ), 45 )
				call SaveInteger( HashTable, HandleID, StringHash( "OrderID" ), GetUnitCurrentOrder( GetUnit( "Caster" ) ) )
				call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetUnit( "Caster" ), GetReal( "TargX" ), GetReal( "TargY" ) ) )
			endif

			if Time <= 100 then
				if GetInt( "OrderID" ) == GetUnitCurrentOrder( GetUnit( "Caster" ) ) then
					if Counter( 0, 20 ) then
						call CreateNewHakuren( GetReal( "CastX" ), GetReal( "CastY" ), 200, GetReal( "Angle" ), GetReal( "Change" ), false )
						call SaveReal( HashTable, HandleID, StringHash( "Change" ), GetReal( "Change" ) - 22.5 )
					endif
				else
					call CleanMUI( GetExpiredTimer( ) )
				endif
			endif

			if Time == 100 then
				call SaveReal( HashTable, HandleID, StringHash( "CastX" ), NewX( GetReal( "CastX" ), 200, GetReal( "Angle" ) ) )
				call SaveReal( HashTable, HandleID, StringHash( "CastY" ), NewY( GetReal( "CastY" ), 200, GetReal( "Angle" ) ) )
				call SaveBoolean( HashTable, HandleID, StringHash( "CastBool" ), true )
				call IssueImmediateOrder( GetUnit( "Caster" ), "stop" )
				call SetUnitAnimation( GetUnit( "Caster" ), "spell" )
				call PlaySoundOnUnit( Sounds[ 56 ], 100, GetUnit( "Caster" ) )
			endif

			if Time >= 100 and Time <= 170 and GetBool( "CastBool" ) then
				if Counter( 1, 10 ) then
					call SaveReal( HashTable, HandleID, StringHash( "MoveX" ), NewX( GetReal( "CastX" ), 200 * GetInt( "HakurenIterator" ), GetReal( "Angle" ) ) )
					call SaveReal( HashTable, HandleID, StringHash( "MoveY" ), NewY( GetReal( "CastY" ), 200 * GetInt( "HakurenIterator" ), GetReal( "Angle" ) ) )
					call CreateNewHakuren( GetReal( "MoveX" ), GetReal( "MoveY" ), 0, GetReal( "Angle" ), 0, false )
					if GetInt( "HakurenIterator" ) >= 2 then
						call CreateNewHakuren( GetReal( "MoveX" ), GetReal( "MoveY" ), 400, GetReal( "Angle" ), 90, true )
						call CreateNewHakuren( GetReal( "MoveX" ), GetReal( "MoveY" ), 400, GetReal( "Angle" ), -90, true )
					endif
					call CreateNewHakuren( GetReal( "MoveX" ), GetReal( "MoveY" ), 200, GetReal( "Angle" ), 90, true )
					call CreateNewHakuren( GetReal( "MoveX" ), GetReal( "MoveY" ), 200, GetReal( "Angle" ), -90, true )
					call SaveInteger( HashTable, HandleID, StringHash( "HakurenIterator" ), GetInt( "HakurenIterator" ) + 1 )
				endif
			endif
		else
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Rukia_R takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time = SpellTime( )

		if Time == 1 then
			call PlaySoundOnUnit( Sounds[ 58 ], 100, GetUnit( "Caster" ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Shirafune" ), CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'otau', 8000, 8000, bj_UNIT_FACING ) )
		endif

		if Time == 3000 or UnitLife( GetUnit( "Caster" ) ) <= 0 then
			call KillUnit( GetUnit( "Shirafune" ) )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'B00L' )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Rukia_T takes nothing returns nothing
		local integer Time = SpellTime( )

		if Time == 1 then
			call CC_Unit( GetUnit( "Target" ), 1, "stun", true )
			call PlaySoundOnUnit( Sounds[ 59 ], 100, GetUnit( "Caster" ) )
			call SaveEffectHandle( HashTable, GetHandleId( GetUnit( "Target" ) ), StringHash( "WhiteDance" ), AddSpecialEffectTarget( "Abilities\\Spells\\Items\\AIso\\BIsvTarget.mdl", GetUnit( "Target" ), "chest" ) )
		endif

		if Time == 1500 or Stop_Spell( 2 ) then
			call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( GetUnit( "Target" ) ), StringHash( "WhiteDance" ) ) )
			call RemoveSavedHandle( HashTable, GetHandleId( GetUnit( "Target" ) ), StringHash( "WhiteDance" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Rukia_Spells takes nothing returns nothing
		local real LocX = GetUnitX( GetTriggerUnit( ) )
		local real LocY = GetUnitY( GetTriggerUnit( ) )
		local integer AID = GetSpellAbilityId( )
		local integer ALvL = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID = GetUnitTypeId( GetTriggerUnit( ) )
		local integer PID = GetPlayerId( GetTriggerPlayer( ) )
		local integer HandleID

		if AID == 'A04D' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 55 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), LocX )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), LocY )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Rukia_Q )
		endif

		if AID == 'A0AN' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 57 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Rukia_W )
		endif
		
		if AID == 'A062' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), LocX )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), LocY )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Rukia_E )
		endif

		if AID == 'A064' then
			set HandleID = NewMUITimer( PID )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), LocX )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), LocY )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Rukia_R )
		endif

		if AID == 'A06C' then
			set HandleID = NewMUITimer( PID )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Rukia_T )
		endif
	endfunction

    function Init_Rukia takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Rukia_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Chad.j
	function Chad_Q takes unit Caster, real TargX, real TargY returns nothing
		local real ALvL = GetUnitAbilityLevel( Caster, 'A03R' )
		local real Size = ( 20 + 40  * ALvL ) * .01
		local real AoE 	=   95 + 55  * ALvL
		local real DMG 	=  110 + 115 * ALvL
		local real Dist =  350 + 150 * ALvL
		local real SPD	= 1200

		call PlaySoundOnUnit( Sounds[ 17 ], 100, Caster )
		call Linear_Spell( Caster, TargX, TargY, "ElDirectoMissile.mdx", SPD, Dist, AoE, Size, DMG, "" )
	endfunction

	function Chad_E takes nothing returns nothing
		local integer Time = SpellTime( )
		
		if Time == 1 then
			call CircularEffect( GetUnit( "Caster" ), 300, 45, "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl" )
			call CircularEffect( GetUnit( "Caster" ), 500, 45, "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl" )
			call CircularEffect( GetUnit( "Caster" ), 700, 45, "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl" )
			call DestroyAoEDestruct( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 800 )
			call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 800 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
					call CC_Unit( SysUnit, 1.25, "stun", true )
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, 300. + 100. * GetInt( "ALvL" ), "physical" )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time == 50 then
			call IssueImmediateOrder( GetUnit( "Caster" ), "stop" )
			call SetUnitAnimation( GetUnit( "Caster" ), "spell one alternate" )
			call SelectUnitRemoveForPlayer( GetUnit( "Caster" ), Player( GetInt( "PID" ) ) )
			call CircularEffect( GetUnit( "Caster" ), 300, 45, "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl" )
			call CircularEffect( GetUnit( "Caster" ), 500, 45, "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl" )
			call CircularEffect( GetUnit( "Caster" ), 700, 45, "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl" )
			call DestroyAoEDestruct( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 800 )
			call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 800 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
					call CC_Unit( SysUnit, 1.25, "stun", true )
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, 4 * GetHeroStr( GetUnit( "Caster" ), true ), "physical" )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time == 15 + GetInt( "TimeLimit" ) or Stop_Spell( 0 ) then
			call SelectPlayerUnit( GetUnit( "Caster" ), false )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Chad_T takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitInvul( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "attack one alternate" )
			call SetUnitTimeScale( GetUnit( "Caster" ), .4 )
			call PlaySoundOnUnit( Sounds[ 19 ], 100, GetUnit( "Caster" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile_mini.mdl", GetUnit( "Caster" ), "hand right" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_2" ), AddSpecialEffectTarget( "Abilities\\Weapons\\IllidanMissile\\IllidanMissile.mdl", GetUnit( "Caster" ), "hand left" ) )
			call SetUnitXY_1( GetUnit( "Caster" ), NewX( GetUnitX( GetUnit( "Target" ) ), -75, GetReal( "Angle" ) ), NewY( GetUnitY( GetUnit( "Target" ) ), -75, GetReal( "Angle" ) ), true )
			call SetUnitFacing( GetUnit( "Caster" ), GetReal( "Angle" ) )
		endif

		if Time >= 1 and Time <= 150 then
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), .1 * GetHeroStr( GetUnit( "Caster" ), true ), "physical" )
			if not IsTerrainPathable( NewX( GetUnitX( GetUnit( "Target" ) ), 15, GetReal( "Angle" ) ), NewY( GetUnitY( GetUnit( "Target" ) ), 15, GetReal( "Angle" ) ), PATHING_TYPE_WALKABILITY ) then
				call SetUnitXY_1( GetUnit( "Target" ), NewX( GetUnitX( GetUnit( "Target" ) ), 15, GetReal( "Angle" ) ), NewY( GetUnitY( GetUnit( "Target" ) ), 15, GetReal( "Angle" ) ), true )
				call SetUnitXY_1( GetUnit( "Caster" ), NewX( GetUnitX( GetUnit( "Caster" ) ), 15, GetReal( "Angle" ) ), NewY( GetUnitY( GetUnit( "Caster" ) ), 15, GetReal( "Angle" ) ), true )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
				call DestroyAoEDestruct( GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 300 )
			else
				call SaveInteger( HashTable, HandleID, StringHash( "SpellTime" ), 149 )
			endif
		endif

		if Time == 150 or Stop_Spell( 2 ) then
			if Time == 150 then
				call DestroyEffect( AddSpecialEffect( "war3mapImported\\explosion.mdx", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
				call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
				call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 6. * GetHeroStr( GetUnit( "Caster" ), true ) * GetInt( "ALvL" ), "physical" )
				call CC_Unit( GetUnit( "Target" ), 1.5, "stun", true )
				if HasItem( GetUnit( "Target" ), 'I007' ) then
					call CC_Unit( GetUnit( "Target" ), 1.5, "stun", true )
				endif
			endif

			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call SetUnitAnimation( GetUnit( "Caster" ), "Stand" )
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call DestroyEffect( GetEffect( "Effect_2" ) )
			call PauseUnit( GetUnit( "Caster" ), false )
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitInvul( GetUnit( "Caster" ), false )
			call SelectPlayerUnit( GetUnit( "Caster" ), true )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
    function Chad_Spells takes nothing returns nothing
		local integer AID = GetSpellAbilityId( )
		local integer ALvL   = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID 	 = GetUnitTypeId( GetTriggerUnit( ) )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer HandleID

		if AID == 'A03R' then
			call Chad_Q( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) )
		endif

		if AID == 'A03T' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call PlaySoundOnUnit( Sounds[ 16 ], 100, GetTriggerUnit( ) )
			if UID == 'H004' then
				call SetUnitAnimation( GetTriggerUnit( ), "spell one" )
			else
				call SetUnitAnimation( GetTriggerUnit( ), "spell one alternate" )
				call SaveInteger( HashTable, HandleID, StringHash( "TimeLimit" ), 40 )
			endif
			call TimerStart( LoadMUITimer( PID ), .01, true, function Chad_E )
		endif

		if AID == 'A08J' then
			if UID == 'H004' then
				call CreateUnit( Player( PID ), 'ospw', 8000, 8000, bj_UNIT_FACING )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\HowlOfTerror\\HowlCaster.mdl", GetTriggerUnit( ), "origin" ) )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\OrbOfDeath\\AnnihilationMissile.mdl", GetTriggerUnit( ), "origin" ) )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\NightElf\\MoonWell\\MoonWellCasterArt.mdl", GetTriggerUnit( ), "origin" ) )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl", GetTriggerUnit( ), "origin" ) )
				call PlaySoundOnUnit( Sounds[ 18 ], 100, GetTriggerUnit( ) )
			else
				call RemoveUnitOfPlayerByID( PID, 'ospw' )
			endif
		endif

		if AID == 'A043' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitsAngle( GetTriggerUnit( ), GetSpellTargetUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Chad_T )
		endif
    endfunction

    function Init_Chad takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Chad_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Inoue.j
	function Inoue_W takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call Init_DamagedCheck( GetUnit( "Target" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Shield_Effect" ), AddSpecialEffectTarget( "YellowShield.mdx", GetUnit( "Target" ), "origin" ) )
			call SaveReal( HashTable, GetHandleId( GetUnit( "Target" ) ), StringHash( "Inoue_Damage_Blocked" ), 10. + 20. * GetInt( "ALvL" ) + GetHeroInt( GetUnit( "Caster" ), true ) )
		endif

		if Time == GetReal( "Duration" ) or UnitLife( GetUnit( "Target" ) ) <= 0 then
			call SaveReal( HashTable, GetHandleId( GetUnit( "Target" ) ), StringHash( "Inoue_Damage_Blocked" ), 0 )
			call DestroyEffect( GetEffect( "Shield_Effect" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Inoue_E takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect1" ), AddSpecialEffectTarget( "Abilities\\Spells\\Items\\StaffOfSanctuary\\Staff_Sanctuary_Target.mdl", GetUnit( "Target"  ), "chest" ) )
		endif

		if Counter( 0, 100 ) then
			call SetWidgetLife( GetUnit( "Target" ), GetUnitState( GetUnit( "Target" ), UNIT_STATE_LIFE ) + 1.5 * GetHeroInt( GetUnit( "Caster" ), true ) )
			call SetUnitState(  GetUnit( "Target" ), UNIT_STATE_MANA, GetUnitState( GetUnit( "Target" ), UNIT_STATE_MANA ) + .75 * GetHeroInt( GetUnit( "Caster" ), true ) )
		endif

		if Time == 700 or UnitLife( GetUnit( "Target" ) ) <= 0 then
			call DestroyEffect( GetEffect( "Effect1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Inoue_T takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy1" ), CreateUnit( Player( GetInt( "PID" ) ), 'h00O', GetReal( "TargX" ), GetReal( "TargY" ), bj_UNIT_FACING ) )
			call ScaleUnit( GetUnit( "Dummy1" ), 7.4 )
		endif
		
		if Time >= 1 then
			if Counter( 0, 130 ) then
				call EnumUnits_AOE( SpellGroup, GetReal( "TargX" ), GetReal( "TargY" ), 600 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if DefaultFilter( SysUnit ) then
						if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
							if UnitLife( SysUnit ) > 0 then
								if not IsUnitPaused( SysUnit ) then
									call SetUnitTimeScale( SysUnit, 0 )
									call PauseUnit( SysUnit, true )
								endif
								if not IsUnitInGroup( SysUnit, GetGroup( "Inoue_T_Group" ) ) then
									call GroupAddUnit( GetGroup( "Inoue_T_Group" ), SysUnit )
								endif
								call Damage_Unit( GetUnit( "Caster" ), SysUnit, 3. * GetHeroInt( GetUnit( "Caster" ), true ), "magical" )
								call SetUnitManaBJ( SysUnit, GetUnitState( SysUnit, UNIT_STATE_MANA ) - 1.5 * GetHeroInt( GetUnit( "Caster" ), true ) )
								call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", SysUnit, "origin" ) )
							else
								call SetUnitTimeScale( SysUnit, 1 )
								call PauseUnit( SysUnit, false )
								call GroupRemoveUnit( GetGroup( "Inoue_T_Group" ), SysUnit )
							endif
						else
							if UnitLife( SysUnit ) > 0 then
								call SetWidgetLife( SysUnit, GetUnitState( SysUnit, UNIT_STATE_LIFE ) + GetHeroInt( GetUnit( "Caster" ), true ) )
								call SetUnitManaBJ( SysUnit, GetUnitState( SysUnit, UNIT_STATE_MANA ) + GetHeroInt( GetUnit( "Caster" ), true ) / 2. )
								call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", SysUnit, "origin" ) )
							endif
						endif
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
			endif
		endif

		if Time == 70 then
			call SetUnitTimeScale( GetUnit( "Dummy1" ), 0 )
		endif

		if Time == GetInt( "Limit" ) or Stop_Spell( 0 ) then
			loop
				set SysUnit = FirstOfGroup( GetGroup( "Inoue_T_Group" ) )
				exitwhen SysUnit == null
				call PauseUnit( SysUnit, false )
				call SetUnitTimeScale( SysUnit, 1 )
				if UnitLife( SysUnit ) > 0 then
					call SetUnitAnimation( SysUnit, "stand" )
				endif
				call GroupRemoveUnit( GetGroup( "Inoue_T_Group" ), SysUnit )
			endloop
			call RemoveUnit( GetUnit( "Dummy1" ) )
			call DestroyGroup( GetGroup( "Inoue_T_Group" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Inoue_Spells takes nothing returns nothing
		local integer AID = GetSpellAbilityId( )
		local integer ALvL	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID 	 = GetUnitTypeId( GetTriggerUnit( ) )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer HandleID

		if AID == 'A07K' then
			call PlaySoundOnUnit( Sounds[ 41 ], 100, GetTriggerUnit( ) )
			call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "Abilities\\Weapons\\SorceressMissile\\SorceressMissile.mdl", 1200, 1500, 200, 3, 110 + 115 * ALvL, "" )
		endif

		if AID == 'A063' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 42 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Duration" ), ( 2 + ALvL ) * 100 )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Inoue_W )
		endif

		if AID == 'A0AP' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 43 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Inoue_E )
		endif

		if AID == 'A07N' or AID == 'A08D' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 44 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "Limit" ), ( 4 + ALvL ) * 100 )
			call SaveGroupHandle( HashTable, HandleID, StringHash( "Inoue_T_Group" ), CreateGroup( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Inoue_T )
		endif
    endfunction
	
    function Init_Inoue takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Inoue_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Ishida.j
	function ResetGinrei takes nothing returns nothing
		call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "GinreiEff" ) ) )
		call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "GinreiActive" ), false )
		call FlushChildHashtable( HashTable, GetHandleId( GetExpiredTimer( ) ) )
	endfunction

    function Ishida_Q takes unit Source returns nothing
		local integer HandleID
		call SaveInteger( HashTable, GetHandleId( Source ), StringHash( "GinreiCount" ), 0 )
		call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( Source ), StringHash( "GinreiEff" ) ) )
		call SaveEffectHandle( HashTable, GetHandleId( Source ), StringHash( "GinreiEff" ), AddSpecialEffectTarget( "BlueRibbonMissile.mdx", Source, "weapon" ) )
		call SaveBoolean( HashTable, GetHandleId( Source ), StringHash( "GinreiActive" ), true )
		set HandleID = PTimer( Source, "GinreiTimer" )
		call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), Source )
		call TimerStart( LoadTimerHandle( HashTable, GetHandleId( Source ), StringHash( "GinreiTimer" ) ), 6, false, function ResetGinrei )
    endfunction

	function Ishida_W takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )
		local real MoveX
		local real MoveY
		local real Rand1
		local real Rand2
		local real DMG

		if GetInt( "ShotsFired" ) <= GetInt( "ShotLimit" ) then
			if Time == 1 then
				set MoveX = NewX( GetReal( "CastX" ), 120, GetReal( "Angle" ) )
				set MoveY = NewY( GetReal( "CastY" ), 120, GetReal( "Angle" ) )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy1" ), CreateUnit( Player( GetInt( "PID" ) ), 'h01A', MoveX, MoveY, GetReal( "Angle" ) ) )
				call ScaleUnit( GetUnit( "Dummy1" ), 1.9 )
				call SetUnitFlyHeight( GetUnit( "Dummy1" ), 900., 2000. )
			endif
			
			if Time >= 1 and Time <= 50 then
				call SetUnitXY_1( GetUnit( "Dummy1" ), NewX( GetUnitX( GetUnit( "Dummy1" ) ), GetReal( "Move" ), GetReal( "Angle" ) ), NewY( GetUnitY( GetUnit( "Dummy1" ) ), GetReal( "Move" ), GetReal( "Angle" ) ), true )
			endif
			
			if Time == 50 then
				call RemoveUnit( GetUnit( "Dummy1" ) )
			endif

			if Time >= GetInt( "Init" ) then
				if Counter( 0, 3 ) then
					set Rand1 = GetRandomReal( 0, 300. )
					set Rand2 = GetRandomReal( 0, 360. )
					set MoveX = NewX( GetReal( "TargX" ), Rand1, Rand2 )
					set MoveY = NewY( GetReal( "TargY" ), Rand1, Rand2 )
					call SaveInteger( HashTable, HandleID, StringHash( "ShotsFired" ), GetInt( "ShotsFired" ) + 1 )
					set Dummy = CreateUnit( Player( GetInt( "PID" ) ), 'h01I', MoveX, MoveY, Rand2 )
					call SetUnitTimeScale( Dummy, 3. )
					call UnitApplyTimedLife( Dummy, 'BTLF', .6 )

					if GetUnitTypeId( GetUnit( "Caster" ) ) != 'EC08' then
						set DMG = 2.25 * GetHeroAgi( GetUnit( "Caster" ), false )
					else
						set DMG = 1.5 * GetHeroAgi( GetUnit( "Caster" ), false )
					endif

					call DestroyAoEDestruct( MoveX, MoveY, 220 )
					call EnumUnits_AOE( SpellGroup, MoveX, MoveY, 220 )
					loop
						set SysUnit = FirstOfGroup( SpellGroup )
						exitwhen SysUnit == null
						if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
							call CC_Unit( SysUnit, .1, "stun", true )
							call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "physical" )
						endif
						call GroupRemoveUnit( SpellGroup, SysUnit )
					endloop
				endif
			endif
		else
			call RemoveUnit( GetUnit( "Dummy1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Ishida_E takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
            call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\Invisibility\\InvisibilityTarget.mdl", GetUnit( "Caster" ), "weapon" ) )
			if GetUnitTypeId( GetUnit( "Caster" ) ) != 'EC08' then
				set Time = 150
			endif
		endif

		if Time == 10 then
			call SetUnitTimeScale( GetUnit( "Caster" ), 0 )
		endif

		if Time == 150 then
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call IssueImmediateOrder( GetUnit( "Caster" ), "stop" )
			call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
			call PlaySoundOnUnit( Sounds[ 46 ], 100, GetUnit( "Caster" ) )
			call Linear_Spell( GetUnit( "Caster" ), GetReal( "TargX" ), GetReal( "TargY" ), "SeeleSchneider.mdx", 2000, 3500, 200, 1.5, 400 + 350 * GetInt( "ALvL" ), "" )
			call CleanMUI( GetExpiredTimer( ) )
		endif

		if GetUnitOrder( GetUnit( "Caster" ) ) != GetStr( "Order" ) or Stop_Spell( 0 ) then
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Ishida_R takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )
		local real Angle = 0
		local real LocX = GetReal( "CastX" )
		local real LocY = GetReal( "CastY" )
		local real MoveX
		local real MoveY
		
		if Time == 1 then
			call PlaySoundOnUnit( Sounds[ 45 ], 100, GetUnit( "Caster" ) )

			set i = 1
			loop // Inner
				exitwhen i > 5
				set Angle = Angle + 72.
				set MoveX = NewX( LocX, 600, Angle )
				set MoveY = NewY( LocY, 600, Angle )
				call SaveEffectHandle( HashTable, HandleID, StringHash( "PoleEff" + I2S( i ) ), AddSpecialEffect( "Sprenger.mdx", MoveX, MoveY ) )
				call SaveEffectHandle( HashTable, HandleID, StringHash( "FireEff" + I2S( i ) ), AddSpecialEffect( "Doodads\\Cinematic\\TownBurningFireEmitterBlue\\TownBurningFireEmitterBlue.mdl", MoveX, MoveY ) )
				call SaveLightningHandle( HashTable, HandleID, StringHash( "InnerLight" + I2S( i ) ), AddLightningEx( "DRAM", true, LocX, LocY, -120, MoveX, MoveY, -120 ) )
				set i = i + 1
			endloop
		endif
		
		if Time == 180 then
			set i = 1
			loop // Outer
				exitwhen i > 5
				set Angle = Angle + 72.
				set MoveX = NewX( LocX, 600, Angle )
				set MoveY = NewY( LocY, 600, Angle )
				call SaveLightningHandle( HashTable, HandleID, StringHash( "OuterLight" + I2S( i ) ), AddLightningEx( "DRAM", true, MoveX, MoveY, -120, NewX( LocX, 600, Angle + 72 ), NewY( LocY, 600, Angle + 72 ), -120 ) )
				set i = i + 1
			endloop
		endif

		if Time == 250 or Stop_Spell( 0 ) then
			set i = 1
			loop // End
				exitwhen i > 5
				set Angle = Angle + 72.
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", NewX( LocX, 600, Angle ), NewY( LocY, 600, Angle ) ) )
				call DestroyEffect( GetEffect( "PoleEff" + I2S( i ) ) )
				call DestroyEffect( GetEffect( "FireEff" + I2S( i ) ) )
				call DestroyLightning( GetLightning( "InnerLight" + I2S( i ) ) )
				call DestroyLightning( GetLightning( "OuterLight" + I2S( i ) ) )
				set i = i + 1
			endloop

			if Time == 250 then
				call CreateUnit_S_L( CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h009', GetReal( "CastX" ), GetReal( "CastY" ), 270 ), 3, 4 )
				call CreateUnit_S_L( CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h009', GetReal( "CastX" ), GetReal( "CastY" ), 270 ), 1.2, 5 )
				call BasicAoEDMG( GetUnit( "Caster" ), GetReal( "CastX" ), GetReal( "CastY" ), 600, 500. + 400. * GetInt( "ALvL" ), "magical" )
			endif
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Ishida_T takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if not GetBool( "FormEnded" ) and ( Time == 5000 or UnitLife( GetUnit( "Caster" ) ) <= 0 ) then
			call SaveInteger( HashTable, HandleID, StringHash( "EndTime" ), Time )
			call SaveBoolean( HashTable, HandleID, StringHash( "FormEnded" ), true )
		endif

		if not GetBool( "FormEnded" ) then
			if Time == 1 then
				set i = 1
				loop
					exitwhen i > 3
					set SysUnit = CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h009', GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), bj_UNIT_FACING )
					call ScaleUnit( SysUnit, 2.2 )
					call SetUnitTimeScale( SysUnit, 1.5 * i )
					call UnitApplyTimedLife( SysUnit, 'BTLF', 3. )
					set i = i + 1
				endloop
				call SetHeroAgi( GetUnit( "Caster" ), GetHeroAgi( GetUnit( "Caster" ), false ) + 60, true )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnit( "Caster" ), "origin" ) )
				call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\NightElf\\NECancelDeath\\NECancelDeath.mdl", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
				call PlaySoundOnUnit( Sounds[ 49 ], 100, GetUnit( "Caster" ) )
				call TransformDisplace( GetUnit( "Caster" ) )
			endif

			if Counter( 0, 100 ) then
				call SetUnitState( GetUnit( "Caster" ), UNIT_STATE_MANA, GetUnitState( GetUnit( "Caster" ), UNIT_STATE_MANA ) + 60. )
				call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 100 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
						call SetUnitState( SysUnit, UNIT_STATE_MANA, GetUnitState( SysUnit, UNIT_STATE_MANA ) - 60. )
						call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\PriestMissile\\PriestMissile.mdl", SysUnit, "chest" ) )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
			endif
		else
			if Time == GetInt( "EndTime" ) + 1 then	
				call SetHeroAgi( GetUnit( "Caster" ), GetHeroAgi( GetUnit( "Caster" ), false ) - 60, true )
				call SaveInteger( HashTable, HandleID, StringHash( "STR" ), R2I( .8 * GetHeroStr( GetUnit( "Caster" ), false ) ) )
				call SaveInteger( HashTable, HandleID, StringHash( "AGI" ), R2I( .8 * GetHeroAgi( GetUnit( "Caster" ), false ) ) )
				call SaveInteger( HashTable, HandleID, StringHash( "INT" ), R2I( .8 * GetHeroInt( GetUnit( "Caster" ), false ) ) )
				call SetHeroStr( GetUnit( "Caster" ), GetHeroStr( GetUnit( "Caster" ), false ) - GetInt( "STR" ), true )
				call SetHeroAgi( GetUnit( "Caster" ), GetHeroAgi( GetUnit( "Caster" ), false ) - GetInt( "AGI" ), true )
				call SetHeroInt( GetUnit( "Caster" ), GetHeroInt( GetUnit( "Caster" ), false ) - GetInt( "INT" ), true )
				call RemoveUnitOfPlayerByID( GetInt( "PID" ), 'opeo' )
				call SetUnitState( GetUnit( "Caster" ), UNIT_STATE_MANA, 0 )
			endif

			if Time == GetInt( "EndTime" ) + 1500 then
				call CreateUnit( Player( GetInt( "PID" ) ), 'opeo', 8000, 8000, bj_UNIT_FACING )
				call SetHeroStr( GetUnit( "Caster" ), GetHeroStr( GetUnit( "Caster" ), false ) + GetInt( "STR" ), true )
				call SetHeroAgi( GetUnit( "Caster" ), GetHeroAgi( GetUnit( "Caster" ), false ) + GetInt( "AGI" ), true )
				call SetHeroInt( GetUnit( "Caster" ), GetHeroInt( GetUnit( "Caster" ), false ) + GetInt( "INT" ), true )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", GetUnit( "Caster" ), "origin" ) )
				call CleanMUI( GetExpiredTimer( ) )
			endif
		endif
	endfunction

	function Ishida_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer ALvL	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID 	 = GetUnitTypeId( GetTriggerUnit( ) )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer Init	 = 250

		if AID == 'A0AV' then
			call PlaySoundOnUnit( Sounds[ 47 ], 100, GetTriggerUnit( ) )
			call Ishida_Q( GetTriggerUnit( ) )
		endif

		if AID == 'A0D7' then
			if UID != 'EC08' then
				set Init = 150
			endif
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 48 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "Init"  ), Init ) // ( 1.5 + .1 * ( 10 + 3 * ALvL ) ) * 100
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ShotLimit"  ), 10 + 3 * ALvL )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Move"  ), GetAxisDistance( GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ), GetSpellTargetX( ), GetSpellTargetY( ) ) / 100 ) // 12.5
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ishida_W )
		endif

		if AID == 'A04W' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call SaveStr( HashTable, HandleID, StringHash( "Order" ), GetUnitOrder( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ishida_E )
		endif

		if AID == 'A04X' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ishida_R )
		endif

		if AID == 'A0AT' then
			if UID == 'EC08' then
				set HandleID = NewMUITimer( PID )
				call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
				call TimerStart( LoadMUITimer( PID ), .01, true, function Ishida_T )
			endif
		endif
    endfunction

    function Init_Ishida takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Ishida_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Renji.j
	function GetZabimaru takes unit Owner, string HashName returns unit
		return LoadUnitHandle( HashTable, GetHandleId( Owner ), StringHash( HashName ) )
	endfunction

	function Renji_Q takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )
		local real MoveX
		local real MoveY
		local real Angle
		local real DMG
		
		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "attack slam" )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'A0BM' )
			call SetUnitTimeScale( GetUnit( "Caster" ), .6 )
			call SaveReal( HashTable, HandleID, StringHash( "AngleChange" ), -90 )
			set i = 1
			loop
				exitwhen i > 18
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Zabimaru_" + I2S( i ) ), CreateUnit( Player( GetInt( "PID" ) ), 'h01R', GetReal( "CastX" ), GetReal( "CastY" ), GetReal( "Angle" ) ) )
				call ScaleUnit( GetUnit( "Zabimaru_" + I2S( i ) ), .3 + .04 * i )
				set i = i + 1
			endloop
		endif
		
		if Time > 1 then
			if GetInt( "Delay" ) == 1 then
				call SaveInteger( HashTable, HandleID, StringHash( "Delay" ), 0 )
				call SaveReal( HashTable, HandleID, StringHash( "AngleChange" ), GetReal( "AngleChange" ) + 10 )
				set Angle = GetReal( "Angle" ) + GetReal( "AngleChange" )
				set i = 1
				loop
					exitwhen i > 18
					set MoveX = NewX( GetReal( "CastX" ), 25 * i, Angle )
					set MoveY = NewY( GetReal( "CastY" ), 25 * i, Angle )
					call SetUnitXY_1( GetUnit( "Zabimaru_" + I2S( i ) ), MoveX, MoveY, true )
					call SetUnitFacingTimed( GetUnit( "Zabimaru_" + I2S( i ) ), Angle, 0 )
					call EnumUnits_AOE( SpellGroup, MoveX, MoveY, 100 )
					loop
						set SysUnit = FirstOfGroup( SpellGroup )
						exitwhen SysUnit == null
						if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and not IsUnitIgnored( SysUnit ) then
							set DMG = 100. + 100. * GetInt( "ALvL" ) + ( 2. + .5 * GetInt( "ALvL" ) ) * GetHeroStr( GetUnit( "Caster" ), true )
							call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "physical" )
							call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", SysUnit, "chest" ) )
						endif
						call GroupRemoveUnit( SpellGroup, SysUnit )
					endloop
					call DestroyAoEDestruct( MoveX, MoveY, 100 )
					set i = i + 1
				endloop
			else
				call SaveInteger( HashTable, HandleID, StringHash( "Delay" ), GetInt( "Delay" ) + 1 )
			endif

			if GetReal( "AngleChange" ) > 90 or Stop_Spell( 0 ) then
				set i = 1
				loop
					exitwhen i > 18
					call RemoveUnit( GetUnit( "Zabimaru_" + I2S( i ) ) )
					set i = i + 1
				endloop
				call UnitAddAbility( GetUnit( "Caster" ), 'A0BM' )
				call PauseUnit( GetUnit( "Caster" ), false )
				call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
				call SetUnitAnimation( GetUnit( "Caster" ), "Stand" )
				call CleanMUI( GetExpiredTimer( ) )
			endif
		endif
	endfunction

	function Renji_W takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		
		if Time == 40 and GetUnitOrder( GetUnit( "Caster" ) ) == GetStr( "Order" ) then
			call PlaySoundOnUnit( Sounds[ 52 ], 100, GetUnit( "Caster" ) )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			call DestroyEffect( AddSpecialEffect( "war3mapImported\\explosion.mdx", GetReal( "TargX" ), GetReal( "TargY" ) ) )
			call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", GetReal( "TargX" ), GetReal( "TargY" ) ) )
			call EnumUnits_AOE( SpellGroup, GetReal( "TargX" ), GetReal( "TargY" ), 300 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if DefaultUnitFilter( SysUnit ) and ( SysUnit == GetUnit( "Caster" ) or IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) ) then
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, 500. + 100. * GetInt( "ALvL" ) + 20. * GetHeroLevel( GetUnit( "Caster" ) ), "physical" )
					call CC_Unit( SysUnit, .5, "stun", true )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time == 40 or Stop_Spell( 0 ) then
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Renji_E takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )
		local real MoveX
		local real MoveY

		if Time == 1 then
			call UnitRemoveAbility( GetUnit( "Caster" ), 'A0BM' )
			call RemoveUnitOfPlayerByID( GetPlayerId( GetOwningPlayer( GetUnit( "Caster" ) ) ), 'edoc' )
			call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "AttackDisabled" ), true )
			set i = 1
			loop
				exitwhen i > 8
				if GetRandomInt( 1, 100 ) <= 50 then
					set Dummy = CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h01S', GetReal( "CastX" ), GetReal( "CastY" ), i * 45. )
				else
					set Dummy = CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h01T', GetReal( "CastX" ), GetReal( "CastY" ), i * 45. )
				endif
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Zabimaru_" + I2S( i ) ), Dummy )
				call SetUnitFlyHeight( GetUnit( "Zabimaru_" + I2S( i ) ), 300, 500. )
				set i = i + 1
			endloop
		endif
		
		if Time >= 1 and Time <= 30 then
			set i = 1
            loop
                exitwhen i > 8
				set MoveX = NewX( GetUnitX( GetUnit( "Zabimaru_" + I2S( i ) ) ), 10, GetUnitFacing( GetUnit( "Zabimaru_" + I2S( i ) ) ) )
				set MoveY = NewY( GetUnitY( GetUnit( "Zabimaru_" + I2S( i ) ) ), 10, GetUnitFacing( GetUnit( "Zabimaru_" + I2S( i ) ) ) )
                call SetUnitXY_1( GetUnit( "Zabimaru_" + I2S( i ) ), MoveX, MoveY, true )
                set i = i + 1
            endloop
		endif
		
		if Time > 30 then
			set i = 1
            loop
                exitwhen i > 8
				set MoveX = NewX( GetUnitX( GetUnit( "Zabimaru_" + I2S( i ) ) ), 12.5, GetUnitsAngle( GetUnit( "Zabimaru_" + I2S( i ) ), GetUnit( "Target" ) ) )
				set MoveY = NewY( GetUnitY( GetUnit( "Zabimaru_" + I2S( i ) ) ), 12.5, GetUnitsAngle( GetUnit( "Zabimaru_" + I2S( i ) ), GetUnit( "Target" ) ) )
                call SetUnitXY_1( GetUnit( "Zabimaru_" + I2S( i ) ), MoveX, MoveY, true )
                set i = i + 1
            endloop

			if GetUnitsDistance( GetUnit( "Zabimaru_1" ), GetUnit( "Target" ) ) <= 60. or Stop_Spell( 2 ) then
				if not Stop_Spell( 2 ) then
					call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), GetReal( "Damage" ), "physical" )
					call DestroyEffect( AddSpecialEffect( "NewDirtEXNofire.mdx", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
					call CC_Unit( GetUnit( "Target" ), 1.5, "stun", true )
				endif

				set i = 1
				loop
					exitwhen i > 8
					call RemoveUnit( GetUnit( "Zabimaru_" + I2S( i ) ) )
					set i = i + 1
				endloop

				call UnitAddAbility( GetUnit( "Caster" ), 'A0BM' )
				call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "AttackDisabled" ), false )
				call CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'edoc', 8000, 8000, bj_UNIT_FACING )
				call CleanMUI( GetExpiredTimer( ) )
			endif
		endif
	endfunction

	function Renji_R takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )
		local real MoveX
		local real MoveY
		local real Angle
		local real DMG
		local integer UID
		
		if Time == 1 then
			call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "AttackDisabled" ), true )
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "attack slam" )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'A0BM' )
			call SetUnitTimeScale( GetUnit( "Caster" ), .5 )
			set UID = 'h01U'
			set i = 1
			loop
				exitwhen i > 18
				if i == 18 then
					set UID = 'h01V'
				endif
				call RemoveUnit( GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) ) )
				call RemoveSavedHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Zabimaru_" + I2S( i ) ) )
				call SaveUnitHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Zabimaru_" + I2S( i ) ), CreateUnit( Player( GetInt( "PID" ) ), UID, GetReal( "CastX" ), GetReal( "CastY" ), GetReal( "Angle" ) ) )
				call ScaleUnit( GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) ), 1 )
				set i = i + 1
			endloop
			call RemoveUnitOfPlayerByID( GetPlayerId( GetOwningPlayer( GetUnit( "Caster" ) ) ), 'edoc' )
			call CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'oshm', 8000, 8000, bj_UNIT_FACING )
		endif
		
		if Time == 30 then
			call SetUnitTimeScale( GetUnit( "Caster" ), .0 )
		endif
		
		if Time > 1 then
			if GetInt( "Delay" ) == 2 then
				call SaveInteger( HashTable, HandleID, StringHash( "Delay" ), 0 )
				if GetReal( "AngleChange" ) <= 360 then
					set Angle = GetReal( "Angle" ) + GetReal( "AngleChange" )
					set i = 1
					loop
						exitwhen i > 18
						set MoveX = NewX( GetReal( "CastX" ), 65 * i, Angle )
						set MoveY = NewY( GetReal( "CastY" ), 65 * i, Angle )
						call SetUnitXY( GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) ), MoveX, MoveY )
						call DestroyAoEDestruct( MoveX, MoveY, 200 )
						call EnumUnits_AOE( SpellGroup, MoveX, MoveY, 200 )
						loop
							set SysUnit = FirstOfGroup( SpellGroup )
							exitwhen SysUnit == null
							if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and not IsUnitIgnored( SysUnit ) then
								set DMG = ( 7. + GetInt( "ALvL" ) ) * GetHeroStr( GetUnit( "Caster" ), true ) + ( 25. + 5. * GetInt( "ALvL" ) ) * GetHeroLevel( GetUnit( "Caster" ) )
								call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "physical" )
								call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", SysUnit, "chest" ) )
								call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl", SysUnit, "chest" ) )
							endif
							call GroupRemoveUnit( SpellGroup, SysUnit )
						endloop

						call SetUnitFacingTimed( GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) ), Angle, 0 )
						set i = i + 1
					endloop
					call SetUnitFacingTimed( GetUnit( "Caster" ), Angle, 0 )
				endif

				if GetReal( "AngleChange" ) == 370 then
					call PauseUnit( GetUnit( "Caster" ), false )
					call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
					call SetUnitAnimation( GetUnit( "Caster" ), "Stand" )
					set i = 1
					loop
						exitwhen i > 18
						call SetUnitFacingTimed( GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) ), GetRandomReal( 0, 360. ), 3 )
						set i = i + 1
					endloop
				endif

				if GetReal( "AngleChange" ) > 370 and GetReal( "AngleChange" ) < 500 then
					set i = 1
					loop
						exitwhen i > 18
						set SysUnit = GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) )
						set Angle = GetUnitFacing( SysUnit )
						set MoveX = NewX( GetUnitX( SysUnit ), 7.5 * i, Angle )
						set MoveY = NewY( GetUnitY( SysUnit ), 7.5 * i, Angle )
						call SetUnitXY_1( SysUnit, MoveX, MoveY, true )
						call SetUnitFacingTimed( SysUnit, Angle, 0 )
						set i = i + 1
					endloop
				endif
				if GetReal( "AngleChange" ) <= 500 then
					call SaveReal( HashTable, HandleID, StringHash( "AngleChange" ), GetReal( "AngleChange" ) + 10 )
				endif
			else
				call SaveInteger( HashTable, HandleID, StringHash( "Delay" ), GetInt( "Delay" ) + 1 )
			endif

			if Time == 1000 or Stop_Spell( 0 ) then
				if not LoadBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Renji_T_Cast" ) ) then
					call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "AttackDisabled" ), false )
					set i = 1
					loop
						exitwhen i > 18
						call RemoveUnitWithEffect( GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) ), "Abilities\\Spells\\Orc\\FeralSpirit\\feralspirittarget.mdl" )
						call RemoveSavedHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Zabimaru_" + I2S( i ) ) )
						set i = i + 1
					endloop
					call UnitAddAbility( GetUnit( "Caster" ), 'A0BM' )
					call CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'edoc', 8000, 8000, bj_UNIT_FACING )
					call RemoveUnitOfPlayerByID( GetPlayerId( GetOwningPlayer( GetUnit( "Caster" ) ) ), 'oshm' )
				endif
				call CleanMUI( GetExpiredTimer( ) )
			endif
		endif
	endfunction

	function Renji_T takes nothing returns nothing
		local integer i
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real Angle
		local real MoveX
		local real MoveY
		local real Distance
		local real DMG
		
		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitInvul( GetUnit( "Caster" ), true )
			call SetUnitInvul( GetUnit( "Target" ), true )
			call SetUnitFacingUnit( GetUnit( "Caster" ), GetUnit( "Target" ) )
			call SetUnitFacingUnit( GetUnit( "Target" ), GetUnit( "Caster" ) )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
			set i = 1
			loop
				exitwhen i > 18
				set SysUnit = GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) )
				call SetUnitPathing( SysUnit, false )
				call SetUnitFlyHeight( SysUnit, 16. * i, 1500. )
				set Angle = GetReal( "Angle" ) + 20 * i
				set MoveX = NewX( GetUnitX( GetUnit( "Caster" ) ), 15 * i, Angle )
				set MoveY = NewY( GetUnitY( GetUnit( "Caster" ) ), 15 * i, Angle )
				set Angle = GetAngleCast( SysUnit, MoveX, MoveY )
				set Distance = GetAxisDistance( GetUnitX( SysUnit ), GetUnitY( SysUnit ), MoveX, MoveY )
				call SetUnitFacing( SysUnit, Angle )
				call LinearDisplacement( SysUnit, Angle, Distance, 1, .01, false, false, "origin", "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl" )
				set i = i + 1
			endloop
		endif

		if Time == 5 then
			call SetUnitTimeScale( GetUnit( "Caster" ), 0 )
		endif

		if Time == 100 then
			set i = 1
			loop
				exitwhen i > 18
				set SysUnit = GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) )
				if i == 18 then
					call SetUnitLookAt( SysUnit, "bone_chest", GetUnit( "Target" ), 0, 0, GetUnitFlyHeight( GetUnit( "Target" ) ) )
				else
					call SetUnitLookAt( SysUnit, "bone_chest", GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i + 1 ) ), 0, 0, GetUnitFlyHeight( GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i + 1 ) ) ) )
				endif
				set i = i + 1
			endloop
		endif

		if Time == 150 then
			call SetUnitInvul( GetUnit( "Target" ), false )
			set i = 1
			loop
				exitwhen i > 18
				set SysUnit = GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) )
				set Angle = GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) )// + GetRandomReal( -90, 90 )
				set MoveX = NewX( GetUnitX( GetUnit( "Caster" ) ), 5 * i, Angle )
				set MoveY = NewY( GetUnitY( GetUnit( "Caster" ) ), 5 * i, Angle )
				call SetUnitFacing( SysUnit, Angle )
				call SetUnitXY( SysUnit, MoveX, MoveY )
				call SetUnitFlyHeight( SysUnit, 60., i * 200 )
				set i = i + 1
			endloop
			call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl", MoveX, MoveY ) )
		endif

		if Time >= 155 and Time <= 300 then
			if Counter( 0, 2 ) then
				set i = 1
				loop
					exitwhen i > 18
					set SysUnit = GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) )
					set Angle = GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) )// + GetRandomReal( -90, 90 )
					set MoveX = NewX( GetUnitX( SysUnit ), 2 * i, Angle )
					set MoveY = NewY( GetUnitY( SysUnit ), 2 * i, Angle )
					call SetUnitFacing( SysUnit, Angle )
					call SetUnitXY_1( SysUnit, MoveX, MoveY, true )
					call SetUnitFlyHeight( SysUnit, 60., i * 200 )
					if Time >= 200 then
						call BasicAoEDMG( GetUnit( "Caster" ), MoveX, MoveY, 100, .15 * GetHeroStr( GetUnit( "Caster" ), true ), "magical" )
					endif
					set i = i + 1
				endloop
				set SysUnit = GetZabimaru( GetUnit( "Caster" ), "Zabimaru_18" )
				set Angle = GetUnitsAngle( SysUnit, GetUnit( "Target" ) )
				set MoveX = NewX( GetUnitX( SysUnit ), 10, Angle )
				set MoveY = NewY( GetUnitY( SysUnit ), 10, Angle )
				call SetUnitXY_1( GetUnit( "Target" ), MoveX, MoveY, true )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl", MoveX, MoveY ) )
			endif
		endif

		if Time == 300 or Stop_Spell( 2 ) then
			call SetUnitTimeScale( GetUnit( "Caster" ), 1. )
			call SetUnitInvul( GetUnit( "Caster" ), false )
			call SetUnitInvul( GetUnit( "Target" ), false )
			call PauseUnit( GetUnit( "Caster" ), false )
			call PauseUnit( GetUnit( "Target" ), false )
			if UnitLife( GetUnit( "Caster" ) ) > 0 then
				call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
				call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
				call PlaySoundOnUnit( Sounds[ 54 ], 100, GetUnit( "Caster" ) )
				set DMG = ( 10. + 6. * GetInt( "ALvL" ) ) * GetHeroStr( GetUnit( "Caster" ), true )
				set SysUnit = GetZabimaru( GetUnit( "Caster" ), "Zabimaru_18" )
				call Linear_Spell_XY( GetUnit( "Caster" ), GetUnitX( SysUnit ), GetUnitY( SysUnit ), GetUnitFacing( SysUnit ), "war3mapImported\\FireWave.mdl", 1500, 1500, 350, 3, DMG, "", "physical" )
			endif

			call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "AttackDisabled" ), false )
			set i = 1
			loop
				exitwhen i > 18
				call RemoveUnitWithEffect( GetZabimaru( GetUnit( "Caster" ), "Zabimaru_" + I2S( i ) ), "Abilities\\Spells\\Orc\\FeralSpirit\\feralspirittarget.mdl" )
				set i = i + 1
			endloop
			call UnitAddAbility( GetUnit( "Caster" ), 'A0BM' )
			call CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'edoc', 8000, 8000, bj_UNIT_FACING )
			call RemoveUnitOfPlayerByID( GetInt( "PID" ), 'oshm' )
			call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Renji_T_Cast" ), false )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Renji_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), GetSpellAbilityId( ) )

		if AID == 'A013' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 50 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Renji_Q )
		endif
		
		if AID == 'A014' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call SaveStr( HashTable, HandleID, StringHash( "Order" ), GetUnitOrder( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Renji_W )
		endif

		if AID == 'A0BN' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 53 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Damage" ), ( 5. + ALvL ) * GetHeroStr( GetTriggerUnit( ), true ) + ( 18. + 2. * ALvL ) * GetHeroLevel( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Renji_E )
		endif

		if AID == 'A0BP' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 51 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitFacing( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Renji_R )
		endif

		if AID == 'A0BQ' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetUnitX( GetSpellTargetUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetUnitY( GetSpellTargetUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitsAngle( GetTriggerUnit( ), GetSpellTargetUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Renji_T )
			//call RenjiT( )
		endif
    endfunction

    function Init_Renji takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Renji_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Byakuya.j
	function Petal_Explosion takes integer PID, unit Source, unit Senkey returns nothing
		if Senkey != null then
			call CreateUnit( Player( PID ), 'ohun', 8000, 8000, bj_UNIT_FACING )
			call UnitRemoveAbility( Source, 'B027' )
			call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( Source ), StringHash( "Bankai_Effect_1" ) ) )
			call SetUnitAbilityLevel( Source, 'A0AI', 1 )
			call BasicAoEDMG( Source, GetUnitX( Source ), GetUnitY( Source ), 1350, 600 + 200 * GetUnitAbilityLevel( Source, 'A01R' ), "physical" )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl", Source, "origin" ) )
			call RemoveUnit( Senkey )
			set SysUnit = CreateUnit( Player( PID ), 'h019', GetUnitX( Source ), GetUnitY( Source ), 270 )
			call SetUnitTimeScale( SysUnit, .5 )
			call UnitApplyTimedLife( SysUnit, 'BTLF', 5. )
		endif
	endfunction

	function Byakuya_W takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		
		if Time == 1 then
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "LightPrison.mdx", GetUnit( "Target" ), "chest" ) )
			call SaveInteger( HashTable, HandleID, StringHash( "Duration" ), R2I( 1.75 + .25 * GetInt( "ALvL" ) ) * 100 )
			call CC_Unit( GetUnit( "Target" ), R2I( 1.75 + .25 * GetInt( "ALvL" ) ), "stun", true )
		endif

		if UnitLife( GetUnit( "Target" ) ) <= 0 or Time >= GetInt( "Duration" ) or not HasAbility( GetUnit( "Target" ), 'BSTN' ) then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Byakuya_E takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real TargX
		local real TargY
		local real MoveX
		local real MoveY

		if Time == 1 then
			set i = 1
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetUnit( "Caster" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetUnit( "Caster" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitFacing( GetUnit( "Caster" ) ) )
			call SaveEffectHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Bankai_Effect_1" ), AddSpecialEffectTarget( "!SenbonzakuraArmor!.mdx", GetUnit( "Caster" ), "chest" ) )
			call Petal_Explosion( GetInt( "PID" ), GetUnit( "Caster" ), LoadUnitHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Senkey_Unit" ) ) )

			loop
				exitwhen i > 4
				set TargX = NewX( GetReal( "CastX" ), 256, GetReal( "Angle" ) + 90 )
				set TargY = NewY( GetReal( "CastY" ), 256, GetReal( "Angle" ) + 90 )
				set MoveX = NewX( TargX, -75 * i, GetReal( "Angle" ) )
				set MoveY = NewY( TargY, -75 * i, GetReal( "Angle" ) )
				set Dummy = CreateUnit( Player( GetInt( "PID" ) ), 'h00P', MoveX, MoveY, GetReal( "Angle" ) )
				call SetUnitVertexColor( Dummy, 255, 255, 255, 165 )
				call SetUnitTimeScale( Dummy, 400. )
				call UnitApplyTimedLife( Dummy, 'BTLF', 1.1 )
				set TargX = NewX( GetReal( "CastX" ), 256, GetReal( "Angle" ) - 90 )
				set TargY = NewY( GetReal( "CastY" ), 256, GetReal( "Angle" ) - 90 )
				set MoveX = NewX( TargX, -75 * i, GetReal( "Angle" ) )
				set MoveY = NewY( TargY, -75 * i, GetReal( "Angle" ) )
				set Dummy = CreateUnit( Player( GetInt( "PID" ) ), 'h00P', MoveX, MoveY, GetReal( "Angle" ) )
				call SetUnitVertexColor( Dummy, 255, 255, 255, 165 )
				call SetUnitTimeScale( Dummy, 400. )
				call UnitApplyTimedLife( Dummy, 'BTLF', 1.1 )
				set i = i + 1
			endloop
		endif

		if Time >= GetInt( "Duration" ) or UnitLife( GetUnit( "Caster" ) ) <= 0 then
			call CreateUnit( Player( GetInt( "PID" ) ), 'okod', 8000, 8000, bj_UNIT_FACING )
			call SetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AI', 1 )
			call SetUnitAbilityLevel( GetUnit( "Caster" ), 'A058', 1 )
			call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Bankai_Effect_1" ) ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Byakuya_R takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )

		if Time == 1 then
			call SetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AI', ( GetUnitAbilityLevel( GetUnit( "Caster" ), 'A01R' ) + 6 ) )
			set Dummy = CreateUnit( Player( GetInt( "PID" ) ), 'u002', GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 270 )
			call UnitAddAbility( Dummy, 'S000' )
			call UnitAddAbility( Dummy, 'A027' )
			call UnitAddAbility( Dummy, 'A023' )
			call SetUnitAbilityLevel( Dummy, 'A023', GetUnitAbilityLevel( GetUnit( "Caster" ), 'A01R' ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Senkey_Stats" ), Dummy )
			set Dummy = CreateUnit( Player( GetInt( "PID" ) ), 'u998', GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 270 )
			call ScaleUnit( Dummy, 1.5 )
			call SaveUnitHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Senkey_Unit" ), Dummy )
			call SaveEffectHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Senkey_Dummy_Effect" ), AddSpecialEffectTarget( "Senkei.mdl", Dummy, "origin" ) )
			call PauseUnit( Dummy, true )
		endif

		if Time >= 3500 or UnitLife( GetUnit( "Caster" ) ) <= 0 or UnitLife( LoadUnitHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Senkey_Unit" ) ) ) <= 0 then //
            call CreateUnit( Player( GetInt( "PID" ) ), 'ohun', 8000, 8000, bj_UNIT_FACING )
			call KillUnit( GetUnit( "Senkey_Stats" ) )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'B027' )
			call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Senkey_Dummy_Effect" ) ) )
			call RemoveSavedHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Senkey_Dummy_Effect" ) )
			call RemoveUnit( LoadUnitHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Senkey_Unit" ) ) )
			call RemoveSavedHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Senkey_Unit" ) )
            call SetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AI', 1 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Byakuya_T takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'B00R' )
			call Petal_Explosion( GetInt( "PID" ), GetUnit( "Caster" ), LoadUnitHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Senkey_Unit" ) ) )
			call TargetCast( GetUnit( "Caster" ), GetUnit( "Caster" ), 'A07R', 1, "innerfire" )
		endif

		if Time == 100 then
			call SetUnitTimeScale( GetUnit( "Caster" ), .5 )
			call SetUnitAnimation( GetUnit( "Caster" ), "attack slam" )
		endif
		
		if Time > 100 then // used to move each .03 seconds by 40
			call SaveReal( HashTable, HandleID, StringHash( "NewX" ), NewX( GetUnitX( GetUnit( "Caster" ) ), 20, GetReal( "Angle" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "NewY" ), NewY( GetUnitY( GetUnit( "Caster" ) ), 20, GetReal( "Angle" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Travelled" ), GetReal( "Travelled" ) + 20 )
			call SetUnitXY_1( GetUnit( "Caster" ), GetReal( "NewX" ), GetReal( "NewY" ), true )
			call SetUnitFacing( GetUnit( "Caster" ), GetReal( "Angle" ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl", GetReal( "NewX" ), GetReal( "NewY" ) ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Silence\\SilenceAreaBirth.mdl", GetUnit( "Caster" ), "chest" ) )
			call MUIAoEDMG( GetUnit( "Caster" ), GetReal( "NewX" ), GetReal( "NewY" ), 400, 3000. + 20 * GetUnitAbilityLevel( GetUnit( "Caster" ), 'A0AL' ) * GetHeroLevel( GetUnit( "Caster" ) ), "physical" )
			call DestroyAoEDestruct( GetReal( "NewX" ), GetReal( "NewY" ), 400 )
		endif

		if GetReal( "Travelled" ) >= 3000 or Stop_Spell( 0 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			call SelectPlayerUnit( GetUnit( "Caster" ), true )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'B029' )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Byakuya_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), GetSpellAbilityId( ) )
		
		if AID == 'A01M' then
			call PlaySoundOnUnit( Sounds[ 12 ], 100, GetTriggerUnit( ) )
			call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "war3mapImported\\arcane.mdx", 1500, 950, 150, 3, 320 + 80 * GetUnitAbilityLevel( GetTriggerUnit( ), 'A01M' ), "" )
			call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "war3mapImported\\arcane.mdx", 1500, 950, 150, 3, 0, "" )
		endif
		
		if AID == 'A0AM' then
			call PlaySoundOnUnit( Sounds[ 14 ], 100, GetTriggerUnit( ) )
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Byakuya_W )
		endif
		
		if AID == 'A04V' then
			set HandleID = NewMUITimer( PID )
			call RemoveUnitOfPlayerByID( PID, 'okod' )
			call PlaySoundOnUnit( Sounds[ 15 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "Duration" ), R2I( ( 8.5 + ( 1.5 * ALvL ) ) * 100 ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SetUnitAbilityLevel( GetTriggerUnit( ), 'A0AI', ALvL + 1 )
			call SetUnitAbilityLevel( GetTriggerUnit( ), 'A058', ALvL + 1 )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Byakuya_E )
		endif
		
		if AID == 'A01R' then
			set HandleID = NewMUITimer( PID )
			call RemoveUnitOfPlayerByID( PID, 'ohun' )
			call PlaySoundOnUnit( Sounds[ 13 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call RemoveUnit( LoadUnitHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Senkey_Unit" ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Byakuya_R )
		endif

		if AID == 'A0AL' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 11 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Byakuya_T )
		endif
    endfunction

    function Init_Byakuya takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Byakuya_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Toshiro.j
    function Toshiro_Q takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local integer ALvL
		local real DMG
		local real MoveX
		local real MoveY

		if Time == 1 then
			call GroupClear( SpellGroup )
			call SaveReal( HashTable, HandleID, StringHash( "Distance" ), 700 )
			set MoveX = NewX( GetUnitX( GetUnit( "Caster" ) ), 200, GetReal( "Angle" ) )
			set MoveY = NewY( GetUnitY( GetUnit( "Caster" ) ), 200, GetReal( "Angle" ) )
			call SetUnitFacingTimed( GetUnit( "Caster" ), GetReal( "Angle" ), 0 )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( GetInt( "PID" ) ), 'h016', MoveX, MoveY, GetReal( "Angle" ) ) )
			call SetUnitTimeScale( GetUnit( "Dummy_1" ), .75 )
			call ScaleUnit( GetUnit( "Dummy_1" ), 1.2 )
			call SetUnitAnimation( GetUnit( "Dummy_1" ), "death" )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\FrostWyrmMissile\\FrostWyrmMissile.mdl", GetUnit( "Caster" ), "weapon" ) )
		endif

		if Time >= 1 then
			if GetReal( "Travelled" ) <= GetReal( "Distance" ) and not Stop_Spell( 0 ) then
				set DMG = 150 + 75 * GetUnitAbilityLevel( GetUnit( "Caster" ), 'A01F' )
				set MoveX = NewX( GetUnitX( GetUnit( "Dummy_1" ) ), 15, GetReal( "Angle" ) )
				set MoveY = NewY( GetUnitY( GetUnit( "Dummy_1" ) ), 15, GetReal( "Angle" ) )
				call SaveReal( HashTable, HandleID, StringHash( "Travelled" ), GetReal( "Travelled" ) + 15 )
				call SetUnitXY_1( GetUnit( "Dummy_1" ), MoveX, MoveY, true )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\FrostWyrmMissile\\FrostWyrmMissile.mdl", MoveX, MoveY ) )
				call SetUnitFacingTimed( GetUnit( "Dummy_1" ), GetReal( "Angle" ), 0 )
				if GetUnitTypeId( GetUnit( "Caster" ) ) == 'E003' then
					set ALvL = 7
				else
					set ALvL = 1
				endif

				call EnumUnits_AOE( SpellGroup, MoveX, MoveY, 300 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and not IsUnitIgnored( SysUnit ) and DefaultUnitFilter( SysUnit ) then
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "magical" )
						call TargetCast( GetUnit( "Caster" ), SysUnit, 'A02H', ALvL, "frostnova" )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
				call DestroyAoEDestruct( MoveX, MoveY, 300 )
			else
				call RemoveUnit( GetUnit( "Dummy_1" ) )
				call CleanMUI( GetExpiredTimer( ) )
			endif
		endif
    endfunction

	function Toshiro_W_Normal takes nothing returns nothing
		local integer i
		local real MoveX
		local real MoveY
		local real DMG
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		
		if Time == 1 then
			set i = 1
			loop
				exitwhen i > 3
				set MoveX = NewX( NewX( GetReal( "TargX" ), 90, i * 120 - 120 ), -200, i * 120 )
				set MoveY = NewY( NewY( GetReal( "TargY" ), 90, i * 120 - 120 ), -200, i * 120 )
				set Dummy = CreateUnit( Player( GetInt( "PID" ) ), 'h016', MoveX, MoveY, i * 120 )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_" + I2S( i ) ), Dummy )
				call SetUnitTimeScale( Dummy, .75 )
				call ScaleUnit( Dummy, 1.2 )
				call SetUnitAnimation( Dummy, "death" )
				set i = i + 1
			endloop
		endif
		
		if Time >= 1 and Time <= 19 then
			set i = 1
			loop
				exitwhen i > 3
				set MoveX = NewX( GetUnitX( GetUnit( "Dummy_" + I2S( i ) ) ), 10, i * 120 )
				set MoveY = NewY( GetUnitY( GetUnit( "Dummy_" + I2S( i ) ) ), 10, i * 120 )
				call SetUnitXY_1( GetUnit( "Dummy_" + I2S( i ) ), MoveX, MoveY, true )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\FrostWyrmMissile\\FrostWyrmMissile.mdl", MoveX, MoveY ) )
				set i = i + 1
			endloop
		endif
		
		if Time == 20 then
			set DMG = GetRandomReal( 50 + 150 * GetInt( "ALvL" ), 100 + 300 * GetInt( "ALvL" ) )
			call EnumUnits_AOE( SpellGroup, GetReal( "TargX" ), GetReal( "TargY" ), 400 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and not IsUnitIgnored( SysUnit ) then
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "magical" )
					call TargetCast( GetUnit( "Caster" ), SysUnit, 'A02H', 8, "frostnova" )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop

			call DestroyAoEDestruct( GetReal( "TargX" ), GetReal( "TargY" ), 400 )
			call DestroyEffect( AddSpecialEffect( "war3mapImported\\icestomp.mdx", GetReal( "TargX" ), GetReal( "TargY" ) ) )
			set i = 1
			loop
				exitwhen i > 3
				call RemoveUnit( GetUnit( "Dummy_" + I2S( i ) ) )
				set i = i + 1
			endloop
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Toshiro_W_BanKai takes nothing returns nothing
		local integer i
		local real Angle
		local real MoveX
		local real MoveY
		local real DMG
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		
		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
		endif

		if Time == 2 then
			call PauseUnit( GetUnit( "Caster" ), false )
			set i = 1
			loop
				exitwhen i > 5
				set MoveX = NewX( GetReal( "TargX" ), 600, i * 72 )
				set MoveY = NewY( GetReal( "TargY" ), 600, i * 72 )
				call DestroyEffect( AddSpecialEffect( "war3mapImported\\icestomp.mdx", MoveX, MoveY ) )
				set i = i + 1
			endloop
			set i = 1
			loop
				exitwhen i > 18
				set MoveX = NewX( GetReal( "TargX" ), 600, i * 20 )
				set MoveY = NewY( GetReal( "TargY" ), 600, i * 20 )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_" + I2S( i ) ), CreateUnit( Player( GetInt( "PID" ) ), 'h005', MoveX, MoveY, 0 ) )
				set i = i + 1
			endloop
		endif
		
		if Time >= 55 and Time <= 145 then
			if Counter( 0, 5 ) then
				set i = 1
				loop
					exitwhen i > 18
					set Angle = GetAngleCast( GetUnit( "Dummy_" + I2S( i ) ), GetReal( "TargX" ), GetReal( "TargY" ) )
					set MoveX = NewX( GetUnitX( GetUnit( "Dummy_" + I2S( i ) ) ), 25, Angle )
					set MoveY = NewY( GetUnitY( GetUnit( "Dummy_" + I2S( i ) ) ), 25, Angle )
					call SetUnitXY_1( GetUnit( "Dummy_" + I2S( i ) ), MoveX, MoveY, true )
					call DestroyAoEDestruct( MoveX, MoveY, 100 )
					call EnumUnits_AOE( SpellGroup, MoveX, MoveY, 100 )
					loop
						set SysUnit = FirstOfGroup( SpellGroup )
						exitwhen SysUnit == null

						if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) and GetAxisDistance( GetUnitX( SysUnit ), GetUnitY( SysUnit ), GetReal( "TargX" ), GetReal( "TargY" ) ) < 850. then
							set Angle = GetAngleCast( SysUnit, GetReal( "TargX" ), GetReal( "TargY" ) )
							set MoveX = NewX( GetUnitX( SysUnit ), 25, Angle )
							set MoveY = NewY( GetUnitY( SysUnit ), 25, Angle )
							call SetUnitXY_1( SysUnit, MoveX, MoveY, true )
						endif
						call GroupRemoveUnit( SpellGroup, SysUnit )
					endloop
					set i = i + 1
				endloop
			endif
		endif

		if Time == 145 or Stop_Spell( 0 ) then
			if UnitLife( GetUnit( "Caster" ) ) > 0 then
				set DMG = GetRandomReal( 50 + 150 * GetInt( "ALvL" ), 100 + 300 * GetInt( "ALvL" ) )
				call EnumUnits_AOE( SpellGroup, GetReal( "TargX" ), GetReal( "TargY" ), 400 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "magical" )
						call TargetCast( GetUnit( "Caster" ), SysUnit, 'A02H', 8, "frostnova" )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
				call DestroyEffect( AddSpecialEffect( "war3mapImported\\FrostNova.mdx", GetReal( "TargX" ), GetReal( "TargY" ) ) )
				call DestroyEffect( AddSpecialEffect( "war3mapImported\\icestomp.mdx", GetReal( "TargX" ), GetReal( "TargY" ) ) )
			endif
			set i = 1
			loop
				exitwhen i > 18
				call RemoveUnit( GetUnit( "Dummy_" + I2S( i ) ) )
				set i = i + 1
			endloop
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Toshiro_R takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'B00R' )
			call DestroyEffect( AddSpecialEffect( "war3mapImported\\FrostNova.mdx", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 115 )
		endif
		
		if Time >= 1 then // used to move each .03 seconds by 40
			call SaveReal( HashTable, HandleID, StringHash( "NewX" ), NewX( GetUnitX( GetUnit( "Caster" ) ), 15, GetReal( "Angle" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "NewY" ), NewY( GetUnitY( GetUnit( "Caster" ) ), 15, GetReal( "Angle" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Travelled" ), GetReal( "Travelled" ) + 15 )
			call SetUnitXY_1( GetUnit( "Caster" ), GetReal( "NewX" ), GetReal( "NewY" ), true )
			call SetUnitFacing( GetUnit( "Caster" ), GetReal( "Angle" ) )
			if Counter( 0, 3 ) then
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\FreezingBreath\\FreezingBreathMissile.mdl", GetUnit( "Caster" ), "origin" ) )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetUnit( "Caster" ), "origin" ) )
			endif
			call MUIAoEDMG( GetUnit( "Caster" ), GetReal( "NewX" ), GetReal( "NewY" ), 350, 1000. + ( 7. + GetInt( "ALvL" ) ) * GetHeroAgi( GetUnit( "Caster" ), true ), "physical" )
			call DestroyAoEDestruct( GetReal( "NewX" ), GetReal( "NewY" ), 350 )

			if GetReal( "Travelled" ) >= 1500 or Stop_Spell( 0 ) then
				call PauseUnit( GetUnit( "Caster" ), false )
				call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 255 )
				call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
				call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
				call SelectPlayerUnit( GetUnit( "Caster" ), true )
				call UnitRemoveAbility( GetUnit( "Caster" ), 'B029' )
				call DestroyEffect( GetEffect( "Weapon_Effect" ) )
				call CleanMUI( GetExpiredTimer( ) )
			endif
		endif
	endfunction

	function Toshiro_T takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real DMG
		local integer PID
		
		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitInvul( GetUnit( "Caster" ), true )
			call SetUnitInvul( GetUnit( "Target" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
		endif

		if Time >= 100 and Time <= 220 then
			if Counter( 0, 12 ) then
				call SaveInteger( HashTable, HandleID, StringHash( "FirstPetals" ), GetInt( "FirstPetals" ) + 1 )
				set Dummy = CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h015', GetReal( "TargX" ), GetReal( "TargY" ), GetRandomReal( 0, 360 ) )
				call ScaleUnit( Dummy, 1.8 )
				call SetUnitTimeScale( Dummy, 1.1 - ( GetInt( "FirstPetals" ) / 20 ) )
				call SetUnitFlyHeight( Dummy, 1100. - ( 100. * GetInt( "FirstPetals" ) ), 0 )
				call SetUnitXY_1( Dummy, GetReal( "TargX" ), GetReal( "TargY" ), true )
				call UnitApplyTimedLife( Dummy, 'BTLF', ( 220 - Time ) / 100 )
			endif
		endif

		if Time == 170 then
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitInvul( GetUnit( "Target" ), false )
			set DMG = 2500. + 30. * GetHeroLevel( GetUnit( "Caster" ) ) * GetInt( "ALvL" )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), DMG, "physical" )
			call CC_Unit( GetUnit( "Target" ), 4, "stun", true )
			set i = 1
			loop
				exitwhen i > 5
				call ScaleUnit( CreateUnit_S_L( CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h014', GetReal( "TargX" ), GetReal( "TargY" ), GetRandomReal( 0, 360 ) ), 1, .25 ), 2. - .2 * i )
				set i = i + 1
			endloop

			call CreateUnit_S_L( CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h00M', GetReal( "TargX" ), GetReal( "TargY" ), 270 ), .1, .5 )
			call CreateUnit_S_L( CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h00M', GetReal( "TargX" ), GetReal( "TargY" ), 270 ), .3, .5 )
			call CreateUnit_S_L( CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h00M', GetReal( "TargX" ), GetReal( "TargY" ), 270 ), .5, .5 )
			call CreateUnit_S_L( CreateUnit( GetOwningPlayer( GetUnit( "Caster" ) ), 'h00M', GetReal( "TargX" ), GetReal( "TargY" ), 270 ), 1., .5 )
			set DMG = DMG * .5
			call DestroyAoEDestruct( GetReal( "TargX" ), GetReal( "TargY" ), 700 )
			call EnumUnits_AOE( SpellGroup, GetReal( "TargX" ), GetReal( "TargY" ), 700 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
					if SysUnit != GetUnit( "Target" ) then
						call TargetCast( GetUnit( "Caster" ), SysUnit, 'A02H', 8, "frostnova" )
						call CC_Unit( SysUnit, 2, "stun", true )
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "physical" )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop

			call DestroyEffect( AddSpecialEffect( "war3mapImported\\icestomp.mdx", GetReal( "TargX" ), GetReal( "TargY" ) ) )
			call DestroyEffect( AddSpecialEffect( "war3mapImported\\icestomp.mdx", GetReal( "TargX" ), GetReal( "TargY" ) ) )
		endif
		
		if Time == 220 or Stop_Spell( 2 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitInvul( GetUnit( "Caster" ), false )
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitInvul( GetUnit( "Target" ), false )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			call EnableWeatherEffect( Player_Weather[ GetInt( "PID" ) ], false )
			call CleanMUI( GetExpiredTimer( ) )
		endif
    endfunction

	function Toshiro_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), GetSpellAbilityId( ) )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )
		
		if AID == 'A01F' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 22 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Toshiro_Q )
		endif

		if AID == 'A06F' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			if UID == 'EC12' then
				call PlaySoundOnUnit( Sounds[ 25 ], 100, GetTriggerUnit( ) )
				call TimerStart( LoadMUITimer( PID ), .01, true, function Toshiro_W_Normal )
			else
				call PlaySoundOnUnit( Sounds[ 23 ], 100, GetTriggerUnit( ) )
				call TimerStart( LoadMUITimer( PID ), .01, true, function Toshiro_W_BanKai )
			endif
		endif
		
		if AID == 'A01H' then
			if UID == 'EC12' then
				call CreateUnit( Player( PID ), 'oshm', 8000, 8000, bj_UNIT_FACING )
				call DestroyEffect( AddSpecialEffectTarget( "war3mapImported\\FrostNova.mdx", GetTriggerUnit( ), "origin" ) )
				call DestroyEffect( AddSpecialEffectTarget( "war3mapImported\\icestomp.mdx", GetTriggerUnit( ), "origin" ) )
				call PlaySoundOnUnit( Sounds[ 20 ], 100, GetTriggerUnit( ) )
				call TransformDisplace( GetTriggerUnit( ) )
			else
				call RemoveUnitOfPlayerByID( PID, 'oshm' )
			endif
		endif
		
		if AID == 'A01J' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 24 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Weapon_Effect" ), AddSpecialEffectTarget( "Abilities\\Weapons\\ZigguratFrostMissile\\ZigguratFrostMissile.mdl", GetTriggerUnit( ), "weapon" ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Toshiro_R )
		endif
		
		if AID == 'A004' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 21 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetUnitX( GetSpellTargetUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetUnitY( GetSpellTargetUnit( ) ) )
			if Player_Weather[ PID ] == null then
				set Player_Weather[ PID ] = AddWeatherEffect( GetWorldBounds( ), 'SNbs' )
			endif
			call EnableWeatherEffect( Player_Weather[ PID ], true )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Toshiro_T )
		endif
	endfunction

    function Init_Toshiro takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Toshiro_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Zaraki.j
	function Zaraki_W takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real MoveX
		local real MoveY

		if Time == 1 then
			set i = 1
			loop
				exitwhen i > 18
				set Dummy = CreateUnit( Player( GetInt( "PID" ) ), 'u998', GetReal( "CastX" ), GetReal( "CastY" ), 270 )
				call UnitApplyTimedLife( Dummy, 'BTLF', 1 )
				call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_" + I2S( i ) ), AddSpecialEffectTarget( "Objects\\Spawnmodels\\Undead\\UndeadDissipate\\UndeadDissipate.mdl", Dummy, "origin" ) )
				call LinearDisplacement( Dummy, i * 20, 700, 1, .03, false, false, "origin", "" )
				set i = i + 1
			endloop
			call AoECast( GetUnit( "Caster" ), 'A080', 1, "howlofterror" )
			call BasicAoEDMG( GetUnit( "Caster" ), GetReal( "CastX" ), GetReal( "CastY" ), 700, 250 + 50 * GetInt( "ALvL" ) + ( ( .75 + .25 * GetInt( "ALvL" ) ) * GetHeroStr( GetUnit( "Caster" ), true ) ), "magical" )
		endif

		if Time == 100 or Stop_Spell( 0 ) then
			set i = 1
			loop
				exitwhen i > 18
				call DestroyEffect( GetEffect( "Effect_" + I2S( i ) ) )
				set i = i + 1
			endloop
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Zaraki_E takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local integer ALvL
		local real MoveX
		local real MoveY

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitInvul( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
			call SetUnitTimeScale( GetUnit( "Caster" ), .4 )
			if GetRandomInt( 1, 100 ) <= 30 or HasAbility( GetUnit( "Caster" ), 'B01X' ) then
				call SaveInteger( HashTable, HandleID, StringHash( "Delay" ), 50 + Time )
				call SaveEffectHandle( HashTable, HandleID, StringHash( "Origin_Effect" ), AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile_mini.mdl", GetUnit( "Caster" ), "origin" ) )
				call SaveEffectHandle( HashTable, HandleID, StringHash( "Chest_Effect" ), AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile_mini.mdl", GetUnit( "Caster" ), "chest" ) )
				call DisplaceUnitWithArgs( GetUnit( "Caster" ), GetReal( "Angle" ), GetReal( "Distance" ), .5, .01, 900 )
			else
				call SaveInteger( HashTable, HandleID, StringHash( "Delay" ), 100 + Time )
				call DisplaceUnitWithArgs( GetUnit( "Caster" ), GetReal( "Angle" ), GetReal( "Distance" ), 1, .01, 600 )
			endif
		endif

		if Time == GetInt( "Delay" ) or Stop_Spell( 0 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitInvul( GetUnit( "Caster" ), false )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1. )
			if Time == GetInt( "Delay" ) then
				call DestroyAoEDestruct( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 450 )
				call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 450 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
						call CC_Unit( SysUnit, 2, "stun", true )
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, 550 + 50 * GetInt( "ALvL" ) + ( 3. + GetInt( "ALvL" ) ) * GetHeroStr( GetUnit( "Caster" ), true ), "physical" )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
				call DestroyEffect( AddSpecialEffect( "war3mapImported\\explosion.mdx", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", GetUnit( "Caster" ), "origin" ) )
				call DestroyEffect( GetEffect( "Origin_Effect" ) )
				call DestroyEffect( GetEffect( "Chest_Effect" ) )
				call SelectPlayerUnit( GetUnit( "Caster" ), true )
			endif

			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Zaraki_T takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real MoveX
		local real MoveY

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitInvul( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
		endif
		
		if Time == 30 then
			call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
		endif
			
		if Time == 50 then
			set i = 1
			loop
				exitwhen i > 18
				set MoveX = NewX( GetUnitX( GetUnit( "Caster" ) ), i * 45, GetReal( "Angle" ) )
				set MoveY = NewY( GetUnitY( GetUnit( "Caster" ) ), i * 45, GetReal( "Angle" ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Other\\Volcano\\VolcanoDeath.mdl", MoveX, MoveY ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl", MoveX, MoveY ) )
				call DestroyAoEDestruct( MoveX, MoveY, 360 )
				call MUIAoEDMG( GetUnit( "Caster" ), MoveX, MoveY, 360, 1000. + 500. * GetInt( "ALvL" ) + ( 11. + 3. * GetInt( "ALvL" ) ) * GetHeroStr( GetUnit( "Caster" ), true ), "physical" )
				set i = i + 1
			endloop
		endif
		
		if Time == 100 or Stop_Spell( 0 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitInvul( GetUnit( "Caster" ), false )
			call SelectPlayerUnit( GetUnit( "Caster" ), false )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Zaraki_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), GetSpellAbilityId( ) )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A081' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 84 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Zaraki_W )
		endif
		
		if AID == 'A003' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 85 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Distance" ), GetAxisDistance( GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Zaraki_E )
		endif
		
		if AID == 'A01P' then
			call PlaySoundOnUnit( Sounds[ 82 ], 100, GetTriggerUnit( ) )
			set bj_lastCreatedUnit = CreateUnit( Player( PID ), 'ogru', 8000, 8000, 270 )
			call UnitAddAbility( bj_lastCreatedUnit, 'A090' )
			call SetUnitAbilityLevel( bj_lastCreatedUnit, 'A090', ALvL )
			call UnitApplyTimedLife( bj_lastCreatedUnit, 'BTLF', 35. )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", GetTriggerUnit( ), "origin" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", GetTriggerUnit( ), "origin" ) )
			call TransformDisplace( GetTriggerUnit( ) )
		endif

		if AID == 'A00I' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 83 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Distance" ), GetAxisDistance( GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Zaraki_T )
		endif
    endfunction

    function Init_Zaraki takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Zaraki_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Genryusai.j
	function Genryusai_W takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real MoveX
		local real MoveY

		if Time == 1 then
			call DestroyEffect( AddSpecialEffect( "FlameShockwave.mdx", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 700 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, 325 + 75 * GetInt( "ALvL" ), "magical" )
					call GroupAddUnit( GetGroup( "Flame_Group" ), SysUnit )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time >= 1 then
			if Counter( 0, 50 ) then
				call Make_Dummy_Group( GetGroup( "Flame_Group" ) )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if UnitLife( SysUnit ) > 0 then
						call DestroyEffect( AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", SysUnit, "origin" ) )
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, ( 50. + 20. * GetInt( "ALvL" ) ) * .5, "magical" )
					else
						call GroupRemoveUnit( GetGroup( "Flame_Group" ), SysUnit )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
			endif
		endif

		if Time == 400 or Stop_Spells( ) then
			call DestroyGroup( GetGroup( "Flame_Group" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Genryusai_E takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real MoveX
		local real MoveY
		local real Dist
		local real Angle

		if GetInt( "Executions" ) < GetInt( "ExecLimit" ) and Time <= GetInt( "TimeLimit" ) and not Stop_Spell( 0 ) then
			if Counter( 0, 30 ) then
				if GetUnit( "Target" ) != null then
					set Dist  = GetRandomReal( 70, 100 )
					set Angle = GetRandomReal(  0, 360 )
					call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
					set MoveX = NewX( GetUnitX( GetUnit( "Target" ) ), Dist, Angle )
					set MoveY = NewY( GetUnitY( GetUnit( "Target" ) ), Dist, Angle )
					call SetUnitXY_1( GetUnit( "Caster" ), MoveX, MoveY, true )
					call DestroyEffect( AddSpecialEffect( "!Shunpo!.mdx", MoveX, MoveY ) )
					call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Other\\Doom\\DoomDeath.mdl", MoveX, MoveY ) )
					call BasicAoEDMG( GetUnit( "Caster" ), MoveX, MoveY, 220, GetHeroStr( GetUnit( "Caster" ), true ) * 3, "physical" )
					call RemoveSavedHandle( HashTable, HandleID, StringHash( "Target" ) )
					call SaveInteger( HashTable, HandleID, StringHash( "Executions" ), GetInt( "Executions" ) + 1 )
				endif

				call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetRandomEnemyUnitInArea( GetInt( "PID" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 720 ) )
			endif
		else
			call DestroyEffect( GetEffect( "Weapon_Effect" ) )
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 255 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Genryusai_R_Dummy takes unit Caster, real LocX, real LocY, real Distance, real Angle, real AoE, real DMG, boolean IsDummy returns nothing
		local real MoveX = NewX( LocX, Distance, Angle )
		local real MoveY = NewY( LocY, Distance, Angle )
		call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Other\\Doom\\DoomDeath.mdl", MoveX, MoveY ) )
		if IsDummy then
			call UnitApplyTimedLife( CreateUnit( GetOwningPlayer( Caster ), 'h00N', MoveX, MoveY, 270 ), 'BTLF', 20. )
		endif
		call BasicAoEDMG( Caster, MoveX, MoveY, AoE, DMG, "magical" )
	endfunction

	function Genryusai_R takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			call SaveReal( HashTable, HandleID, StringHash( "Distance" ), GetAxisDistance( GetReal( "CastX" ), GetReal( "CastY" ), NewX( GetReal( "CastX" ), 900, GetReal( "Angle" ) ), NewY( GetReal( "CastY" ), 900, GetReal( "Angle" ) ) ) )
		endif

		if Time >= 1 then
			if GetReal( "Travelled" ) <= GetReal( "Distance" ) then
				if Counter( 0, 10 ) then
					call Genryusai_R_Dummy( GetUnit( "Caster" ), GetReal( "CastX" ), GetReal( "CastY" ), GetReal( "Travelled" ), GetReal( "Angle" ), 250, 4 * GetHeroStr( GetUnit( "Caster" ), true ), false )
					call SaveReal( HashTable, HandleID, StringHash( "Travelled" ), GetReal( "Travelled" ) + 100 )
				endif
			else
				if GetReal( "M_Angle" ) <= 180 then
					if Counter( 1, 10 ) then
						call Genryusai_R_Dummy( GetUnit( "Caster" ), GetReal( "CastX" ), GetReal( "CastY" ), 1000, GetReal( "Angle" ) + GetReal( "M_Angle" ), 250, 4 * GetHeroStr( GetUnit( "Caster" ), true ), true )
						call Genryusai_R_Dummy( GetUnit( "Caster" ), GetReal( "CastX" ), GetReal( "CastY" ), 1000, GetReal( "Angle" ) - GetReal( "M_Angle" ), 250, 4 * GetHeroStr( GetUnit( "Caster" ), true ), true )
						call SaveReal( HashTable, HandleID, StringHash( "M_Angle" ), GetReal( "M_Angle" ) + 10 )
					endif
				endif
			endif

			if GetReal( "M_Angle" ) > 180 then
				if Counter( 2, 50 ) then
					call PointCast_XY( GetReal( "CastX" ), GetReal( "CastY" ), 0, 0, 'A00A', 1, "flamestrike" )
					call PointCast_XY( GetReal( "CastX" ), GetReal( "CastY" ), 0, 0, 'A00A', 1, "flamestrike" )
					call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 1100 )
					loop
						set SysUnit = FirstOfGroup( SpellGroup )
						exitwhen SysUnit == null
						if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
							call Damage_Unit( GetUnit( "Caster" ), SysUnit, 37.5 + 12.5 * GetInt( "ALvL" ), "magical" )
							if GetAxisDistance( GetReal( "CastX" ), GetReal( "CastY" ), GetUnitX( SysUnit ), GetUnitY( SysUnit ) ) >= 900 then
								call Damage_Unit( GetUnit( "Caster" ), SysUnit, 75 + 75 * GetInt( "ALvL" ), "magical" )
							endif
						endif
						call GroupRemoveUnit( SpellGroup, SysUnit )
					endloop
				endif
			endif
		endif

		if Time == 2000 or Stop_Spell( 0 ) then
			call RemoveUnitOfPlayerByID( GetInt( "PID" ), 'h00N' )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Genryusai_T takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real MoveX
		local real MoveY

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitInvul( GetUnit( "Caster" ), true )
			call SetUnitInvul( GetUnit( "Target" ), true )
		endif

		if Time == 2 then
			call DestroyEffect( AddSpecialEffect( "!Shunpo!.mdx", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
			set MoveX = NewX( GetUnitX( GetUnit( "Target" ) ), -120, GetReal( "Angle" ) )
			set MoveY = NewY( GetUnitY( GetUnit( "Target" ) ), -120, GetReal( "Angle" ) )
			call SetUnitXY_1( GetUnit( "Caster" ), MoveX, MoveY, true )
			call DestroyEffect( AddSpecialEffect( "!Shunpo!.mdx", MoveX, MoveY ) )
			call SetUnitFacing( GetUnit( "Target" ), GetReal( "R_Angle" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile_mini.mdl", GetUnit( "Caster" ), "weapon" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_2" ), AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile_mini.mdl", GetUnit( "Caster" ), "hand right" ) )
		endif

		if Time == 110 then
			call SetUnitTimeScale( GetUnit( "Caster" ), 2.7 )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_3" ), AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", GetUnit( "Target" ), "origin" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_4" ), AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", GetUnit( "Target" ), "chest" ) )
		endif

		if Time >= 110 and Time <= 210 then
			if Counter( 0, 10 ) then
				if GetRandomInt( 1, 5 ) < 2 then
					call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
				else
					call SetUnitAnimation( GetUnit( "Caster" ), "attack 2" )
				endif
				call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
			endif
		endif

		if Time == 210 then
			call SetUnitInvul( GetUnit( "Target" ), false )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 2000. + 11. * GetInt( "ALvL" ) * GetHeroStr( GetUnit( "Caster" ), false ), "physical" )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnit( "Target" ), "origin" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl", GetUnit( "Target" ), "origin" ) )
		endif

		if Time == 210 or Stop_Spell( 2 ) then
			call SetUnitTimeScale( GetUnit( "Caster" ), 1. )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call DestroyEffect( GetEffect( "Effect_2" ) )
			call DestroyEffect( GetEffect( "Effect_3" ) )
			call DestroyEffect( GetEffect( "Effect_4" ) )
			call SetUnitInvul( GetUnit( "Target" ), false )
			call PauseUnit( GetUnit( "Target" ), false )
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitInvul( GetUnit( "Caster" ), false )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Genryusai_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), GetSpellAbilityId( ) )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A0AY' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 70 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveGroupHandle( HashTable, HandleID, StringHash( "Flame_Group" ), CreateGroup( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Genryusai_W )
		endif

		if AID == 'A04J' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 69 ], 100, GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "ExecLimit" ), 2 + ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "TimeLimit" ), 40 * ( 2 + ALvL ) )
			call SetUnitVertexColor( GetTriggerUnit( ), 255, 255, 255, 125 )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Weapon_Effect" ), AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile_mini.mdl", GetTriggerUnit( ), "weapon" ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Genryusai_E )
		endif

		if AID == 'A04E' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 68 ], 100, GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitFacing( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Genryusai_R )
		endif

		if AID == 'A098' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 71 ], 100, GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetUnitX( GetSpellTargetUnit( ) ), GetUnitY( GetSpellTargetUnit( ) ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "R_Angle" ), GetAngleCast( GetSpellTargetUnit( ), GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Genryusai_T )
		endif
    endfunction

    function Init_Genryusai takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Genryusai_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Yoruichi.j
	function Yoruichi_Q takes nothing returns nothing
		local integer i
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real Angle
		local real MoveX
		local real MoveY

		if Time == 1 then
			set SysUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h01J', GetReal( "CastX" ), GetReal( "CastY" ), 270 )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), SysUnit )
		endif

		if GetReal( "Travelled" ) < GetReal( "Distance" ) and GetUnit( "Target" ) == null and not Stop_Spell( 0 ) then
			if Counter( 0, 2 ) then
				set MoveX = NewX( GetUnitX( GetUnit( "Dummy_1" ) ), GetReal( "Speed" ), GetReal( "Angle" ) )
				set MoveY = NewY( GetUnitY( GetUnit( "Dummy_1" ) ), GetReal( "Speed" ), GetReal( "Angle" ) )
				call SaveReal( HashTable, HandleID, StringHash( "Travelled" ), GetReal( "Travelled" ) + GetReal( "Speed" ) )
				call SetUnitXY_1( GetUnit( "Dummy_1" ), MoveX, MoveY, true )
				call DestroyAoEDestruct( MoveX, MoveY, 200 )
				call EnumUnits_AOE( SpellGroup, MoveX, MoveY, 200 )

				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) and not IsUnitIgnored( SysUnit ) then
						if not IsUnitType( SysUnit, UNIT_TYPE_HERO ) then
							call Damage_Unit( GetUnit( "Caster" ), SysUnit, 300, "magical" )
						else
							if GetUnit( "Target" ) == null then
								call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), SysUnit )
								if GetReal( "Speed" ) >= 50 then
									call Youruichi_Lightning( GetUnit( "Caster" ), GetUnit( "Target" ) )
								endif
								call DestroyEffect( AddSpecialEffect( "!Shunpo!.mdx", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
								set Angle = GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) )
								set MoveX = NewX( GetUnitX( GetUnit( "Target" ) ), -140, Angle )
								set MoveY = NewY( GetUnitY( GetUnit( "Target" ) ), -140, Angle )
								call SetUnitXY_1( GetUnit( "Caster" ), MoveX, MoveY, true )
								call SetUnitFacing( GetUnit( "Caster" ), Angle )
								call DestroyEffect( AddSpecialEffect( "!Shunpo!.mdx", MoveX, MoveY ) )
								call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 12. * GetHeroAgi( GetUnit( "Caster" ), true ) * ( GetReal( "Travelled" ) / 1800 ), "physical" )
								call CC_Unit( GetUnit( "Target" ), .85, "stun", true )
								call PanCameraUnit( GetUnit( "Caster" ) )
								call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnit( "Target" ), "origin" ) )
							endif
						endif
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
			endif
		else
			call KillUnit( GetUnit( "Dummy_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Yoruichi_W takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local string Eff

		if Time == 1 then
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", GetUnit( "Caster" ), "origin" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl", GetUnit( "Caster" ), "origin" ) )
			set Eff = "Abilities\\Spells\\Undead\\AbsorbMana\\AbsorbManaBirthMissile.mdl"
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( Eff, GetUnit( "Caster" ), "chest" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_2" ), AddSpecialEffectTarget( Eff, GetUnit( "Caster" ), "hand right" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_3" ), AddSpecialEffectTarget( Eff, GetUnit( "Caster" ), "hand left" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_4" ), AddSpecialEffectTarget( Eff, GetUnit( "Caster" ), "foot right" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_5" ), AddSpecialEffectTarget( Eff, GetUnit( "Caster" ), "foot left" ) )
			call SaveBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Yoruichi_Riposte" ), true )
		endif

		if Time == 300 or not LoadBoolean( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Yoruichi_Riposte" ) ) or Stop_Spell( 0 ) then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call DestroyEffect( GetEffect( "Effect_2" ) )
			call DestroyEffect( GetEffect( "Effect_3" ) )
			call DestroyEffect( GetEffect( "Effect_4" ) )
			call DestroyEffect( GetEffect( "Effect_5" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Yoruichi_E takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real MoveX
		local real MoveY
		local real Dist
		local real Angle

		if GetInt( "Executions" ) < GetInt( "ExecLimit" ) and Time <= GetInt( "TimeLimit" ) and not Stop_Spell( 0 ) then
			if Counter( 0, 30 ) then
				if GetUnit( "Target" ) != null then
					set Dist  = GetRandomReal( 70, 100 )
					set Angle = GetRandomReal(  0, 360 )
					call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
					call DestroyEffect( AddSpecialEffectTarget( "!Shunpo!.mdx", GetUnit( "Caster" ), "origin" ) )
					set MoveX = NewX( GetUnitX( GetUnit( "Target" ) ), Dist, Angle )
					set MoveY = NewY( GetUnitY( GetUnit( "Target" ) ), Dist, Angle )

					if GetUnitTypeId( GetUnit( "Caster" ) ) != 'OC10' then
						call Youruichi_Lightning( GetUnit( "Caster" ), GetUnit( "Target" ) )
						call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), GetHeroAgi( GetUnit( "Caster" ), true ) * 4, "physical" )
						call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnit( "Target" ), "origin" ) )
					else
						call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), GetHeroAgi( GetUnit( "Caster" ), true ) * 3, "physical" )
					endif
					
					call SetUnitXY_1( GetUnit( "Caster" ), MoveX, MoveY, true )
					call DestroyEffect( AddSpecialEffectTarget( "!Shunpo!.mdx", GetUnit( "Caster" ), "origin" ) )
					call RemoveSavedHandle( HashTable, HandleID, StringHash( "Target" ) )
					call SaveInteger( HashTable, HandleID, StringHash( "Executions" ), GetInt( "Executions" ) + 1 )
				endif
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetRandomEnemyUnitInArea( GetInt( "PID" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 720 ) )
			endif
		else
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 255 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Yoruichi_T takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real MoveX
		local real MoveY

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1.5 )
			call SetUnitAnimation( GetUnit( "Caster" ), "attack 3" )
			call SetUnitInvul( GetUnit( "Caster" ), true )
			call SetUnitInvul( GetUnit( "Target" ), true )
			call SaveReal( HashTable, HandleID, StringHash( "InitAngle" ), GetRandomReal( 0, 360 ) )
			call CC_Unit( GetUnit( "Target" ), .85, "stun", true )
			call Youruichi_Lightning( GetUnit( "Caster" ), GetUnit( "Target" ) )
		endif
		
		if Time >= 3 then
			if GetInt( "Hits_Done" ) <= 16 then
				if Counter( 0, 5 ) then
					set MoveX = NewX( GetUnitX( GetUnit( "Target" ) ), 100, GetReal( "InitAngle" ) )
					set MoveY = NewY( GetUnitY( GetUnit( "Target" ) ), 100, GetReal( "InitAngle" ) )
					call SaveReal( HashTable, HandleID, StringHash( "InitAngle" ), GetReal( "InitAngle" ) + 24 )
					if GetInt( "Hits_Done" ) < 16 then
						call SetUnitAnimation( GetUnit( "Caster" ), "attack 3" )
					else
						call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )
						call SetUnitFacing( GetUnit( "Caster" ), GetReal( "Angle" ) )
						call SetUnitTimeScale( GetUnit( "Caster" ), 1. )
						call SetUnitAnimation( GetUnit( "Caster" ), "spell slam" )
						call PauseUnit( GetUnit( "Caster" ), false )
						call SetUnitInvul( GetUnit( "Caster" ), false )
						call SetUnitInvul( GetUnit( "Target" ), false )
					endif
					call SetUnitAnimation( GetUnit( "Target" ), "stand hit" )
					call SetUnitXY_1( GetUnit( "Caster" ), MoveX, MoveY, true )
					call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
					call SetUnitInvul( GetUnit( "Target" ), false )
					call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), GetHeroAgi( GetUnit( "Caster" ), false ), "magical" )
					call SetUnitInvul( GetUnit( "Target" ), true )
					call AddSpecialEffectTarget( "Abilities\\Weapons\\Bolt\\BoltImpact.mdl", GetUnit( "Target" ), "origin" )
					call SaveInteger( HashTable, HandleID, StringHash( "Hits_Done" ), GetInt( "Hits_Done" ) + 1 )
				endif
			endif

			if GetInt( "Hits_Done" ) == 17 then
				if GetReal( "Travelled" ) <= 1500 then
					if Counter( 0, 3 ) then
						set MoveX = NewX( GetUnitX( GetUnit( "Target" ) ), 30, GetReal( "Angle" ) )
						set MoveY = NewY( GetUnitY( GetUnit( "Target" ) ), 30, GetReal( "Angle" ) )
						if not IsTerrainPathable( MoveX, MoveY, PATHING_TYPE_WALKABILITY ) then
							call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
							call SetUnitXY_1( GetUnit( "Target" ), MoveX, MoveY, true )
							call DestroyAoEDestruct( MoveX, MoveY, 300 )
							call SaveReal( HashTable, HandleID, StringHash( "Travelled" ), GetReal( "Travelled" ) + 30 )
						else
							call SaveReal( HashTable, HandleID, StringHash( "Travelled" ), 1500 )
						endif
					endif
				endif
			endif
		endif

		if GetReal( "Travelled" ) >= 1500 or Stop_Spell( 2 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitInvul( GetUnit( "Caster" ), false )
			call SetUnitInvul( GetUnit( "Target" ), false )
			if GetReal( "Travelled" ) >= 1500 then
				call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), GetHeroAgi( GetUnit( "Caster" ), true ) * 5 * GetInt( "ALvL" ), "physical" )
				call DestroyAoEDestruct( GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 600 )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
			endif
			call SetUnitTimeScale( GetUnit( "Caster" ), 1. )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Yoruichi_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), GetSpellAbilityId( ) )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )
		local boolean Empowered = GetUnitTypeId( GetTriggerUnit( ) ) != 'OC10'
		local real T_Distance
		local real A_Distance
		local real DMG

		if AID == 'A00Y' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 72 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Distance" ), 600 + 200 * ALvL )
			if Empowered then
				call SaveReal( HashTable, HandleID, StringHash( "Speed" ), 50 )
			else
				call SaveReal( HashTable, HandleID, StringHash( "Speed" ), 30 )
			endif
			call TimerStart( LoadMUITimer( PID ), .01, true, function Yoruichi_Q )
		endif

		if AID == 'A07W' then
			set HandleID = NewMUITimer( PID )
			//call PlaySoundOnUnit( Sounds[ 73 ], 100, GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			if Empowered then
				set A_Distance = 600.
				set T_Distance = 900.
				set DMG = 6 * GetHeroAgi( GetTriggerUnit( ), false )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetTriggerUnit( ), "origin" ) )
			else
				set A_Distance = 450.
				set T_Distance = 600.
				set DMG = 5 * GetHeroAgi( GetTriggerUnit( ), false )
			endif
			call SaveReal( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Yoruichi_Riposte_A_Distance" ), A_Distance )
			call SaveReal( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Yoruichi_Riposte_T_Distance" ), T_Distance )
			call SaveReal( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Yoruichi_Riposte_DMG" ), DMG )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Yoruichi_W )
		endif

		if AID == 'A02D' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 74 ], 100, GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "ExecLimit" ), 4 + ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "TimeLimit" ), 40 * ( 4 + ALvL ) )
			call SetUnitVertexColor( GetTriggerUnit( ), 255, 255, 255, 125 )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Yoruichi_E )
		endif
		
		if AID == 'A02C' then
			if UID == 'OC10' then
				call PlaySoundOnUnit( Sounds[ 75 ], 100, GetTriggerUnit( ) )
				call CreateUnit( Player( PID ), 'otbr', 8000, 8000, bj_UNIT_FACING )
				set Dummy = CreateUnit( Player( PID ), 'h000', GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ), bj_UNIT_FACING )
				call ScaleUnit( Dummy, 3 )
				call UnitApplyTimedLife( Dummy, 'BTLF', 5. )
				call SetUnitTimeScale( Dummy, .5 )
				set Dummy = CreateUnit( Player( PID ), 'h000', GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ), bj_UNIT_FACING )
				call ScaleUnit( Dummy, 3 )
				call UnitApplyTimedLife( Dummy, 'BTLF', 5. )
				call SetUnitTimeScale( Dummy, .5 )
				call TransformDisplace( GetTriggerUnit( ) )
			else
				call RemoveUnitOfPlayerByID( PID, 'otbr' )
			endif
		endif
		
		if AID == 'A01C' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 76 ], 100, GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Yoruichi_T )
		endif
    endfunction

	function Init_Yoruichi takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Yoruichi_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Soi_Fon.j
	function SoiFon_E takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real DMG
		local real Result
		local real Distance

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitInvul( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "attack slam" )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile_mini.mdl", GetUnit( "Caster" ), "hand right" ) )
			set DMG = ( 1. + 2. * GetInt( "ALvL" ) ) * GetHeroAgi(  GetUnit( "Caster" ), true )
			if GetHeroAgi( GetUnit( "Caster" ), true ) >= GetHeroAgi( GetUnit( "Target" ), true ) then
				set Result = ( GetHeroAgi( GetUnit( "Target" ), true ) / GetHeroAgi( GetUnit( "Caster" ), true ) ) * DMG
			else
				set Result = DMG
			endif
			
			set DMG = 400. + DMG - Result
			call SaveReal( HashTable, HandleID, StringHash( "DMG" ), DMG )
			call LinearDisplacement( GetUnit( "Caster" ), GetReal( "Angle" ), GetReal( "Distance" ) + 150, .20, .01, false, false, "origin", "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl" )
		endif

		if Time == 20 then
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), GetReal( "DMG" ), "physical" )
			call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Human\\HumanBlood\\BloodElfSpellThiefBlood.mdl", GetUnit( "Target" ), "origin" ) )
		endif
		
		if GetInt( "TimeLimit" ) > 20 then
			if Time == 20 then
				call SetUnitFacing( GetUnit( "Caster" ), GetReal( "R_Angle" ) )
				call SetUnitAnimationWithRarity( GetUnit( "Caster" ), "attack", RARITY_FREQUENT )
			endif

			if Time == 30 then
				set Distance = GetAxisDistance( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) )
				call LinearDisplacement( GetUnit( "Caster" ), GetReal( "R_Angle" ), Distance + 150, .20, .01, false, false, "origin", "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl" )
			endif
			
			if Time == 50 then
				call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), GetReal( "DMG" ) * .75, "physical" )
				call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Human\\HumanBlood\\BloodElfSpellThiefBlood.mdl", GetUnit( "Target" ), "origin" ) )
			endif
		endif

		if Time == GetInt( "TimeLimit" ) or Stop_Spell( 2 ) then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call SetUnitFacing( GetUnit( "Caster" ), GetReal( "Angle" ) )
			call PauseUnit( GetUnit( "Caster" ), false )
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitInvul( GetUnit( "Caster" ), false )
			call SetUnitPathing( GetUnit( "Caster" ), true )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function SoiFon_T takes unit Source, unit Target returns nothing
		local real ALvL = GetUnitAbilityLevel( Source, 'A096' )
		local real Random = GetRandomReal( 1., 100. )
		local real Chance = 0
		local real Modifier = 95. - 5. * ALvL
		local real DMG
		local real Agi_Diff =  GetHeroAgi( Target, true ) / GetHeroAgi( Source, true )
		local boolean Enhanced = GetHeroAgi( Source, true ) >= GetHeroAgi( Target, true )
		
        if not IsUnitPaused( Target ) and not IsUnitCCed( Target ) then
            if Enhanced then
                set Chance = Agi_Diff * Modifier
            else
                set Chance = Modifier
            endif
        else
            if Enhanced then
                set Chance = Agi_Diff * ( Modifier - 20. )
            else
                set Chance = Modifier - 20.
            endif
        endif

        if GetRandomReal( 1., 100. ) <= Chance then
			call TextTagSimpleUnit( "|c0021C795MISS!!!|r", Source, 11, 255, 1.6 )
        else
            if HasAbility( Target, 'B01H' ) then
				call UnitRemoveAbility( Target, 'B01H' )
                if GetHeroLevel( Target ) < GetHeroLevel( Source ) or UnitLifePercent( Target ) <= 25 then
                    set DMG = 99999999
                else
                    set DMG = ( 10. + 2. * ALvL ) * GetHeroAgi( Source, true )
                endif
                call PlaySoundOnUnit( Sounds[ 61 ], 100, Source )
            else
				call TargetCast( Source, Target, 'A097', 1, "lightningshield" )
                call PlaySoundOnUnit( Sounds[ 63 ], 100, Source )
                set DMG = 3. * GetHeroAgi( Source, true )
            endif
            call Damage_Unit( Source, Target, DMG, "passive" )
            if DMG == 99999999 then
				call TextTagSimpleUnit( "|c00FF0303DEATH!|r", Target, 12, 255, 1.6 )
            else
				call TextTagSimpleUnit( "|c00FF0303" + R2SW( DMG, 0, 0 ) + "!|r", Target, 12, 255, 1.6 )
            endif
        endif
    endfunction

    function SoiFon_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), GetSpellAbilityId( ) )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A095' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 60 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetUnitX( GetSpellTargetUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetUnitY( GetSpellTargetUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetUnitX( GetSpellTargetUnit( ) ), GetUnitY( GetSpellTargetUnit( ) ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "R_Angle" ), GetAngleCast( GetSpellTargetUnit( ), GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Distance" ), GetAxisDistance( GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ), GetUnitX( GetSpellTargetUnit( ) ), GetUnitY( GetSpellTargetUnit( ) ) ) )
			if UID != 'O002' then
				call SaveInteger( HashTable, HandleID, StringHash( "TimeLimit" ), 50 )
			else
				call SaveInteger( HashTable, HandleID, StringHash( "TimeLimit" ), 20 )
			endif
			call SetUnitPathing( GetTriggerUnit( ), false )
			call TimerStart( LoadMUITimer( PID ), .01, true, function SoiFon_E )
		endif

		if AID == 'A08V' then
			if UID == 'O002' then
				call PlaySoundOnUnit( Sounds[ 62 ], 100, GetTriggerUnit( ) )
				call CreateUnit( Player( PID ), 'otbr', 8000, 8000, bj_UNIT_FACING )
				set Dummy = CreateUnit( Player( PID ), 'h000', GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ), bj_UNIT_FACING )
				call ScaleUnit( Dummy, 3 )
				call UnitApplyTimedLife( Dummy, 'BTLF', 5. )
				call SetUnitTimeScale( Dummy, .5 )
				set Dummy = CreateUnit( Player( PID ), 'h000', GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ), bj_UNIT_FACING )
				call ScaleUnit( Dummy, 3 )
				call UnitApplyTimedLife( Dummy, 'BTLF', 5. )
				call SetUnitTimeScale( Dummy, .5 )
				call TransformDisplace( GetTriggerUnit( ) )
			else
				call RemoveUnitOfPlayerByID( PID, 'otbr' )
			endif
		endif
		
		if AID == 'A096' then
			call SoiFon_T( GetTriggerUnit( ), GetSpellTargetUnit( ) )
		endif
    endfunction

    function Init_SoiFon takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function SoiFon_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Ikkaku.j
	function Ikkaku_Q takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local integer Random
		
		if Time == 1 then
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\Cripple\\CrippleTarget.mdl", GetUnit( "Caster" ), "origin" ) )
			set Random = GetRandomInt( 1, 3 )
			if Random == 1 then
				call PlaySoundOnUnit( Sounds[ 35 ], 100, GetUnit( "Caster" ) )
		elseif Random == 2 then
				call PlaySoundOnUnit( Sounds[ 36 ], 100, GetUnit( "Caster" ) )
		elseif Random == 3 then
				call PlaySoundOnUnit( Sounds[ 37 ], 100, GetUnit( "Caster" ) )
			endif

			call CC_Unit( GetUnit( "Target" ), .75, "stun", true )
			call SetUnitXY_1( GetUnit( "Caster" ), NewX( GetReal( "TargX" ), -80, GetReal( "Angle" ) ), NewY( GetReal( "TargY" ), -80, GetReal( "Angle" ) ), true )
			call DestroyAoEDestruct( GetReal( "TargX" ), GetReal( "TargY" ), 350 )
			call EnumUnits_AOE( SpellGroup, GetReal( "TargX" ), GetReal( "TargY" ), 350 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
					call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( SysUnit ), GetUnitY( SysUnit ) ) )
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, 100. * GetInt( "ALvL" ) + GetHeroStr( GetUnit( "Caster" ), true ), "physical" )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
        endif

		if Time == 50 then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Ikkaku_R takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			call SaveInteger( HashTable, HandleID, StringHash( "Stacks" ), 2 )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Phoenix_Missile_mini_NoDeathAnim.mdx", GetUnit( "Caster" ), "hand right" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_2" ), AddSpecialEffectTarget( "Phoenix_Missile_mini_NoDeathAnim.mdx", GetUnit( "Caster" ), "hand left" ) )
		endif

		if Time >= 1 then
			if Counter( 0, 250 ) then
				if GetInt( "Stacks" ) < 11 then
					call SetUnitAbilityLevel( GetUnit( "Caster" ), 'A092', GetInt( "Stacks" ) )
					call SaveInteger( HashTable, HandleID, StringHash( "Stacks" ), GetInt( "Stacks" ) + 1 )
				endif
			endif
        endif

		if Time == 4500 or UnitLife( GetUnit( "Caster" ) ) <= 0 or GetUnitTypeId( GetUnit( "Caster" ) ) == 'U00S' then
			call SetUnitAbilityLevel( GetUnit( "Caster" ), 'A092', 2 )
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call DestroyEffect( GetEffect( "Effect_2" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Ikkaku_T takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real MoveX
		local real MoveY

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitTimeScale( GetUnit( "Caster" ), 6 )
			call SetUnitAnimation( GetUnit( "Caster" ), "spell" )
		endif

		if Time >= 1 then
			if Counter( 0, 2 ) then
				set MoveX = NewX( GetUnitX( GetUnit( "Caster" ) ), 45, GetReal( "Angle" ) )
				set MoveY = NewY( GetUnitY( GetUnit( "Caster" ) ), 45, GetReal( "Angle" ) )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl", GetUnit( "Caster" ), "origin" ) )
				if not IsTerrainPathable( MoveX, MoveY, PATHING_TYPE_WALKABILITY ) then
					call SetUnitXY_1( GetUnit( "Caster" ), MoveX, MoveY, true )
				endif
				call MUIAoEDMG( GetUnit( "Caster" ), MoveX, MoveY, 400, ( 5. + GetInt( "ALvL" ) ) * ( 60. * ( GetUnitAbilityLevel( GetUnit( "Caster" ), 'A092' ) - 1. ) ) + ( 11. + 3. * GetInt( "ALvL" ) ) * GetHeroStr( GetUnit( "Caster" ), true ), "physical" )
			endif

			if Counter( 1, 25 ) then
				call SetWidgetLife( GetUnit( "Caster" ), GetUnitState( GetUnit( "Caster" ), UNIT_STATE_LIFE ) - .15 * GetUnitState( GetUnit( "Caster" ), UNIT_STATE_MAX_LIFE ) )
			endif
		endif

		if Time == 101 or UnitLifePercent( GetUnit( "Caster" ) ) < 15 or Stop_Spells( ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call SelectPlayerUnit( GetUnit( "Caster" ), true )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Ikkaku_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), GetSpellAbilityId( ) )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )
		
		if AID == 'A091' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetUnitX( GetSpellTargetUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetUnitY( GetSpellTargetUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetUnitX( GetSpellTargetUnit( ) ), GetUnitY( GetSpellTargetUnit( ) ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ikkaku_Q )
		endif
		
		if AID == 'A08Y' then
			if UID == 'U00S' then
				call PlaySoundOnUnit( Sounds[ 38 ], 100, GetTriggerUnit( ) )
				call CreateUnit( Player( PID ), 'oshm', 8000, 8000, bj_UNIT_FACING )
				call DestroyEffect( AddSpecialEffect( "NewDirtEXNofire.mdx", GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ) ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\MarkOfChaos\\MarkOfChaosTarget.mdl", GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ) ) )
				call DestroyEffect( AddSpecialEffectTarget( "war3mapImported\\explosion.mdx", GetTriggerUnit( ), "origin" ) )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Orc\\WarStomp\\WarStompCaster.mdl", GetTriggerUnit( ), "origin" ) )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\MarkOfChaos\\MarkOfChaosTarget.mdl", GetTriggerUnit( ), "origin" ) )
				call TransformDisplace( GetTriggerUnit( ) )
			else
				call RemoveUnitOfPlayerByID( PID, 'oshm' )
			endif
		endif

		if AID == 'A093' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 34 ], 100, GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ikkaku_R )
		endif

		if AID == 'A094' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 39 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ikkaku_T )
		endif
    endfunction

    function Init_Ikkaku takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Ikkaku_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Kaname.j
	function Kaname_Q takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			if LoadGroupHandle( HashTable, GetHandleId( Player( GetInt( "PID" ) ) ), StringHash( "Suzumushi_Group" ) ) == null then
				call SaveGroupHandle( HashTable, GetHandleId( Player( GetInt( "PID" ) ) ), StringHash( "Suzumushi_Group" ), CreateGroup( ) )
			endif

			call DestroyEffect( AddSpecialEffect( "!Suzumushi!.mdx", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call GroupClear( LoadGroupHandle( HashTable, GetHandleId( Player( GetInt( "PID" ) ) ), StringHash( "Suzumushi_Group" ) ) )
			call AoECast( GetUnit( "Caster" ), 'A0C7', 1, "howlofterror" )
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 700 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
					if not IsUnitType( SysUnit, UNIT_TYPE_HERO ) then
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, 300, "magical" )
					else
						call CC_Unit( SysUnit, 1.75, "sleep", true )
						call GroupAddUnit( LoadGroupHandle( HashTable, GetHandleId( Player( GetInt( "PID" ) ) ), StringHash( "Suzumushi_Group" ) ), SysUnit )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Kaname_E takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real Angle

		if Time == 1 then
			set SysUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h01A', GetReal( "CastX" ), GetReal( "CastY" ), GetReal( "Angle" ) )
			call SetUnitVertexColor( SysUnit, 255, 0, 255, 255 )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), SysUnit )
		endif

		if Time >= 1 then
			if GetInt( "TimeLimit" ) <= 0 then
				call SetUnitXY_4( GetUnit( "Dummy_1" ), GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 20, GetUnitsAngle( GetUnit( "Dummy_1" ), GetUnit( "Target" ) ) )
				if GetUnitsDistance( GetUnit( "Dummy_1" ), GetUnit( "Target" ) ) <= 60 then
					call SaveInteger( HashTable, HandleID, StringHash( "TimeLimit" ), Time + 500 )
					call KillUnit( GetUnit( "Dummy_1" ) )
				endif
			endif
			
			if GetInt( "TimeLimit" ) > 0 then
				if Counter( 0, 100 ) then
					call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 220 )
					loop
						set SysUnit = FirstOfGroup( SpellGroup )
						exitwhen SysUnit == null
						if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
							call Damage_Unit( GetUnit( "Caster" ), SysUnit, ( .01 + .01 * GetInt( "ALvL" ) ) * GetUnitState( GetUnit( "Target" ), UNIT_STATE_MAX_LIFE ), "magical" )
							call DestroyEffect( AddSpecialEffectTarget( "Environment\\NightElfBuildingFire\\ElfLargeBuildingFire1.mdl", SysUnit, "origin" ) )
							call DestroyEffect( AddSpecialEffectTarget( "Environment\\NightElfBuildingFire\\ElfLargeBuildingFire1.mdl", SysUnit, "chest" ) )
							call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\DeathandDecay\\DeathandDecayTarget.mdl", SysUnit, "origin" ) )
						endif
						call GroupRemoveUnit( SpellGroup, SysUnit )
					endloop
				endif
			endif
		endif

		if Time == GetInt( "TimeLimit" ) or Stop_Spell( 1 ) then
			call KillUnit( GetUnit( "Dummy_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Kaname_R takes nothing returns nothing
		local integer i
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real DMG
		local real MoveX
		local real MoveY
		local real Angle

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
			set i = 1
			loop
				exitwhen i > 7
				set Angle = GetReal( "Angle" ) - 72 + 18 * i
				set MoveX = NewX( GetReal( "CastX" ), 50, Angle )
				set MoveY = NewY( GetReal( "CastY" ), 50, Angle )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_" + I2S( i ) ), CreateUnit( Player( GetInt( "PID" ) ), 'h020', MoveX, MoveY, Angle ) )
				call UnitApplyTimedLife( GetUnit( "Dummy_" + I2S( i ) ), 'BTLF', .65 )
				set i = i + 1
			endloop
		endif
		
		if Time == 40 then
			call SetUnitTimeScale( GetUnit( "Caster" ), 2.2 )
			call SetUnitAnimation( GetUnit( "Caster" ), "spell throw" )
			call PlaySoundOnUnit( Sounds[ 64 ], 100, GetUnit( "Caster" ) )
			set i = 1
			loop
				exitwhen i > 7
				set Angle = GetUnitFacing( GetUnit( "Dummy_" + I2S( i ) ) )
				set MoveX = GetUnitX( GetUnit( "Dummy_" + I2S( i ) ) )
				set MoveY = GetUnitY( GetUnit( "Dummy_" + I2S( i ) ) )
				set DMG = ( 1.5 + .5 * GetInt( "ALvL" ) ) * GetHeroAgi( GetUnit( "Caster" ), true )
				call SetUnitFlyHeight( Linear_Spell( GetUnit( "Caster" ), MoveX, MoveY, "!BenihikoBlade!.mdl", 3000, 1200, 100, 1, DMG, "" ), 120, 0 )
				call RemoveUnit( GetUnit( "Dummy_" + I2S( i ) ) )
				set i = i + 1
			endloop
		endif

		if Time == 65 or UnitLife( GetUnit( "Caster" ) ) <= 0 then
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call PauseUnit( GetUnit( "Caster" ), false )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Kaname_T takes nothing returns nothing
		local integer i
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			set SysUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h021', GetReal( "CastX" ), GetReal( "CastY" ), 270 )
			call SetUnitVertexColor( SysUnit, 255, 255, 255, 125 )
			call UnitAddAbility( SysUnit, 'A0AC' )
			call UnitApplyTimedLife( SysUnit, 'BTLF', 20. )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), SysUnit )
		endif

		if Time >= 1 and Time <= 2000 then
			if Counter( 0, 100 ) then
				call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 850 )

				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
						call CC_Unit( SysUnit, 1.05, "silence", false )
						call TargetCast( GetUnit( "Caster" ), SysUnit, 'A0C8', GetInt( "ALvL" ), "curse" )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
			endif
		endif

		if Time == 2000 or UnitLife( GetUnit( "Caster" ) ) <= 0 then
			call KillUnit( GetUnit( "Dummy_1" ) )
			call CreateUnit( Player( GetInt( "PID" ) ), 'okod', 8000, 8000, bj_UNIT_FACING )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
    function Kaname_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A0C1' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 66 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Kaname_Q )
		endif
		
		if AID == 'A03D' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 65 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitsAngle( GetTriggerUnit( ), GetSpellTargetUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Kaname_E )
		endif
		
		if AID == 'A0C3' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 64 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Kaname_R )
		endif
		
		if AID == 'A03K' then
			set HandleID = NewMUITimer( PID )
			call RemoveUnitOfPlayerByID( PID, 'okod' )
			call PlaySoundOnUnit( Sounds[ 67 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Kaname_T )
		endif
    endfunction

    function Init_Kaname takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Kaname_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Lucci.j
	function Lucci_W_Normal takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Abilities\\Weapons\\IllidanMissile\\IllidanMissile.mdl", GetUnit( "Caster" ), "origin" ) )
		endif

		if Time == 10 then
			call PlaySoundOnUnit( Sounds[ 120 ], 100, GetUnit( "Caster" ) )
			call CC_Unit( GetUnit( "Target" ), .75, "stun", true )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 125 + 75 * GetInt( "ALvL" ), "physical" )
			call SetUnitXY_4( GetUnit( "Caster" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), GetUnitsDistance( GetUnit( "Caster" ), GetUnit( "Target" ) ) - 80, GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\IllidanMissile\\IllidanMissile.mdl", GetUnit( "Target" ), "origin" ) )
		endif

		if Time == 50 or Stop_Spell( 1 ) then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Lucci_W_Form takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitPathing( GetUnit( "Caster" ), false )
			call SelectUnitRemoveForPlayer( GetUnit( "Caster" ), Player( GetInt( "PID" ) ) )
			call SetUnitTimeScale( GetUnit( "Caster" ), 2.2 )
			call SetUnitAnimation( GetUnit( "Caster" ), "spell slam" )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Abilities\\Weapons\\IllidanMissile\\IllidanMissile.mdl", GetUnit( "Caster" ), "chest" ) )
		endif

		if Time >= 2 then
			if Counter( 0, 3 ) then
				call SetUnitXY_4( GetUnit( "Caster" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 80, GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )
			endif

			if ( Time >= 15 and ( Time == 300 or GetUnitsDistance( GetUnit( "Caster" ), GetUnit( "Target" ) ) <= 100 ) ) or Stop_Spell( 0 ) then
				if UnitLife( GetUnit( "Caster" ) ) > 0 then
					call PlaySoundOnUnit( Sounds[ 120 ], 100, GetUnit( "Caster" ) )
					call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnit( "Target" ), "origin" ) )
					call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 275 )
					loop
						set SysUnit = FirstOfGroup( SpellGroup )
						exitwhen SysUnit == null
						if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
							if SysUnit == GetUnit( "Target" ) then
								call IssueTargetOrder( GetUnit( "Caster" ), "attack", GetUnit( "Target" ) )
								call Damage_Unit( GetUnit( "Caster" ), SysUnit, 250 + 150 * GetInt( "ALvL" ), "physical" )
							else
								call CC_Unit( SysUnit, .75, "stun", true )
								call Damage_Unit( GetUnit( "Caster" ), SysUnit, 125 +  75 * GetInt( "ALvL" ), "physical" )
							endif
						endif
						call GroupRemoveUnit( SpellGroup, SysUnit )
					endloop
				endif
				call DestroyEffect( GetEffect( "Effect_1" ) )
				call PauseUnit( GetUnit( "Caster" ), false )
				call SetUnitPathing( GetUnit( "Caster" ), true )
				call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
				call SelectUnitForPlayerSingle( GetUnit( "Caster" ), Player( GetInt( "PID" ) ) )
				call CleanMUI( GetExpiredTimer( ) )
			endif
		endif
	endfunction

    function Lucci_E takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			call PlaySoundOnUnit( Sounds[ 118 ], 100, GetUnit( "Caster" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl", GetUnit( "Caster" ), "chest" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Incinerate\\IncinerateBuff.mdl", GetUnit( "Caster" ), "chest" ) )
		endif

		if Time >= 1 then
			if not HasAbility( GetUnit( "Caster" ), 'A104' ) then
				call UnitAddAbility( GetUnit( "Caster" ), 'A104' )
			endif
		endif

		if Time == GetInt( "Duration" ) or UnitLife( GetUnit( "Caster" ) ) <= 0 then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'A104' )
			call CleanMUI( GetExpiredTimer( ) )
		endif
    endfunction

    function Lucci_T takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real MoveX
		local real MoveY
		local real DMG
		
		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
			call SetUnitInvulnerable( GetUnit( "Caster" ), true )
			call SetUnitInvulnerable( GetUnit( "Target" ), true )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Abilities\\Weapons\\IllidanMissile\\IllidanMissile.mdl", GetUnit( "Caster" ), "chest" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_2" ), AddSpecialEffectTarget( "Abilities\\Weapons\\IllidanMissile\\IllidanMissile.mdl", GetUnit( "Caster" ), "origin" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_3" ), AddSpecialEffectTarget( "Abilities\\Weapons\\IllidanMissile\\IllidanMissile.mdl", GetUnit( "Caster" ), "hand right" ) )
			call SetUnitXY_4( GetUnit( "Caster" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), GetUnitsDistance( GetUnit( "Caster" ), GetUnit( "Target" ) ) - 80, GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )

			loop
				exitwhen GetAxisDistance( GetReal( "InitX" ), GetReal( "InitY" ), GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) < 100
				set MoveX = NewX( GetReal( "InitX" ), 100, GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )
				set MoveY = NewY( GetReal( "InitY" ), 100, GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", MoveX, MoveY ) )
				call SaveReal( HashTable, HandleID, StringHash( "InitX" ), MoveX )
				call SaveReal( HashTable, HandleID, StringHash( "InitY" ), MoveY )
			endloop
		endif

		if Time == 50 then
			call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
			call PlaySoundOnUnit( Sounds[ 119 ], 100, GetUnit( "Caster" ) )
			call SetUnitInvulnerable( GetUnit( "Target" ), false )
			set DMG = 2000 + 35 * GetInt( "ALvL" )
			if GetUnitTypeId( GetUnit( "Caster" ) ) == 'N00W' then
				set DMG = DMG * 1.25
			endif
			call CC_Unit( GetUnit( "Target" ), 1.5, "stun", true )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), DMG, "physical" )
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call DestroyEffect( GetEffect( "Effect_2" ) )
			call DestroyEffect( GetEffect( "Effect_3" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Undead\\UDeathSmall\\UDeathSmall.mdl", GetUnit( "Target" ), "origin" ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
		endif

		if Time == 60 or Stop_Spell( 2 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitInvulnerable( GetUnit( "Target" ), false )
			call SetUnitInvulnerable( GetUnit( "Caster" ), false )
			call CleanMUI( GetExpiredTimer( ) )
		endif
    endfunction

    function Lucci_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )
		local real DMG

		if AID == 'A06M' then
			if UID != 'N00W' then
				set DMG = 110 + 115 * ALvL
			else
				set DMG = 175 + 125 * ALvL
			endif
			call PlaySoundOnUnit( Sounds[ 117 ], 100, GetTriggerUnit( ) )
			call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "Abilities\\Weapons\\GargoyleMissile\\GargoyleMissile.mdl", 1200, 900, 300, 5, DMG, "" )
		endif

		if AID == 'A079' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			if UID != 'N00W' then
				call TimerStart( LoadMUITimer( PID ), .01, true, function Lucci_W_Normal )
			else
				call TimerStart( LoadMUITimer( PID ), .01, true, function Lucci_W_Form )
			endif
		endif

		if AID == 'A07D' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "Duration" ), ( 3 + ALvL ) * 100 )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Lucci_E )
		endif

		if AID == 'A04U' then
			if UID != 'N00W' then
				call PlaySoundOnUnit( Sounds[ 121 ], 100, GetTriggerUnit( ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Other\\HowlOfTerror\\HowlCaster.mdl", GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ) ) )
			endif
		endif

		if AID == 'A052' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "InitX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "InitY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Lucci_T )
		endif
    endfunction

    function Init_Lucci takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Lucci_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Crocodile.j
	function Crocodile_W takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl", GetUnit( "Target" ), "chest" ) )
		endif

		if Counter( 0, 2 ) then
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), ( GetHeroStr( GetUnit( "Caster" ), false ) * 6 ) / 20, "magical" )
			call SaveInteger( HashTable, HandleID, StringHash( "Damage_Counter" ), GetInt( "Damage_Counter" ) + 1 )
		endif

		if GetInt( "Damage_Counter" ) >= 20 or Stop_Spell( 2 ) then
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Crocodile_E takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real Angle

		if Counter( 0, 15 ) then
			call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl", GetReal( "CastX" ) + GetRandomReal( -250, 250 ), GetReal( "CastY" ) + GetRandomReal( -250, 250 ) ) )
			call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl", GetReal( "CastX" ) + GetRandomReal( -250, 250 ), GetReal( "CastY" ) + GetRandomReal( -250, 250 ) ) )
		endif

		if Counter( 1, 3 ) then
			call DestroyAoEDestruct( GetReal( "CastX" ), GetReal( "CastY" ), 500 )
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 500 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 then
					set Angle = GetAngleCast( SysUnit, GetReal( "CastX" ), GetReal( "CastY" ) )
					call IssueImmediateOrder( SysUnit, "stop" )
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, ( 175 + 25 * GetInt( "ALvL" ) + 5 * GetHeroLevel( GetUnit( "Caster" ) ) ) * .03, "physical" )
					call SetUnitXY_1( SysUnit, NewX( GetUnitX( SysUnit ), 5, Angle ), NewY( GetUnitY( SysUnit ), 5, Angle ), true )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif
		
		if Time == GetInt( "Duration" ) or Stop_Spell( 0 ) then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call DestroyEffect( GetEffect( "Effect_2" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Crocodile_R takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real DMG

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'u999', GetReal( "CastX" ), GetReal( "CastY" ), GetReal( "Angle" ) ) )
			call SetUnitFlyHeight( GetUnit( "Dummy_1" ), 100, 0 )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "SablesPesado.mdl", GetUnit( "Dummy_1" ), "origin" ) )
		endif
		
		if Time >= 1 then
			if GetUnit( "Target" ) == null then
				call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 150 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 and not IsUnitType( SysUnit, UNIT_TYPE_ANCIENT ) then
						call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), SysUnit )
						call GroupClear( SpellGroup )
						exitwhen true
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
			endif
		endif

		if Counter( 0, 3 ) then
			if GetUnit( "Target" ) == null then
				call SetUnitXY_1( GetUnit( "Dummy_1" ), NewX( GetUnitX( GetUnit( "Dummy_1" ) ), 50, GetReal( "Angle" ) ), NewY( GetUnitY( GetUnit( "Dummy_1" ) ), 50, GetReal( "Angle" ) ), true )
				call SaveReal( HashTable, HandleID, StringHash( "Travelled" ), GetReal( "Travelled" ) + 50 )
			else
				call SetUnitXY_1( GetUnit( "Dummy_1" ), GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), true )
				set DMG = ( ( 11. + GetInt( "ALvL" ) ) * GetHeroStr( GetUnit( "Caster" ), false ) ) / 10.
				call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), DMG, "magical" )
				call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 250 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
						if SysUnit != GetUnit( "Target" ) then
							call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG * .4, "magical" )
						endif
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
				call SaveInteger( HashTable, HandleID, StringHash( "Damage_Counter" ), GetInt( "Damage_Counter" ) + 1 )
			endif
		endif

		if ( GetReal( "Travelled" ) > 1000 and GetInt( "Damage_Counter" ) == 0 ) or GetInt( "Damage_Counter" ) >= 10 or Stop_Spell( 0 ) then
			call KillUnit( GetUnit( "Dummy_1" ) )
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Crocodile_T takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real DMG
		local real AoE
		local real Reduction

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitTimeScale( GetUnit( "Caster" ), .3 )
			call SetUnitAnimation( GetUnit( "Caster" ), "spell two" )
			call UnitAddAbility( GetUnit( "Caster" ), 'A0CW' )
			call SaveReal( HashTable, HandleID, StringHash( "Multiplier" ), .37 )
		endif

		if Time >= 40 and Time <= 140 then
			if Counter( 0, 10 ) then
				call SaveInteger( HashTable, HandleID, StringHash( "Wave_Counter" ), GetInt( "Wave_Counter" ) + 1 )
				set AoE = 200 + 100 * GetInt( "Wave_Counter" )
				call EnumUnits_AOE( SpellGroup, GetReal( "InitX" ), GetReal( "InitY" ), AoE )
				call CircularEffect( GetUnit( "Caster" ), AoE, 20, "Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl" )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 then
						set DMG = UnitMaxLife( SysUnit ) * GetReal( "Multiplier" )
						if IsUnitType( SysUnit, UNIT_TYPE_ANCIENT ) then
							set DMG = DMG / 2
						endif
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "physical" )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
				call SaveReal( HashTable, HandleID, StringHash( "Multiplier" ), GetReal( "Multiplier" ) * .85 )
			endif
		endif

		if GetInt( "Wave_Counter" ) == 10 or Stop_Spell( 0 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call SetUnitAnimation( GetUnit( "Caster" ), "Stand" )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'A0CW' )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Crocodile_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A05P' then
			call PlaySoundOnUnit( Sounds[ 105 ], 100, GetTriggerUnit( ) )
			call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "", 900, 1000, 140, 2, 100 + 100 * ALvL + ( 2 + .5 * ALvL ) * GetHeroStr( GetTriggerUnit( ), true ), "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl" )
			call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "", 900, 1000, 140, 2, 0, "Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl" )
		endif

		if AID == 'A07F' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 103 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Crocodile_W )
		endif

		if AID == 'A0C4' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 104 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetSpellTargetY( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "Duration" ), R2I( ( 1.75 + .25 * ALvL ) * 100 ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffect( "Girasole.mdx",  GetSpellTargetX( ),  GetSpellTargetY( ) ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_2" ), AddSpecialEffect( "Girasole.mdx",  GetSpellTargetX( ),  GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Crocodile_E )
		endif

		if AID == 'A0C9' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 107 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Crocodile_R )
		endif

		if AID == 'A0BV' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 106 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "InitX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "InitY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Crocodile_T )
		endif
    endfunction

    function Init_Crocodile takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Crocodile_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Mihawk.j
	function Mihawk_W takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( GetInt( "PID" ) ), 'h00G', GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), GetUnitFacing( GetUnit( "Caster" ) ) ) )
			call SetUnitTimeScale( GetUnit( "Dummy_1" ), .7 )
			call SetUnitAnimation( GetUnit( "Dummy_1" ), "spell" )
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 0 )
			call SetUnitXY_4( GetUnit( "Caster" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), GetUnitsDistance( GetUnit( "Caster" ), GetUnit( "Target" ) ) - 80, GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnit( "Target" ), "origin" ) )
			call CC_Unit( GetUnit( "Target" ), .75, "stun", true )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 5 * GetHeroStr( GetUnit( "Caster" ), false ), "physical" )

			if UnitLife( GetUnit( "Target" ) ) > 0 then
				call IssueTargetOrder( GetUnit( "Caster" ), "attack", GetUnit( "Target" ) )
			endif
		endif

		if Time >= 1 then
			if Counter( 0, 5 ) then
				call SaveInteger( HashTable, HandleID, StringHash( "Iterator" ), GetInt( "Iterator" ) + 1 )
				call SetUnitVertexColor( GetUnit( "Dummy_1" ), 255, 255, 255, R2I( 12.75 * GetInt( "Iterator" ) ) )
				call SetUnitVertexColor( GetUnit( "Caster" ),  255, 255, 255, R2I( 225 - 12.75 * GetInt( "Iterator" ) ) )
			endif
		endif

		if Time == 50 or Stop_Spell( 2 ) then
			call RemoveUnit( GetUnit( "Dummy_1" ) )
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 255 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Mihawk_T takes nothing returns nothing
		local integer i
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitInvulnerable( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "spell" )
			call SetUnitTimeScale( GetUnit( "Caster" ), .3 )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitInvulnerable( GetUnit( "Target" ), true )
		endif

		if Time >= 1 and Time <= 20 then
			if Counter( 0, 5 ) then
				call SaveInteger( HashTable, HandleID, StringHash( "Iterator" ), GetInt( "Iterator" ) + 1 )
				call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 255 - 25 * GetInt( "Iterator" ) )
				call SetUnitXY_4( GetUnit( "Caster" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), -10, GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )
			endif
		endif

		if Time == 20 then
			call ShowUnit( GetUnit( "Caster" ), false )
			// Occupying Dummy_1 -> Dummy_5 | Effect_1 -> Effect_5
			set i = 1
			loop
				exitwhen i > 5
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_" + I2S( i ) ), CreateUnit( Player( GetInt( "PID" ) ), 'h00G', GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), i * 72 ) )
				call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_" + I2S( i ) ), AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile_mini.mdl", GetUnit( "Dummy_" + I2S( i ) ), "hand right" ) )
				call SetUnitPathing( GetUnit( "Dummy_" + I2S( i ) ), false )
				call SetUnitTimeScale( GetUnit( "Dummy_" + I2S( i ) ), .5 )
				call SetUnitAnimation( GetUnit( "Dummy_" + I2S( i ) ), "spell" )
				call SetUnitVertexColor( GetUnit( "Dummy_" + I2S( i ) ), 255, 255, 255, 122 )
				set i = i + 1
			endloop
		endif

		if Time >= 20 and Time <= 70 then
			if Counter( 1, 2 ) then
				set i = 1
				loop
					exitwhen i > 5
					call SetUnitXY_4( GetUnit( "Dummy_" + I2S( i ) ), GetUnitX( GetUnit( "Dummy_" + I2S( i ) ) ), GetUnitY( GetUnit( "Dummy_" + I2S( i ) ) ), 30, i * 72 )
					call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl", GetUnitX( GetUnit( "Dummy_" + I2S( i ) ) ), GetUnitY( GetUnit( "Dummy_" + I2S( i ) ) ) ) )
					set i = i + 1
				endloop
			endif
		endif

		if Time == 75 then
			set i = 1
			loop
				exitwhen i > 5
				call DestroyEffect( GetEffect( "Effect_" + I2S( i ) ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX( GetUnit( "Dummy_" + I2S( i ) ) ), GetUnitY( GetUnit( "Dummy_" + I2S( i ) ) ) ) )
				call RemoveUnit( GetUnit( "Dummy_" + I2S( i ) ) )
				set i = i + 1
			endloop
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitInvulnerable( GetUnit( "Target" ), false )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "MoveX" ), NewX( GetUnitX( GetUnit( "Target" ) ), 100, GetReal( "Angle" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "MoveY" ), NewY( GetUnitY( GetUnit( "Target" ) ), 100, GetReal( "Angle" ) ) )

			if IsTerrainPathable( GetReal( "MoveX" ), GetReal( "MoveY" ), PATHING_TYPE_WALKABILITY ) then
				call SaveReal( HashTable, HandleID, StringHash( "MoveX" ), NewX( GetUnitX( GetUnit( "Target" ) ), -100, GetReal( "Angle" ) ) )
				call SaveReal( HashTable, HandleID, StringHash( "MoveY" ), NewY( GetUnitY( GetUnit( "Target" ) ), -100, GetReal( "Angle" ) ) )
			endif

			call ShowUnit( GetUnit( "Caster" ), true )
			call SetUnitXY_1( GetUnit( "Caster" ), GetReal( "MoveX" ), GetReal( "MoveY" ), true )
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 255 )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX( GetUnit( "Caster" ) ), GetUnitX( GetUnit( "Caster" ) ) ) )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 2000 + GetHeroStr( GetUnit( "Caster" ), false ) * ( 11 * GetInt( "ALvL" ) ), "physical" )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
			call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Human\\HumanBlood\\BloodElfSpellThiefBlood.mdl", GetUnit( "Target" ), "origin" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Human\\HumanBlood\\BloodElfSpellThiefBlood.mdl", GetUnit( "Target" ), "origin" ) )
		endif
		
		if Time == 90 then
			call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Human\\HumanBlood\\BloodElfSpellThiefBlood.mdl", GetUnit( "Target" ), "origin" ) )
		endif
		
		if Time == 140 then
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitInvulnerable( GetUnit( "Caster" ), false )
			call SetUnitPathing( GetUnit( "Caster" ), true )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand ready" )
			call SelectUnitForPlayerSingle( GetUnit( "Caster" ), GetOwningPlayer( GetUnit( "Caster" ) ) )
			call RemoveUnitOfPlayerByID( GetInt( "PID" ), 'h00G' )
		endif

		if Time == 140 or Stop_Spell( 2 ) then
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitInvulnerable( GetUnit( "Target" ), false )
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitInvulnerable( GetUnit( "Caster" ), false )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 255 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Mihawk_Spells takes nothing returns nothing
		local integer i = 0
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )
		local real Angle

		if AID == 'A08A' then
			call PlaySoundOnUnit( Sounds[ 131 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Q_Hits" ), 0 )
			call SaveReal( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Q_Damage" ), ( 1.5 + .25 * ALvL ) * GetHeroStr( GetTriggerUnit( ), false ) )
		endif

		if AID == 'A018' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 132 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Mihawk_W )
		endif

		if AID == 'A03X' then
			call PlaySoundOnUnit( Sounds[ 133 ], 100, GetTriggerUnit( ) )
			set Angle = GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) + 50

			loop
				exitwhen i == 5
				call Linear_Spell( GetTriggerUnit( ), NewX( GetSpellTargetX( ), 256, Angle - i * 25 ), NewY( GetSpellTargetY( ), 256, Angle - i * 25 ), "war3mapImported\\sw_zhaoyun.mdx", 1050, 1000, 150, 1, 100 + 60 * ALvL, "" )
				set i = i + 1
			endloop
		endif

		if AID == 'A03L' then
			call PlaySoundOnUnit( Sounds[ 134 ], 100, GetTriggerUnit( ) )
			set i = 0
			loop
				exitwhen i == 6
				call Linear_Spell( GetTriggerUnit( ), NewX( GetUnitX( GetTriggerUnit( ) ), 300, i * 60 ), NewY( GetUnitY( GetTriggerUnit( ) ), 300, i * 60 ), "Abilities\\Weapons\\GargoyleMissile\\GargoyleMissile.mdl", 800, 150 + 350 * ALvL, 500, 8, 575 + 25 * ALvL, "" )
				set i = i + 1
			endloop
		endif

		if AID == 'A04Y' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 135 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Mihawk_T )
		endif
    endfunction

    function Init_Mihawk takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Mihawk_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Sanji.j
	function Sanji_Q takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real DMG

		if Time == 1 then
			set DMG = 100 + ( 1.5 + .5 * GetInt( "ALvL" ) ) * GetHeroAgi( GetUnit( "Caster" ), true )
			if GetUnitTypeId( GetUnit( "Caster" ) ) != 'N004' then
				set DMG = DMG * 1.2
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnit( "Caster" ), "origin" ) )
			endif
			call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 300 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 then
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "physical" )
					call LinearDisplacement( SysUnit, GetUnitsAngle( GetUnit( "Caster" ), SysUnit ), 100, .2, .01, false, false, "origin", "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl" )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time == 20 or Stop_Spell( 0 ) then
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Sanji_W takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real DMG
		local real Angle

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitTimeScale( GetUnit( "Caster" ), 2 )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
		endif

		if Counter( 0, 10 ) then
			set DMG = 2.5 * GetHeroAgi( GetUnit( "Caster" ), true )
			call SaveInteger( HashTable, HandleID, StringHash( "Veau_Shots" ), GetInt( "Veau_Shots" ) + 1 )
			if GetUnitTypeId( GetUnit( "Caster" ) ) != 'N004' then
				set DMG = DMG * 1.2
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnit( "Target" ), "origin" ) )
			endif
			if GetRandomInt( 1, 100 ) <= 60 then
				call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
			else
				call SetUnitAnimation( GetUnit( "Caster" ), "spell" )
			endif
			call SetUnitAnimation( GetUnit( "Target" ), "stand hit" )
			set Angle = GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), DMG, "physical" )
			call SetUnitXY_2( GetUnit( "Caster" ), GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 30, Angle )
			call SetUnitXY_2( GetUnit( "Target" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 30, Angle )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl", GetUnit( "Target" ), "origin" ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
		endif

		if GetInt( "Veau_Shots" ) == 5 or Stop_Spell( 2 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Sanji_T takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real DMG
		local real Angle

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
		endif
		
		if Time == 2 then
			call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
			call SetUnitXY_2( GetUnit( "Caster" ), GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 75, GetRandomReal( 0, 360 ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )
			call SetUnitFacing( GetUnit( "Caster" ), GetReal( "Angle" ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnit( "Target" ), "origin" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", GetUnit( "Target" ), "origin" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_2" ), AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", GetUnit( "Target" ), "chest" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_3" ), AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", GetUnit( "Target" ), "hand right" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_4" ), AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", GetUnit( "Target" ), "hand left" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_5" ), AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", GetUnit( "Target" ), "foot right" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_6" ), AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", GetUnit( "Target" ), "foot left" ) )
		endif

		if Time == 25 then
			call PauseUnit( GetUnit( "Caster" ), false )
		endif

		if Time >= 2 and Time <= 155 then
			if Counter( 0, 3 ) then
				call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), ( 10 * GetInt( "ALvL" ) * GetHeroLevel( GetUnit( "Caster" ) ) * GetUnitAbilityLevel( GetUnit( "Caster" ), 'A02M' ) ) * .03, "physical" )
				call SetUnitXY_2( GetUnit( "Target" ), GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ),  35, GetReal( "Angle" ) )
				call DestroyAoEDestruct( GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 300 )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl", GetUnit( "Target" ), "origin" ) )
			endif

			if Time == 155 or Stop_Spell( 2 ) then
				call DestroyEffect( GetEffect( "Effect_1" ) )
				call DestroyEffect( GetEffect( "Effect_2" ) )
				call DestroyEffect( GetEffect( "Effect_3" ) )
				call DestroyEffect( GetEffect( "Effect_4" ) )
				call DestroyEffect( GetEffect( "Effect_5" ) )
				call DestroyEffect( GetEffect( "Effect_6" ) )
				call PauseUnit( GetUnit( "Caster" ), false )
				call PauseUnit( GetUnit( "Target" ), false )

				if not Stop_Spell( 2 ) then
					call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
					call SetUnitAnimation( GetUnit( "Target" ), "stand hit critical" )
					call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
					call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
					call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_7" ), AddSpecialEffect( "war3mapImported\\ChaosExplosion.mdx", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
					call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 1000 * GetInt( "ALvL" ), "magical" )
					call SelectUnitForPlayerSingle( GetUnit( "Caster" ), Player( GetInt( "PID" ) ) )
				else
					call CleanMUI( GetExpiredTimer( ) )
				endif
			endif
		endif

		if Time == 300 then
			call DestroyEffect( GetEffect( "Effect_7" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Sanji_Spells takes nothing returns nothing
		local integer i = 0
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )
		local real Angle

		if AID == 'A00J' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 156 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Sanji_Q )
		endif

		if AID == 'A02K' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 157 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Sanji_W )
		endif

		if AID == 'A02M' then
			if UID == 'N004' then
				call PlaySoundOnUnit( Sounds[ 153 ], 100, GetTriggerUnit( ) )
				call CreateUnit( Player( PID ), 'odoc', 8000, 8000, bj_UNIT_FACING )
				call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetTriggerUnit( ), "origin" ) )
				call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", GetUnitX( GetTriggerUnit( ) ), GetUnitY( GetTriggerUnit( ) ) ) )
			else
				call RemoveUnitOfPlayerByID( PID, 'odoc' )
			endif
		endif

		if AID == 'A02P' then
			call PlaySoundOnUnit( Sounds[ 155 ], 100, GetTriggerUnit( ) )
			set Angle = GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) + 50

			loop
				exitwhen i == 3
				call Linear_Spell( GetTriggerUnit( ), NewX( GetSpellTargetX( ), 256, Angle - i * 50 ), NewY( GetSpellTargetY( ), 256, Angle - i * 50 ), "war3mapImported\\FireWave.mdl", 1050, 1200, 150, 1, ( 500 + 12 * GetHeroAgi( GetTriggerUnit( ), true ) ) / 3., "" )
				set i = i + 1
			endloop
		endif

		if AID == 'A02Q' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 154 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Sanji_T )
		endif
    endfunction

    function Init_Sanji takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Sanji_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Luffy.j
	function Luffy_Q takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real DMG

		if Time == 1 then
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\Cripple\\CrippleTarget.mdl", GetUnit( "Caster" ), "origin" ) )
			if GetUnitTypeId( GetUnit( "Caster" ) ) != 'N002' then
				call PlaySoundOnUnit( Sounds[ 130 ], 100, GetUnit( "Caster" ) )
			else
				call PlaySoundOnUnit( Sounds[ 122 ], 100, GetUnit( "Caster" ) )
			endif
		endif

		if Time == 2 then
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
			call SetUnitXY_1( GetUnit( "Caster" ), GetReal( "CastX" ), GetReal( "CastY" ), true )
			set DMG = 110 + 115 * GetInt( "ALvL" )
			if GetUnitTypeId( GetUnit( "Caster" ) ) != 'N002' then
				set DMG = DMG + 150 * GetInt( "ALvL" )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			endif
			call DestroyAoEDestruct( GetReal( "CastX" ), GetReal( "CastY" ), 220 )
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 220 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 then
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "physical" )
					call CC_Unit( SysUnit, .5, "stun", true )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time == 50 or Stop_Spell( 0 ) then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Luffy_W takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real DMG

		if Time == 1 then
			set DMG = 175 + 225 * GetInt( "ALvL" )
			if GetUnitTypeId( GetUnit( "Caster" ) ) != 'N002' then
				set DMG = DMG + 125 + 115 * GetInt( "ALvL" )
				call PlaySoundOnUnit( Sounds[ 127 ], 100, GetUnit( "Caster" ) )
			else
				call PlaySoundOnUnit( Sounds[ 123 ], 100, GetUnit( "Caster" ) )
			endif
			call LinearDisplacement( GetUnit( "Target" ), GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ), 200, .01, .01, false, false, "origin", "" )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), DMG, "physical" )
			call CC_Unit( GetUnit( "Target" ), 1.25, "stun", true )
		endif

		if Time == 5 then
			call SetUnitFacing( GetUnit( "Target" ), GetUnitsAngle( GetUnit( "Target" ), GetUnit( "Caster" ) ) )
			call DestroyEffect( AddSpecialEffect( "war3mapImported\\explosion.mdx", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
		endif

		if Time == 50 or Stop_Spell( 2 ) then
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Luffy_E takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real DMG

		if Time == 1 then
			if GetUnitTypeId( GetUnit( "Caster" ) ) != 'N002' then
				call PlaySoundOnUnit( Sounds[ 128 ], 100, GetUnit( "Caster" ) )
			else
				call PlaySoundOnUnit( Sounds[ 124 ], 100, GetUnit( "Caster" ) )
			endif
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitFacing( GetUnit( "Caster" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), NewX( GetUnitX( GetUnit( "Caster" ) ), 200, GetReal( "Angle" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), NewY( GetUnitY( GetUnit( "Caster" ) ), 200, GetReal( "Angle" ) ) )
		endif

		if Counter( 0, 10 ) then
			set DMG = 100 + 100 * GetInt( "ALvL" )
			call SaveInteger( HashTable, HandleID, StringHash( "Gatling_Hits" ), GetInt( "Gatling_Hits" ) + 1 )
			if GetUnitTypeId( GetUnit( "Caster" ) ) != 'N002' then
				set DMG = DMG + 2 * GetHeroLevel( GetUnit( "Caster" ) ) * GetInt( "ALvL" )
			endif
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call DestroyAoEDestruct( GetReal( "CastX" ), GetReal( "CastY" ), 350 )
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 350 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if UnitLife( SysUnit ) > 0 then
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG / 10, "physical" )
						call CC_Unit( SysUnit, .05, "stun", true )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if GetInt( "Gatling_Hits" ) == 50 or Stop_Spell( 0 ) or GetUnitOrder( GetUnit( "Caster" ) ) != "stampede" then
			if GetUnitOrder( GetUnit( "Caster" ) ) == "stampede" then
				call IssueImmediateOrder( GetUnit( "Caster" ), "stop" )
			endif
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Luffy_T takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real DMG
		local real Dist
		local real CCDur

		if Time == 1 then
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), NewX( GetUnitX( GetUnit( "Caster" ) ), 240, GetReal( "Angle" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), NewY( GetUnitY( GetUnit( "Caster" ) ), 240, GetReal( "Angle" ) ) )
		endif

		if Time == 2 then
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			set DMG = 1400 + 400 * GetInt( "ALvL" )
			if GetUnitTypeId( GetUnit( "Caster" ) ) != 'N002' then
				set CCDur = 3
				set DMG = DMG + GetRandomReal( 14 * GetInt( "ALvL" ), 20 * GetInt( "ALvL" ) ) *  GetHeroLevel( GetUnit( "Caster" ) )
			endif
			call DestroyAoEDestruct( GetReal( "CastX" ), GetReal( "CastY" ), 400 )
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 400 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 then
					if CCDur > 0 then
						call CC_Unit( SysUnit, CCDur, "stun", true )
					endif
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, DMG, "physical" )
					call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( SysUnit ), GetUnitY( SysUnit ) ) )
					set Dist = 500 - GetAxisDistance( GetReal( "CastX" ), GetReal( "CastY" ), GetUnitX( SysUnit ), GetUnitY( SysUnit ) )
					if Dist < 0 then
						set Dist = Dist * -1
					endif
					if Dist > 500 then
						set Dist = 500
					endif
					call LinearDisplacement( SysUnit, GetReal( "Angle" ), Dist, .5, .01, false, false, "origin", "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl" )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time == 5 or Stop_Spell( 0 ) then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Luffy_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A00H' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetSpellTargetY( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Luffy_Q )
		endif

		if AID == 'A00M' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Luffy_W )
		endif
		
		if AID == 'A0BL' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Luffy_E )
		endif

		if AID == 'A00O' then
			if UID == 'N002' then
				call PlaySoundOnUnit( Sounds[ 125 ], 100, GetTriggerUnit( ) )
				call SetUnitVertexColor( GetTriggerUnit( ), 255, 190, 190, 255 )
				call SetUnitAnimation( GetTriggerUnit( ), "spell" )
			else
				call SetUnitVertexColor( GetTriggerUnit( ), 255, 255, 255, 255 )
			endif
		endif

		if AID == 'A00Q' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 126 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Luffy_T )
		endif
    endfunction

    function Init_Luffy takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Luffy_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Enel.j
	function Enel_Q takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Counter( 0, 10 ) then
			call SaveInteger( HashTable, HandleID, StringHash( "El_Thor_Hits" ), GetInt( "El_Thor_Hits" ) + 1 )
			call DestroyEffect( AddSpecialEffect( "war3mapImported\\El_Thor.mdl", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call DestroyAoEDestruct( GetReal( "CastX" ), GetReal( "CastY" ), 250 )
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 250 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, 150 + 3 * GetHeroInt( GetUnit( "Caster" ), true ), "magical" )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), NewX( GetReal( "CastX" ), 180, GetReal( "Angle" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), NewY( GetReal( "CastY" ), 180, GetReal( "Angle" ) ) )
		endif

		if GetInt( "El_Thor_Hits" ) == GetInt( "ALvL" ) or Stop_Spell( 0 ) then
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Enel_E takes nothing returns nothing
		local integer i
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			set i = 1
			call PlaySoundOnUnit( Sounds[ 111 ], 100, GetUnit( "Caster" ) )
			loop
				exitwhen i == 5
				set bj_lastCreatedUnit = CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'h000', GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 270 )
				call ScaleUnit( bj_lastCreatedUnit, 14 )
				call SetUnitTimeScale( bj_lastCreatedUnit, .25 * i )
				call UnitApplyTimedLife( bj_lastCreatedUnit, 'BTLF', 5 )
				set i = i + 1
			endloop

			call DestroyAoEDestruct( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 1650 )
			call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 1650 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 then
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, ( 5 + 3 * GetInt( "ALvL" ) ) * GetHeroInt( GetUnit( "Caster" ), true ), "magical" )
					call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", SysUnit, "origin" ) )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Enel_R takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1500 or UnitLife( GetUnit( "Caster" ) ) <= 0 then
			call SaveInteger( HashTable, GetHandleId( Player( GetInt( "PID" ) ) ), StringHash( "Mamaragan_AP_Chance" ), 0 )
			call SaveInteger( HashTable, GetHandleId( Player( GetInt( "PID" ) ) ), StringHash( "Mamaragan_AD_Chance" ), 0 )
			call EnableWeatherEffect( Player_Weather[ GetInt( "PID" ) ], false )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Enel_T takes nothing returns nothing
		local integer i
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( GetInt( "PID" ) ), 'h01L', GetReal( "CastX" ), GetReal( "CastY" ), GetRandomReal( 0, 360 ) ) )
			call UnitAddAbility( GetUnit( "Dummy_1" ), 'A030' )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Lightning_Ball_Tail_FX.mdx", GetUnit( "Dummy_1" ), "origin" ) )
		endif

		if Time > 1200 or Stop_Spell( 0 ) or GetUnitsDistance( GetUnit( "Caster" ), GetUnit( "Dummy_1" ) ) > 700 or HasAbility( GetUnit( "Caster" ), 'BNsi' ) then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call RemoveUnit( GetUnit( "Dummy_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif

		if Time >= 1 and Time <= 1200 then
			if Counter( 0, 5 ) then
				call SaveInteger( HashTable, HandleID, StringHash( "Raigo_Waves" ), GetInt( "Raigo_Waves" ) + 1 )
				call SetWidgetLife( GetUnit( "Caster" ), GetUnitState( GetUnit( "Caster" ), UNIT_STATE_LIFE ) + 12 )
				call IssueTargetOrder( GetUnit( "Dummy_1" ), "fingerofdeath", GetUnit( "Caster" ) )
				call ScaleUnit( GetUnit( "Dummy_1" ), .03 * GetInt( "Raigo_Waves" ) )
				call SetUnitFlyHeight( GetUnit( "Dummy_1" ), 2.3 * GetInt( "Raigo_Waves" ), 0 )
				set bj_lastCreatedUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h01N', GetReal( "CastX" ), GetReal( "CastY" ), 270 )
				call ScaleUnit( GetUnit( "Dummy_1" ), .03 * GetInt( "Raigo_Waves" ) )
				call SetUnitFlyHeight( bj_lastCreatedUnit, 2.3 * GetInt( "Raigo_Waves" ), 0 )
				call UnitApplyTimedLife( bj_lastCreatedUnit, 'BTLF', .1 )
			endif
		endif

		if Time == 1200 then
			call DestroyAoEDestruct( GetReal( "CastX" ), GetReal( "CastY" ), 3000 )
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 3000 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if UnitLife( SysUnit ) > 0 then
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, ( 27.5 + 2.5 * GetInt( "ALvL" ) ) * GetHeroInt( GetUnit( "Caster" ), true ), "magical" )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
			set i = 1
			loop
				exitwhen i > 12
				set bj_lastCreatedUnit = CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'h000', GetReal( "CastX" ), GetReal( "CastY" ), 270 )
				call ScaleUnit( bj_lastCreatedUnit, 16 )
				call SetUnitFlyHeight( bj_lastCreatedUnit, 860, 0 )
				call SetUnitTimeScale( bj_lastCreatedUnit, .10 * i )
				call UnitApplyTimedLife( bj_lastCreatedUnit, 'BTLF', 4 )
				set i = i + 1
			endloop
		endif
	endfunction

    function Enel_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A0BI' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 108 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetSpellTargetY( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Enel_Q )
		endif

		if AID == 'A02X' then
			call PlaySoundOnUnit( Sounds[ 109 ], 100, GetTriggerUnit( ) )
		endif

		if AID == 'A02Y' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 111 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Enel_E )
		endif

		if AID == 'A02U' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 112 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, GetHandleId( Player( PID ) ), StringHash( "Mamaragan_AP_Chance" ), 25 + 5 * ALvL )
			call SaveInteger( HashTable, GetHandleId( Player( PID ) ), StringHash( "Mamaragan_AD_Chance" ),  5 + 3 * ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			if Player_Weather[ PID ] == null then
				set Player_Weather[ PID ] = AddWeatherEffect( GetWorldBounds( ), 'RLhr' )
			endif
			call EnableWeatherEffect( Player_Weather[ PID ], true )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Enel_R )
		endif

		if AID == 'A07G' or AID == 'A02Z' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 110 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetSpellTargetY( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Enel_T )
		endif
    endfunction

    function Init_Enel takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Enel_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Ace.j
	function Ace_W takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect1" ), AddSpecialEffectTarget( "Abilities\\Spells\\Other\\ImmolationRed\\ImmolationRedTarget.mdl", GetUnit( "Target"  ), "chest" ) )
		endif

		if Counter( 0, 100 ) then
			call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 220 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if UnitLife( SysUnit ) > 0 then
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, 50 * GetInt( "ALvL" ) + 4 * GetHeroLevel( GetUnit( "Caster" ) ), "magical" )
						call DestroyEffect( AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", GetUnit( "Target"  ), "chest" ) )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time > 600 or UnitLife( GetUnit( "Target" ) ) <= 0 then
			call DestroyEffect( GetEffect( "Effect1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Ace_E takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real MoveX
		local real MoveY

		if Time == 1 then
			call DestroyEffect( AddSpecialEffect( "FlameShockwave.mdx", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call DestroyAoEDestruct( GetReal( "CastX" ), GetReal( "CastY" ), 350 )
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 350 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
					call TargetCast( GetUnit( "Caster" ), SysUnit, 'A07E', 1, "slow" )
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, ( 5 + 5 * GetInt( "ALvL" ) ) * GetHeroLevel( GetUnit( "Caster" ) ), "magical" )
					call GroupAddUnit( GetGroup( "Flame_Group" ), SysUnit )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time >= 1 then
			if Counter( 0, 100 ) then
				call Make_Dummy_Group( GetGroup( "Flame_Group" ) )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if UnitLife( SysUnit ) > 0 then
						call DestroyEffect( AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", SysUnit, "origin" ) )
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, 125. + 25. * GetInt( "ALvL" ), "magical" )
					else
						call GroupRemoveUnit( GetGroup( "Flame_Group" ), SysUnit )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
			endif
		endif

		if Time > 300 or Stop_Spell( 0 ) then
			call DestroyGroup( GetGroup( "Flame_Group" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Ace_R takes nothing returns nothing
		local integer i
		local integer j
		local integer ID
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real Dist
		local real Stun_Dur

		if Time == 1 then
			call SaveInteger( HashTable, HandleID, StringHash( "Limit" ), R2I( GetInt( "ALvL" ) / 2. + .5 ) )
			set i = 1
			loop
				exitwhen i > GetInt( "Limit" )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Target_" + I2S( i ) ), GetRandomEnemyHeroInArea( GetInt( "PID" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 2000 ) )
				if GetUnit( "Target_" + I2S( i ) ) != null then
					call SaveInteger( HashTable, HandleID, StringHash( "Targets" ), GetInt( "Targets" ) + 1 )
				endif
				set i = i + 1
			endloop
		endif

		if Time == 5 then
			call SaveInteger( HashTable, HandleID, StringHash( "Limit" ), GetInt( "Limit" ) * 10 )
			set i = 1
			set j = 1
			loop
				exitwhen i > GetInt( "Limit" )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_" + I2S( i ) ), CreateUnit( Player( GetInt( "PID" ) ), 'h001', NewX( GetUnitX( GetUnit( "Caster" ) ), 60, j * 120 ), NewY( GetUnitY( GetUnit( "Caster" ) ), 60, j * 120 ), i * 12 ) )
				call SetUnitFlyHeight( GetUnit( "Dummy_" + I2S( i ) ), 500, 500 )
				if i == 10 or i == 20 then
					set j = j + 1
				endif
				set i = i + 1
			endloop
		endif

		if Time >= 50 and Time <= 100 then
			if Counter( 0, 2 ) then
				set i = 1
				set j = 1
				loop
					exitwhen i > GetInt( "Limit" )
					call SetUnitXY_2( GetUnit( "Dummy_" + I2S( i ) ), GetUnitX( GetUnit( "Dummy_" + I2S( i ) ) ), GetUnitY( GetUnit( "Dummy_" + I2S( i ) ) ), 6, j * 36 )
					call SetUnitFlyHeight( GetUnit( "Dummy_" + I2S( i ) ), GetUnitFlyHeight( GetUnit( "Dummy_" + I2S( i ) ) ) + 20, 0 )
					set j = j + 1
					if j > 10 then
						set j = 0
					endif
					set i = i + 1
				endloop
			endif
		endif

		if Time >= 100 and Time <= 800 then
			if Counter( 1, 3 ) then
				set i = 1
				set ID = 1
				loop
					exitwhen i > GetInt( "Limit" )
					if GetUnit( "Dummy_" + I2S( i ) ) != null then
						call SetUnitXY_2( GetUnit( "Dummy_" + I2S( i ) ), GetUnitX( GetUnit( "Dummy_" + I2S( i ) ) ), GetUnitY( GetUnit( "Dummy_" + I2S( i ) ) ), 20, GetUnitsAngle( GetUnit( "Dummy_" + I2S( i ) ), GetUnit( "Target_" + I2S( ID ) ) ) )
						set Dist = GetUnitsDistance( GetUnit( "Dummy_" + I2S( i ) ), GetUnit( "Target_" + I2S( ID ) ) )
						call SetUnitFlyHeight( GetUnit( "Dummy_" + I2S( i ) ), Dist / 2, 0 )
						if Dist <= 100 then
							if i < 10 then
								set j = 1
							else
								set j = ( ID - 1 ) * 10
							endif
							call DestroyEffect( AddSpecialEffect( "war3mapImported\\ChaosExplosion.mdx", GetUnitX( GetUnit( "Target_" + I2S( ID ) ) ), GetUnitY( GetUnit( "Target_" + I2S( ID ) ) ) ) )
							call DestroyEffect( AddSpecialEffect( "Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", GetUnitX( GetUnit( "Target_" + I2S( ID ) ) ), GetUnitY( GetUnit( "Target_" + I2S( ID ) ) ) ) )
							set Stun_Dur = .5
							if GetUnit( "Target_" + I2S( ID ) ) != GetUnit( "Target_1" ) then
								set Stun_Dur = Stun_Dur + .5
							endif
							if GetUnit( "Target_" + I2S( ID ) ) != GetUnit( "Target_2" ) then
								set Stun_Dur = Stun_Dur + .5
							endif
							if GetUnit( "Target_" + I2S( ID ) ) != GetUnit( "Target_3" ) then
								set Stun_Dur = Stun_Dur + .5
							endif
							call CC_Unit( GetUnit( "Target_" + I2S( ID ) ), Stun_Dur, "stun", true )
							call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target_" + I2S( ID ) ), 650 + 150 * GetInt( "ALvL" ), "magical" )
							loop
								exitwhen j > ID * 10
								call SetUnitXY( GetUnit( "Dummy_" + I2S( j ) ), GetUnitX( GetUnit( "Target_" + I2S( ID ) ) ), GetUnitY( GetUnit( "Target_" + I2S( ID ) ) ) )
								call SetUnitFlyHeight( GetUnit( "Dummy_" + I2S( j ) ), 0, 0 )
								call KillUnit( GetUnit( "Dummy_" + I2S( j ) ) )
								call RemoveSavedHandle( HashTable, HandleID, StringHash( "Dummy_" + I2S( j ) ) )
								set j = j + 1
							endloop
						endif
					endif
					if i == 10 or i == 20 then
						set ID = ID + 1
					endif
					set i = i + 1
				endloop
			endif
		endif

		if Time == 800 or Stop_Spell( 0 ) or GetInt( "Targets" ) == 0 then
			set i = 1
			loop
				exitwhen i > 30
				if GetUnit( "Dummy_" + I2S( i ) ) != null then
					call KillUnit( GetUnit( "Dummy_" + I2S( i ) ) )
				endif
				set i = i + 1
			endloop
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Ace_T takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "spell two" )
		endif

		if Time == 100 then
			call PlaySoundOnUnit( Sounds[ 88 ], 100, GetUnit( "Caster" ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'u999', GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 270 ) )
			call ScaleUnit( GetUnit( "Dummy_1" ), 8 )
			call DestroyEffect( AddSpecialEffectTarget( "war3mapImported\\Impact.mdl", GetUnit( "Dummy_1" ), "origin" ) )
			call SetUnitFlyHeight( GetUnit( "Dummy_1" ), 500, 0 )
		endif

		if Time == 300 then
			call ScaleUnit( GetUnit( "Dummy_1" ), 5 )
			call SetUnitFlyHeight( GetUnit( "Dummy_1" ), 0, 0 )
			call DestroyEffect( AddSpecialEffectTarget( "war3mapImported\\NewMassiveEX.mdl", GetUnit( "Dummy_1" ), "origin" ) ) // 'h00B'
			call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Other\\NeutralBuildingExplosion\\NeutralBuildingExplosion.mdl", GetUnit( "Dummy_1" ), "origin" ) ) // 'h007'
			call DestroyEffect( AddSpecialEffect( "war3mapImported\\A-Bomb.mdx", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
			call BasicAoEDMG( GetUnit( "Caster" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 1000, 3000 + 30 * GetInt( "ALvL" ) * GetHeroLevel( GetUnit( "Caster" ) ), "magical" )
		endif

		if Time == 300 or Stop_Spell( 0 ) then
			call RemoveUnit( GetUnit( "Dummy_1" ) )
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Ace_Spells takes nothing returns nothing
		local integer i = 0
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A031' then
			call PlaySoundOnUnit( Sounds[ 92 ], 100, GetTriggerUnit( ) )
			call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "war3mapImported\\FireWave.mdl", 1000, 900, 400, 2, 110 + 115 * ALvL, "" )
		endif
		
		if AID == 'A08F' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 89 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ace_W )
		endif

		if AID == 'A034' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 90 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveGroupHandle( HashTable, HandleID, StringHash( "Flame_Group" ), CreateGroup( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ace_E )
		endif
		
		if AID == 'A033' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 87 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ace_R )
		endif

		if AID == 'A03A' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 86 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Ace_T )
		endif
    endfunction

    function Init_Ace takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Ace_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Kuma.j
	function Kuma_E takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )
		local real LocX
		local real LocY
		local real Random

		if Counter( 0, 15 ) then
			set i = 1
			loop
				exitwhen i > 2
				set Random = GetRandomReal( 30, 90 )
				set LocX = NewX( GetReal( "CastX" ), Random, GetReal( "Angle" ) + 90 )
				set LocY = NewY( GetReal( "CastY" ), Random, GetReal( "Angle" ) + 90 )
				set SysUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h01Y', LocX, LocY, GetReal( "Angle" ) )
				call SetUnitVertexColor( SysUnit, 255, 255, 255, 255 )

				set Random = GetRandomReal( 30, 90 )
				set LocX = NewX( GetReal( "CastX" ), Random, GetReal( "Angle" ) - 90 )
				set LocY = NewY( GetReal( "CastY" ), Random, GetReal( "Angle" ) - 90 )
				set SysUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h01Y', LocX, LocY, GetReal( "Angle" ) )
				call SetUnitVertexColor( SysUnit, 255, 255, 255, 255 )
				set i = i + 1
			endloop

			call Linear_Spell( GetUnit( "Caster" ), GetReal( "CastX" ), GetReal( "CastY" ), "", 300, 600, 300, 1, ( 150 + 50 * GetInt( "ALvL" ) + ( 3.5 + .5 * GetInt( "ALvL" ) ) * GetHeroInt( GetUnit( "Caster" ), true ) ) / 6, "" )
			call SaveInteger( HashTable, HandleID, StringHash( "Paw_Hits" ), GetInt( "Paw_Hits" ) + 1 )
		endif

		if Counter( 1, 3 ) then
			call EnumUnits_Player( SpellGroup, GetInt( "PID" ) )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if GetUnitTypeId( SysUnit ) == 'h01Y' then
					if GetUnitsDistance( GetUnit( "Caster" ), SysUnit ) <= 600 then
						call SetUnitXY_2( SysUnit, GetUnitX( SysUnit ), GetUnitY( SysUnit ), GetRandomReal( 15, 30 ), GetReal( "Angle" ) )
					else
						call KillUnit( SysUnit )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Stop_Spell( 0 ) or GetUnitOrder( GetUnit( "Caster" ) ) != "stampede" or GetInt( "Paw_Hits" ) >= 25 then
			if GetUnitOrder( GetUnit( "Caster" ) ) == "stampede" then
				call IssueImmediateOrder( GetUnit( "Caster" ), "stop" )
			endif
			call RemoveUnitOfPlayerByID( GetInt( "PID" ), 'h01Y' )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Kuma_R takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real HP_Regen
		local real MP_Regen

		if Time == 1 then
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "PawAura.mdx", GetUnit( "Target" ), "origin" ) )
		endif

		if Counter( 0, 100 ) then
			set HP_Regen = 2.2 * GetHeroInt( GetUnit( "Caster" ), true ) //UnitMaxLife( GetUnit( "Target" ) ) - UnitLife( GetUnit( "Target" ) )
			set MP_Regen = 1.1 * GetHeroInt( GetUnit( "Caster" ), true ) //GetUnitState( GetUnit( "Target" ), UNIT_STATE_MAX_MANA ) - GetUnitState( GetUnit( "Target" ), UNIT_STATE_MANA )
			call SetWidgetLife( GetUnit( "Target" ), UnitLife( GetUnit( "Target" ) ) + HP_Regen )
			call SetUnitManaBJ( GetUnit( "Target" ), GetUnitState( GetUnit( "Target" ), UNIT_STATE_MANA ) + MP_Regen )
			if not IsUnitInArea( GetUnit( "Target" ), "rapire" ) then
				call UnitRemoveBuffs( GetUnit( "Target" ), false, true ) // Remove Negative Buffs
			endif
			call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), 350 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if UnitLife( SysUnit ) > 0 and not IsUnitType( SysUnit, UNIT_TYPE_ANCIENT ) then
					if IsUnitEnemy_v2( GetUnit( "Target" ), SysUnit ) then
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, HP_Regen, "magical" )
						if MP_Regen < GetUnitState( SysUnit, UNIT_STATE_MANA ) then
							call SetUnitManaBJ( SysUnit, GetUnitState( SysUnit, UNIT_STATE_MANA ) - MP_Regen )
						else
							call SetUnitManaBJ( SysUnit, 0 )
						endif
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time == 1000 or Stop_Spell( 1 ) then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Kuma_T takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )
		
		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1.5 )
			call SetUnitAnimation( GetUnit( "Caster" ), "spell three" )
		endif

		if Time == 200 then
			call SetUnitAnimation( GetUnit( "Caster" ), "spell two" )
			call DestroyEffect( AddSpecialEffect( "UrsusShock.mdx", GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) ) )
			call DestroyAoEDestruct( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 900 )
			call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 900 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if UnitLife( SysUnit ) > 0 then
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
						if Damage_Unit( GetUnit( "Caster" ), SysUnit, 1000 + ( 10 + 4 * GetInt( "ALvL" ) ) * GetHeroInt( GetUnit( "Caster" ), true ), "magical" ) then
							call CC_Unit( SysUnit, 3, "silence", false )
							call TargetCast( GetUnit( "Caster" ), SysUnit, 'A07E', 1, "slow" )
						endif
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time > 200 or Stop_Spell( 0 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Kuma_Spells takes nothing returns nothing
		local integer i = 0
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A0BW' then
			call PlaySoundOnUnit( Sounds[ 113 ], 100, GetTriggerUnit( ) )
			call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "!Ylaser!.mdl", 1500, 1100, 200, .7, 100 + 100 * ALvL + ALvL * GetHeroInt( GetTriggerUnit( ), true ), "" )
		endif

		if AID == 'A0BX' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 114 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Kuma_E )
		endif

		if AID == 'A0BY' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 115 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Kuma_R )
		endif

		if AID == 'A07M' or AID == 'A053' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 116 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Kuma_T )
		endif
    endfunction

    function Init_Kuma takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Kuma_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Aokiji.j
	function Aokiji_V takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( GetInt( "PID" ) ), 'n00V', GetReal( "CastX" ), GetReal( "CastY" ), 270 ) )
			call UnitApplyTimedLife( GetUnit( "Dummy_1" ), 'BTLF', 20 )
		endif

		if Counter( 0, 50 ) then
			if IsEnemyHeroInAoE( GetInt( "PID" ), GetReal( "CastX" ), GetReal( "CastY" ), 350 ) then
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetReal( "CastX" ), GetReal( "CastY" ) ) )
				call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 350 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if UnitLife( SysUnit ) > 0 then
						if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
							call CC_Unit( SysUnit, 1.2, "stun", false )
							call Damage_Unit( GetUnit( "Caster" ), SysUnit, 450, "magical" )
						endif
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
				call KillUnit( GetUnit( "Dummy_1" ) )
			endif
		endif

		if Time == 2000 or UnitLife( GetUnit( "Dummy_1" ) ) <= 0 then
			call RemoveUnit( GetUnit( "Dummy_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Aokiji_Q takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Counter( 0, 3 ) then
			call SaveInteger( HashTable, HandleID, StringHash( "Travelled" ), GetInt( "Travelled" ) + 100 )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), NewX( GetReal( "CastX" ), 100, GetReal( "Angle" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), NewY( GetReal( "CastY" ), 100, GetReal( "Angle" ) ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\FrostWyrmMissile\\FrostWyrmMissile.mdl", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\FreezingBreath\\FreezingBreathMissile.mdl", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 150 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if UnitLife( SysUnit ) > 0 then
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and not IsUnitIgnored( SysUnit ) then
						call CC_Unit( SysUnit, 1.5, "stun", true )
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, 100 + 125 * GetInt( "ALvL" ), "magical" )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if GetInt( "Travelled" ) >= 1200 or Stop_Spell( 0 ) then
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Aokiji_E takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real MoveX
		local real MoveY

		if Time == 1 then
			call CC_Unit( GetUnit( "Target" ), 1, "stun", true )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_0" ), CreateUnit( Player( GetInt( "PID" ) ), 'u002', GetReal( "TargX" ), GetReal( "TargY" ), 270 ) )
			call UnitAddAbility( GetUnit( "Dummy_0" ), 'A0AZ' )
			call UnitApplyTimedLife( GetUnit( "Dummy_0" ), 'BTLF', 1.5 + .5 * GetInt( "ALvL" ) )

			set i = 1
			loop
				exitwhen i > 18
				set MoveX = NewX( GetReal( "TargX" ), 150, i * 20 )
				set MoveY = NewY( GetReal( "TargY" ), 150, i * 20 )
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_" + I2S( i ) ), CreateUnit( Player( GetInt( "PID" ) ), 'h013', MoveX, MoveY, GetRandomReal( 0, 360 ) ) )
				call ScaleUnit( GetUnit( "Dummy_" + I2S( i ) ), .88 )
				call UnitApplyTimedLife( GetUnit( "Dummy_" + I2S( i ) ), 'BTLF', 1.5 + .5 * GetInt( "ALvL" ) )
				set i = i + 1
			endloop
		endif

		if Counter( 0, 50 ) then
			call EnumUnits_AOE( SpellGroup, GetReal( "TargX" ), GetReal( "TargY" ), 400 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if UnitLife( SysUnit ) > 0 then
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, ( 175 + 25 * GetInt( "ALvL" ) + 5 * GetHeroLevel( GetUnit( "Caster" ) ) ) * .5, "magical" )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time == GetInt( "Duration" ) or Stop_Spell( 2 ) then
			set i = 0
			loop
				exitwhen i > 18
				call RemoveUnit( GetUnit( "Dummy_" + I2S( i ) ) )
				set i = i + 1
			endloop
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Aokiji_R takes nothing returns nothing
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetRandomEnemyHeroInArea( GetInt( "PID" ), GetReal( "CastX" ), GetReal( "CastY" ), 300 ) )
			if GetUnit( "Target" ) == null then
				call ResetAbilityCD( GetUnit( "Caster" ), GetInt( "AID" ) )
				call CleanMUI( GetExpiredTimer( ) )
			endif
		endif
		
		if GetInt( "Count" ) > 0 then
			if GetInt( "Count" ) == 10 then
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
				call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\FreezingBreath\\FreezingBreathMissile.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
			endif
			if Counter( 0, 100 ) then
				call TextTagSimpleUnit( "|c0000FFFF" + I2S( GetInt( "Count" ) ) + "|r", GetUnit( "Target" ), 11, 255, 1.6 )
				call TargetCast( GetUnit( "Caster" ), GetUnit( "Target" ), 'A0A5', 6, "frostnova" )
                call UnitRemoveAbility( GetUnit( "Target" ), 'B00Q' )
                call UnitRemoveAbility( GetUnit( "Target" ), 'B00R' )
				call SaveInteger( HashTable, HandleID, StringHash( "Count" ), GetInt( "Count" ) - 1 )
			endif
		endif

		if GetInt( "Count" ) == 0 then
			call CC_Unit( GetUnit( "Target" ), 4, "stun", true )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 600, "magical" )
			call SaveInteger( HashTable, HandleID, StringHash( "Count" ), GetInt( "Count" ) - 1 )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Weapons\\FrostWyrmMissile\\FrostWyrmMissile.mdl", GetUnit( "Target" ), "origin" ) )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "Abilities\\Spells\\Undead\\FreezingBreath\\FreezingBreathTargetArt.mdl", GetUnit( "Target" ), "origin" ) )
		endif

		if Time == 1400 or Stop_Spell( 1 ) then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Aokiji_T takes nothing returns nothing
		local integer i
		local integer j
		local integer Time     = SpellTime( )
		local integer HandleID = MUIHandle( )
		local real Angle
		local real MoveX
		local real MoveY

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SetUnitInvulnerable( GetUnit( "Caster" ), true )
			call SetUnitTimeScale( GetUnit( "Caster" ), .75 )
			call SetUnitAnimation( GetUnit( "Caster" ), "spell one" )
		endif

		if Time == 5 then
			call DestroyEffect( AddSpecialEffect( "war3mapImported\\icestomp.mdx", GetReal( "CastX" ), GetReal( "CastY" ) ) )
			set i = 1
			loop
				exitwhen i > 3
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_" + I2S( i ) ), CreateUnit( Player( GetInt( "PID" ) ), 'h015', GetReal( "CastX" ), GetReal( "CastY" ), GetRandomReal( 0, 360 ) ) )
				call SetUnitTimeScale( GetUnit( "Dummy_1" + I2S( i ) ), .3 * i )
				call ScaleUnit( GetUnit( "Dummy_1" + I2S( i ) ), 3.2 )
				set i = i + 1
			endloop
		endif

		if Time == 30 then
			set bj_lastCreatedUnit = CreateUnit( Player( GetInt( "PID" ) ), 'u002', GetReal( "CastX" ), GetReal( "CastY" ), 270 )
			call UnitAddAbility( bj_lastCreatedUnit, 'A0A8' )
			call UnitApplyTimedLife( bj_lastCreatedUnit, 'BTLF', 7 )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_0" ), bj_lastCreatedUnit )
		endif

		if Time >= 5 and Time <= 65 then
			if Counter( 0, 8 ) then
				call SaveInteger( HashTable, HandleID, StringHash( "Ice_Waves" ), GetInt( "Ice_Waves" ) + 1 )
				set i = 1
				set j = GetInt( "Ice_Waves" )
				set Angle = 0
				loop
					exitwhen i > 8 * j
					set Angle = Angle + 360 / ( 8 * j )
					set MoveX = NewX( GetReal( "CastX" ), j * 175, Angle )
					set MoveY = NewY( GetReal( "CastY" ), j * 175, Angle )
					set bj_lastCreatedUnit = CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'h014', MoveX, MoveY, GetRandomReal( 0, 360 ) )
					if j < 4 then
						call ScaleUnit( bj_lastCreatedUnit, 1 )
					else
						call ScaleUnit( bj_lastCreatedUnit, .25 * j )
					endif

					call UnitApplyTimedLife( bj_lastCreatedUnit, 'BTLF', .5 )
					call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\FrostWyrmMissile\\FrostWyrmMissile.mdl", MoveX, MoveY ) )
					call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Undead\\FreezingBreath\\FreezingBreathMissile.mdl", MoveX, MoveY ) )
					call EnumUnits_AOE( SpellGroup, MoveX, MoveY, 300 )
					loop
						set SysUnit = FirstOfGroup( SpellGroup )
						exitwhen SysUnit == null
						if UnitLife( SysUnit ) > 0 then
							if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and not IsUnitIgnored( SysUnit ) then
								call CC_Unit( SysUnit, 4, "stun", true )
								call Damage_Unit( GetUnit( "Caster" ), SysUnit, 2000 + 20 * GetInt( "ALvL" ) * GetHeroLevel( GetUnit( "Caster" ) ), "physical" )
							endif
						endif
						call GroupRemoveUnit( SpellGroup, SysUnit )
					endloop
					set i = i + 1
				endloop
			endif
		endif

		if Time == 70 or Stop_Spell( 0 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitInvulnerable( GetUnit( "Caster" ), false )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			set i = 0
			loop
				exitwhen i > 3
				call RemoveUnit( GetUnit( "Dummy_1" + I2S( i ) ) )
				set i = i + 1
			endloop
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Aokiji_Spells takes nothing returns nothing
		local integer HandleID
		local integer AID  = GetSpellAbilityId( )
		local integer PID  = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID  = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A09J' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 93 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), NewX( GetUnitX( GetTriggerUnit( ) ), 50, GetUnitFacing( GetTriggerUnit( ) ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), NewY( GetUnitY( GetTriggerUnit( ) ), 50, GetUnitFacing( GetTriggerUnit( ) ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Aokiji_V )
		endif

		if AID == 'A09K' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 94 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Aokiji_Q )
		endif

		if AID == 'A09C' then
			if UID == 'N009' then
				call PlaySoundOnUnit( Sounds[ 97 ], 100, GetTriggerUnit( ) )
			endif
		endif
		
		if AID == 'A09M' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 96 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "Duration" ), R2I( ( 1.5 + .5 * ALvL ) * 100 ) )
			call SaveReal( HashTable, HandleID, StringHash( "Life" ), 1.5 + .5 * ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetUnitX( GetSpellTargetUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetUnitY( GetSpellTargetUnit( ) ) )

			call TimerStart( LoadMUITimer( PID ), .01, true, function Aokiji_E )
		endif

		if AID == 'A01S' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 98 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "AID" ), AID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "Count" ), 10 )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Aokiji_R )
		endif

		if AID == 'A09H' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 95 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ),  PID  )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Aokiji_T )
		endif
    endfunction

    function Init_Aokiji takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Aokiji_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Zoro.j
	function Zoro_V takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "BlueRibbonMissile.mdx", GetUnit( "Caster" ), "weapon" ) )
			call SetUnitXY_2( GetUnit( "Caster" ), GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ), -100, GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ) )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 4 * GetHeroStr( GetUnit( "Caster" ), true ), "physical" )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", GetUnit( "Target" ), "origin" ) )
			call IssueTargetOrder( GetUnit( "Caster" ), "attack", GetUnit( "Target" ) )
		endif

		if Time == 25 or Stop_Spell( 2 ) then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Zoro_W takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )
		local real MoveX
		local real MoveY

		if Time == 1 then
			set MoveX = NewX( GetUnitX( GetUnit( "Caster" ) ), 120, GetReal( "Angle" ) + 90 )
			set MoveY = NewY( GetUnitY( GetUnit( "Caster" ) ), 120, GetReal( "Angle" ) + 90 )
			call Linear_Spell_XY( GetUnit( "Caster" ), MoveX, MoveY, GetReal( "Angle" ),       "war3mapImported\\sw_zhaoyun.mdx", 1000, 500, 200, 1, 25 + 125 * GetInt( "ALvL" ), "", "magical" )
			call Linear_Spell_XY( GetUnit( "Caster" ), MoveX, MoveY, GetReal( "Angle" ) + 180, "war3mapImported\\sw_zhaoyun.mdx", 1000, 500, 200, 1, 25 + 125 * GetInt( "ALvL" ), "", "magical" )
			set MoveX = NewX( GetUnitX( GetUnit( "Caster" ) ), 120, GetReal( "Angle" ) - 90 )
			set MoveY = NewY( GetUnitY( GetUnit( "Caster" ) ), 120, GetReal( "Angle" ) - 90 )
			call Linear_Spell_XY( GetUnit( "Caster" ), MoveX, MoveY, GetReal( "Angle" ),       "war3mapImported\\sw_zhaoyun.mdx", 1000, 500, 200, 1, 25 + 125 * GetInt( "ALvL" ), "", "magical" )
			call Linear_Spell_XY( GetUnit( "Caster" ), MoveX, MoveY, GetReal( "Angle" ) + 180, "war3mapImported\\sw_zhaoyun.mdx", 1000, 500, 200, 1, 25 + 125 * GetInt( "ALvL" ), "", "magical" )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Zoro_E takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SetUnitTimeScale( GetUnit( "Caster" ), 0 )
		endif
		
		if GetUnitOrder( GetUnit( "Caster" ) ) == "stampede" then
			if Counter( 0, 65 ) then
				call TextTagAngled( Progress_Text( GetInt( "Multiplier" ) ), NewX( GetUnitX( GetUnit( "Caster" ) ), -50, 0 ), NewY( GetUnitY( GetUnit( "Caster" ) ), 150, 90 ), 90, 0, 10, 255, .65 )
				if IsPlayerAlly( GetLocalPlayer( ), GetOwningPlayer( GetUnit( "Caster" ) ) ) then
					call SetTextTagVisibility( bj_lastCreatedTextTag, true )
				else
					call SetTextTagVisibility( bj_lastCreatedTextTag, false )
				endif
				call SaveInteger( HashTable, HandleID, StringHash( "Multiplier" ), GetInt( "Multiplier" ) + 1 )
			endif
		else
			if GetEffect( "Effect_1" ) == null then
				call PlaySoundOnUnit( Sounds[ 165 ], 100, GetUnit( "Caster" ) )
				call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
				call SetUnitAnimation( GetUnit( "Caster" ), "spell" )
				call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 75 )
				call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "BlueRibbonMissile.mdx", GetUnit( "Caster" ), "chest" ) )
				call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_2" ), AddSpecialEffectTarget( "BlueRibbonMissile.mdx", GetUnit( "Caster" ), "hand right" ) )
				call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_3" ), AddSpecialEffectTarget( "BlueRibbonMissile.mdx", GetUnit( "Caster" ), "hand left" ) )
			endif

			if Counter( 1, 2 ) then
				call SaveReal( HashTable, HandleID, StringHash( "Travelled" ), GetReal( "Travelled" ) + 100 )
				call SetUnitXY_2( GetUnit( "Caster" ), GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 100, GetReal( "Angle" ) )
				call DestroyAoEDestruct( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 350 )
				call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 350 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 and not IsUnitIgnored( SysUnit ) then
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, 5.5 * GetInt( "Multiplier" ) * GetHeroStr( GetUnit( "Caster" ), true ), "physical" )
						call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", SysUnit, "chest" ) )
						call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", SysUnit, "origin" ) )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
			endif
		endif

		if GetInt( "Multiplier" ) == 5 then
			call IssueImmediateOrder( GetUnit( "Caster" ), "stop" )
		endif

		if Stop_Spell( 0 ) or GetReal( "Travelled" ) >= 1500 then
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call DestroyEffect( GetEffect( "Effect_2" ) )
			call DestroyEffect( GetEffect( "Effect_3" ) )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call SetUnitVertexColor( GetUnit( "Caster" ), 255, 255, 255, 255 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Zoro_R takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			set i = 0
			loop
				exitwhen i == 12
				set bj_lastCreatedUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h00S', GetReal( "CastX" ), GetReal( "CastY" ), 270 )
				call SetUnitFlyHeight( bj_lastCreatedUnit, 350 * i, 0 )
				call UnitApplyTimedLife( bj_lastCreatedUnit, 'BTLF', 1.8 )
				call SetUnitAnimation( bj_lastCreatedUnit, "stand" )
				call SetUnitTimeScale( bj_lastCreatedUnit, 3 )

				set bj_lastCreatedUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h00S', GetReal( "CastX" ), GetReal( "CastY" ), 270 )
				call SetUnitFlyHeight( bj_lastCreatedUnit, 350 * i, 0 )
				call UnitApplyTimedLife( bj_lastCreatedUnit, 'BTLF', 1.8 )
				call SetUnitAnimation( bj_lastCreatedUnit, "stand" )

				set bj_lastCreatedUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h00S', GetReal( "CastX" ), GetReal( "CastY" ), 270 )
				call SetUnitFlyHeight( bj_lastCreatedUnit, 350 * i, 0 )
				call UnitApplyTimedLife( bj_lastCreatedUnit, 'BTLF', 1.8 )
				call SetUnitAnimation( bj_lastCreatedUnit, "stand" )
				call SetUnitTimeScale( bj_lastCreatedUnit, .3 )

				set bj_lastCreatedUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h00T', GetReal( "CastX" ), GetReal( "CastY" ), 270 )
				call SetUnitFlyHeight( bj_lastCreatedUnit, 350 * i, 0 )
				call UnitApplyTimedLife( bj_lastCreatedUnit, 'BTLF', 2.6 )
				set i = i + 1
			endloop
		endif
		
		if Time == 5 then
			call BasicAoEDMG( GetUnit( "Caster" ), GetReal( "CastX" ), GetReal( "CastY" ), 400, 12 * GetHeroStr( GetUnit( "Caster" ), true ), "physical" )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Zoro_T takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			call SetUnitTimeScale( GetUnit( "Caster" ), 0 )
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitInvulnerable( GetUnit( "Caster" ), true )
			call SetUnitInvulnerable( GetUnit( "Target" ), true )
			call UnitAddAbility( GetUnit( "Caster" ), 'A017' )

			set bj_lastCreatedUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h00D', GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), GetReal( "Angle" ) + 120 )
			call UnitAddAbility( bj_lastCreatedUnit, 'A017' )
			call SetUnitPathing( bj_lastCreatedUnit, false )
			call SetUnitAnimation( bj_lastCreatedUnit, "stand" )
			call SetUnitTimeScale( bj_lastCreatedUnit, 0 )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), bj_lastCreatedUnit )

			set bj_lastCreatedUnit = CreateUnit( Player( GetInt( "PID" ) ), 'h00D', GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), GetReal( "Angle" ) - 120 )
			call UnitAddAbility( bj_lastCreatedUnit, 'A017' )
			call SetUnitPathing( bj_lastCreatedUnit, false )
			call SetUnitAnimation( bj_lastCreatedUnit, "stand" )
			call SetUnitTimeScale( bj_lastCreatedUnit, 0 )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_2" ), bj_lastCreatedUnit )
		endif

		if Time == 100 then
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitInvulnerable( GetUnit( "Target" ), false )
			call SaveReal( HashTable, HandleID, StringHash( "MoveX" ), NewX( GetUnitX( GetUnit( "Target" ) ), 150, GetReal( "Angle" ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "MoveY" ), NewY( GetUnitY( GetUnit( "Target" ) ), 150, GetReal( "Angle" ) ) )

			if IsTerrainPathable( GetReal( "MoveX" ), GetReal( "MoveY" ), PATHING_TYPE_WALKABILITY ) then
				call SaveReal( HashTable, HandleID, StringHash( "MoveX" ), NewX( GetUnitX( GetUnit( "Target" ) ), -100, GetReal( "Angle" ) ) )
				call SaveReal( HashTable, HandleID, StringHash( "MoveY" ), NewY( GetUnitY( GetUnit( "Target" ) ), -100, GetReal( "Angle" ) ) )
			endif

			call SetUnitXY_1( GetUnit( "Caster" ),  GetReal( "MoveX" ), GetReal( "MoveY" ), true )
			call SetUnitXY_1( GetUnit( "Dummy_1" ), GetReal( "MoveX" ), GetReal( "MoveY" ), true )
			call SetUnitXY_1( GetUnit( "Dummy_2" ), GetReal( "MoveX" ), GetReal( "MoveY" ), true )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 2000 + GetHeroStr( GetUnit( "Caster" ), true ) * ( 11 * GetInt( "ALvL" ) ), "physical" )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
			call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Human\\HumanBlood\\BloodElfSpellThiefBlood.mdl", GetUnit( "Target" ), "origin" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Human\\HumanBlood\\BloodElfSpellThiefBlood.mdl", GetUnit( "Target" ), "origin" ) )
		endif

		if Time == 120 then
			call PlaySoundOnUnit( Sounds[ 166 ], 100, GetUnit( "Target" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Objects\\Spawnmodels\\Human\\HumanBlood\\BloodElfSpellThiefBlood.mdl", GetUnit( "Target" ), "origin" ) )
		endif

		if Time > 150 or ( Time > 150 and Stop_Spell( 2 ) ) then
			call RemoveUnit( GetUnit( "Dummy_1" ) )
			call RemoveUnit( GetUnit( "Dummy_2" ) )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'A017' )
			call PauseUnit( GetUnit( "Caster" ), false )
			call SetUnitInvulnerable( GetUnit( "Caster" ), false )
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitInvulnerable( GetUnit( "Target" ), false )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			call SelectUnitForPlayerSingle( GetUnit( "Caster" ), Player( GetInt( "PID" ) ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Zoro_Spells takes nothing returns nothing
		local integer i = 0
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A057' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 163 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Zoro_V )
		endif

		if AID == 'A00T' then
			call PlaySoundOnUnit( Sounds[ 169 ], 100, GetTriggerUnit( ) )
			call Linear_Spell( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ), "war3mapImported\\sw_zhaoyun.mdx", 1000, 1200, 200, 1, 110 + 115 * ALvL, "" )
		endif

		if AID == 'A050' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 167 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitFacing( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Zoro_W )
		endif

		if AID == 'A00W' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 168 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Zoro_E )
		endif

		if AID == 'A00X' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 164 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Zoro_R )
		endif

		if AID == 'A00Z' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 170 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitsAngle( GetTriggerUnit( ), GetSpellTargetUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Zoro_T )
		endif
    endfunction

    function Init_Zoro takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Zoro_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Robin.j
	function Robin_V takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )
		local real Dist

		if Time == 1 then
			call SetUnitTimeScale( GetUnit( "Caster" ), .8 )
			call SetUnitAnimation( GetUnit( "Caster" ), "spell" )
			call SaveEffectHandle( HashTable, HandleID, StringHash( "Effect_1" ), AddSpecialEffectTarget( "war3mapImported\\AWING.MDX", GetUnit( "Caster" ), "chest" ) )
			set Dist = GetMaxAllowedDistance( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), GetReal( "Angle" ), 50, 1250 )
			call DisplaceUnitWithArgs( GetUnit( "Caster" ), GetReal( "Angle" ), Dist, .75, .01, Dist / 2.5 )
		endif

		if Time == 75 or Stop_Spell( 0 ) then
			if UnitLife( GetUnit( "Caster" ) ) > 0 then
				call DestroyAoEDestruct( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 300 )
			endif
			call DestroyEffect( GetEffect( "Effect_1" ) )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Robin_Clear_Q takes nothing returns nothing
		call GroupClear( LoadGroupHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Robin_Q_Group" ) ) )
	endfunction

	function Robin_Q takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 350 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if UnitLife( SysUnit ) > 0 then
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
						call TargetCast( GetUnit( "Caster" ), SysUnit, 'A049', 1, "ensnare" )
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, 110 + 115 * GetInt( "ALvL" ) + 3 * GetHeroInt( GetUnit( "Caster" ), true ), "magical" )
						call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", SysUnit, "chest" ) )
						call GroupAddUnit( LoadGroupHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Robin_Q_Group" ) ), SysUnit )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Robin_Clear_W takes nothing returns nothing
		call GroupClear( LoadGroupHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Robin_W_Group" ) ) )
	endfunction

	function Robin_W takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )

		if Time == 1 then
			call GroupAddUnit( LoadGroupHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Robin_W_Group" ) ), GetUnit( "Target" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", GetUnit( "Target" ), "chest" ) )
		endif
		
		if Counter( 0, 100 ) then
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 600, "magical" )
		endif

		if Time > GetInt( "Duration" ) or not IsUnitInGroup( GetUnit( "Target" ), LoadGroupHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Robin_W_Group" ) ) ) or Stop_Spell( 1 ) then
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Robin_E takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real S_DMG

		if Time == 1 then
			call EnumUnits_AOE( SpellGroup, GetReal( "CastX" ), GetReal( "CastY" ), 2000 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if UnitLife( SysUnit ) > 0 then
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
						set S_DMG = ( GetInt( "ALvL" ) * GetHeroLevel( GetUnit( "Caster" ) ) * GetHeroInt( GetUnit( "Caster" ), true ) ) / 16

						set bj_lastCreatedGroup = LoadGroupHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Robin_Q_Group" ) )
						if IsUnitInGroup( SysUnit, bj_lastCreatedGroup ) and ( GetStr( "Clutch_Type" ) == null or GetStr( "Clutch_Type" ) == "Q_Clutch" ) then
							call SaveStr( HashTable, HandleID, StringHash( "Clutch_Type" ), "Q_Clutch" )
							call Damage_Unit( GetUnit( "Caster" ), SysUnit, S_DMG + 400, "magical" )
							call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", SysUnit, "chest" ) )
							call GroupRemoveUnit( bj_lastCreatedGroup, SysUnit )
							call UnitRemoveAbility( SysUnit, 'B01N' )
							call UnitRemoveAbility( SysUnit, 'B01O' )
						endif

						set bj_lastCreatedGroup = LoadGroupHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Robin_W_Group" ) )
						if IsUnitInGroup( SysUnit, bj_lastCreatedGroup ) and ( GetStr( "Clutch_Type" ) == null or GetStr( "Clutch_Type" ) == "W_Clutch" ) then
							call SaveStr( HashTable, HandleID, StringHash( "Clutch_Type" ), "W_Clutch" )
							call Damage_Unit( GetUnit( "Caster" ), SysUnit, S_DMG + 500, "magical" )
							call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", SysUnit, "chest" ) )
							call GroupRemoveUnit( bj_lastCreatedGroup, SysUnit )
							call UnitRemoveAbility( SysUnit, 'B000' )
						endif

						set bj_lastCreatedGroup = LoadGroupHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Robin_R_Group" ) )
						if IsUnitInGroup( SysUnit, bj_lastCreatedGroup ) and ( GetStr( "Clutch_Type" ) == null or GetStr( "Clutch_Type" ) == "R_Clutch" ) then
							call SaveStr( HashTable, HandleID, StringHash( "Clutch_Type" ), "R_Clutch" )
							call CC_Unit( SysUnit, -( LoadInteger( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "R_Stun" ) ) / 100. ), "stun", true )
							call SaveInteger( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "R_Stun" ), 0 )
							call Damage_Unit( GetUnit( "Caster" ), SysUnit, S_DMG + 700, "magical" )
							call DestroyEffect( AddSpecialEffectTarget( "Units\\Undead\\Abomination\\AbominationExplosion.mdl", SysUnit, "chest" ) )
							call GroupRemoveUnit( bj_lastCreatedGroup, SysUnit )
							call UnitRemoveAbility( SysUnit, 'B001' )
						endif
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Robin_Clear_R takes nothing returns nothing
		call GroupClear( LoadGroupHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Robin_R_Group" ) ) )
	endfunction

	function Robin_R takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )

		if Time == 1 then
			call CC_Unit( GetUnit( "Target" ), 4, "stun", true )
			call SaveInteger( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "R_Stun" ), 400 )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), 750 + 250 * GetInt( "ALvL" ), "magical" ) 
			call GroupAddUnit( LoadGroupHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Robin_R_Group" ) ), GetUnit( "Target" ) )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", GetUnit( "Target" ), "chest" ) )
			call DestroyEffect( AddSpecialEffect( "Fleur.mdx", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
		endif

		call SaveInteger( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "R_Stun" ), LoadInteger( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "R_Stun" ) ) - 1 )

		if Time > 400 or LoadInteger( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "R_Stun" ) ) <= 0 then
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Robin_T takes nothing returns nothing
		local integer i
		local integer j
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Counter( 0, 100 ) then
			call DestroyAoEDestruct( GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 500 )
			call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), 500 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if UnitLife( SysUnit ) > 0 then
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) then
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, ( 7 + GetInt( "ALvL" ) ) * GetHeroInt( GetUnit( "Caster" ), true ), "magical" )
						call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", SysUnit, "chest" ) )
					endif
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
			set i = 0
			loop
				exitwhen i > 7
				set j = 1
				loop
					exitwhen j > 4
					call DestroyEffect( AddSpecialEffect( "Fleur.mdx", NewX( GetUnitX( GetUnit( "Caster" ) ), j * 120, i * 45 ), NewY( GetUnitY( GetUnit( "Caster" ) ), j * 120, i * 45 ) ) )
					set j = j + 1
				endloop
				set i = i + 1
			endloop
		endif

		if Time > GetInt( "Duration" ) or Stop_Spell( 0 ) then
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Robin_Spells takes nothing returns nothing
		local integer i
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A039' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 150 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetSpellTargetY( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Robin_V )
		endif

		if AID == 'A037' then
			set HandleID = NewMUITimer( PID )
			if LoadGroupHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Robin_Q_Group" ) ) == null then
				call SaveGroupHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Robin_Q_Group" ), CreateGroup( ) )
			endif
			call GroupClear( LoadGroupHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Robin_Q_Group" ) ) )
			call PlaySoundOnUnit( Sounds[ 151 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetSpellTargetY( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Robin_Q )
			set HandleID = PTimer( GetTriggerUnit( ), "Robin_Clear_Q" )
			if LoadUnitHandle( HashTable, HandleID, StringHash( "Caster" ) ) == null then
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			endif
			call TimerStart( LoadTimerHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Robin_Clear_Q" ) ), 2.5, false, function Robin_Clear_Q )
		endif

		if AID == 'A00S' then
			set HandleID = NewMUITimer( PID )
			if LoadGroupHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Robin_W_Group" ) ) == null then
				call SaveGroupHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Robin_W_Group" ), CreateGroup( ) )
			endif
			call GroupClear( LoadGroupHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Robin_W_Group" ) ) )
			call PlaySoundOnUnit( Sounds[ 149 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "Duration" ), R2I( ( 1.9 + .25 * ALvL ) * 100 ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Robin_W )
			set HandleID = PTimer( GetTriggerUnit( ), "Robin_Clear_W" )
			if LoadUnitHandle( HashTable, HandleID, StringHash( "Caster" ) ) == null then
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			endif
			call TimerStart( LoadTimerHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Robin_Clear_W" ) ), 1.75 + .25 * ALvL, false, function Robin_Clear_W )
		endif

		if AID == 'A01V' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 147 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Robin_E )
		endif

		if AID == 'A021' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "R_Stun" ), 0 )
			if LoadGroupHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Robin_R_Group" ) ) == null then
				call SaveGroupHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Robin_R_Group" ), CreateGroup( ) )
			endif
			call PlaySoundOnUnit( Sounds[ 148 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Robin_R )
			set HandleID = PTimer( GetTriggerUnit( ), "Robin_Clear_R" )
			if LoadUnitHandle( HashTable, HandleID, StringHash( "Caster" ) ) == null then
				call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			endif
			call TimerStart( LoadTimerHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Robin_Clear_R" ) ), 4, false, function Robin_Clear_R )
		endif
		
		if AID == 'A08P' or AID == 'A08Q' then
			if AID == 'A08Q' then
				set i = 6
			else
				set i = 8
			endif
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 152 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveInteger( HashTable, HandleID, StringHash( "Duration" ), i * 100 )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Robin_T )
		endif
    endfunction

    function Init_Robin takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Robin_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Nami.j
	function Nami_V takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( GetInt( "PID" ) ), 'h01N', NewX( GetReal( "CastX" ), 50, GetReal( "Angle" ) ), NewY( GetReal( "CastY" ), 150, GetReal( "Angle" ) ), GetReal( "Angle" ) ) )
			call EnumUnits_Player( SpellGroup, GetInt( "PID" ) )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if GetUnitTypeId( SysUnit ) == 'h01O' and GetUnitsDistance( GetUnit( "Dummy_1" ), SysUnit ) <= 1000 then
					call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_2" ), SysUnit )
					exitwhen true
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if UnitLife( GetUnit( "Dummy_1" ) ) > 0 then
			if Counter( 0, 3 ) then
				if GetUnit( "Dummy_2" ) == null then
					call SetUnitXY_2( GetUnit( "Dummy_1" ), GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 45, GetReal( "Angle" ) )
					if GetAxisDistance( GetReal( "CastX" ), GetReal( "CastY" ), GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ) ) <= 600 then
						call DestroyAoEDestruct( GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 220 )
						call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 220 )
						loop
							set SysUnit = FirstOfGroup( SpellGroup )
							exitwhen SysUnit == null
							if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 and not IsUnitIgnored( SysUnit ) then
								call TargetCast( GetUnit( "Caster" ), SysUnit, 'A05C', 1, "slow" )
								call Damage_Unit( GetUnit( "Caster" ), SysUnit, 6. * GetHeroInt( GetUnit( "Caster" ), true ), "physical" )
							endif
							call GroupRemoveUnit( SpellGroup, SysUnit )
						endloop
					endif
				else
					call SetUnitFlyHeight( GetUnit( "Dummy_1" ), GetUnitFlyHeight( GetUnit( "Dummy_1" ) ) + 150, 0 )
					if GetUnitsDistance( GetUnit( "Dummy_1" ), GetUnit( "Dummy_2" ) ) >= 45 then
						call SetUnitXY_2( GetUnit( "Dummy_1" ), GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 45, GetUnitsAngle( GetUnit( "Dummy_1" ), GetUnit( "Dummy_2" ) ) )
					endif
				endif
			endif
		endif

		if Time == 40 then
			call KillUnit( GetUnit( "Dummy_1" ) )
			if GetUnit( "Dummy_2" ) == null then
				call CleanMUI( GetExpiredTimer( ) )
			endif
		endif

		if Time == 60 then
			call PlaySoundOnUnit( Sounds[ 145 ], 100, GetUnit( "Caster" ) )
		endif

		if Time >= 60 then
			if Counter( 1, 100 ) then
				call SaveInteger( HashTable, HandleID, StringHash( "Thunder_Waves" ), GetInt( "Thunder_Waves" ) + 1 )
				call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Dummy_2" ) ), GetUnitY( GetUnit( "Dummy_2" ) ), 800 )
				loop
					set SysUnit = FirstOfGroup( SpellGroup )
					exitwhen SysUnit == null
					if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
						call DestroyEffect( AddSpecialEffect( "war3mapImported\\Great Lightning.mdx", GetUnitX( SysUnit ), GetUnitY( SysUnit ) ) )
						call Damage_Unit( GetUnit( "Caster" ), SysUnit, 50 + 50 * GetUnitAbilityLevel( GetUnit( "Caster" ), 'A059' ) + ( .5 + ( .5 * GetUnitAbilityLevel( GetUnit( "Caster" ), 'A059' ) ) ) * GetHeroInt( GetUnit( "Caster" ), true ), "physical" )
					endif
					call GroupRemoveUnit( SpellGroup, SysUnit )
				endloop
			endif

			if UnitLife( GetUnit( "Dummy_2" ) ) <= 0 or GetInt( "Thunder_Waves" ) >= 6 or Stop_Spell( 0 ) then
				if UnitLife( GetUnit( "Dummy_2" ) ) > 0 then
					call KillUnit( GetUnit( "Dummy_2" ) )
				endif
				call CleanMUI( GetExpiredTimer( ) )
			endif
		endif
	endfunction

	function Nami_Q takes nothing returns nothing
		local integer i
		local integer j
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )
		local real DummyX
		local real DummyY

		if Time == 1 then
			call AoECastXY( GetUnit( "Caster" ), GetReal( "TargX" ), GetReal( "TargY" ), 'A05G', 1, "thunderclap" )
			call BasicAoEDMG( GetUnit( "Caster" ), GetReal( "TargX" ), GetReal( "TargY" ), 275, 110 + 115 * GetInt( "ALvL" ), "physical" )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetReal( "TargX" ), GetReal( "TargY" ) ) )
			call EnumUnits_Player( SpellGroup, GetInt( "PID" ) )
			set i = 1
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if GetUnitTypeId( SysUnit ) == 'u998' and LoadStr( HashTable, GetHandleId( SysUnit ), StringHash( "Dummy_Type" ) ) == "Nami_T" then
					call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_" + I2S( i ) ), SysUnit )
					set i = i + 1
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop

			if GetUnit( "Dummy_1" ) == null then
				call PlaySoundOnUnit( Sounds[ 143 ], 100, GetUnit( "Caster" ) ) // Normal
			else
				call PlaySoundOnUnit( Sounds[ 146 ], 100, GetUnit( "Caster" ) ) // Thunderlance
				set i = 1
				loop
					exitwhen GetUnit( "Dummy_" + I2S( i ) ) == null
					set DummyX = GetUnitX( GetUnit( "Dummy_" + I2S( i ) ) )
					set DummyY = GetUnitY( GetUnit( "Dummy_" + I2S( i ) ) )
					call SaveReal( HashTable, HandleID, StringHash( "MoveX" ), DummyX )
					call SaveReal( HashTable, HandleID, StringHash( "MoveY" ), DummyY )
					call SaveReal( HashTable, HandleID, StringHash( "Angle_1" ), GetAxisAngle( DummyX, DummyY, GetReal( "TargX" ), GetReal( "TargY" ) ) )
					call SaveReal( HashTable, HandleID, StringHash( "Distance_1" ), GetAxisDistance( DummyX, DummyY, GetReal( "TargX" ), GetReal( "TargY" ) ) )
					set j = 0
					loop
						exitwhen j >= GetReal( "Distance_1" )
						call SaveReal( HashTable, HandleID, StringHash( "MoveX" ), NewX( GetReal( "MoveX" ), 300, GetReal( "Angle_1" ) ) )
						call SaveReal( HashTable, HandleID, StringHash( "MoveY" ), NewY( GetReal( "MoveY" ), 300, GetReal( "Angle_1" ) ) )
						call BasicAoEDMG( GetUnit( "Caster" ), GetReal( "MoveX" ), GetReal( "MoveY" ), 150, 8 * GetUnitAbilityLevel( GetUnit( "Caster" ), 'A05H' ) * GetHeroInt( GetUnit( "Caster" ), true ), "physical" )
						call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl", GetReal( "MoveX" ), GetReal( "MoveY" ) ) )
						set j = j + 300
					endloop
					call SaveLightningHandle( HashTable, HandleID, StringHash( "Lightning_" + I2S( i ) + "_#1" ), AddLightningEx( "CLPB", true, DummyX, DummyY, 0, GetReal( "TargX" ), GetReal( "TargY" ), 0 ) )
					call SaveLightningHandle( HashTable, HandleID, StringHash( "Lightning_" + I2S( i ) + "_#2" ), AddLightningEx( "CLSB", true, DummyX, DummyY, 0, GetReal( "TargX" ), GetReal( "TargY" ), 0 ) )
					call SaveLightningHandle( HashTable, HandleID, StringHash( "Lightning_" + I2S( i ) + "_#3" ), AddLightningEx( "FORK", true, DummyX, DummyY, 0, GetReal( "TargX" ), GetReal( "TargY" ), 0 ) )
					set i = i + 1
				endloop
			endif
		endif

		if Time == 180 or Stop_Spell( 0 ) then
			set i = 1
			loop
				exitwhen GetUnit( "Dummy_" + I2S( i ) ) == null
				call RemoveSavedString( HashTable, GetHandleId( GetUnit( "Dummy_1" ) ), StringHash( "Dummy_Type" ) )
				call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( GetUnit( "Dummy_" + I2S( i ) ) ), StringHash( "Nami_T_Cloud" ) ) )
				call RemoveSavedHandle( HashTable, GetHandleId( GetUnit( "Dummy_" + I2S( i ) ) ), StringHash( "Nami_T_Cloud" ) )
				call KillUnit( GetUnit( "Dummy_" + I2S( i ) ) )
				call DestroyLightning( LoadLightningHandle( HashTable, HandleID, StringHash( "Lightning_" + I2S( i ) + "_#1" ) ) )
				call DestroyLightning( LoadLightningHandle( HashTable, HandleID, StringHash( "Lightning_" + I2S( i ) + "_#2" ) ) )
				call DestroyLightning( LoadLightningHandle( HashTable, HandleID, StringHash( "Lightning_" + I2S( i ) + "_#3" ) ) )
				set i = i + 1
			endloop
			call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Nami_T_Effect" ) ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Nami_W takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( GetInt( "PID" ) ), 'h01O', GetReal( "TargX" ), GetReal( "TargY" ), GetReal( "Angle" ) ) )
		endif

		if Time == 1000 or Stop_Spell( 0 ) then
			call KillUnit( GetUnit( "Dummy_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Nami_E takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SetUnitOwner( DummyCaster, GetOwningPlayer( GetUnit( "Caster" ) ), false )
			call SetUnitXY( DummyCaster, GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ) )
			set bj_lastCreatedItem = UnitAddItemById( DummyCaster, 'I03P' )
			set i = 0
			loop
				exitwhen i == 4
				call UnitUseItemTarget( DummyCaster, bj_lastCreatedItem, GetUnit( "Caster" ) )
				set i = i + 1
			endloop
			call SaveItemHandle( HashTable, HandleID, StringHash( "Item_1" ), bj_lastCreatedItem )
		endif

		if Time == 10 then
			call RemoveItem( GetItem( "Item_1" ) )
			call SetUnitOwner( DummyCaster, Player( PLAYER_NEUTRAL_PASSIVE ), false )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Nami_R takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( GetInt( "PID" ) ), 'h01M', NewX( GetReal( "CastX" ), 50, GetReal( "Angle" ) ), NewY( GetReal( "CastY" ), 150, GetReal( "Angle" ) ), GetReal( "Angle" ) ) )
			call SetUnitTimeScale( GetUnit( "Dummy_1" ), 1.8 )
			call ScaleUnit( GetUnit( "Dummy_1" ), .7 )
		endif
		
		if Counter( 0, 3 ) then
			call SaveInteger( HashTable, HandleID, StringHash( "Travelled" ), GetInt( "Travelled" ) + 30 )
			call SetUnitXY_2( GetUnit( "Dummy_1" ), GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 30, GetReal( "Angle" ) )
			call DestroyAoEDestruct( GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 220 )
			call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 220 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 and not IsUnitIgnored( SysUnit ) then
					call SetUnitXY_1( SysUnit, GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), true )
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, ( 6 + 2 * GetInt( "ALvL" ) ) * GetHeroInt( GetUnit( "Caster" ), true ), "physical" )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time == 800 or Stop_Spell( 0 ) or GetInt( "Travelled" ) >= 2500 then
			call SetUnitTimeScale( GetUnit( "Dummy_1" ), 1 )
			call KillUnit( GetUnit( "Dummy_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Nami_T takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time  = SpellTime( )

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( GetInt( "PID" ) ), 'u998', GetReal( "CastX" ), GetReal( "CastY" ), GetReal( "Angle" ) ) )
			call SaveStr( HashTable, GetHandleId( GetUnit( "Dummy_1" ) ), StringHash( "Dummy_Type" ), "Nami_T" )
			call SaveEffectHandle( HashTable, GetHandleId( GetUnit( "Dummy_1" ) ), StringHash( "Nami_T_Cloud" ), AddSpecialEffect( "war3mapImported\\OutlandStorm.mdx", GetReal( "CastX" ), GetReal( "CastY" ) ) )
		endif

		if Time == 4000 then
			call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( GetUnit( "Dummy_1" ) ), StringHash( "Nami_T_Cloud" ) ) )
			call RemoveSavedString( HashTable, GetHandleId( GetUnit( "Dummy_1" ) ), StringHash( "Dummy_Type" ) )
			call RemoveSavedHandle( HashTable, GetHandleId( GetUnit( "Dummy_1" ) ), StringHash( "Nami_T_Cloud" ) )
			call KillUnit( GetUnit( "Dummy_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Nami_Spells takes nothing returns nothing
		local integer i
		local integer HandleID
		local integer AID = GetSpellAbilityId( )
		local integer PID 	 = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL 	 = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID	 = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A056' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 144 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Nami_V )
		endif

		if AID == 'A055' then
			set HandleID = NewMUITimer( PID )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Nami_Q )
		endif

		if AID == 'A059' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 140 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargX" ), GetSpellTargetX( ) )
			call SaveReal( HashTable, HandleID, StringHash( "TargY" ), GetSpellTargetY( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Nami_W )
		endif

		if AID == 'A0AH' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 142 ], 100, GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Nami_E )
		endif

		if AID == 'A05E' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 141 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), GetUnitX( GetTriggerUnit( ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), GetUnitY( GetTriggerUnit( ) ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetAngleCast( GetTriggerUnit( ), GetSpellTargetX( ), GetSpellTargetY( ) ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Nami_R )
		endif

		if AID == 'A05H' or AID == 'A08G' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 140 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastX" ), NewX( GetUnitX( GetTriggerUnit( ) ), 300, GetUnitFacing( GetTriggerUnit( ) ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "CastY" ), NewY( GetUnitY( GetTriggerUnit( ) ), 300, GetUnitFacing( GetTriggerUnit( ) ) ) )
			call SaveReal( HashTable, HandleID, StringHash( "Angle" ), GetUnitFacing( GetTriggerUnit( ) ) )
			call DestroyEffect( LoadEffectHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Nami_T_Effect" ) ) )
			call SaveEffectHandle( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Nami_T_Effect" ), AddSpecialEffectTarget( "Abilities\\Weapons\\FarseerMissile\\FarseerMissile.mdl", GetTriggerUnit( ), "weapon" ) )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Nami_T )
		endif
    endfunction

    function Init_Nami takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Nami_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Heroes\Usopp.j
	function Usopp_V_1 takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )

		if Time == 1 then
			call SelectUnitRemoveForPlayer( GetUnit( "Caster" ), GetOwningPlayer( GetUnit( "Caster" ) ) )
			call IssueImmediateOrder( GetUnit( "Caster" ), "stop" )
			call SetUnitAnimation( GetUnit( "Caster" ), "spell" )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'A047' )
			call UnitAddAbility( GetUnit( "Caster" ), 'A08O' )
			call DestroyEffect( AddSpecialEffectTarget( "Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnit( "Caster" ), "origin" ) )
			call SetUnitTimeScale( GetUnit( "Caster" ), .1 )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'B014' )
		endif
		
		if Time == 2 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call SaveReal( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Usopp_V_Damage" ), 0 )
			call SelectUnitAddForPlayer( GetUnit( "Caster" ), GetOwningPlayer( GetUnit( "Caster" ) ) )
		endif

		if Time == 300 or Stop_Spell( 0 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call UnitRemoveAbility( GetUnit( "Caster" ), 'B018' )
			call SetUnitTimeScale( GetUnit( "Caster" ), 1 )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction
	
	function Usopp_V_2 takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real DMG

		if Time == 1 then
			call PauseUnit( GetUnit( "Caster" ), true )
			call PauseUnit( GetUnit( "Target" ), true )
			call SetUnitAnimation( GetUnit( "Caster" ), "attack" )
			call SelectUnitAddForPlayer( GetUnit( "Caster" ), Player( GetInt( "PID" ) ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
			call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX( GetUnit( "Target" ) ), GetUnitY( GetUnit( "Target" ) ) ) )
			set DMG = LoadReal( HashTable, GetHandleId( GetUnit( "Caster" ) ), StringHash( "Usopp_V_Damage" ) )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Target" ), DMG, "magical" )
			call Damage_Unit( GetUnit( "Caster" ), GetUnit( "Caster" ), DMG * .3, "magical" )
			call DestroyEffect( AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", GetUnit( "Caster" ), "origin" ) )
			call LinearDisplacement( GetUnit( "Target" ), GetUnitsAngle( GetUnit( "Caster" ), GetUnit( "Target" ) ), 450, .3, .01, false, false, "origin", "Abilities\\Weapons\\AncientProtectorMissile\\AncientProtectorMissile.mdl" )
		endif

		if Time == 30 or Stop_Spell( 2 ) then
			call PauseUnit( GetUnit( "Caster" ), false )
			call PauseUnit( GetUnit( "Target" ), false )
			call SetUnitAnimation( GetUnit( "Caster" ), "stand" )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Usopp_Q takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( GetInt( "PID" ) ), 'h00C', GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), GetReal( "Angle" ) ) )
		endif

		if Time >= 1 then
			if UnitLife( GetUnit( "Dummy_1" ) ) > 0 then
				call SetUnitXY_2( GetUnit( "Dummy_1" ), GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 30, GetReal( "Angle" ) )
				if GetAxisDistance( GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), GetReal( "TargX" ), GetReal( "TargY" ) ) <= 50 then
					call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Other\\Doom\\DoomDeath.mdl", GetReal( "TargX" ), GetReal( "TargY" ) ) )
					call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\DemolisherFireMissile\\DemolisherFireMissile.mdl", GetReal( "TargX" ), GetReal( "TargY" ) ) )
					call EnumUnits_AOE( SpellGroup, GetReal( "TargX" ), GetReal( "TargY" ), 330 )
					loop
						set SysUnit = FirstOfGroup( SpellGroup )
						exitwhen SysUnit == null
						if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and DefaultUnitFilter( SysUnit ) then
							call GroupAddUnit( GetGroup( "Flame_Group" ), SysUnit )
						endif
						call GroupRemoveUnit( SpellGroup, SysUnit )
					endloop
					call KillUnit( GetUnit( "Dummy_1" ) )
				endif
			else
				if Counter( 0, 100 ) then
					call Make_Dummy_Group( GetGroup( "Flame_Group" ) )
					loop
						set SysUnit = FirstOfGroup( SpellGroup )
						exitwhen SysUnit == null
						if UnitLife( SysUnit ) > 0 then
							call DestroyEffect( AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", SysUnit, "origin" ) )
							call Damage_Unit( GetUnit( "Caster" ), SysUnit, ( 60. + 20. * GetInt( "ALvL" ) ), "magical" )
						else
							call GroupRemoveUnit( GetGroup( "Flame_Group" ), SysUnit )
						endif
						call GroupRemoveUnit( SpellGroup, SysUnit )
					endloop
				endif
			endif
		endif

		if Time == 925 or Stop_Spells( ) then
			call DestroyGroup( GetGroup( "Flame_Group" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Usopp_R takes nothing returns nothing
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( GetInt( "PID" ) ), 'h022', GetUnitX( GetUnit( "Caster" ) ), GetUnitY( GetUnit( "Caster" ) ), GetReal( "Angle" ) ) )
			call UnitApplyTimedLife( GetUnit( "Dummy_1" ), 'BTLF', 8 )
		endif

		if Counter( 0, 3 ) then
			call SaveInteger( HashTable, HandleID, StringHash( "Travelled" ), GetInt( "Travelled" ) + 50 )
			call SetUnitXY_2( GetUnit( "Dummy_1" ), GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 50, GetReal( "Angle" ) )
			call DestroyAoEDestruct( GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 300 )
			call EnumUnits_AOE( SpellGroup, GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 300 )
			loop
				set SysUnit = FirstOfGroup( SpellGroup )
				exitwhen SysUnit == null
				if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 and not IsUnitIgnored( SysUnit ) then
					call DestroyEffect( AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", SysUnit, "origin" ) )
					call Damage_Unit( GetUnit( "Caster" ), SysUnit, 500 + ( 7 + GetInt( "ALvL" ) ) * GetHeroAgi( GetUnit( "Caster" ), true ), "magical" )
				endif
				call GroupRemoveUnit( SpellGroup, SysUnit )
			endloop
		endif

		if Time == 1000 or Stop_Spell( 0 ) or GetInt( "Travelled" ) >= 2000 then
			call KillUnit( GetUnit( "Dummy_1" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

	function Usopp_T takes nothing returns nothing
		local integer i
		local integer HandleID = MUIHandle( )
		local integer Time     = SpellTime( )
		local real MoveX
		local real MoveY

		if Time == 1 then
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Dummy_1" ), CreateUnit( Player( GetInt( "PID" ) ), 'h00C', GetReal( "CastX" ), GetReal( "CastY" ), GetReal( "Angle" ) ) )
		endif

		if Time >= 1 then
			if UnitLife( GetUnit( "Dummy_1" ) ) > 0 then
				call SetUnitXY_2( GetUnit( "Dummy_1" ), GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), 30, GetReal( "Angle" ) )
				if GetAxisDistance( GetUnitX( GetUnit( "Dummy_1" ) ), GetUnitY( GetUnit( "Dummy_1" ) ), GetReal( "TargX" ), GetReal( "TargY" ) ) <= 50 then
					call KillUnit( GetUnit( "Dummy_1" ) )
				endif
			else
				if GetInt( "Waves" ) < 8 then
					if Counter( 0, 1 ) then
						set i = 1
						loop
							exitwhen i == 6
							set MoveX = NewX( GetReal( "TargX" ), GetInt( "Waves" ) * 250, 72 * i )
							set MoveY = NewY( GetReal( "TargY" ), GetInt( "Waves" ) * 250, 72 * i )
							call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Other\\Doom\\DoomDeath.mdl", MoveX, MoveY ) )
							call DestroyEffect( AddSpecialEffect( "Abilities\\Weapons\\DemolisherFireMissile\\DemolisherFireMissile.mdl", MoveX, MoveY ) )
							call DestroyAoEDestruct( MoveX, MoveY, 250 )
							call EnumUnits_AOE( SpellGroup, MoveX, MoveY, 250 )
							loop
								set SysUnit = FirstOfGroup( SpellGroup )
								exitwhen SysUnit == null
								if IsUnitEnemy_v2( GetUnit( "Caster" ), SysUnit ) and UnitLife( SysUnit ) > 0 and not IsUnitIgnored( SysUnit ) then
									call TargetCast( GetUnit( "Caster" ), SysUnit, 'A07B', 1, "curse" )
									call Damage_Unit( GetUnit( "Caster" ), SysUnit, 1400 + 40 * GetHeroLevel( GetUnit( "Caster" ) ), "magical" )
									call GroupAddUnit( GetGroup( "Flame_Group" ), SysUnit )
								endif
								call GroupRemoveUnit( SpellGroup, SysUnit )
							endloop
							set i = i + 1
						endloop
						call SaveInteger( HashTable, HandleID, StringHash( "Waves" ), GetInt( "Waves" ) + 1 )
					endif
				else
					if Time >= 100 then
						if Counter( 1, 100 ) then
							call Make_Dummy_Group( GetGroup( "Flame_Group" ) )
							loop
								set SysUnit = FirstOfGroup( SpellGroup )
								exitwhen SysUnit == null
								if UnitLife( SysUnit ) > 0 then
									call DestroyEffect( AddSpecialEffectTarget( "Environment\\LargeBuildingFire\\LargeBuildingFire1.mdl", SysUnit, "origin" ) )
									call Damage_Unit( GetUnit( "Caster" ), SysUnit, UnitMaxLife( SysUnit ) * ( ( 3 + GetInt( "ALvL" ) ) / 100. ), "magical" )
								else
									call GroupRemoveUnit( GetGroup( "Flame_Group" ), SysUnit )
								endif
								call GroupRemoveUnit( SpellGroup, SysUnit )
							endloop
						endif
					endif
				endif
			endif
		endif

		if Time == 1300 or Stop_Spells( ) then
			call DestroyGroup( GetGroup( "Flame_Group" ) )
			call CleanMUI( GetExpiredTimer( ) )
		endif
	endfunction

    function Usopp_Spells takes nothing returns nothing
		local integer i = 0
		local integer HandleID
		local integer AID  = GetSpellAbilityId( )
		local integer PID  = GetPlayerId( GetTriggerPlayer( ) )
		local integer ALvL = GetUnitAbilityLevel( GetTriggerUnit( ), AID )
		local integer UID  = GetUnitTypeId( GetTriggerUnit( ) )

		if AID == 'A047' then
			set HandleID = NewMUITimer( PID )
			call Ability_Handler( AID, GetTriggerUnit( ), null, 0, 0, function Usopp_V_1 )
		endif

		if AID == 'A08O' then
			set HandleID = NewMUITimer( PID )
			call PlaySoundOnUnit( Sounds[ 160 ], 100, GetTriggerUnit( ) )
			call SaveInteger( HashTable, HandleID, StringHash( "PID" ), PID )
			call SaveInteger( HashTable, HandleID, StringHash( "ALvL" ), ALvL )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Caster" ), GetTriggerUnit( ) )
			call SaveUnitHandle( HashTable, HandleID, StringHash( "Target" ), GetSpellTargetUnit( ) )
			call SelectUnitRemoveForPlayer( GetTriggerUnit( ), Player( PID ) )
			call UnitRemoveAbility( GetTriggerUnit( ), 'A08O' )
			call UnitAddAbility( GetTriggerUnit( ), 'A047' )
			call IssueImmediateOrder( GetTriggerUnit( ), "berserk" )
			call TimerStart( LoadMUITimer( PID ), .01, true, function Usopp_V_2 )
		endif

		if AID == 'A048' then
			call PlaySoundOnUnit( Sounds[ 161 ], 100, GetTriggerUnit( ) )
			set HandleID = Ability_Handler( AID, GetTriggerUnit( ), null, GetSpellTargetX( ), GetSpellTargetY( ), function Usopp_Q )
			call SaveGroupHandle( HashTable, HandleID, StringHash( "Flame_Group" ), CreateGroup( ) )
		endif

		if AID == 'A03P' then
			call PlaySoundOnUnit( Sounds[ 162 ], 100, GetTriggerUnit( ) )
		endif

		if AID == 'A04C' then
			call Ability_Handler( AID, GetTriggerUnit( ), null, GetSpellTargetX( ), GetSpellTargetY( ), function Usopp_R )
		endif

		if AID == 'A04B' then
			call PlaySoundOnUnit( Sounds[ 158 ], 100, GetTriggerUnit( ) )
			set HandleID = Ability_Handler( AID, GetTriggerUnit( ), null, GetSpellTargetX( ), GetSpellTargetY( ), function Usopp_T )
			call SaveGroupHandle( HashTable, HandleID, StringHash( "Flame_Group" ), CreateGroup( ) )
		endif
    endfunction

    function Init_Usopp takes nothing returns nothing
		call TriggerAddAction( LoadTrig( "SPELL_EFECT" ), function Usopp_Spells )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Systems\Ability_Handler.j
    function Is_Ultimate takes unit Caster, integer AID returns boolean
        return AID == LoadInt( "Hero_Ability_" + I2S( LoadInteger( HashTable, GetHandleId( Caster ), StringHash( "Hero_Index" ) ) ) + "_5" )
    endfunction

	function All_Abilities_Cast takes nothing returns nothing
		local integer PID = GetPlayerId( GetTriggerPlayer( ) )
		local integer AID = GetSpellAbilityId( )

		if IsTerrainPathable( GetSpellTargetX( ), GetSpellTargetY( ), PATHING_TYPE_WALKABILITY ) then
			call IssueImmediateOrder( GetTriggerUnit( ), "stop" )
			return
		endif

		if AID == 'A094' and UnitLifePercent( GetTriggerUnit( ) ) <= 20 then
			call IssueImmediateOrder( GetTriggerUnit( ), "stop" )
			call DisplayTimedTextToPlayer( Player( PID ), 0, 0, 4., "|cffffcc00Your HP is too low|r" )
		endif

		if AID == 'A0BQ' then
			call SaveBoolean( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Renji_T_Cast" ), true )
		endif
	endfunction

	function All_Abilities_Effect takes nothing returns nothing
		local integer i = 0
		local integer AID = GetSpellAbilityId( )
		local integer Team = GetPlayerTeam( GetTriggerPlayer( ) )
		local real LocX = GetUnitX( GetTriggerUnit( ) )
		local real LocY = GetUnitY( GetTriggerUnit( ) )

		if IsUnitType( GetTriggerUnit( ), UNIT_TYPE_HERO ) then
			call Mamaragan_Handler( GetTriggerUnit( ) )
		endif

		// if ( -7808 <= LocX and LocX <= -7008 and -4448 <= LocY and LocY <= -3744 ) then
			// if Is_Ultimate( GetTriggerUnit( ), AID ) then
				// if Team == 0 then
					// set UltimatesUsed_1 = UltimatesUsed_1 + 1
			// elseif Team == 1 then
					// set UltimatesUsed_2 = UltimatesUsed_2 + 1
				// endif
			// endif
		// endif
	endfunction
	
	function All_Abilities_End_Cast takes nothing returns nothing
		local integer AID = GetSpellAbilityId( )

		if AID == 'A07W' then
			call SaveBoolean( HashTable, GetHandleId( GetTriggerUnit( ) ), StringHash( "Yoruichi_Riposte" ), false )
		endif
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Init\Sounds.j
	function Init_Music takes nothing returns nothing
		set Sounds[ 0 ]   = MakeSound( "Sounds\\war3mapImported\\triple_kill.mp3" )
		set Sounds[ 1 ]   = MakeSound( "Sounds\\war3mapImported\\ultrakill.mp3" )
		set Sounds[ 2 ]   = MakeSound( "Sound\\Interface\\SecretFound.wav" )
		set Sounds[ 3 ]   = MakeSound( "Sounds\\war3mapImported\\rampage.mp3" )
		set Sounds[ 4 ]   = MakeSound( "Sounds\\war3mapImported\\humiliation.mp3" )
		set Sounds[ 5 ]   = MakeSound( "Sounds\\war3mapImported\\Double_Kill.mp3" )
		set Sounds[ 6 ]   = MakeSound( "Sound\\Interface\\CreepAggroWhat1.wav" )
		set Sounds[ 7 ]   = MakeSound( "Sound\\Interface\\ClanInvitation.wav" )
		set Sounds[ 8 ]   = MakeSound( "Sound\\Interface\\BattleNetTick.wav" )
		set Sounds[ 9 ]   = MakeSound( "Sound\\Interface\\ArrangedTeamInvitation.wav" )
		set Sounds[ 10 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Aizen\\KyoukaSuigetsu.mp3" )
		set Sounds[ 11 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Byakuya\\ShukeiHakuteiken.mp3" )
		set Sounds[ 12 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Byakuya\\Senbonzakura.mp3" )
		set Sounds[ 13 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Byakuya\\Senkei.mp3" )
		set Sounds[ 14 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Byakuya\\ByakuyaRikujo.mp3" )
		set Sounds[ 15 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Byakuya\\ByakuyaBankai.mp3" )
		set Sounds[ 16 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Chad\\EarthSlam.mp3" )
		set Sounds[ 17 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Chad\\ElDirecto.mp3" )
		set Sounds[ 18 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Chad\\TrueForm.mp3" )
		set Sounds[ 19 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Chad\\LaMuerte.mp3" )
		set Sounds[ 20 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Hitsugaya\\HitsugayaBankai.mp3" )
		set Sounds[ 21 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Hitsugaya\\HyotenHyakkaso.mp3" )
		set Sounds[ 22 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Hitsugaya\\Hyourinmaru.mp3" )
		set Sounds[ 23 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Hitsugaya\\SennenHyoro.mp3" )
		set Sounds[ 24 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Hitsugaya\\Ryuusenka.mp3" )
		set Sounds[ 25 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Hitsugaya\\Hyorusenbi.mp3" )
		set Sounds[ 26 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ichigo\\BankaiGetsuga.mp3" )
		set Sounds[ 27 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ichigo\\IchigoBankai.mp3" )
		set Sounds[ 28 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ichigo\\TrueHollowForm.mp3" )
		set Sounds[ 29 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ichigo\\Reiatsu.mp3" )
		set Sounds[ 30 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ichigo\\IchigoMask.mp3" )
		set Sounds[ 31 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ichigo\\IchigoGetsuga.mp3" )
		set Sounds[ 32 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ichigo\\GetsugaHollowForm.mp3" )
		set Sounds[ 33 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ichigo\\Cero.mp3" )
		set Sounds[ 34 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ikkaku\\DragonCharge.mp3" )
		set Sounds[ 35 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ikkaku\\Ikkaku1.mp3" )
		set Sounds[ 36 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ikkaku\\Ikkaku2.mp3" )
		set Sounds[ 37 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ikkaku\\Ikkaku3.mp3" )
		set Sounds[ 38 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ikkaku\\IkkakuBankai.mp3" )
		set Sounds[ 39 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ikkaku\\FinalMadness.mp3" )
		set Sounds[ 40 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Inoue\\InoueR.mp3" )
		set Sounds[ 41 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Inoue\\KotenZanshun.mp3" )
		set Sounds[ 42 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Inoue\\SantenKesshun.mp3" )
		set Sounds[ 43 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Inoue\\ShoutenKissun.mp3" )
		set Sounds[ 44 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Inoue\\TimeReverse.mp3" )
		set Sounds[ 45 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ishida\\Sprenger.mp3" )
		set Sounds[ 46 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ishida\\Seele.mp3" )
		set Sounds[ 47 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ishida\\GinreiKojyaku.mp3" )
		set Sounds[ 48 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ishida\\LichtRegen.mp3" )
		set Sounds[ 49 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Ishida\\QQF.mp3" )
		set Sounds[ 50 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Renji\\Zabimaru.mp3" )
		set Sounds[ 51 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Renji\\BankaiHigaZekko.mp3" )
		set Sounds[ 52 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Renji\\Shakkahou.mp3" )
		set Sounds[ 53 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Renji\\HigaZekko.mp3" )
		set Sounds[ 54 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Renji\\HihotsuTaiho.mp3" )
		set Sounds[ 55 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Rukia\\Tsukishiro.mp3" )
		set Sounds[ 56 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Rukia\\Hakuren.mp3" )
		set Sounds[ 57 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Rukia\\RukiaSokatsui.mp3" )
		set Sounds[ 58 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Rukia\\Shirafune.mp3" )
		set Sounds[ 59 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Rukia\\WhiteDance.mp3" )
		set Sounds[ 60 ]  = MakeSound( "Sounds\\Bleach\\Spells\\SoiFon\\Assassinate.mp3" )
		set Sounds[ 61 ]  = MakeSound( "Sounds\\Bleach\\Spells\\SoiFon\\NigekiKessatsu.mp3" )
		set Sounds[ 62 ]  = MakeSound( "Sounds\\Bleach\\Spells\\SoiFon\\SoiShunkou.mp3" )
		set Sounds[ 63 ]  = MakeSound( "Sounds\\Bleach\\Spells\\SoiFon\\Suzumebachi.mp3" )
		set Sounds[ 64 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Tousen\\Benihiko.mp3" )
		set Sounds[ 65 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Tousen\\Haien.mp3" )
		set Sounds[ 66 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Tousen\\Suzumushi.mp3" )
		set Sounds[ 67 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Tousen\\TousenBankai.mp3" )
		set Sounds[ 68 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Yama\\JokakuEnjou.mp3" )
		set Sounds[ 69 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Yama\\FireSlash.mp3" )
		set Sounds[ 70 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Yama\\FlameSweep.mp3" )
		set Sounds[ 71 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Yama\\Nadegiri.mp3" )
		set Sounds[ 72 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Yoruichi\\FlashArrow.mp3" )
		set Sounds[ 73 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Yoruichi\\FlashCounter.mp3" )
		set Sounds[ 74 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Yoruichi\\FlashStrike.mp3" )
		set Sounds[ 75 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Yoruichi\\YoruichiShunkou.mp3" )
		set Sounds[ 76 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Yoruichi\\YoruichiUlti.mp3" )
		set Sounds[ 77 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Zangetsu\\ZangetsuR.mp3" )
		set Sounds[ 78 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Zangetsu\\ZangetsuQ.mp3" )
		set Sounds[ 79 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Zangetsu\\ZangetsuE.mp3" )
		set Sounds[ 80 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Zangetsu\\ZangetsuT.mp3" )
		set Sounds[ 81 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Zangetsu\\ZangetsuW.mp3" )
		set Sounds[ 82 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Zaraki\\EyePatchRelease.mp3" )
		set Sounds[ 83 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Zaraki\\Kendo.mp3" )
		set Sounds[ 84 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Zaraki\\ThrillingReiatsu.mp3" )
		set Sounds[ 85 ]  = MakeSound( "Sounds\\Bleach\\Spells\\Zaraki\\CrazyJump.mp3" )
		set Sounds[ 86 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Ace\\Daenkai.mp3" )
		set Sounds[ 87 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Ace\\Hotarubi.mp3" )
		set Sounds[ 88 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Ace\\Entei.mp3" )
		set Sounds[ 89 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Ace\\FireShield.mp3" )
		set Sounds[ 90 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Ace\\Hibarashi.mp3" )
		set Sounds[ 91 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Ace\\Hidaruma.mp3" )
		set Sounds[ 92 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Ace\\Hiken.mp3" )
		set Sounds[ 93 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Aokiji\\AokijiV.mp3" )
		set Sounds[ 94 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Aokiji\\AokijiQ.mp3" )
		set Sounds[ 95 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Aokiji\\IceAge.mp3" )
		set Sounds[ 96 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Aokiji\\IcePrison.mp3" )
		set Sounds[ 97 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Aokiji\\IceSaber.mp3" )
		set Sounds[ 98 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Aokiji\\IceTime.mp3" )
		set Sounds[ 99 ]  = MakeSound( "Sounds\\OnePiece\\Spells\\Brook\\Gavotte.mp3" )
		set Sounds[ 100 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Brook\\NemuriutaFuran.mp3" )
		set Sounds[ 101 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Brook\\PolkaRemise.mp3" )
		set Sounds[ 102 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Brook\\Yahazugiri.mp3" )
		set Sounds[ 103 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Crocodile\\Barchan.mp3" )
		set Sounds[ 104 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Crocodile\\DesertGirasole.mp3" )
		set Sounds[ 105 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Crocodile\\DesertSpada.mp3" )
		set Sounds[ 106 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Crocodile\\GroundDeath.mp3" )
		set Sounds[ 107 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Crocodile\\SablesPesado.mp3" )
		set Sounds[ 108 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Enel\\ElThor.mp3" )
		set Sounds[ 109 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Enel\\Gloam.mp3" )
		set Sounds[ 110 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Enel\\Raigou.mp3" )
		set Sounds[ 111 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Enel\\ShockRelease.mp3" )
		set Sounds[ 112 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Enel\\ThunderStorm.mp3" )
		set Sounds[ 113 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Kuma\\KumaQ.mp3" )
		set Sounds[ 114 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Kuma\\KumaE.mp3" )
		set Sounds[ 115 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Kuma\\KumaR.mp3" )
		set Sounds[ 116 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Kuma\\KumaT.mp3" )
		set Sounds[ 117 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Lucci\\LucciRankyaku.mp3" )
		set Sounds[ 118 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Lucci\\LucciTekkai.mp3" )
		set Sounds[ 119 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Lucci\\Rokuogan.mp3" )
		set Sounds[ 120 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Lucci\\Shigan.mp3" )
		set Sounds[ 121 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Lucci\\NekoNeko.mp3" )
		set Sounds[ 122 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Luffy\\Rocket.mp3" )
		set Sounds[ 123 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Luffy\\Bazooka.mp3" )
		set Sounds[ 124 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Luffy\\Gatling.mp3" )
		set Sounds[ 125 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Luffy\\GearSecond.mp3" )
		set Sounds[ 126 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Luffy\\GiantBazooka.mp3" )
		set Sounds[ 127 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Luffy\\JetBazooka.mp3" )
		set Sounds[ 128 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Luffy\\JetGatling.mp3" )
		set Sounds[ 129 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Luffy\\JetGiantBazooka.mp3" )
		set Sounds[ 130 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Luffy\\JetRocket.mp3" )
		set Sounds[ 131 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Mihawk\\Mihawk1.mp3" )
		set Sounds[ 132 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Mihawk\\Mihawk2.mp3" )
		set Sounds[ 133 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Mihawk\\Mihawk3.mp3" )
		set Sounds[ 134 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Mihawk\\Mihawk4.mp3" )
		set Sounds[ 135 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Mihawk\\Mihawk5.mp3" )
		set Sounds[ 136 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Moria\\BrickBat.mp3" )
		set Sounds[ 137 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Moria\\Doppleman.mp3" )
		set Sounds[ 138 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Moria\\ShadowRage.mp3" )
		set Sounds[ 139 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Moria\\ShadowSteal.mp3" )
		set Sounds[ 140 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Nami\\CloudTempo.mp3" )
		set Sounds[ 141 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Nami\\CycloneTempo.mp3" )
		set Sounds[ 142 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Nami\\MirageTempo.mp3" )
		set Sounds[ 143 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Nami\\SwingArm.mp3" )
		set Sounds[ 144 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Nami\\ThunderBall.mp3" )
		set Sounds[ 145 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Nami\\ThunderboltTempo.mp3" )
		set Sounds[ 146 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Nami\\ThunderLanceTempo.mp3" )
		set Sounds[ 147 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Robin\\Clutch.mp3" )
		set Sounds[ 148 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Robin\\CuatroMano.mp3" )
		set Sounds[ 149 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Robin\\DoseFleur.mp3" )
		set Sounds[ 150 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Robin\\Wing.mp3" )
		set Sounds[ 151 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Robin\\SpiderNet.mp3" )
		set Sounds[ 152 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Robin\\RobinT.mp3" )
		set Sounds[ 153 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Sanji\\DiableJamble.mp3" )
		set Sounds[ 154 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Sanji\\Flambage.mp3" )
		set Sounds[ 155 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Sanji\\FritAssortie.mp3" )
		set Sounds[ 156 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Sanji\\PartyTable.mp3" )
		set Sounds[ 157 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Sanji\\VeauShot.mp3" )
		set Sounds[ 158 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Usopp\\Atlas.mp3" )
		set Sounds[ 159 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Usopp\\Hinotori.mp3" )
		set Sounds[ 160 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Usopp\\ImpactDial.mp3" )
		set Sounds[ 161 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Usopp\\Kaenboshi.mp3" )
		set Sounds[ 162 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Usopp\\Rokuren.mp3" )
		set Sounds[ 163 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Zoro\\Shishisonson.mp3" )
		set Sounds[ 164 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Zoro\\Tatsumaki.mp3" )
		set Sounds[ 165 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Zoro\\Sanzensekai2.mp3" )
		set Sounds[ 166 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Zoro\\Makyuusen.mp3" )
		set Sounds[ 167 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Zoro\\Rashomon.mp3" )
		set Sounds[ 168 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Zoro\\Sanzensekai1.mp3" )
		set Sounds[ 169 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Zoro\\36poundcannon.mp3" )
		set Sounds[ 170 ] = MakeSound( "Sounds\\OnePiece\\Spells\\Zoro\\Ashura.mp3" )
		set Sounds[ 171 ] = MakeSound( "Special\\Spells\\Sasuke\\Chidori.mp3" )
		set Sounds[ 172 ] = MakeSound( "Special\\Spells\\Sasuke\\Chidorinagashi.mp3" )
		set Sounds[ 173 ] = MakeSound( "Special\\Spells\\Sasuke\\CursedSeal.mp3" )
		set Sounds[ 174 ] = MakeSound( "Special\\Spells\\Sasuke\\Gokakyu.mp3" )
		set Sounds[ 175 ] = MakeSound( "Special\\Spells\\Sasuke\\Kirin.mp3" )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Init\Units.j
	function Init_Units takes nothing returns nothing
		local integer PID = PLAYER_NEUTRAL_PASSIVE

		call CreateUnit( Player( PID ), 'hlum', -7168., 448., 270. )
		call CreateUnit( Player( PID ), 'ncp3', -3456., 2048., 270. )
		call CreateUnit( Player( PID ), 'hhou', 4864., 1152., 270. )
		call CreateUnit( Player( PID ), 'hwtw', 4992., 1152., 270. )
		call CreateUnit( Player( PID ), 'harm', 5120., 1152., 270. )
		call CreateUnit( Player( PID ), 'hbla', 5248., 1152., 270. )
		call CreateUnit( Player( PID ), 'hars', 5760., 640., 270. )
		call CreateUnit( Player( PID ), 'hvlt', 5760., 1024., 270. )
		call CreateUnit( Player( PID ), 'n001', 5760., 832., 270. )
		call CreateUnit( Player( PID ), 'nC16', 5376., 1152., 270. )
		set WayGate_Arr[ 0 ] = CreateUnit( Player( PID ), 'n00M', -7104., -576., 270. )
		call WaygateSetDestination( WayGate_Arr[ 0 ], -3456, 2048 )
		call WaygateActivate( WayGate_Arr[ 0 ], true )
		call SetUnitColor( WayGate_Arr[ 0 ], ConvertPlayerColor( 9 ) )
		call CreateUnit( Player( PID ), 'nC16', -6784., 1088., 270. )
		set WayGate_Arr[ 2 ] = CreateUnit( Player( PID ), 'n00M', -6848., -576., 270. )
		call WaygateSetDestination( WayGate_Arr[ 2 ], -3472, -1744 )
		call WaygateActivate( WayGate_Arr[ 2 ], true )
		call SetUnitColor( WayGate_Arr[ 2 ], ConvertPlayerColor( 9 ) )
		call CreateUnit( Player( PID ), 'n001', -7168., 832., 270. )
		call CreateUnit( Player( PID ), 'hars', -7168., 640., 270. )
		call CreateUnit( Player( PID ), 'hvlt', -7168., 1024., 270. )
		call CreateUnit( Player( PID ), 'hbla', -6656., 1088., 270. )
		call CreateUnit( Player( PID ), 'harm', -6528., 1088., 270. )
		call CreateUnit( Player( PID ), 'hwtw', -6400., 1088., 270. )
		call CreateUnit( Player( PID ), 'hhou', -6272., 1088., 270. )
		set WayGate_Arr[ 1 ] = CreateUnit( Player( PID ), 'n00M', 4672., -640., 270. )
		call WaygateSetDestination( WayGate_Arr[ 1 ], -3456, 2048 )
		call WaygateActivate( WayGate_Arr[ 1 ], true )
		call SetUnitColor( WayGate_Arr[ 1 ], ConvertPlayerColor( 9 ) )
		set WayGate_Arr[ 3 ] = CreateUnit( Player( PID ), 'n00M', 4928., -640., 270. )
		call WaygateSetDestination( WayGate_Arr[ 3 ], -3472, -1744 )
		call WaygateActivate( WayGate_Arr[ 3 ], true )
		call SetUnitColor( WayGate_Arr[ 3 ], ConvertPlayerColor( 9 ) )
		set WayGate_Arr[ 5 ] = CreateUnit( Player( PID ), 'n00M', 5184., -640., 270. )
		call WaygateSetDestination( WayGate_Arr[ 5 ], -672, -288 )
		call WaygateActivate( WayGate_Arr[ 5 ], true )
		call SetUnitColor( WayGate_Arr[ 5 ], ConvertPlayerColor( 9 ) )
		set WayGate_Arr[ 7 ] = CreateUnit( Player( PID ), 'n00M', 5440., -640., 270. )
		call WaygateSetDestination( WayGate_Arr[ 7 ], 2128, -1712 )
		call WaygateActivate( WayGate_Arr[ 7 ], true )
		call SetUnitColor( WayGate_Arr[ 7 ], ConvertPlayerColor( 9 ) )
		set WayGate_Arr[ 9 ] = CreateUnit( Player( PID ), 'n00M', 5696., -640., 270. )
		call WaygateSetDestination( WayGate_Arr[ 9 ], 2144, 2048 )
		call WaygateActivate( WayGate_Arr[ 9 ], true )
		call SetUnitColor( WayGate_Arr[ 9 ], ConvertPlayerColor( 9 ) )

		call CreateUnit( Player( PID ), 'ncp3', 2112., 2048., 270. )
		call CreateUnit( Player( PID ), 'ncp3', -3456., -1728., 270. )
		call CreateUnit( Player( PID ), 'ncp3', 2112., -1728., 270. )
		call CreateUnit( Player( PID ), 'hlum', 5760., 448., 270. )
		call CreateUnit( Player( PID ), 'hgtw', 5760., 192., 270. )

		call SetUnitColor( CreateUnit( Player( PID ), 'hgtw', -7168., 192., 270. ), ConvertPlayerColor( 1 ) )
		set WayGate_Arr[ 4 ] = CreateUnit( Player( PID ), 'n00M', -6592., -576., 270. )
		call WaygateSetDestination( WayGate_Arr[ 4 ], -672, -288 )
		call WaygateActivate( WayGate_Arr[ 4 ], true )
		call SetUnitColor( WayGate_Arr[ 4 ], ConvertPlayerColor( 9 ) )
		set WayGate_Arr[ 6 ] = CreateUnit( Player( PID ), 'n00M', -6336., -576., 270. )
		call WaygateSetDestination( WayGate_Arr[ 6 ], 2128, -1712 )
		call WaygateActivate( WayGate_Arr[ 6 ], true )
		call SetUnitColor( WayGate_Arr[ 6 ], ConvertPlayerColor( 9 ) )
		set WayGate_Arr[ 8 ] = CreateUnit( Player( PID ), 'n00M', -6080., -576., 270. )
		call WaygateSetDestination( WayGate_Arr[ 8 ], 2144, 2048 )
		call WaygateActivate( WayGate_Arr[ 8 ], true )
		call SetUnitColor( WayGate_Arr[ 8 ], ConvertPlayerColor( 9 ) )

		call CreateUnit( Player( PID ), 'n00Y', -6912., 1088., 270. )
		call CreateUnit( Player( PID ), 'n00Y', 5504., 1152., 270. )
		
		set SysUnit = CreateUnit( Player( PID ), 'nwgt', 7040., 5888., 270. )
		call WaygateSetDestination( SysUnit, 2128, -1712 )
		call SetUnitColor( SysUnit, ConvertPlayerColor( 0 ) )
		set WayGate_Arr[ 11 ] = CreateUnit( Player( PID ), 'nwgt', -2944., 6976., 270. )
		call WaygateSetDestination( WayGate_Arr[ 11 ], -3472, -1744 )
		call SetUnitColor( WayGate_Arr[ 11 ], ConvertPlayerColor( 10 ) )
		set SysUnit = CreateUnit( Player( PID ), 'nwgt', 2752., -2368., 270. )
		call WaygateSetDestination( SysUnit, 6656, 6416 )
		call SetUnitColor( SysUnit, ConvertPlayerColor( 0 ) )
		set WayGate_Arr[ 10 ] = CreateUnit( Player( PID ), 'nwgt', -4224., -2432., 270. )
		call WaygateSetDestination( WayGate_Arr[ 10 ], -1600, 6144 )
		call SetUnitColor( WayGate_Arr[ 10 ], ConvertPlayerColor( 10 ) )
		
		set WayGate_Arr[ 13 ] = CreateUnit( Player( PID ), 'nwgt', -705., -3200., 270. )
		call WaygateSetDestination( WayGate_Arr[ 13 ], 7360, 3680 )
		call SetUnitColor( WayGate_Arr[ 13 ], ConvertPlayerColor( 4 ) )
		set SysUnit = CreateUnit( Player( PID ), 'nwgt', 7360., 3840., 270. )
		call WaygateSetDestination( SysUnit, -704, -3072 )
		call SetUnitColor( SysUnit, ConvertPlayerColor( 4 ) )
		set SysUnit = CreateUnit( Player( PID ), 'nwgt', 4160., 5312., 270. )
		call WaygateSetDestination( SysUnit, -688, 3344 )

		set WayGate_Arr[ 12 ] = CreateUnit( Player( PID ), 'nwgt', -704., 3456., 270. )
		call WaygateSetDestination( WayGate_Arr[ 12 ], 4160, 5488 )
		call SetUnitColor( WayGate_Arr[ 12 ], ConvertPlayerColor( 1 ) )	
		set WayGate_Arr[ 16 ] = CreateUnit( Player( PID ), 'nwgt', -2944., 5312., 270. )
		call WaygateSetDestination( WayGate_Arr[ 16 ], -3472, -1744 )
		call SetUnitColor( WayGate_Arr[ 16 ], ConvertPlayerColor( 10 ) )
		set WayGate_Arr[ 15 ] = CreateUnit( Player( PID ), 'nwgt', -256., 5312., 270. )
		call WaygateSetDestination( WayGate_Arr[ 15 ], -3472, -1744 )
		call SetUnitColor( WayGate_Arr[ 15 ], ConvertPlayerColor( 10 ) )
		set WayGate_Arr[ 14 ] = CreateUnit( Player( PID ), 'nwgt', -256., 6976., 270. )
		call WaygateSetDestination( WayGate_Arr[ 14 ], -3472, -1744 )
		call SetUnitColor( WayGate_Arr[ 14 ], ConvertPlayerColor( 10 ) )
		set DummyCaster = CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'u002', 8000, 8000, 0 )
		call SaveUnitHandle( HashTable, GetHandleId( HashTable ), StringHash( "CC_Dummy" ), CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), 'u995', 8000, 8000, 0 ) )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Init\StartData.j
	function Register_Destructable_Death takes nothing returns nothing
		call TriggerRegisterDeathEvent( LoadTrig( "T_Res_Destructables" ), GetEnumDestructable( ) )
	endfunction

	function Teleporter_Text takes string Text, unit WayGate returns nothing
		set bj_lastCreatedTextTag = CreateTextTag( )
		call SetTextTagText( bj_lastCreatedTextTag, Text, .018 ) // 8 * 0.0023 = .0184
		call SetTextTagColor( bj_lastCreatedTextTag, 255, 255, 255, 255 )
		call SetTextTagPos( bj_lastCreatedTextTag, GetUnitX( WayGate ), GetUnitY( WayGate ), 0 )
	endfunction

    function Restore_Destructables takes nothing returns nothing
        local destructable Pux = GetTriggerDestructable( )
        call TriggerSleepAction( 100. )
        call DestructableRestoreLife( Pux, GetDestructableMaxLife( Pux ), true )
		set Pux = null
    endfunction

	function MakeFogModifier takes integer Init_ID, real MinX, real MaxX, real MinY, real MaxY, integer Team returns nothing
		local integer i = 0
		call SetRect( SysRect, MinX, MaxX, MinY, MaxY )

		loop
			if ( ( Team == 0 or Team == 1 ) and GetPlayerTeam( Player( i ) ) == Team ) or Team == -1 then
				call FogModifierStart( CreateFogModifierRect( Player( i ), FOG_OF_WAR_VISIBLE, SysRect, true, false ) ) // i + Init_ID
			endif
			set i = i + 1
			exitwhen i == 12
		endloop
	endfunction

	function Init_Map takes nothing returns nothing
		local integer i = 0
		local integer Team_1_Players = CountPlayersInTeam( 0 )
		local integer Team_2_Players = CountPlayersInTeam( 1 )
		local integer Total_Players = 0
		local integer Kills = 30
		local integer Team_1_Gold = 4800 
		local integer Team_2_Gold = 4800
		local integer TotalPlayers = IMaxBJ( Team_1_Players, Team_2_Players )
		
		call ClearSelection( )
		call FogMaskEnable( false )
		call EnumDestructablesInRect( GetWorldBounds( ), null, function Register_Destructable_Death )
        call TriggerAddAction( LoadTrig( "T_Res_Destructables" ), function Restore_Destructables )

		if Team_1_Players > 0 then
			set Team_1_Gold = Team_1_Gold / Team_1_Players
		endif

		if Team_2_Players > 0 then
			set Team_2_Gold = Team_2_Gold / Team_2_Players
		endif

		if TotalPlayers > 1 then
			set Kills = 30 + 60 * ( TotalPlayers - 1 )
		endif
		call SaveInt( "Kill_Limit", Kills )

		loop
			exitwhen i > 11
			if GetPlayerTeam( Player( i ) ) == 0 then
				call SetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD, Team_1_Gold )
			else
				call SetPlayerState( Player( i ), PLAYER_STATE_RESOURCE_GOLD, Team_2_Gold )
			endif
			
			call SaveString( "Player_Name_" + I2S( i ), GetColour( i ) + GetPlayerName( Player( i ) ) + "|r" )
			call CreateUnit( Player( i ), 'okod', 8000, 8000, bj_UNIT_FACING )
			call CreateUnit( Player( i ), 'opeo', 8000, 8000, bj_UNIT_FACING )
			call CreateUnit( Player( i ), 'edoc', 8000, 8000, bj_UNIT_FACING )
			call CreateUnit( Player( i ), 'ohun', 8000, 8000, bj_UNIT_FACING )
			call CreateUnit( Player( i ), 'earc', 8000, 8000, bj_UNIT_FACING )
			set i = i + 1
		endloop

		call Teleporter_Text( "Top - Left", WayGate_Arr[ 0 ] )
		call Teleporter_Text( "Top - Left", WayGate_Arr[ 1 ] )
		
		call Teleporter_Text( "Bottom - Left", WayGate_Arr[ 2 ] )
		call Teleporter_Text( "Bottom - Left", WayGate_Arr[ 3 ] )
		
		call Teleporter_Text( "Middle", WayGate_Arr[ 4 ] )
		call Teleporter_Text( "Middle", WayGate_Arr[ 5 ] )
		
		call Teleporter_Text( "Bottom - Right", WayGate_Arr[ 6 ] )
		call Teleporter_Text( "Bottom - Right", WayGate_Arr[ 7 ] )
		
		call Teleporter_Text( "Top - Right", WayGate_Arr[ 8 ] )
		call Teleporter_Text( "Top - Right", WayGate_Arr[ 9 ] )

		call MakeFogModifier( 0,  -4480., -2720.,  3104.,  2432., -1 )
		call MakeFogModifier( 12,  3328., -6784.,  4736., -5248., -1 )
		call MakeFogModifier( 24, -7168.,  4864., -4576.,  7296., -1 )
		call MakeFogModifier( 36, -7456., -6848., -4704., -4096., -1 )
		call MakeFogModifier( 48, -3264.,  5056.,    64.,  7232., -1 )
		call MakeFogModifier( 60, -4480.,  2368., -3840.,  4064., -1 )
		call MakeFogModifier( 72,  2432.,  2336.,  3072.,  4096., -1 )
		call MakeFogModifier( 84, -7808., -7008., -4448., -3744., -1 )
		call MakeFogModifier( 96, -7392., -1056., -5664.,  1792.,  0 )
		call MakeFogModifier( 96,  4224., -1056.,  6048.,  1920.,  1 )

		call SetCameraPosition( 4032, -6016 + 50 )
		call SetFloatGameState( GAME_STATE_TIME_OF_DAY, 12.)
		call SuspendTimeOfDay( true )
		call SetTimeOfDayScale( 2 )
		call StopMusic( false )
		call ClearMapMusic( )

        call CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), 'nfgo', NewX( 6656, 350, 90 ), NewY( 6416, 350, 90 ), bj_UNIT_FACING )
        set Oz_Boss = CreateUnit( Player( PLAYER_NEUTRAL_AGGRESSIVE ), 'n00F', -1600, 6144, bj_UNIT_FACING )

		call CreateQuestBJ( 0, "Contacts", "If you have any suggestions, comments, or bug reports please write to me in Discord:
|c001ce6b9Unryze#4087|r

Or if you want to share ideas, bugs / glitches, you can visit our forums at:
|c001ce6b9https://vendev.info / |r or |c001ce6b9https://vk.com/acfwc3|r", "ReplaceableTextures\\CommandButtons\\BTNSpy.blp" )
		call QuestSetEnabled( bj_lastCreatedQuest, true )
		call CreateQuestBJ( 0, "Modes & Commands", "Modes:
All Random: -ar, Half Score: -hs, Double Score: -ds, No Duel: -nd, No 3v3: -n3, No 5V5: -n5, No Events: -ne.

Game Commands:
-ms, -ma, -clear, -camera 50-150, -help, -gameinfo, -so (locally toggles selection circles on/off).

Specific Commands:
-repick ( if available ), -swap ( if available ), -random ( if you have no hero picked yet ), -chance / - c ( if you play with Soi Fon )", "ReplaceableTextures\\CommandButtons\\BTNManual3.blp" )
		call QuestSetEnabled( bj_lastCreatedQuest, true )
		call CreateQuestBJ( 0, "Credits", "
Thanks to:
Kira_Izuru_3th, DarkDaro, WhiteSquirrel, Outrunner.

Additional Thanks to:
The first of all, thanks to Tite Kubo & Eiichiro Oda for their splendid creations. 
Blizzard for the World Editor, DotA Allstars, Naruto vs Bleach, FoC, and other Anime maps as my source of inspirations.

Also huge thanks to Kurogane for making this map, as it inspired me to give it a second breath with all models updated to HQ.
I've also decided addes icons to spells and sounds. I hope you will enjoy playing this map!", "ReplaceableTextures\\CommandButtons\\BTNShadowMelShop_1.blp" )
		call QuestSetEnabled( bj_lastCreatedQuest, true )
		call CreateQuestBJ( 2, "Latest Version", "Get the latest version and read the changelog from:
|c001ce6b9https://vk.com/acfwc3|r", "ReplaceableTextures\\CommandButtons\\BTNScrollofRegeneration.blp" )
		call QuestSetEnabled( bj_lastCreatedQuest, true )
		call CreateQuestBJ( 2, "Author Comments", "Thanks to all people who helped me until this point.
I would appreciate any kind of feedback about the map on my vk group: https://vk.com/acfwc3, so your thoughts will be very useful.

- Unryze", "ReplaceableTextures\\CommandButtons\\BTNShadowMelShop_1.blp" )
		call QuestSetEnabled( bj_lastCreatedQuest, true )
		call CreateQuestBJ( 2, "Model Credits", "Modelers / Animators / Skinners:
Bandai Namco, Unryze.

If you use models from this map, please add this names to your credit section!", "ReplaceableTextures\\CommandButtons\\BTNCloakOfFlames.blp" )
		call QuestSetEnabled( bj_lastCreatedQuest, true )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Init\Triggers.j
    function Init_Triggers takes nothing returns nothing
		local integer i = 0
		local trigger Trigger = CreateTrigger( )

		loop
			exitwhen i == 12
			call SetPlayerAbilityAvailable( Player( i ), 'A0D4', false )
			call SetPlayerAbilityAvailable( Player( i ), 'A104', false )
			call SetPlayerAbilityAvailable( Player( i ), 'Amrf', false )
			call SaveUnitHandle( HashTable, GetHandleId( Player( i ) ), StringHash( "Damage_Dummy" ), CreateUnit( Player( i ), 'u995', 8000, 8000, 0 ) )
			set i = i + 1
		endloop
		call SaveFloat( "Camera_Height", 2000 )
		set Rapire = CreateItem( 'I00A', 7360, -1360 )
		call TimerStart( CreateTimer( ), 1, true, function Game_Timer )
		call TimerStart( CreateTimer( ), .01, true, function CameraSetHeight )
		call ChatEvent( CreateTrigger( ), "-", false, function Game_Commands )
		call PlayerEvent( CreateTrigger( ), EVENT_PLAYER_LEAVE, function Player_Left_Action )

		call Rect_Enter_Event( CreateTrigger( ),  6784, -1728,  7936,  4500, function Enter_Rapire_Area )
		call Rect_Enter_Event( CreateTrigger( ),  6144,  5792,  7168,  7040, function Enteting_Forgotten_One_Area )
		call Rect_Enter_Event( CreateTrigger( ), -3648,  4736,   384,  7712, function Entering_Golem_Area )
		call Rect_Enter_Event( CreateTrigger( ),  3750,  5100,  4600,  7008, function Entering_Ring_Boss_Area )
		call Rect_Enter_Event( CreateTrigger( ), -1856, -3616,   448, -1888, function Create_Rapire_Doomguards )
		// TODO: FIX removes bankai when enter Rapire
		call Rect_Leave_Event( 			Trigger, -7392, -1056, -5664,  1792, function Leaving_Any_Area ) // Base 1
		call Rect_Leave_Event( 			Trigger,  4224, -1056,  6048,  1920, null ) 					 // Base 2
		call Rect_Leave_Event( 			Trigger,  6784, -1728,  7936,  4320, null ) 					 // Rapire Rect
		call Rect_Leave_Event( 			Trigger,  6144,  5792,  7168,  7040, null ) 					 // Forgotten One Area
		call Rect_Leave_Event( 			Trigger, -3648,  4736,   384,  7712, null ) 					 // Golem Area
		call Rect_Leave_Event( 			Trigger,  3750,  5100,  4600,  7008, null ) 					 // Ring Boss Area

		call Rect_Leave_Event( CreateTrigger( ), -4400,  2450, -3700,  4050, function  Left_Boss_Left )
		call Rect_Leave_Event( CreateTrigger( ),  2300,  2450,  3050,  4050, function Right_Boss_Left )

		call UnitEvent( LoadTrig( "SPELL_CAST" ),    EVENT_PLAYER_UNIT_SPELL_CAST, 	  function All_Abilities_Cast 	  )
		call UnitEvent( LoadTrig( "SPELL_EFECT" ),   EVENT_PLAYER_UNIT_SPELL_EFFECT,  function All_Abilities_Effect   )
		call UnitEvent( LoadTrig( "SPELL_ENDCAST" ), EVENT_PLAYER_UNIT_SPELL_ENDCAST, function All_Abilities_End_Cast )

		call UnitEvent( CreateTrigger( ), EVENT_PLAYER_UNIT_SELECTED, 		function Hero_Selection_Action 	)
		call UnitEvent( CreateTrigger( ), EVENT_PLAYER_UNIT_DEATH, 			function Death_Event 			)
        call UnitEvent( CreateTrigger( ), EVENT_PLAYER_HERO_LEVEL, 			function Unit_Level_Up_Event 	)
        call UnitEvent( CreateTrigger( ), EVENT_PLAYER_UNIT_PICKUP_ITEM, 	function Item_Pick_Up_Event 	)
		call UnitEvent( CreateTrigger( ), EVENT_PLAYER_UNIT_SELL_ITEM, 		function Item_Sell_Event 		)
		call UnitEvent( CreateTrigger( ), EVENT_PLAYER_UNIT_USE_ITEM, 		function Item_Use_Event 		)
        call UnitEvent( CreateTrigger( ), EVENT_PLAYER_UNIT_ATTACKED, 		function Unit_Attack_Event 		)
		call UnitEvent( CreateTrigger( ), EVENT_PLAYER_HERO_SKILL, 			function Ability_Learnt_Event 	)
        call TriggerAddAction( 			  LoadTrig( "Event_Damaged" ), 		function Unit_Damaged_Function  )
		set Trigger = null
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Init\Boundary.j
	function Init_Boundary takes nothing returns nothing
		local real MinX = -7808.0 + GetCameraMargin( CAMERA_MARGIN_LEFT )
		local real MinY = -7040.0 + GetCameraMargin( CAMERA_MARGIN_BOTTOM )
		local real MaxX =  8192.0 - GetCameraMargin( CAMERA_MARGIN_RIGHT )
		local real MaxY =  7424.0 - GetCameraMargin( CAMERA_MARGIN_TOP )
		call NewSoundEnvironment( "Default" )
        call SetCameraBounds( MinX, MinY, MaxX, MaxY, MinX, MaxY, MaxX, MinY )
        call SetDayNightModels( "Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdl", "Environment\\DNC\\DNCLordaeron\\DNCLordaeronUnit\\DNCLordaeronUnit.mdl" )
        // call SetAmbientDaySound( "CityScapeDay" )
        // call SetAmbientNightSound( "CityScapeNight" )
        // call SetMapMusic( "Music", true, 0 )
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Debug\Test_Commands.j
	function C2Id takes string Input returns integer
		local integer Pos = 0
		local string  FindChar

		loop
			set FindChar = SubString( "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", Pos, Pos + 1 )
			exitwhen FindChar == null or FindChar == Input
			set Pos = Pos + 1
		endloop

		if Pos < 10 then
			return Pos + 48
	elseif Pos < 36 then
			return Pos + 65 - 10
		endif
		
		return Pos + 97 - 36
	endfunction

	function S2Id takes string Input returns integer
		return ( ( C2Id( SubString( Input, 0, 1 ) ) * 256 + C2Id( SubString( Input, 1, 2 ) ) ) * 256 + C2Id( SubString( Input, 2, 3 ) ) ) * 256 + C2Id( SubString( Input, 3, 4 ) )
	endfunction

	function Id2C takes integer Input returns string
		local integer Pos = Input - 48

		if Input >= 97 then
			set Pos = Input - 97 + 36
	elseif Input >= 65 then
			set Pos = Input - 65 + 10
		endif

		return SubString( "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", Pos, Pos + 1 )
	endfunction

	function Id2S takes integer Input returns string
		local integer Result = Input / 256
		local string  Char   = Id2C( Input - 256 * Result )

		set Input  = Result / 256
		set Char   = Id2C( Result - 256 * Input ) + Char
		set Result = Input / 256

		return Id2C( Result ) + Id2C( Input - 256 * Result ) + Char
	endfunction

	function UnitID takes unit Target returns string
		return Id2S( GetUnitTypeId( Target ) )
	endfunction

	function Debug takes integer ID, string Text returns nothing
		if LoadBool( "Is_Debug_" + I2S( ID ) ) then
			call DisplayTextToPlayer( Player( ID ), 0, 0, Text )
		endif
	endfunction

	function GetUsedAbilityIDAction takes nothing returns nothing
		call Debug( GetPlayerId( GetTriggerPlayer( ) ), "|c0000ff00Used Ability ID|r: " + "[" + Id2S( GetSpellAbilityId( ) ) + "]" )
		call TriggerSleepAction( .01 )
		if LoadBool( "No_CD" ) then
			call UnitResetCooldown( GetTriggerUnit( ) )
		endif
	endfunction

	function UnitIDAction takes nothing returns nothing
		call Debug( GetPlayerId( GetTriggerPlayer( ) ), "|c0000ff00Selected unit ID|r: " + "[" + UnitID( GetTriggerUnit( ) ) + "]
		
		|cffffcc00Unit axis|r:
		|cffffcc00" + "X: " + "|r" + "|c0000ffff" + R2S( GetUnitX( GetTriggerUnit( ) ) ) + "|r
		|cffffcc00" + "Y: " + "|r" + "|c0000ffff" + R2S( GetUnitY( GetTriggerUnit( ) ) ) + "|r" )
	endfunction

	function PickedUpItemIDAction takes nothing returns nothing
		call Debug( GetPlayerId( GetTriggerPlayer( ) ), "|c0000ff00Picked Item ID|r: " + "[" + Id2S( GetItemTypeId( GetManipulatedItem( ) ) ) + "]" )
	endfunction

	function Test_Commands takes nothing returns nothing
		local integer i = 1
		local integer PID = GetPlayerId( GetTriggerPlayer( ) )
		local integer Value = 0
		local string Text = SubString( GetEventPlayerChatString( ), 1, StringLength( GetEventPlayerChatString( ) ) )
		local integer EmptyAt = FindEmptyString( 0, Text )
		local string Command = StringCase( SubString( Text, 0, EmptyAt ), false )
		local string Payload = SubString( Text, EmptyAt + 1, StringLength( GetEventPlayerChatString( ) ) )

		call SelectedUnit( Player( PID ) )

		if StringLength( Payload ) > 0 then
			if Command == "execute" then
				call ExecuteFunc( Payload )
				return
			endif
			set Value = S2I( Payload )

			if Command == "level" then
				if IsUnitType( Unr_Unit, UNIT_TYPE_HERO ) then
					if Value > GetHeroLevel( Unr_Unit ) then
						call SetHeroLevel( Unr_Unit, Value, false )
					else
						call UnitStripHeroLevel( Unr_Unit, GetHeroLevel( Unr_Unit ) - Value )
					endif
				endif
		elseif Command == "owner" then
				if Value >= 0 and Value <= 15 then
					call SetUnitOwner( Unr_Unit, Player( Value ), true )
				endif
		elseif Command == "scale" then
				call SetUnitScale( Unr_Unit, S2R( Payload ), S2R( Payload ), S2R( Payload ) )
		elseif Command == "str" or Command == "agi" or Command == "int" then
				if Command == "str" then
					call SetHeroStr( Unr_Unit, Value, true )
			elseif Command == "agi" then
					call SetHeroAgi( Unr_Unit, Value, true )
			elseif Command == "int" then
					call SetHeroInt( Unr_Unit, Value, true )
				endif
		elseif Command == "playanimation" then
				if i >= 0 then
					call Debug( PID, "|c0000ffff" + "Animation ID|r: " + "|cffffcc00" + "[" + I2S( i ) + "]|r" )
					call SetUnitAnimationByIndex( Unr_Unit, i )
				endif
			endif

			set Value = S2Id( Payload )

			if Command == "learn" then
				if Value != 0 then
					call Debug( PID, "|c0000ff00Ability|r: " + "[" + GetObjectName( Value ) + "] |c0000ff00was added|r" )
					call UnitAddAbility( Unr_Unit, Value )
				endif
		elseif Command == "unlearn" then
				if Value != 0 then
					call Debug( PID, "|c0000ff00Ability|r: " + "[" + GetObjectName( Value ) + "] |c0000ff00was removed|r" )
					call UnitRemoveAbility( Unr_Unit, Value )
				endif
		elseif Command == "createunit" then
				if Value != 0 then
					call CreateUnit( Player( PID ), Value, GetCameraTargetPositionX( ), GetCameraTargetPositionY( ), 270 )
					call Debug( PID, "|c0000ff00Unit with ID|r: " + "[" + Id2S( Value ) + "] |c0000ff00was spawned" )
				endif
		elseif Command == "createitem" then
				if Value != 0 then
					call Debug( PID, "|c0000ff00Item with ID|r: " + "[" + Id2S( Value ) + "] |c0000ff00was spawned" )
					call CreateItem( Value, GetUnitX( Unr_Unit ), GetUnitY( Unr_Unit ) )
				endif
			endif
	elseif StringLength( Payload ) == 0 then
			if Command == "debug" then
				if LoadBool( "Is_Debug_" + I2S( PID ) ) then
					call SaveBool( "Is_Debug_" + I2S( PID ), false )
					call DisplayTextToPlayer( Player( PID ), 0, 0, "|c00ff0000Debug Text Disabled!" )
				else
					call SaveBool( "Is_Debug_" + I2S( PID ), true )
					call DisplayTextToPlayer( Player( PID ), 0, 0, "|c0000FF00Debug Text Enabled!" )
				endif
		elseif Command == "nc" then
				if LoadBool( "No_CD" ) then
					call SaveBool( "No_CD", false )
					call Debug( PID, "|c00ff0000No-CoolDown Mode Operation Disabled!" )
				else
					call SaveBool( "No_CD", true )
					call Debug( PID, "|c0000FF00No-CoolDown Mode Operation Enabled!" )
				endif
		elseif Command == "copy" then
				set Value = GetUnitTypeId( Unr_Unit )
				if Value != 0 then
					call CreateUnit( Player( PID ), Value, GetUnitX( Unr_Unit ), GetUnitY( Unr_Unit ), 270 )
				endif
		elseif Command == "uninvul" then
				call SetUnitInvul( Unr_Unit, false )
		elseif Command == "ms" then
				call Debug( PID, "|c0000ffff" + "Movement Speed|r: " + "|cffffcc00" + "[" + R2S( GetUnitMoveSpeed( Unr_Unit ) ) + "]|r" )
		elseif Command == "res" or Command == "gold" then
				call Debug( PID, "|c0000ff00You recieved 100000000 resources.|r" )
				call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_LUMBER, 100000000 )
				call SetPlayerState( Player( PID ), PLAYER_STATE_RESOURCE_GOLD, 100000000 )
		elseif Command == "removeunit" then
				call Debug( PID, "|c0000ff00Unit removed|r" )
				call RemoveUnit( Unr_Unit )
		elseif Command == "teleport" then
				call Debug( PID, "|cffffcc00You have been teleported to axis|r:
				|cffffcc00" + "X: " + "|r" + "|c0000ffff" + R2S( GetCameraTargetPositionX( ) ) + "|r
				|cffffcc00" + "Y: " + "|r" + "|c0000ffff" + R2S( GetCameraTargetPositionY( ) ) + "|r" )
				call SetUnitPosition( Unr_Unit, GetCameraTargetPositionX( ), GetCameraTargetPositionY( ) )
		elseif Command == "heroes" then
				set i = 1
				loop
					exitwhen i > LoadInt( "Total_Heroes" )
					set PlayerUnit[ PID ] = CreateUnit( Player( PID ), LoadInt( "Hero_UID_" + I2S( i ) ), 0, 0, 270. )
					call SetHeroLevel( PlayerUnit[ PID ], 99, false )
					call PlacePickedHero( PID, i, " recieved: " )
					set i = i + 1
				endloop
			endif
		endif
	endfunction

	function Test_Triggers takes nothing returns nothing
		if true then
			// call SaveString( "Spawn_Type", "Off" )
			call UnitEvent( CreateTrigger( ), EVENT_PLAYER_UNIT_SPELL_EFFECT, 	function GetUsedAbilityIDAction )
			call UnitEvent( CreateTrigger( ), EVENT_PLAYER_UNIT_SELECTED, 		function UnitIDAction )
			call UnitEvent( CreateTrigger( ), EVENT_PLAYER_UNIT_PICKUP_ITEM, 	function PickedUpItemIDAction )
			call ChatEvent( CreateTrigger( ), "-", false, function Test_Commands )
		endif
	endfunction
	//#ExportEnd

	//#ExportTo Scripts\Init\main.j
    function main takes nothing returns nothing
		set g_ver = GetPatchLevel( )
		call ExecuteFunc( "InitBlizzard" )
		call ExecuteFunc( "Init_Boundary" )
        call ExecuteFunc( "Init_Music" )
        call ExecuteFunc( "Init_Units" )
		call ExecuteFunc( "Init_Triggers" )
		call ExecuteFunc( "Init_Map" )
		call ExecuteFunc( "Init_HeroPick" )
		call ExecuteFunc( "Init_AI" )
		call ExecuteFunc( "Test_Triggers" )
		call ExecuteFunc( "Init_Multiboard" )
		call ExecuteFunc( "Init_ItemPrices" )
    endfunction
	//#ExportEnd

	//#ExportTo Scripts\Init\config.j
    function config takes nothing returns nothing
		local integer i = 0
        call SetMapName( "|cff00ff00BvO Another v1.1c T26|r" )
        call SetMapDescription( "Choose from 30 different heroes from anime Bleach or One Piece to join the battle arena!\nModes: |c0020c000-ar, -hs, -ds, -nd, -n3, -n5, -ne, -fh, -sh|r" )
        call SetPlayers( 12 )
        call SetTeams( 2 )

		loop
			exitwhen i > 11
			if i != 5 and i != 11 then
				if i <= 4 then
					call DefineStartLocation( i, -6736., 435. )
					call SetPlayerTeam( Player( i ), 0 )
				else
					call DefineStartLocation( i,  5232., 435. )
					call SetPlayerTeam( Player( i ), 1 )
				endif

				call SetPlayerStartLocation( Player( i ), i )
				call ForcePlayerStartLocation( Player( i ), i )
				call SetPlayerColor( Player( i ), ConvertPlayerColor( i ) )
				call SetPlayerRacePreference( Player( i ), RACE_PREF_HUMAN )
				call SetPlayerRaceSelectable( Player( i ), false )
				call SetPlayerController( Player( i ), MAP_CONTROL_USER )
				call SetPlayerState( Player( i ), PLAYER_STATE_ALLIED_VICTORY, 1 )
			endif

			set i = i + 1
		endloop
    endfunction
	//#ExportEnd

