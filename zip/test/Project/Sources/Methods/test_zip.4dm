//%attributes = {}
  //$src:=Get 4D folder(Current resources folder)+Current method name+Folder separator
  //CREATE FOLDER($src;*)

  //METHOD GET CODE(Current method path;$code)
  //TEXT TO DOCUMENT($src+Current method name+".txt";$code;"utf-8")

$pass:="password"

$src:=System folder:C487(Desktop:K41:16)+"test"+Folder separator:K24:12
$dst:=System folder:C487(Desktop:K41:16)+Current method name:C684+".zip"
$success:=Zip ($src;$dst;$pass;ZIP_Compression_level_default;ZIP_With_attributes)

$dst:=System folder:C487(Desktop:K41:16)+Current method name:C684+".7z"
$success:=Zip ($src;$dst;$pass;0;ZIP_7Z)