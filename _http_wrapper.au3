#include-once
#include "WinHttp.au3"

;Параметры запроса
Global const $host="78.46.92.245"
Global const $uri="/metro/vk/121003/vk_metro.php"
Global const $user_agent="Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.89 Safari/537.1"
Global const $referer="http://cs309329.vk.com/u74657/9ec7251c212a9a.zip"

Func _http_init()
   Local $aIEproxy = _WinHttpGetIEProxyConfigForCurrentUser()
   Global $hOpen = _WinHttpOpen($user_agent,$WINHTTP_ACCESS_TYPE_DEFAULT_PROXY)
   Global $hConnect = _WinHttpConnect($hOpen, $host)
   if @error then return SetError (1, 0, 0)
   Return 1
EndFunc

Func _http_destruct()
   
   _WinHttpCloseHandle($hConnect)
   _WinHttpCloseHandle($hOpen)
   if NOT @error then 
	  DebugPrnt ("[winhttp] destroy successfully")
   Else
	  _DebugReport ("[winhttp] destroy error", True)
	  return SetError (1, 0, 0)
   EndIf
   return 1
EndFunc

Func __http_send(ByRef $hRequest, $params)
   local $text2 = _URIEncode(_ArrayToString ($params,"&"));
   $hRequest = _WinHttpOpenRequest($hConnect, "POST", $uri, Default, $referer)
   _WinHttpAddRequestHeaders($hRequest, "Origin: http://cs309329.vk.com")
   _WinHttpAddRequestHeaders($hRequest, "Content-Type: application/x-www-form-urlencoded")
   _WinHttpAddRequestHeaders($hRequest, "Accept-Encoding: gzip,deflate,sdch")
   _WinHttpAddRequestHeaders($hRequest, "Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4")
   _WinHttpAddRequestHeaders($hRequest, "Accept-Charset: windows-1251,utf-8;q=0.7,*;q=0.3")
   _WinHttpSendRequest($hRequest, Default, Default, StringLen($text2))
   _WinHttpWriteData($hRequest, $text2)
   
   if $hRequest = 0 or @error <> 0 then 
	  _DebugReport ("[winhttp] send error")
	  return SetError (1, 0, 0)
   EndIF
   return 1
EndFunc

Func __http_receive(ByRef $hRequest)
   _WinHttpReceiveResponse($hRequest)
   
   if @error then 
	  _DebugReport ("[winhttp] http_receive error", True)
	  Return SetError (1, 0, "")
   EndIf
   
   Local $summ = 0
   Local $data
   local $a
   while 1
	  if _WinHttpQueryDataAvailable($hRequest) Then
		 $a=@extended ;Доступные данные
		 $chunk = _WinHttpReadData ($hRequest,Default,$a)
		 $data &= $chunk
		 ;=@extended ;Полученные данные
		 ;$summ = $summ + $r
		 ;ConsoleWrite ("[" & $r & "/" & $summ & "] " & $chunk & @CRLF)
	  EndIf
	  If $a=0 then ExitLoop
   WEnd
   
   if @error=1 then 
	  _DebugReport ("[winhttp] http_receive error", True)
	  return SetError (1, 0, "")
   EndIf
   
   return $data
EndFunc

Func _http_SendAndReceive ($params)
   Local $hRequest
   Local $response
   
   if __http_send ($hRequest, $params) then 
      $response = __http_receive($hRequest)
   EndIf
   
   if @error then 
	  _WinHttpCloseHandle($hRequest)   
	  Return SetError (1, 0, "")
   EndIf
   _WinHttpCloseHandle($hRequest)   
   Return $response
EndFunc