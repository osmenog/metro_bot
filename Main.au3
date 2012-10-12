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
   local $c=1 ;Счетчик попыток поиска соперника
   while $c < 50
	  local $arena_data_raw = metro_OpenArena()	 ;Заходим на арену, получаем инфу о сопернике.
	 
	  if Not $arena_data_raw then 
		 _DebugOut ("OpenArena error")
		 Return SetError (1, 0, 0)
	  EndIf
	  
	  ; Выполняем проверку на корректность данных
	  local $arena_data_array = _JSONDecode($arena_data_raw)
	  
	  if (NOT IsArray($arena_data_array)) then
		 _DebugOut ("Ошибка в OpenArena. Вернулись неверные данные")
		 _DebugReportVar ("arena_data_array",$arena_data_array)
		 Return SetError (1,0,0)
	  EndIf
	  
	  If ($arena_data_array[1][0]<>"foe") Then
		 _DebugOut ("Ошибка в OpenArena. Вернулись неверные данные")
		 _DebugReportVar ("arena_data_array",$arena_data_array)
		 Return SetError (1,0,0)
	  EndIf
	  
	  local $foe = $arena_data_array[1][1] ;Выбираем первую группу: foe
	  ;_ArrayDisplay ($foe, "foe")
	  local $fraction = $foe[13][1]			 ;Определяем фракцию (frac)
	  
	  _DebugOut ("Oppenent #" & $c & ": " & $foe[2][1] & ", " & $foe[1][1] & ", " & $fraction)
	  ;_DebugReportVar ("foe", $foe)
	  
	  if $fraction <> 0 then
		 $c += 1
		 Sleep (3000);
		 ContinueLoop
	  Else
		 _DebugOut ("Founded: " & $foe[2][1] & ", " & $foe[1][1] & ", " & $fraction)
		 
		 local $arena_data2_raw = metro_StartArena($foe[1][1])
		 if (Not $arena_data2_raw) Then
			_DebugOut ("StartArena error")
			Return SetError (1, 0, 0)
		 EndIf
		 
		 local $arena_data2_array = _JSONDecode($arena_data2_raw)

		 if (NOT IsArray($arena_data2_array)) then
			_DebugOut ("Ошибка в StartArena. Вернулись неверные данные")
			_DebugReportVar ("arena_data2_array",$arena_data2_array)
			Return SetError (1,0,0)
		 EndIf
	  
		 If ($arena_data2_array[1][0]<>"player") Then
			_DebugOut ("Ошибка в StartArena. Вернулись неверные данные")
			_DebugReportVar ("arena_data2_array",$arena_data2_array)
			Return SetError (1,0,0)
		 EndIf
		 
		 local $fray = $arena_data2_array[2][0]
		 
		 _ArrayDisplay($fray)
		 
		 Exit
		 
		 if $fray[1][1] = 1 then
			local $rew = $fray[6][0]
			_DebugOut ("Win! +" & $rew[1][1] & "exp +" & $rew[2][1] & "gold")
		 Else
			_DebugOut ("Loose!")
		 EndIf
		 
		 Sleep (1000)
		 
		 local $arena_data3_raw = metro_StopArena()
		 ;local $fray = $arena_data2_array[2][1]
		 
		 
		 ExitLoop
	  EndIf
   WEnd
EndFunc