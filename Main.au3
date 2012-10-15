#include "_utils.au3"
#include "_metro.au3"

Global $runned = True	;Флаг активности бота

Main()
Exit

Func Main()
   Debug ("Started...","main")
   LoadSettings()
   Metro_init()
   _DebugOut ("Gold: " & metro_GetGold() & "; Energy: " & metro_GetEnergy() & ".")
   
   While $runned
	  IF NOT IsFightTimeout() Then
		 PlayArena()
	  Else
		 $pausetime = @extended - _TimeGetStamp() + 10
		 _DebugOut ("Wait for timeout: " & $pausetime & " seconds...")
		 Sleep ($pausetime*1000)
	  EndIf
   WEnd

   Metro_destruct()
EndFunc

Func PlayArena()
   _DebugOut ("Searching opponent...")
   local $c=1 ;Счетчик попыток поиска соперника
   while $c < 50
	  local $opponent = Metro_OpenArena()	 ;Заходим на арену, получаем инфу о сопернике.
	  _DebugOut ("Oppenent #" & $c & ": " & $opponent[0] & ", " & $opponent[1] & ", " & $opponent[2])
	  If $opponent[2] = 0 Then ExitLoop
	  Sleep (2000)
	  $c += 1
   WEnd
   _DebugOut ("Founded #" & $c & ": " & $opponent[0] & ", " & $opponent[1] & ", " & $opponent[2])
   
   local $fight = Metro_ArenaFight ($opponent[0])
   if @error<>0 then 
	  _DebugOut ("error on Metro_ArenaFight: " & @error & " ex: " & @extended)
	  if @extended="1202" then _DebugOut ("need timeout 5 min")
	  Return 0
   EndIf
   
   _DebugOut ("Fight with " & $opponent[1] & ": Win! +" & $fight[1] & " gold +" & $fight[2] & " exp." )
   
   $fight = Metro_ArenaStop()
   if @error<>0 then 
	  _DebugOut ("error on Metro_ArenaStop: " & @error & " ex: " & @extended)
	  Return 0
   EndIf
   
   _DebugOut ("Current stats: " & $fight[0] & " gold, " & $fight[1] & " exp, " & $fight[2] & " win rating.")
EndFunc