set PROTO_INCLUDE_DIR=D:\vcpkg\installed\x64-windows\include\
set GPRC_CPP_PLUGIN="D:\vcpkg\installed\x64-windows\tools\grpc\grpc_cpp_plugin.exe"
set COMPILE_TOOL_SET=.\tools\vs2019\
set CPP_GENERATED=.\generated_cpp

set PROTO_FILES_TO_COMPILE=.\sensor.proto .\scan.proto .\pscan.proto .\discrete_scan.proto .\IF_scan.proto .\analog_demod.proto .\iq_acquire.proto .\drone_detect.proto .\tdoa.proto

@rem cpp

%COMPILE_TOOL_SET%protoc --proto_path=%PROTO_INCLUDE_DIR% --proto_path=.\  --grpc_out=%CPP_GENERATED%   --plugin=protoc-gen-grpc=%GPRC_CPP_PLUGIN%  %PROTO_FILES_TO_COMPILE%

%COMPILE_TOOL_SET%protoc --proto_path=%PROTO_INCLUDE_DIR% --proto_path=.\  --cpp_out=%CPP_GENERATED%  %PROTO_FILES_TO_COMPILE%

