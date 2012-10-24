#include-once
#include <Debug.au3>
#include "AssocArrays.au3"
#include <Crypt.au3>
global $init_debug_session = False
global $settings_savecache = 0
global $SectionName = "stats_" & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC

local const $SaveCachePath = @ScriptDir & "\logs\"
local const $DebugLogPath = @ScriptDir & "\logs\Debug.log"
local const $StatisticsLogPath = @ScriptDir & "\logs\Statistics.log"

Func _URIEncode($sData)
    ; Prog@ndy
    Local $aData = StringSplit(BinaryToString(StringToBinary($sData,4),1),"")
    Local $nChar
    $sData=""
    For $i = 1 To $aData[0]
        ; ConsoleWrite($aData[$i] & @CRLF)
        $nChar = Asc($aData[$i])
        Switch $nChar
            Case 44, 45, 46
                $sData &= "%" & Hex($nChar,2)
            Case 32
                $sData &= "+"
            Case Else
                
				$sData &= $aData[$i]
        EndSwitch
    Next
    Return $sData
EndFunc

Func _URIDecode($sData)
    ; Prog@ndy
    Local $aData = StringSplit(StringReplace($sData,"+"," ",0,1),"%")
    $sData = ""
    For $i = 2 To $aData[0]
        $aData[1] &= Chr(Dec(StringLeft($aData[$i],2))) & StringTrimLeft($aData[$i],2)
    Next
    Return BinaryToString(StringToBinary($aData[1],1),4)
EndFunc
 
Func DebugPrnt ($str, $itabs = 0)
   ;Если функция вызывается впервые, то инициализируем отладочную сессию
   if $init_debug_session = False then 
	 
	  $init_debug_session = true
   EndIf
   
   If StringLen($str)=0 then Return
   
   local $tab = ""
   for $i=0 to $itabs
	  $tab &= @TAB
   Next
   
   Local $msg
   $msg="[" & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & "]" & $tab & $str
   _DebugOut ($msg)
EndFunc

Func LoadSettings()
   local $sf = @ScriptDir & "\settings.ini"
;~    If NOT FileExists ($sf) then 
;~ 	  _DebugOut ("Отсутствует файл settings.ini!")
;~ 	  Exit
;~    EndIf
   $sSession = IniRead($sf, "vk", "session","")
   $sViewer = IniRead($sf, "vk", "viewer_id","")
   $p_key = IniRead($sf, "vk", "auth_key","")
   
   local $iDebugFlag = IniRead($sf, "debug", "flag","4")
   $settings_savecache = IniRead($sf, "debug", "savecache", 0)

   _DebugSetup("Metro bot debug log", True, $iDebugFlag, $DebugLogPath)
   
   If NOT FileExists ($sf) then 
	  DebugPrnt ("Settings.ini not found! Terminate!")
	  Exit (1)
   EndIf
   
   DebugPrnt ("Settings loaded!")
EndFunc

Func SaveCache(ByRef $text, $filename = "cache.txt")
   local $file = FileOpen($SaveCachePath & $filename, 10) ; which is similar to 2 + 8 (erase + create dir)
   FileWrite ($file, $text)
   FileClose($file)
EndFunc

Func LoadFromCache ($filename)
   local $text = ""
   local $file = FileOpen($filename, 0) ; read mode
   While 1
	  Local $chars = FileRead($file,1)
	  $text &= $chars
	  If @error = -1 Then ExitLoop
   WEnd
   FileClose($file)
   return $text
EndFunc

Func _TimeGetStamp()
        Local $av_Time
        $av_Time = DllCall('CrtDll.dll', 'long:cdecl', 'time', 'ptr', 0)
        If @error Then
                SetError(99)
                Return False
        EndIf
        Return $av_Time[0]
	 EndFunc
	 
Func SaveStatistics ($iGold = 0, $iExp = 0, $iWins = 0, $iLoses = 0)
   local $cur_gold = IniRead($StatisticsLogPath, $SectionName, "gold", 0)
   local $cur_exp = IniRead($StatisticsLogPath, $SectionName, "xp", 0)
   local $cur_wins = IniRead($StatisticsLogPath, $SectionName, "wins", 0)
   local $cur_loses = IniRead($StatisticsLogPath, $SectionName, "loses", 0)
   
   IniWrite ($StatisticsLogPath, $SectionName, "gold", $cur_gold + $iGold)
   IniWrite ($StatisticsLogPath, $SectionName, "xp", $cur_exp + $iExp)
   IniWrite ($StatisticsLogPath, $SectionName, "wins", $cur_wins + $iWins)
   IniWrite ($StatisticsLogPath, $SectionName, "loses", $cur_loses + $iLoses)
EndFunc

Func AssocArrayDisplay (ByRef $avArray)
   $asKeys = AssocArrayKeys($avArray)

   $sName = ""
   For $iCount = 0 To UBound($asKeys) - 1
	  $sName &= "[" & $asKeys[$iCount] & "] = " & AssocArrayGet($avArray, $asKeys[$iCount]) & @CRLF
   Next
   DebugPrnt ($sName)
EndFunc

Func _AddSign (ByRef $p)
   _ArraySort ($p)
   _Crypt_Startup()
   local $sig= StringLower (StringTrimLeft(_Crypt_HashData(_ArrayToString ($p,"") & $p_key, $CALG_MD5),2))
   _Crypt_Shutdown()
   _ArrayPush ($p, "auth=" & $sig)
EndFunc