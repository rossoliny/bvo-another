// RP2 repick diagnostics for Warcraft III 1.26; excluded from normal builds.
// Merge globals into map globals; insert functions after endglobals.
// Apply the commented connection snippets only to a temporary diagnostic script.
// Commands: -cheats bvo-rossoliny, -repickauto, Nami V or Kuma Q, -repicklog.
// Use a fresh normal-pick match, before 60 seconds, with at least 300 gold.
// Each export overwrites Logs\BvO_repick_RP2_P<player>.pld.

globals
    timer TestCommands_RepickLogClock = null
    integer TestCommands_RepickLogLineCount = 0
    integer TestCommands_RepickLogDroppedLines = 0
    integer TestCommands_RepickLogLastSnapshotStart = 0
    string array TestCommands_RepickLogLines
    boolean array TestCommands_RepickLogHeroDetailLines
    integer array TestCommands_RepickLogHeroTypes
    boolean array TestCommands_RepickLogInitialMembership
    player TestCommands_RepickPlayerOverride = null
    boolean array TestCommands_RepickAutoArmed
endglobals

function TestCommands_RepickLogBoolean takes boolean value returns string
    if value then
        return "1"
    endif
    return "0"
endfunction

function TestCommands_RepickLogAdd takes string message returns nothing
    if TestCommands_RepickLogLineCount < 2048 then
        set TestCommands_RepickLogLines[TestCommands_RepickLogLineCount] = "[RP2 t=" + R2S(TimerGetElapsed(TestCommands_RepickLogClock)) + "] " + message
        set TestCommands_RepickLogHeroDetailLines[TestCommands_RepickLogLineCount] = SubString(message, 0, 5) == "HERO "
        set TestCommands_RepickLogLineCount = TestCommands_RepickLogLineCount + 1
    else
        set TestCommands_RepickLogDroppedLines = TestCommands_RepickLogDroppedLines + 1
    endif
endfunction

function TestCommands_RepickLogHeroName takes integer heroType returns string
    if heroType == 0 then
        return "none"
    endif
    return GetObjectName(heroType) + "(id=" + I2S(heroType) + ")"
endfunction

function TestCommands_RepickLogMarker takes integer heroIndex returns unit
    if heroIndex <= 15 then
        return wj[heroIndex]
    endif
    return xj[heroIndex - 15]
endfunction

function TestCommands_RepickLogSnapshot takes string eventName, player focusPlayer returns nothing
    local integer heroIndex = 1
    local integer normalMembers = 0
    local integer secretMembers = 0
    local integer focusPlayerId = -1
    local unit heroMarker = null
    local boolean inPool = false
    local string availability = ""
    set TestCommands_RepickLogLastSnapshotStart = TestCommands_RepickLogLineCount
    if focusPlayer != null then
        set focusPlayerId = GetPlayerId(focusPlayer)
    endif
    call TestCommands_RepickLogAdd("BEGIN " + eventName + " player=" + I2S(focusPlayerId + 1) + " destroyFlag=" + TestCommands_RepickLogBoolean(bj_wantDestroyGroup) + " poolHandle=" + I2S(GetHandleId(i4)))
    if focusPlayer != null then
        call TestCommands_RepickLogAdd("PLAYER hero=" + TestCommands_RepickLogHeroName(GetUnitTypeId(m[focusPlayerId + 1])) + " gold=" + I2S(GetPlayerState(focusPlayer, PLAYER_STATE_RESOURCE_GOLD)) + " repicked=" + TestCommands_RepickLogBoolean(y4[focusPlayerId + 1]) + " repickEnabled=" + TestCommands_RepickLogBoolean(IsTriggerEnabled(qF)))
    endif
    loop
        exitwhen heroIndex > 30
        set heroMarker = TestCommands_RepickLogMarker(heroIndex)
        set inPool = IsUnitInGroup(heroMarker, i4)
        if eventName == "POOL_CREATED" then
            set TestCommands_RepickLogInitialMembership[heroIndex] = inPool
        endif
        if inPool then
            set normalMembers = normalMembers + 1
        endif
        set availability = ""
        if focusPlayer != null then
            set availability = " buyCap=" + I2S(GetPlayerTechMaxAllowed(focusPlayer, TestCommands_RepickLogHeroTypes[heroIndex]))
        endif
        call TestCommands_RepickLogAdd("HERO " + TestCommands_RepickLogHeroName(TestCommands_RepickLogHeroTypes[heroIndex]) + " initial=" + TestCommands_RepickLogBoolean(TestCommands_RepickLogInitialMembership[heroIndex]) + " inPool=" + TestCommands_RepickLogBoolean(inPool) + " markerType=" + I2S(GetUnitTypeId(heroMarker)) + " x=" + R2S(GetUnitX(heroMarker)) + " y=" + R2S(GetUnitY(heroMarker)) + availability)
        set heroIndex = heroIndex + 1
    endloop
    set heroIndex = 1
    loop
        exitwhen heroIndex > 2
        if yj[heroIndex] != null and IsUnitInGroup(yj[heroIndex], i4) then
            set secretMembers = secretMembers + 1
        endif
        set heroIndex = heroIndex + 1
    endloop
    call TestCommands_RepickLogAdd("END " + eventName + " normalMembers=" + I2S(normalMembers) + "/30 secretMembers=" + I2S(secretMembers) + " destroyFlag=" + TestCommands_RepickLogBoolean(bj_wantDestroyGroup))
    set heroMarker = null
