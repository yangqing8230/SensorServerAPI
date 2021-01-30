set PROTO_INCLUDE_DIR=D:\vcpkg\installed\x64-windows\include\
set GPRC_CPP_PLUGIN="D:\vcpkg\installed\x64-windows\tools\grpc\grpc_cpp_plugin.exe"
set GPRC_PYTHON_PLUGIN="D:\vcpkg\installed\x64-windows\tools\grpc\grpc_python_plugin.exe"

set PROTO_FILES_TO_COMPILE=.\sensor.proto .\scan.proto .\pscan.proto .\discrete_scan.proto .\IF_scan.proto .\analog_demod.proto .\iq_acquire.proto .\drone_detect.proto .\tdoa.proto

@rem cpp

.\protoc --proto_path=%PROTO_INCLUDE_DIR% --proto_path=.\  --grpc_out=..\gRPCGenerated  --plugin=protoc-gen-grpc=%GPRC_CPP_PLUGIN%  %PROTO_FILES_TO_COMPILE%

.\protoc --proto_path=%PROTO_INCLUDE_DIR% --proto_path=.\  --cpp_out=..\gRPCGenerated   %PROTO_FILES_TO_COMPILE%

@rem python

protoc --proto_path=%PROTO_INCLUDE_DIR% --proto_path=.\  --grpc_python_out=..\PythonClient  --plugin=protoc-gen-grpc_python=%GPRC_PYTHON_PLUGIN%  %PROTO_FILES_TO_COMPILE%

.\protoc --proto_path=%PROTO_INCLUDE_DIR% --proto_path=.\  --python_out=..\PythonClient %PROTO_FILES_TO_COMPILE%


@rem .\protoc --proto_path=%PROTO_INCLUDE_DIR% --proto_path=.\  --java_out=.\generated-java   .\rf_node.proto  .\spectrum.proto