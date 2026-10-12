// One-shot transition probes: -killonT, -killonT back; cancel with -nokillonT.
// Included only in development builds; each player's default phase is zero.
globals
    integer array TestCommands_KillOnTPhase
endglobals

function TestCommands_KillOnTChat takes nothing returns nothing
    local string commandText = GetEventPlayerChatStringMatched()
    local player commandPlayer = GetTriggerPlayer()
    local integer playerIndex = GetPlayerId(commandPlayer)

    if commandText == "-killont back" then
        set TestCommands_KillOnTPhase[playerIndex] = 2
        call DisplayTimedTextToPlayer(commandPlayer,0,0,5,"killonT: смерть Пустого при обратном превращении, один раз")
    elseif commandText == "-killont" then
        set TestCommands_KillOnTPhase[playerIndex] = 1
        call DisplayTimedTextToPlayer(commandPlayer,0,0,5,"killonT: смерть Ичиго при входе в форму Пустого, один раз")
    elseif commandText == "-nokillont" then
        set TestCommands_KillOnTPhase[playerIndex] = 0
        call DisplayTimedTextToPlayer(commandPlayer,0,0,5,"killonT: оба режима выключены")
    endif
    set commandPlayer = null
endfunction

function TestCommands_KillOnTProbe takes unit targetUnit, integer transitionPhase returns nothing
    local integer playerIndex
    if targetUnit == null then
        return
    endif
    set playerIndex = GetPlayerId(GetOwningPlayer(targetUnit))
    if TestCommands_KillOnTPhase[playerIndex] == transitionPhase then
        set TestCommands_KillOnTPhase[playerIndex] = 0
        call KillUnit(targetUnit)
    endif
endfunction

function TestCommands_KillOnTInit takes nothing returns nothing
    local trigger commandTrigger = CreateTrigger()
    local integer playerIndex = 0
    loop
        exitwhen playerIndex >= 12
        set TestCommands_KillOnTPhase[playerIndex] = 0
        if GetPlayerController(Player(playerIndex)) == MAP_CONTROL_USER and GetPlayerSlotState(Player(playerIndex)) == PLAYER_SLOT_STATE_PLAYING then
            call TriggerRegisterPlayerChatEvent(commandTrigger,Player(playerIndex),"-killonT",true)
            call TriggerRegisterPlayerChatEvent(commandTrigger,Player(playerIndex),"-killonT back",true)
            call TriggerRegisterPlayerChatEvent(commandTrigger,Player(playerIndex),"-nokillonT",true)
        endif
        set playerIndex = playerIndex + 1
    endloop
    call TriggerAddAction(commandTrigger,function TestCommands_KillOnTChat)
    set commandTrigger = null
endfunction