endfunction

function TestCommands_RepickLogCommand takes nothing returns nothing
    local player requestingPlayer = GetTriggerPlayer()
    local string command = GetEventPlayerChatString()
    local string logPath = "Logs\\BvO_repick_RP2_P" + I2S(GetPlayerId(requestingPlayer) + 1) + ".pld"
    local integer lineIndex = 0
    if command == "-repickauto" then
        if not TestCommands_Access[GetPlayerId(requestingPlayer)] then
            call DisplayTimedTextToPlayer(requestingPlayer, 0, 0, 20, "[RP2] First enter -cheats bvo-rossoliny.")
        elseif not IsTriggerEnabled(qF) then
            call DisplayTimedTextToPlayer(requestingPlayer, 0, 0, 20, "[RP2] Repick is closed. Start a new match and use this before 60 seconds.")
        elseif m[GetPlayerId(requestingPlayer) + 1] == null or y4[GetPlayerId(requestingPlayer) + 1] then
            call DisplayTimedTextToPlayer(requestingPlayer, 0, 0, 20, "[RP2] Pick a hero first; repick can be used only once per player.")
        elseif GetUnitTypeId(m[GetPlayerId(requestingPlayer) + 1]) != 'E001' and GetUnitTypeId(m[GetPlayerId(requestingPlayer) + 1]) != 'N00X' then
            call DisplayTimedTextToPlayer(requestingPlayer, 0, 0, 20, "[RP2] This scenario requires Nami or Kuma.")
        elseif GetPlayerState(requestingPlayer, PLAYER_STATE_RESOURCE_GOLD) < 300 then
            call DisplayTimedTextToPlayer(requestingPlayer, 0, 0, 20, "[RP2] Repick requires at least 300 gold.")
        else
            set TestCommands_RepickAutoArmed[GetPlayerId(requestingPlayer)] = true
            call TestCommands_RepickLogAdd("AUTO_ARMED player=" + I2S(GetPlayerId(requestingPlayer) + 1))
            call DisplayTimedTextToPlayer(requestingPlayer, 0, 0, 30, "[RP2] Armed once. Cast Nami V Thunder Ball or Kuma Q Laser Beam before 60 seconds, then enter -repicklog.")
        endif
    elseif command == "-repicklog" then
        call TestCommands_RepickLogSnapshot("MANUAL_EXPORT", requestingPlayer)
        if GetLocalPlayer() == requestingPlayer then
            call PreloadGenClear()
            call PreloadGenStart()
            loop
                exitwhen lineIndex >= TestCommands_RepickLogLineCount
                call Preload("// " + TestCommands_RepickLogLines[lineIndex])
                set lineIndex = lineIndex + 1
            endloop
            call Preload("// RP2 droppedLines=" + I2S(TestCommands_RepickLogDroppedLines))
            call PreloadGenEnd(logPath)
            call PreloadGenClear()
        endif
        call DisplayTimedTextToPlayer(requestingPlayer, 0, 0, 30, "[RP2] Export requested: " + logPath + " (" + I2S(TestCommands_RepickLogLineCount) + " lines). If missing, use -repickscreen.")
    elseif command == "-repickscreen" then
        call TestCommands_RepickLogSnapshot("MANUAL_SCREEN", requestingPlayer)
        loop
            exitwhen lineIndex >= TestCommands_RepickLogLineCount
            if not TestCommands_RepickLogHeroDetailLines[lineIndex] or lineIndex >= TestCommands_RepickLogLastSnapshotStart then
                call DisplayTimedTextToPlayer(requestingPlayer, 0, 0, 60, TestCommands_RepickLogLines[lineIndex])
            endif
            set lineIndex = lineIndex + 1
        endloop
        call DisplayTimedTextToPlayer(requestingPlayer, 0, 0, 60, "[RP2] droppedLines=" + I2S(TestCommands_RepickLogDroppedLines))
    endif
    set requestingPlayer = null
