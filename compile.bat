set PROTO_INCLUDE_DIR=D:\vcpkg\installed\x64-windows\include\
set COMPILE_TOOL_SET=.\tools\vs2019\x64\
set CPP_GENERATED=.\generated_cpp
set PYTHON_GENERATED=.\generated_python
set PROTO_FILES_TO_COMPILE=.\sensor.proto .\scan.proto .\pscan.proto .\discrete_scan.proto .\IF_scan.proto .\analog_demod.proto .\iq_acquire.proto .\drone_detect.proto .\tdoa.proto .\zerospan.proto .\multi_scan.proto .\pulseAnalysis.proto .\task_manage.proto

@rem cpp
set GPRC_CPP_PLUGIN="D:\vcpkg\installed\x64-windows\tools\grpc\grpc_cpp_plugin.exe"

%COMPILE_TOOL_SET%protoc --proto_path=%PROTO_INCLUDE_DIR% --proto_path=.\  --grpc_out=%CPP_GENERATED%   --plugin=protoc-gen-grpc=%GPRC_CPP_PLUGIN%  %PROTO_FILES_TO_COMPILE%

%COMPILE_TOOL_SET%protoc --proto_path=%PROTO_INCLUDE_DIR% --proto_path=.\  --cpp_out=%CPP_GENERATED%  %PROTO_FILES_TO_COMPILE%

@rem python
set GPRC_PYTHON_PLUGIN="D:\vcpkg\installed\x64-windows\tools\grpc\grpc_python_plugin.exe"

%COMPILE_TOOL_SET%protoc --proto_path=%PROTO_INCLUDE_DIR% --proto_path=.\  --grpc_python_out=%PYTHON_GENERATED%  --plugin=protoc-gen-grpc_python=%GPRC_PYTHON_PLUGIN%  %PROTO_FILES_TO_COMPILE%

%COMPILE_TOOL_SET%protoc --proto_path=%PROTO_INCLUDE_DIR% --proto_path=.\  --python_out=%PYTHON_GENERATED% %PROTO_FILES_TO_COMPILE%