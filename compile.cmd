CALL project.cmd

REM $compiler $options $includes -c $file -o $object

clang -o %Output% %Files% -I /GNUstep/GNUstep/System/Library/Headers -L /GNUstep/GNUstep/System/Library/Libraries -std=c99 -lobjc -fblocks -fobjc-nonfragile-abi -lgnustep-base -fobjc-exceptions -fconstant-string-class=NSConstantString

REM PAUSE