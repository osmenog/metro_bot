Opt("TrayAutoPause", 0) ;0=no pause, 1=Pause
Opt("TrayIconDebug", 0) ;0=no info, 1=debug line info
Opt("TrayIconHide", 1) ;0=show, 1=hide tray icon

#include "_utils.au3"
#include "_metro.au3"
#include "AssocArrays.au3"

Global $runned = True		;Флаг активности бота
Global Const $ver = "0.4"	;Версия скрипта

local $mr = Main()
Exit ($mr)

Func Main()
   LoadSettings()
   DebugPrnt ("Started v" & $ver & " ...")
   
   If Not Metro_init() then 
	  DebugPrnt ("Завершаем работу программы...")
	  Return 1
   EndIf
   
   #region Вывод информации о профиле игрока
   DebugPrnt ("Информация о профиле")
   DebugPrnt ("Деньги: " & AssocArrayGet($CacheArray, "gold") & _
			   "; Опыт: " & AssocArrayGet($CacheArray, "xp") & _
			   "; Энергия: " & AssocArrayGet($CacheArray, "energy") & ".", 1)
			   
   local $js = Metro_JobStatus()
   ;_ArrayDisplay ($js)
   Switch $js[0]
   case $JOB_NOTEARN
	  DebugPrnt ("Работа не взята", 1)
   case $JOB_ACTIVE
	  DebugPrnt ("Выполняется работа №" & $js[2] & ". Окончание в " & $js[1] & "." & "Награда: " & $js[3] & ".", 1)
   case $JOB_FINISHED
	  DebugPrnt ("Работа №" & $js[2] & " окончена. Награда: " & $js[3] & ".", 1)
   case else 
	  DebugPrnt ("Функция Metro_JobStatus вернула какуюто хрень :(", 1)
   EndSwitch
   
   local $st = AssocArrayGet($CacheArray, "servertime")
   local $ts = _TimeGetStamp()
   DebugPrnt ("Время сервера: " & $st & ". Время клиента: " & $ts & ". Разность: " & ($ts-$st), 1)
   #endregion   
   
   ;AssocArrayDisplay ($CacheArray)
   	  
   While $runned
	  
	  ;Проверяем взята ли работа, выполненна ли она, и получаем вознаграждение
	  local $js = Metro_JobStatus()   
	  Switch $js[0]
		 case $JOB_NOTEARN
			Metro_JobTake(2)	;Взять работу
			If @error=0 then 
			   DebugPrnt ("Начинаю работу №" & $js[2] & ". Окончание в " & $js[1] & ". Награда: " & $js[3] & ".")
			Else
			   DebugPrnt("Ошибка при взятии работы")
			EndIf
		 case $JOB_FINISHED
			Metro_JobEarn()		;Получить вознаграждение
			DebugPrnt ("Получили вознаграждение за работу: " & $js[3] & ".")
	  EndSwitch
	  	  
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
		 local $ts = _TimeGetStamp()
		 $pausetime = @extended - $ts + 15
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