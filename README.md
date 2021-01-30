# 网格化监测系统API说明 v1.0

## 概述

该文档介绍系统的编程接口，指导开发者进行二次开发，构建自己的无线电监测应用程序。系统的接口基于protobuf和gRPC技术，采用语言中立的proto文件描述接口及消息。开发者可以根据个人喜好选择开发语言和开发环境。

## 典型C++/Qt环境搭建

### 依赖项

- Win7、Win10操作系统
- VS2015 update3 
- Qt5.7或以上
- vcpkg

### C++ API生成

- 双击运行`probuf-compile.bat`，把生成的.h和.cc文件拷贝到自己的工程目录下

- 在自己的工程中添加宏定义`_WIN32_WINNT=0x0600`

  其他方面请参考https://grpc.io/docs/tutorials/basic/cpp

建议开发者先了解熟悉protobuf和gRPC的相关技术，再进行二次开发。

## 接口说明

系统提供的接口，分布于`sensor.proto、scan.proto、pscan.proto、IF_scan.proto、discrete_scan.proto、analog_demod.proto、tdoa.proto、drone_detect`这几个文件中。其中`sensor.proto`文件描述了通用的消息类型和传感网络管理接口，`scan.proto pscan.proto IF_scan.proto discrete_scan.proto`分别描述了全景扫描，中频扫描，离散扫描的消息类型和接口，`analog_demod.proto`描述了模拟解调的消息类型和接口，`tdoa.proto`描述了TDOA定位的消息类型和接口，`drone_detect`描述了无人机探测的消息类型和接口。

### sensor.proto
该文件对应射频传感器网络的管理功能，用于传感器节点发现、节点信息获取、节点控制等。
该文件包含三个接口：

```protobuf
service RFNodeService {
  rpc ListAllNodes(google.protobuf.Empty) returns (NodesInfo) {}
  rpc GetNodeInfo(NodeId) returns (NodeInfo) {}
  rpc NodeControl(NodeControlRequest) returns (NodeReply) {}
}
```

1. `prorpc ListAllNodes(google.protobuf.Empty) returns (NodesInfo) {}`

   `ListAllNodes()`接口用于获取目前所有在线的传感器节点信息，`GetNodeInfo()`接口获得指定传感器的节点信息，`NodeControl`接口用于节点控制，比如操纵节点重启，停止所有运行中的任务等。接口返回一个`NodesInfo`消息，该消息包含了所有在线节点的信息，每一个节点的信息用一个`NodeInfo`表示。（注意`NodesInfo`和`NodeInfo`是两个不同的消息）。客户端可以采用轮询的方式，周期性调用该API，获取系统当前的节点信息，如果有节点新增或者掉线，应及时更新客户端的节点信息数据。`NodeInfo`是一个`protobuf`消息，定义如下：

```protobuf
//感知节点信息
message NodeInfo {
  NodeId id = 1;          //节点id
  string name = 2;        //节点名字
  Timestamp last_heard_time = 3;  //最近一次通信的时刻
  Position position = 4;          //节点位置
  repeated DeviceId devices = 5;  //隶属于节点的设备列表
  repeated TaskSummary tasks = 6; //节点正在运行的任务列表
}
```

2. `rpc GetNodeInfo(NodeId) returns (NodeInfo) {}`

   `GetNodeInfo()`接口用于获取指定节点的信息，由`NodeId`指明。

3. `rpc NodeControl(NodeControlRequest) returns (NodeReply) {}`

   `NodeControl()`接口用于节点控制，包括停止节点所有任务、节点重启、节点自检等，控制请求`NodeControlRequest`消息定义为：

```protobuf
//节点控制请求
message NodeControlRequest{
  repeated NodeId node_id = 1;  //节点id
  NodeControlType type = 2;     //控制类型
}
```

### scan.proto

该文件定义了系统**频谱扫描类型**功能的通用消息，全景扫描、离散扫描、中频扫描都会用到这些消息。

1. `FrequencySpan`消息定义了一个频率范围，该范围包含了起始频率和终止频率，单位均为Hz。

```protobuf
//频率范围
message FrequencySpan {
  double start_freq = 1;    //起始频率
  double stop_freq  = 2;    //终止频率
}
```

2. `SignalDescriptor`消息定义了一个频域上的信号，可用来表示信号检测和门限判决的结果。

