CALL project.cmd

gcc -o %Output% %Files% -I /GNUstep/GNUstep/System/Library/Headers -L /GNUstep/GNUstep/System/Library/Libraries -std=c99 -lobjc -lgnustep-base -fobjc-exceptions -fconstant-string-class=NSConstantString

PAUSE