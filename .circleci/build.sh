#!/usr/bin/env bash

# Toolchains
    # 0 = linaro gcc
    # 1 = clang 10
    # 2 = clang Latest
    
# Compiler switch
TC=2

cd /

#Fetch sources
git clone --depth 1 https://github.com/offset1313/xd wahoo
git clone --depth 1 git://github.com/CurioussX13/AnyKernel3 -b mido ak3

# Set Build Env
IMG=/wahoo/out/arch/arm64/boot/Image.gz-dtb
BID=$(openssl enc -base64 -d <<< OTk0MzkyMzY3OkFBRk9ZUS04aXZKUklLQTR2MEJQTGJuV3B0M1hWejNJSXFz )
GID=$(openssl enc -base64 -d <<< LTEwMDEzMTM2MDAxMDY= )
BDT=$(date +"%h-%m-%s")
export ARCH=arm64
#Gcc
if [ "$TC" == "0" ] ;
	then 
	    TOOL_VERSION=$(wahoo/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
		git clone --depth 1 https://github.com/offset1313/gcc  -b linaro gcc
		export CROSS_COMPILE=/gcc/bin/aarch64-linux-gnu-
		#CROSS_COMPILE_ARM32=arm-linux-gnueabi- 
		
#Clang 10
elif [ "$TC" == "1" ] ;
    then
        TOOL_VERSION=$("/pclang/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        git clone --depth 1 https://github.com/offset1313/clang  -b master pclang
        export CLANG_PATH=/pclang/bin
        export PATH=${CLANG_PATH}:${PATH}
        export LD_LIBRARY_PATH="/pclang/bin/../lib:$PATH"
        
#Clang 11
elif [ "$TC" == "2" ] ;
    then
        TOOL_VERSION=$("/pclang/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        git clone --depth 1 https://github.com/kdrag0n/proton-clang.git pclang
        export CLANG_PATH=/pclang/bin
        export PATH=${CLANG_PATH}:${PATH}
        export LD_LIBRARY_PATH="/pclang/bin/../lib:$PATH"
fi

function sendInfo() 
{
 curl -s -X POST https://api.telegram.org/bot"$BID"/sendMessage -d chat_id="$GID" -d "parse_mode=HTML" -d text="$(
  for POST in "${@}"; do
   echo "${POST}"
    done
     )" 
}

function sendLog() 
{
 curl -F chat_id="${GID}" -F document=@/build.log https://api.telegram.org/bot"$BID"/sendDocument
}

function sendZip()
{
 cd /ak3 || exit
 ZIP=$(echo *.zip)
 curl -F chat_id="${GID}" -F document="@$ZIP"  https://api.telegram.org/bot"${BID}"/sendDocument
}

function zipper()
{
 cp "${IMG}" /ak3
 cd /ak3 || exit 
 make -j16
 mv Thy-Kernel.zip Thy-"${BDT}".zip
}
function success() 
{
 sendInfo "<b>Commit: </b><code>$(git --no-pager log --pretty=format:'"%h - %s (%an)"' -1)</code>" \
          "<b>Compile Time: </b><code>$((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)</code>" \
          "<b>Toolchain:</b><code>${TOOL_VERSION}</code>" \
          "<b>proJTHy Success</b>"
 sendLog
}

function failed() 
{
 sendInfo "<b>Commit:</b><code>$(git --no-pager log --pretty=format:'"%h - %s (%an)"' -1)</code>" \
          "<b>ProJThy Failed</b>" \
          "<b>Total Time Elapsed: </b><code>$((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds.</code>"
 sendLog
 exit 1;
 }

function compile() 
{

if [ "$TC" == "0" ] ;
	then
		cd /wahoo || exit
		START=$(date +"%s")
		make ARCH=arm64 mido_defconfig O=out 
		make O=out -j16 &> /build.log 

fi

if [ "$TC" == "1" ] || [ "$TC" == "2" ] ;
	then 
		cd /wahoo || exit
		START=$(date +"%s")
		make ARCH=arm64 mido_defconfig O=out 
		PATH="/pclang/bin/:${PATH}" \
		make O=out -j16 &> /build.log \
			CC=clang \
			CLANG_TRIPLE=aarch64-linux-gnu- \
			CROSS_COMPILE=aarch64-linux-gnu- \
			CROSS_COMPILE_ARM32=arm-linux-gnueabi-
		

fi

if ! [ -a "$IMG" ] ; 
then																		
   END=$(date +"%s")
   DIFF=$((END - START))
   failed  

fi
  END=$(date +"%s")
  DIFF=$((END - START))
  success
  zipper
  sendZip
}

compile