```protobuf
//信号描述符
message SignalDescriptor {
  double center_freq = 1;   //中心频率
  double bandwidth = 2;     //带宽 
  float peak = 3;           //峰值
  float channel_power = 4;  //信号功率
  int32 emerge_count = 5;   //出现次数
}
```

3. `ResultOption`消息定义了系统在频谱扫描任务中的数据处理选项，这些选项包括数据保持、信号检测、门限判决。用户可以根据需要设置这些选项，如果选项被设置为`true`，则功能选项被激活，回送给客户端的结果中也随之会带有相应的处理数据，反之则不进行处理，结果中该部分也为空。

```protobuf
//结果选项
message ResultOption{
  bool enable_data_hold = 1;  //使能数据保持
  bool enable_auto_detect = 2;  //使能信号检测
  bool enable_threshold = 3;    //使能门限判别
}
```

4. `DetectResult`消息定义了信号检测的结果，结果中包含两项，一为系统自动生成的检测线，二为检出的信号列表。

```protobuf
//信号检测结果
message DetectResult{
  repeated float ref_trace = 1; //检测线
  repeated SignalDescriptor detect_signals = 2; //检出的信号列表
}
```

5. `ThresholdResult`消息定义了门限判别的结果，结果中包含两项，一为用户设置的门限电平线，二为通过门限比对产生的超过门限的信号列表。

```protobuf
//门限判别结果
message ThresholdResult{
  repeated float threshold_trace = 1; //门限线
  repeated SignalDescriptor over_threshold_signals = 2; //超出门限的信号列表
}
```

6. `DataHoldResult`消息定义了数据保持的结果，结果中包含两项，一为最大保持曲线，二为最小保持曲线。

```protobuf
//数据保持结果
message DataHoldResult{
  repeated float minhold_trace = 1; //最大保持线
  repeated float maxhold_trace = 2; //最小保持线
}
```

7. `ResultBody`消息定义了频谱的总结果，包含当前频率范围、频谱曲线，另外根据用户设定的选项，可能包含上面[4, 6]的子消息。

   注意：`Resultbody`中的`freq_span`和`realtime_trace`是每次结果肯定会有的，而`data_hold_result`、`detect_result`、`threshold_result`则可能为空，取决于用户在启动任务时的`ResultOption`选项。用户可以利用`protobuf`提供的消息接口`has_xxx`来判断子消息的有无，例如使用`resultBody.has_data_hold_result()`来判断是否存在数据保持的结果。

```protobuf
message ResultBody {
  FrequencySpan freq_span = 1;        //频率范围
  repeated float realtime_trace = 2;  //实时频谱线
  DataHoldResult data_hold_result = 3;  //数据保持结果
  DetectResult detect_result = 4;       //信号检测结果
  ThresholdResult threshold_result = 5; //门限判别结果
}
```

### pscan.proto

`pscan.proto`定义了系统**全景扫描**功能的消息和接口，全景扫描在一个频率范围内快速连续扫描，通常用于在一个较宽的频率范围内进行全范围监测，检测目前存在的信号和发现异常干扰。

包含6个服务接口：

```protobuf
service PScanService {
  rpc Start(StartPScanRequest) returns (TaskAccount) {} //启动任务
  rpc GetResult(TaskId) returns (stream PScanResult) {} //获取任务结果
  rpc ChangeRange(ChangeRangeRequest) returns (NodeReply) {}  //改变监测范围,注意:只改变回传的数据范围,不改变实际的扫描范围
  rpc Stop(TaskId) returns (NodeReply) {}   //停止任务
  rpc RecordOn(TaskAccount) returns (NodeReply) {}  //启动记录,启动后节点会将任务数据保存
  rpc RecordOff(TaskAccount) returns (NodeReply) {}   //停止记录
}
```

1. `rpc Start(StartPScanRequest) returns (TaskAccount) {} `

   `Start()`用于发起一个全景扫描任务，接口需要一个`StartPScanRequest`类型的消息作为请求，服务端会返回一个`TaskAccount`的消息作为响应。全景扫描任务发起的流程大致为：当客户端选择好参与全景扫描的节点和设备以及任务参数后，调用`Start()`，向服务端发起任务请求，服务端会解析`StartPScanRequest`消息，从中得到参与到该任务的传感器节点，就向所有这些节点发送任务参数，得到节点的正常响应后，服务端会将该节点id加到正常响应的节点列表中，并创建一个代表该任务的`TaskAccount`任务账号返回给客户端。
   
   `StartPScanRequest`消息定义：