endfunction

function TestCommands_RepickLogInitialize takes nothing returns nothing
    local trigger logCommandTrigger = CreateTrigger()
    local integer playerIndex = 0
    set TestCommands_RepickLogClock = CreateTimer()
    call TimerStart(TestCommands_RepickLogClock, 3600, false, null)
    set TestCommands_RepickLogHeroTypes[1] = 'EC08'
    set TestCommands_RepickLogHeroTypes[2] = 'EC12'
    set TestCommands_RepickLogHeroTypes[3] = 'H00I'
    set TestCommands_RepickLogHeroTypes[4] = 'H004'
    set TestCommands_RepickLogHeroTypes[5] = 'H003'
    set TestCommands_RepickLogHeroTypes[6] = 'O002'
    set TestCommands_RepickLogHeroTypes[7] = 'O001'
    set TestCommands_RepickLogHeroTypes[8] = 'OC10'
    set TestCommands_RepickLogHeroTypes[9] = 'UC13'
    set TestCommands_RepickLogHeroTypes[10] = 'U00S'
    set TestCommands_RepickLogHeroTypes[11] = 'U004'
    set TestCommands_RepickLogHeroTypes[12] = 'UC11'
    set TestCommands_RepickLogHeroTypes[13] = 'E004'
    set TestCommands_RepickLogHeroTypes[14] = 'H01Q'
    set TestCommands_RepickLogHeroTypes[15] = 'U00A'
    set TestCommands_RepickLogHeroTypes[16] = 'N009'
    set TestCommands_RepickLogHeroTypes[17] = 'N002'
    set TestCommands_RepickLogHeroTypes[18] = 'N006'
    set TestCommands_RepickLogHeroTypes[19] = 'N00T'
    set TestCommands_RepickLogHeroTypes[20] = 'N003'
    set TestCommands_RepickLogHeroTypes[21] = 'N00S'
    set TestCommands_RepickLogHeroTypes[22] = 'N007'
    set TestCommands_RepickLogHeroTypes[23] = 'N004'
    set TestCommands_RepickLogHeroTypes[24] = 'N005'
    set TestCommands_RepickLogHeroTypes[25] = 'N008'
    set TestCommands_RepickLogHeroTypes[26] = 'E000'
    set TestCommands_RepickLogHeroTypes[27] = 'E002'
    set TestCommands_RepickLogHeroTypes[28] = 'E001'
    set TestCommands_RepickLogHeroTypes[29] = 'N00U'
    set TestCommands_RepickLogHeroTypes[30] = 'N00X'
    call TestCommands_RepickLogAdd("Current map; repick fix ON; direct hero marker registration; automatic repick after natural spell cleanup; pool membership observed with native IsUnitInGroup; buyCap is the player's type limit, not a stock query.")
    loop
        exitwhen playerIndex >= 12
        call TriggerRegisterPlayerChatEvent(logCommandTrigger, Player(playerIndex), "-repickauto", true)
        call TriggerRegisterPlayerChatEvent(logCommandTrigger, Player(playerIndex), "-repicklog", true)
        call TriggerRegisterPlayerChatEvent(logCommandTrigger, Player(playerIndex), "-repickscreen", true)
        if GetPlayerSlotState(Player(playerIndex)) == PLAYER_SLOT_STATE_PLAYING and GetPlayerController(Player(playerIndex)) == MAP_CONTROL_USER then
            call DisplayTimedTextToPlayer(Player(playerIndex), 0, 0, 60, "[RP2] Repick diagnostics: -cheats bvo-rossoliny, -repickauto, Nami V or Kuma Q, then -repicklog. Screen: -repickscreen. Export overwrites this player's RP2 file.")
        endif
        set playerIndex = playerIndex + 1
    endloop
    call TriggerAddAction(logCommandTrigger, function TestCommands_RepickLogCommand)
    set logCommandTrigger = null
