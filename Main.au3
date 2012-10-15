#include "_utils.au3"
#include "_metro.au3"

Main()
Exit

Func Main()
   Debug ("Started...","main")
   LoadSettings()
   Metro_init()
   _DebugOut ("Gold: " & metro_GetGold() & "; Energy: " & metro_GetEnergy() & ".")
   
   PlayArena()
   
   Metro_destruct()
EndFunc

Func PlayArena()
   local $arena_timer = $cached_data[4][1]	;player[]
   $arena_timer = $arena_timer[29][1]		;stat[]
   $arena_timer = $arena_timer[14][1]		;"51"
   _DebugOut ($arena_timer)
   
   _DebugOut ("Searching opponent...")
   local $c=1 ;������� ������� ������ ���������
   while $c < 50
	  local $opponent = Metro_OpenArena()	 ;������� �� �����, �������� ���� � ���������.
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
   
   Metro_ArenaStop()
EndFunc