```protobuf
//启动全景扫描请求
message StartPScanRequest {
  repeated NodeDevice task_runner = 1;  //参与任务的节点设备
  PScanParams pscan_params = 2;         //任务参数
}
```
 `TaskAccount`消息定义于`sensor.proto`，每种类型的任务在创建时，系统都会给客户端返回一个`TaskAccount`，该消息包含任务ID号和真正执行该任务的节点设备列表。任务ID是任务的唯一标识，在任务启动后续的API调用时，都要带有任务ID。注意：由于网络超时或节点被占用等各种原因，在任务参数下发时，并非所有节点都会正常响应，客户端程序需要查看`TaskAccount`中的`node_devices`是否与下发任务时选中的节点设备数量一致，如果不一致，意味着有节点没有正常响应，此刻需要写入日志或向用户及时反馈，后续所有其他任务的创建与之类似，都需要对响应结果进行确认，后面不再赘述。

```protobuf
//任务账号
message TaskAccount{
  TaskId task_id = 1;   //任务id
  repeated NodeDevice node_devices = 2; //有效执行该任务的节点
}
```

2. `rpc GetResult(TaskId) returns (stream PScanResult) {} `

   `GetResult()`用于获取该任务的数据。该接口的返回值是一个`gRPC`消息流，接口会持续的推送`PScanResult`消息到客户端。客户端不应在主线程调用该接口，因为在任务结束之前，该接口的调用不会返回，主线程将得不到控制权。所有流式接口都应有**独立的工作线程**来进行结果的接收。

   `PScanResult`定义如下：

```protobuf
//全景扫描结果
message PScanResult {
  NodeDevice result_from = 1;     //结果来自哪个节点设备
  PScanResultHeader header = 2;   //结果头
  ResultBody result_body = 3;     //结果体
}
```

`result_from`表明该消息来自哪个节点设备，描述头包括数据的时间戳，方位戳，顺序号等子消息，数据体是一个子消息，其类型是在`scan.proto`中定义的`ResultBody`，包括频率范围、频谱迹线、信号列表、门限等数据细目。

3. `rpc ChangeRange(ChangeRangeRequest) returns (NodeReply) {} `

   `ChangeRange()`用于更改任务的频率范围。

   `ChangeRangeRequest`消息定义如下：

```protobuf
//监测范围改变的请求
message ChangeRangeRequest {
  TaskAccount task_account = 1;     //任务账号
  FrequencySpan span = 2;           //要监测的范围
}
```

从中可以看出，该请求向服务端发送了`TaskAccount`和一个待变更的频率范围，服务端在收到该消息后，将会根据`TaskAccount`所列的设备id，向相关的设备节点发送该频率变更指令，待所有节点响应后，会生成一个`NodeReply`消息，返回给客户端。`NodeReply`是一个`CmdHeader`消息的集合，反映了所有执行该请求的设备节点的响应结果，与启动任务时类似，因为无法保证所有响应结果均为正常，所以客户端需要对这个响应结果进行解析，根据错误码来确定后续行为。可能遇到的响应错误情况包括`taskId`非法、频率范围参数非法、节点响应超时等。

`NodeReply`消息定义为

```protobuf
//节点响应
message NodeReply{
  repeated CmdHeader cmd_header = 1;  //命令响应集合
}
```

可以看到，响应结果是一组`CmdHeader`消息，`CmdHeader`消息定义为

```protobuf
message CmdHeader{
  uint32 sequence_number = 1;	//指令顺序号
  ErrorType error_code = 2;		//错误码
  TaskId task_id = 3;			//任务id
  NodeDevice task_runner = 4;	//设备节点id
};
```

值得进一步说明的是`ChangeRange`接口的惯常调用方式。`ChangeRange`是一种对**任务过程进行干预**的API。后面的`RecordOn`和`RecordOff`接口也属于此类API，这类API在其他任务类型中也或多或少存在，这类API通常在任务的执行过程中被用户调用，用来改变任务的行为，用户可以任意设定**所有参与任务的节点集合的一个子集**去处理该请求。

设置的关键在于请求消息中的`taskAccount`，用户可以根据需要，选取节点设备来填充`taskAccount`中`node_devices`子消息，下发给系统，从而这个子集去执行该请求。例如，客户端如果想让所有任务节点都响应`ChangeRange`，就可以传入任务创建时的`taskAccount`，这种情况下所有参与任务的节点都会执行该请求；如果只想让某个节点设备执行该请求，就只把该设备节点填入`node_devices`中。这样，任务就会变得很灵活，即可以观察同一个频率范围，也可以观察若干不同的频率范围，以适应不同的应用场景。

