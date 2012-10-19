Opt("TrayAutoPause", 0) ;0=no pause, 1=Pause
Opt("TrayIconDebug", 0) ;0=no info, 1=debug line info
Opt("TrayIconHide", 1) ;0=show, 1=hide tray icon

#include "_utils.au3"
#include "_metro.au3"

Global $runned = True	;Флаг активности бота
Global $ver = "0.2"		;Версия скрипта

Main()
Exit

Func Main()
   LoadSettings()
   DebugPrnt ("Started...")
   Metro_init()
   DebugPrnt ("Gold: " & $metro_var_gold & "; exp: " & $metro_var_xp & "; energy: " & $metro_var_energy & ".")
   DebugPrnt ("Servertime: " & $metro_var_servertime & ", current: " & _TimeGetStamp() & ", diff: " & (_TimeGetStamp()-$metro_var_servertime))
   While $runned
	  ;Проверяем взята ли работа, выполненна ли она, и получаем вознаграждение
	  IF IsJobFinished() then 
		 if ($metro_var_job_num = 0) and ($metro_var_job_finished = 0) then 
			Metro_JobTake (2)	;Взять вторую работу
			If @error=0 then 
			   DebugPrnt ("Начинаю работу №" & $metro_var_job_num & ". Окончание в " & $metro_var_job_finished & ".")
			Else
			   DebugPrnt ("Ошибка при взятии работы")
			EndIf
		 Else
			Metro_JobEarn()		;Получить вознаграждение
			DebugPrnt ("Работа завершена. Получили вознаграждение. <ПОКА НЕ РАБОТАЕТ!>")
		 EndIf
	  Else
		 ;DebugPrnt ("Выполняется работа №" & $metro_var_job_num & ". Окончание через " & $metro_var_job_finished-_TimeGetStamp() & ".")
	  EndIf
	  
	  ;Проверяем была ли завершена предыдущая битва на арене
	  IF $metro_var_NotFinishedFight = true then 
		 _DebugOut ("Обнаружена не завершенная битва на арене!!!")
		 $fight = Metro_ArenaStop()
		 if @error<>0 then 
			DebugPrnt ("Cannot close fight!")
		 Else
			DebugPrnt ("Fight in previous session closed!")
			$metro_var_NotFinishedFight = False
		 EndIf
	  EndIf
	  
	  ;Проверяем можно ли драться на арене
	  IF NOT IsFightTimeout() Then
		 PlayArena()
	  Else
		 $pausetime = @extended - _TimeGetStamp() + 15
		 DebugPrnt ("Wait for timeout: " & $pausetime & " seconds...")
	  EndIf
	  
	  ;Выдерживаем паузу между запросами
	  Sleep (10000)
   WEnd

   Metro_destruct()
EndFunc

Func PlayArena()
   DebugPrnt ("Searching opponent...")
   local $c=1 ;Счетчик попыток поиска соперника
   while $c < 50
	  local $opponent = Metro_OpenArena()	 ;Заходим на арену, получаем инфу о сопернике.
	  ;Тут нужна проверка на @error (1203)
	  DebugPrnt ("Oppenent #" & $c & ": " & $opponent[0] & ", " & $opponent[1] & ", " & $opponent[2])
	  If ($opponent[2]=1) or ($opponent[2]=0) Then ExitLoop
	  Sleep (1000)
	  $c += 1
   WEnd
   DebugPrnt ("Founded #" & $c & ": " & $opponent[0] & ", " & $opponent[1] & ", " & $opponent[2])
   
   local $fight = Metro_ArenaFight ($opponent[0])
   if @error<>0 then 
	  DebugPrnt ("error on Metro_ArenaFight: " & @error & " ex: " & @extended)
	  if @extended="1202" then 
		 DebugPrnt ("need timeout 5 min")
		 $metro_var_ArenaTimer = _TimeGetStamp() + 300
		 Return 0
	  EndIf
	  $runned = false
	  Return 0
   EndIf
   
   if $fight[0]=1 Then
	  DebugPrnt ("Fight with " & $opponent[1] & ": Win! +" & $fight[1] & " gold +" & $fight[2] & " exp." )
   Else
	  DebugPrnt ("Fight with " & $opponent[1] & ": Loose...")
   EndIf
   
   $fight = Metro_ArenaStop()
   if @error<>0 then 
	  DebugPrnt ("error on Metro_ArenaStop: " & @error & " ex: " & @extended)
	  Return 0
   EndIf
   
   if $fight[0]=1 Then DebugPrnt ("Current stats: " & $fight[0] & " gold, " & $fight[1] & " exp, " & $fight[2] & " win rating.")
EndFunc