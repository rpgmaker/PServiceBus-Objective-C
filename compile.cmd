CALL project.cmd

clang -o %Output% %Files% -I /GNUstep/GNUstep/System/Library/Headers -L /GNUstep/GNUstep/System/Library/Libraries -std=c99 -lobjc -fblocks -fobjc-nonfragile-abi -lgnustep-base -fobjc-exceptions -fconstant-string-class=NSConstantString

PAUSE