endfunction

function TestCommands_RepickLogMaintenance takes nothing returns nothing
    if bj_wantDestroyGroup then
        call TestCommands_RepickLogAdd("MAINTENANCE_CONSUMES destroyFlag=1")
    endif
endfunction

function TestCommands_RepickResolvePlayer takes player eventPlayer returns player
    if TestCommands_RepickPlayerOverride != null then
        return TestCommands_RepickPlayerOverride
    endif
    return eventPlayer
endfunction

function TestCommands_RepickAutoCleanup takes player castingPlayer returns nothing
    local player previousOverride = TestCommands_RepickPlayerOverride
    local integer playerIndex = GetPlayerId(castingPlayer)
    if castingPlayer != null and TestCommands_RepickAutoArmed[playerIndex] then
        set TestCommands_RepickAutoArmed[playerIndex] = false
        if not TestCommands_Access[playerIndex] or not IsTriggerEnabled(qF) then
            call TestCommands_RepickLogAdd("AUTO_SKIPPED player=" + I2S(playerIndex + 1) + " reason=access_or_selection_closed")
            call DisplayTimedTextToPlayer(castingPlayer, 0, 0, 20, "[RP2] Automatic repick skipped: access or selection is closed. Start a new match.")
        elseif not bj_wantDestroyGroup then
            call TestCommands_RepickLogAdd("AUTO_SKIPPED player=" + I2S(playerIndex + 1) + " reason=no_cleanup_flag")
        else
            set TestCommands_RepickPlayerOverride = castingPlayer
            call TestCommands_RepickLogAdd("AUTO_BEGIN player=" + I2S(playerIndex + 1) + " destroyFlag=1")
            if TriggerEvaluate(qF) then
                call TriggerExecute(qF)
                call DisplayTimedTextToPlayer(castingPlayer, 0, 0, 30, "[RP2] Repick handler executed. Check taverns, then enter -repicklog.")
            else
                call TestCommands_RepickLogAdd("AUTO_SKIPPED player=" + I2S(playerIndex + 1) + " reason=repick_condition")
                call DisplayTimedTextToPlayer(castingPlayer, 0, 0, 20, "[RP2] Automatic repick skipped: the normal repick condition failed. Enter -repicklog.")
            endif
            set TestCommands_RepickPlayerOverride = previousOverride
        endif
    endif
    set previousOverride = null
endfunction

function TestCommands_RepickGetPlayer takes nothing returns player
    local player requestingPlayer = GetTriggerPlayer()
    set requestingPlayer = TestCommands_RepickResolvePlayer(requestingPlayer)
    return requestingPlayer
endfunction

// TEMPORARY CONNECTIONS
// Keep the gameplay pool guard and direct marker registration enabled.
// Route GetTriggerPlayer() through TestCommands_RepickGetPlayer() only in:
// RepickHasHeroAndUnused, RepickNeedsNormalRefund, RepickHasSpecialGoldMode,
// RepickGoldBelowMinimum, RepickHasSecretHero, RepickCreateRandomHero,
// RepickDisableRandomHero, RepickEnableAvailableHero, RepickHasEnoughGold,
// and RepickAction. This supplies the caster's player during automatic repick.
// Insert local declarations before the first non-local statement.
// Insert only the commented diagnostic lines between their context anchors.

// Connection in the selection-closing handler (s1 / Hero_FinishSelection):
// Insert immediately before call DisableTrigger(qF):
//     call TestCommands_RepickLogSnapshot("SELECTION_CLOSE_BEFORE",null)

// Connection in the selection-closing handler (s1 / Hero_FinishSelection):
// Before: call DestroyTrigger(GetTriggeringTrigger())
//     call TestCommands_RepickLogSnapshot("SELECTION_CLOSED",null)
// After: endfunction

// Connection in InitializeAvailableHeroPool:
// Before: endif
//     call TestCommands_RepickLogAdd("SCAN_RECT minX="+R2S(GetRectMinX(Qo))+" minY="+R2S(GetRectMinY(Qo))+" maxX="+R2S(GetRectMaxX(Qo))+" maxY="+R2S(GetRectMaxY(Qo)))
//     call TestCommands_RepickLogSnapshot("POOL_CREATED",null)
// After: call ForGroupBJ(i4,function W1)