4. `rpc Stop(TaskId) returns (NodeReply) {}`

   `Stop()`用于停止某个全景扫描任务。接口以`TaskId`作为请求，服务端在收到请求后，会向参与该任务的所有节点发送停止命令，待节点响应后，向客户端返回`NodeReply`响应结果。可能遇到的响应错误情况包括`taskId`非法，节点响应超时等。

5. `rpc RecordOn(TaskAccount) returns (NodeReply) {}`

   `RecordOn()`启动节点端的数据记录功能。该接口向服务端发送了`TaskAccount`，来说明需要开启记录的节点，服务端在收到消息后，会向相关节点发送指令，由节点端执行实际的数据记录（数据将记录在节点本地），待节点响应后，向客户端返回`NodeReply`响应结果。如果有节点已经开始记录或出现其他无法启动记录的情况，将体现在`NodeReply`的错误码中。

6. `rpc RecordOff(TaskAccount) returns (NodeReply) {}`

   `RecordOff()`停止记录功能。该接口向服务端发送了`TaskAccount`，来说明需要停止记录的节点，服务端在收到消息后，会向相关节点发送指令，待节点响应后，向客户端返回`NodeReply`响应结果。如果有的节点之前并没有开启记录，节点则会忽略此操作，并回送响应的错误码。

### TDOA.proto

该文件定义了系统TDOA功能的消息和接口，包含3个接口

```protobuf
service TDOAService {
  rpc StartTDOA(StartTDOARequest) returns (TaskAccount) {}
  rpc GetResult(TaskId) returns (stream TDOAResponse) {}
  rpc StopTDOA(TaskId) returns (NodeReply) {}
}
```

1. `StartTDOA()`用于发起一个TDOA任务，客户端通过该接口向服务端发送`StartTDOARequest`消息，服务端回送`TaskAccount`消息作为响应。

`StartTDOARequest`消息定义为：

```protobuf
message StartTDOARequest{
  repeated NodeDevice task_runner = 1;	//参与TDOA定位任务的节点集合
  TDOAParams task_parms = 2;	//任务参数
}
```

其中的第二项`TDOAParams`消息定义为：

```protobuf
message TDOAParams {
  repeated TargetSignal target_signals  = 1;	//待定位的信号列表
  Timestamp sync_acquire_time = 2;				//起始同步采集时刻
  uint32 interval_msec = 3;    					//采集间隔，毫秒为单位
}
```

`TDOAParams`其中的第一项为待定位目标信号的列表，其中的每一项为描述一个信号的消息`TargetSignal`

```protobuf
message TargetSignal {
  double center_freq = 1;	//信号中心频率
  double bandwidth = 2;		//信号带宽
  int32 num_iteration = 3;	//定位迭代次数
  int32 attenuation_gain = 4; 	//增益衰减
  int32 antenna = 5;			//天线端口
}
```

2. `GetResult()`用于持续的获取定位结果，请求的消息为任务id，注意该接口是一个流接口，当启动TDOA任务后，一次性调用该接口会持续收到服务端的响应，响应包含定位过程和定位结果消息，直到任务停止之后，该调用才会返回。

```protobuf
message TDOAResponse {
  TDOAResult tdoa_result = 1;	//定位结果
  TDOADetail detail = 2;		//定位过程数据
}
```

```protobuf
message TDOAResult {
  ResultHeader header = 1;		//定位结果描述头       
  repeated GeogCoord target_position = 2;	//目标位置
  Timestamp timestamp = 3;          //获取时间
  repeated Participator participators = 4;	//参与定位的节点    
}
```

定位的结果数据`TDOAResult`中最重要的一项是序号为2的`repeated GeogCoord target_position`，该项包含了目标位置（经纬度信息），注意该项为复数，可包含[0,2]个定位结果，如果定位结果有0个，说明没有解，如果定位结果有1个，说明有唯一解；如果定位有2个，说明存在模糊解。

定位的过程数据`TDOADetail`可以包含定位过程中产生的频谱迹线、IQ迹线、互相关曲线等过程数据。用户可以根据需要，决定是否显示这些细节。

3. `StopTDOA()`用于停止TDOA任务，客户端以任务id为参数调用该接口，服务端会向所有参与该TDOA任务的节点发送停止命令，待所有节点响应后，将响应结果以`NodeReply`消息形式返回给客户端。







