Opt("TrayAutoPause", 0) ;0=no pause, 1=Pause
Opt("TrayIconDebug", 0) ;0=no info, 1=debug line info
Opt("TrayIconHide", 1) ;0=show, 1=hide tray icon

#include "_utils.au3"
#include "_metro.au3"
#include "AssocArrays.au3"


Global $runned = True	;Флаг активности бота
Global Const $ver = "0.3"		;Версия скрипта

Main()
Exit

Func Main()
   LoadSettings()
   DebugPrnt ("Started v" & $ver & " ...")
   
   Metro_init()
   
   DebugPrnt ("Информация о профиле")
   DebugPrnt ("Деньги: " & AssocArrayGet($CacheArray, "gold") & _
			   "; Опыт: " & AssocArrayGet($CacheArray, "xp") & _
			   "; Энергия: " & AssocArrayGet($CacheArray, "energy") & ".", 1)
   
   if NOT IsJobFinished() then 
	  DebugPrnt ("Выполняется работа №" & AssocArrayGet($CacheArray, "job_num") & _
			     ". Окончание в " & AssocArrayGet($CacheArray, "job_finished") & "." & _
				 "Награда: " & AssocArrayGet($CacheArray, "job_goldrew") & ".", 1)
   Else
	  DebugPrnt ("В данный момент работа не выполняется", 1)
   EndIf
	  
   
   local $st = AssocArrayGet($CacheArray, "servertime")
   local $ts = _TimeGetStamp()
   DebugPrnt ("Время сервера: " & $st & ". Время клиента: " & $ts & ". Разность: " & ($ts-$st), 1)
   
   While $runned
	  ;Проверяем взята ли работа, выполненна ли она, и получаем вознаграждение
	  IF IsJobFinished() then 
		 if (AssocArrayGet($CacheArray, "job_num") = 0) and _ 
		 (AssocArrayGet($CacheArray, "job_finished") = 0) then 
			Metro_JobTake (2)	;Взять работу
			If @error=0 then 
			   DebugPrnt ("Начинаю работу №" & AssocArrayGet($CacheArray, "job_num") & ". Окончание в " & AssocArrayGet($CacheArray, "job_finished") & ".")
			Else
			   DebugPrnt ("Ошибка при взятии работы")
			EndIf
		 Else
			Metro_JobEarn()		;Получить вознаграждение
			DebugPrnt ("Работа завершена. Получили вознаграждение.")
		 EndIf
	  Else
		 ;DebugPrnt ("Выполняется работа №" & $metro_var_job_num & ". Окончание через " & $metro_var_job_finished-_TimeGetStamp() & ".")
	  EndIf
	  
	  ;Проверяем была ли завершена предыдущая битва на арене
	  IF AssocArrayGet($CacheArray, "isfight") then 
		 _DebugOut ("Обнаружена не завершенная битва на арене!!!")
		 $fight = Metro_ArenaStop()
		 if @error<>0 then 
			DebugPrnt ("Ошибка!!! Не могу завершить битву.")
		 Else
			DebugPrnt ("Открытая ранее битва завершена!")
			AssocArrayAssign($CacheArray, "isfight", False)
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
		 AssocArrayAssign($CacheArray, "arenatimer", _TimeGetStamp() + 300)
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