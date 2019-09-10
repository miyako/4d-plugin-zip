//%attributes = {}
  //$src:=Get 4D folder(Current resources folder)+Current method name+Folder separator
  //CREATE FOLDER($src;*)

  //METHOD GET CODE(Current method path;$code)
  //TEXT TO DOCUMENT($src+Current method name+".txt";$code;"utf-8")

$pass:="password"

If (False:C215)
	$src:=System folder:C487(Desktop:K41:16)+"test"
	$dst:=System folder:C487(Desktop:K41:16)+Current method name:C684+".zip"
	$start:=Milliseconds:C459
	$success:=Zip ($src;$dst;$pass;ZIP_Compression_level_2;ZIP_With_attributes)
	$duration:=Milliseconds:C459-$start
Else 
	$src:=System folder:C487(Desktop:K41:16)+Current method name:C684+".zip"
	$dst:=System folder:C487(Desktop:K41:16)
	$start:=Milliseconds:C459
	$success:=Unzip ($src;$dst;$pass;ZIP_With_attributes)
	$duration:=Milliseconds:C459-$start
End if 

  //$dst:=System folder(Desktop)+Current method name+".7z"
  //$success:=Zip ($src;$dst;$pass;0;ZIP_7Z)