// Connection in InitializeAvailableHeroPool:
// Before: call ForGroupBJ(i4,function W1)
//     call TestCommands_RepickLogSnapshot("POOL_INITIALIZED",null)
// After: call DestroyTrigger(GetTriggeringTrigger())

// Connection in kO:
// Before: function kO takes nothing returns nothing
//     call TestCommands_RepickLogAdd("HERO_PURCHASE player="+I2S(GetPlayerId(GetOwningPlayer(GetSoldUnit()))+1)+" hero="+TestCommands_RepickLogHeroName(GetUnitTypeId(GetSoldUnit())))
//     call TestCommands_RepickLogSnapshot("PURCHASE_BEFORE",GetOwningPlayer(GetSoldUnit()))
// After: call ForForce(bj_FORCE_ALL_PLAYERS,function CN)

// Connection in kO:
// Before: call TriggerExecute(Scoreboard_RefreshTrigger)
//     call TestCommands_RepickLogSnapshot("PURCHASE_AFTER",GetOwningPlayer(GetSoldUnit()))
// After: endfunction

// Connection in zpe:
// Before: function zpe takes nothing returns nothing
//     local player TestCommands_RepickCastingPlayer=GetOwningPlayer(GetTriggerUnit())
//     call TestCommands_RepickLogSnapshot("NAMI_THUNDER_BALL_START",TestCommands_RepickCastingPlayer)
// After: set Zf[11]=GetTriggerUnit()

// Connection in zpe:
// Before: call GroupClear(Yj)
//     call TestCommands_RepickLogSnapshot("NAMI_THUNDER_BALL_CLEANUP",TestCommands_RepickCastingPlayer)
//     call TestCommands_RepickAutoCleanup(TestCommands_RepickCastingPlayer)
//     set TestCommands_RepickCastingPlayer=null
// After: endfunction

// Connection in cMx:
// Before: function cMx takes nothing returns nothing
//     local player TestCommands_RepickCastingPlayer=GetOwningPlayer(GetTriggerUnit())
//     call TestCommands_RepickLogSnapshot("KUMA_Q_START",TestCommands_RepickCastingPlayer)
// After: set Hk[0]=GetTriggerUnit()

// Connection in cMx:
// Before: call GroupClear(Kk)
//     call TestCommands_RepickLogSnapshot("KUMA_Q_CLEANUP",TestCommands_RepickCastingPlayer)
//     call TestCommands_RepickAutoCleanup(TestCommands_RepickCastingPlayer)
//     set TestCommands_RepickCastingPlayer=null
// After: endfunction

// Temporary replacement of RepickCondition:
// function RepickCondition takes nothing returns boolean
//     local boolean repickAllowed
//     call TestCommands_RepickLogSnapshot("REPICK_CONDITION",TestCommands_RepickGetPlayer())
//     set repickAllowed=RepickHasHeroAndUnused()
//     call TestCommands_RepickLogAdd("REPICK_CONDITION allowed="+TestCommands_RepickLogBoolean(repickAllowed))
//     return repickAllowed
// endfunction

// Temporary replacement of RepickPoolHasHeroes:
// function RepickPoolHasHeroes takes nothing returns boolean
//     local boolean poolHasHeroes
//     call TestCommands_RepickLogSnapshot("REPICK_POOL_BEFORE",TestCommands_RepickGetPlayer())
//     // The shared hero pool must never be destroyed by a stale spell flag.
//     set bj_wantDestroyGroup=false
//     set poolHasHeroes=(IsUnitGroupEmptyBJ(i4)==false)
//     call TestCommands_RepickLogSnapshot("REPICK_POOL_AFTER",TestCommands_RepickGetPlayer())
//     call TestCommands_RepickLogAdd("REPICK_POOL_CHECK returned="+TestCommands_RepickLogBoolean(poolHasHeroes))
//     return poolHasHeroes
// endfunction

// Connection in RepickAction:
// Before: endif
//     call TestCommands_RepickLogSnapshot("REPICK_COMPLETE",TestCommands_RepickGetPlayer())
// After: endfunction

// Connection in qix:
// Before: function qix takes nothing returns boolean
//     call TestCommands_RepickLogMaintenance()
// After: return(IsUnitGroupEmptyBJ(jg)==false)

// Connection in main:
// Before: call Q3x()
//     call TestCommands_RepickLogInitialize()
// After: call Q4x()
