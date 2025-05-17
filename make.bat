"c:\Program Files (x86)\WinRAR\winrar.exe" a -afzip -r dat.love "assets" "game" "libraries" "states"
"c:\Program Files (x86)\WinRAR\winrar.exe" a -afzip dat.love *.lua
move dat.love distr
copy "assets\icons\game.ico" distr
copy README.txt distr
cd distr
rename game.ico love.ico
copy /b love.exe+dat.love dat.exe
"c:\Program Files (x86)\WinRAR\winrar.exe" a -afzip dat.zip dat.exe *.dll README.txt
copy dat.zip ..\
del dat.*
del *.ico
del *.txt
pause