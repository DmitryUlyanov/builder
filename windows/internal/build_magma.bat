@setlocal

set MAGMA_VERSION=2.5.4

set CUVER_NODOT=%CUDA_VERSION%
set CUVER=%CUVER_NODOT:~0,-1%.%CUVER_NODOT:~-1,1%

set CONFIG_LOWERCASE=%CONFIG:D=d%
set CONFIG_LOWERCASE=%CONFIG_LOWERCASE:R=r%
set CONFIG_LOWERCASE=%CONFIG_LOWERCASE:M=m%

echo Building for configuration: %CONFIG_LOWERCASE%, %CUVER%

:: Download Ninja
curl -k https://s3.amazonaws.com/ossci-windows/ninja_1.8.2.exe --output C:\Tools\ninja.exe
if errorlevel 1 exit /b 1

set "PATH=C:\Tools;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%CUVER%\bin;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%CUVER%\libnvvp;%PATH%"
set CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%CUVER%
set NVTOOLSEXT_PATH=C:\Program Files\NVIDIA Corporation\NvToolsExt

mkdir magma_cuda%CUVER_NODOT%
cd magma_cuda%CUVER_NODOT%

if not exist magma (
  :: MAGMA 2.5.4 from http://icl.utk.edu/projectsfiles/magma/downloads/ with applied patches from our magma folder
  git clone https://github.com/peterjc123/magma.git magma
  if errorlevel 1 exit /b 1
) else (
  rmdir /S /Q magma\build
  rmdir /S /Q magma\install
)

cd magma
mkdir build && cd build

set GPU_TARGET=All
set CUDA_ARCH_LIST= -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=sm_70

IF "%CUVER_NODOT%" == "110" (
  set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80"
)

IF "%CUVER_NODOT%" == "111" (
  set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
)

IF "%CUVER_NODOT%" == "112" (
  set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
)

IF "%CUVER_NODOT%" == "113" (
  set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
)

IF "%CUVER_NODOT%" == "115" (
  set "CUDA_ARCH_LIST=%CUDA_ARCH_LIST% -gencode arch=compute_80,code=sm_80 -gencode arch=compute_86,code=sm_86"
)

set CC=cl.exe
set CXX=cl.exe

cmake .. -DGPU_TARGET="%GPU_TARGET%" ^
            -DUSE_FORTRAN=0 ^
            -DCMAKE_CXX_FLAGS="/FS /Zf" ^
            -DCMAKE_BUILD_TYPE=%CONFIG% ^
            -DCMAKE_GENERATOR=Ninja ^
            -DCMAKE_INSTALL_PREFIX=..\install\ ^
            -DCUDA_ARCH_LIST="%CUDA_ARCH_LIST%"
if errorlevel 1 exit /b 1

cmake --build . --target install --config %CONFIG% -- -j%NUMBER_OF_PROCESSORS%
if errorlevel 1 exit /b 1

cd ..\..\..

:: Create
7z a magma_%MAGMA_VERSION%_cuda%CUVER_NODOT%_%CONFIG_LOWERCASE%.7z %cd%\magma_cuda%CUVER_NODOT%\magma\install\*

rmdir /S /Q magma_cuda%CUVER_NODOT%\
@endlocal
