// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:async';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  UsbPort? _port;
  String _status = "Idle";
  List<Widget> _ports = [];
  List<Widget> _serialData = [];
  List<String> _input = ["80", "35", "45", "1", "60", 'N'];

  int i = 0;
  // double _throttle = 0;
  // double _battery = 0;

  StreamSubscription<String>? _subscription;
  Transaction<String>? _transaction;
  UsbDevice? _device;

  // TextEditingController _textController = TextEditingController();

  Future<bool> _connectTo(device) async {
    _serialData.clear();

    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }

    if (_transaction != null) {
      _transaction!.dispose();
      _transaction = null;
    }

    if (_port != null) {
      _port!.close();
      _port = null;
    }
    if (device == null) {
      _device = null;
      setState(() {
        _status = "Disconnected";
      });
      return true;
    }

    _port = await device.create();
    if (await (_port!.open()) != true) {
      setState(() {
        _status = "Failed to open port";
      });
      return false;
    }
    _device = device;

    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    _transaction = Transaction.stringTerminated(
        _port!.inputStream as Stream<Uint8List>, Uint8List.fromList([13, 10]));

    _transaction?.stream.listen((String data) {
      if (i < 6) {
        _input[i] = data;
        i = i + 1;
      }
      if (i == 6) {
        i = 0;
      }
      // overwriting the array with the incoming arduino string data.
      // the serial output of arduino is in this order: Speed, Throttle%, Battery%, fault number, power, Gear selection
    });

    _subscription = _transaction!.stream.listen((String line) {
      setState(() {
        _serialData.add(Text(line));
        if (_serialData.length > 20) {
          _serialData.removeAt(0);
        }
      });
    });

    setState(() {
      _status = "Connected";
    });
    return true;
  }

  void _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (!devices.contains(_device)) {
      _connectTo(null);
    }

    //print(devices);

    devices.forEach((device) {
      _ports.add(ListTile(
          leading: const Icon(Icons.usb),
          title: Text(device.productName!),
          //subtitle: Text(device.manufacturerName!),
          trailing: ElevatedButton(
            child: Text(_device == device ? "Disconnect" : "Connect"),
            onPressed: () {
              _connectTo(_device == device ? null : device).then((res) {
                _getPorts();
              });
            },
          )));
    });

    // setState(() {
    //   print(_ports);
    // });
  }

  @override
  void initState() {
    super.initState();

    UsbSerial.usbEventStream!.listen((UsbEvent event) {
      _getPorts();
    });

    _getPorts();
  }

  @override
  void dispose() {
    super.dispose();
    _connectTo(null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      backgroundColor: const Color.fromARGB(41, 11, 39, 43),
      appBar: AppBar(
        toolbarHeight: 25,
        title: const Text('Damos'),
        backgroundColor: Colors.black,
      ),
      body: Center(
          child: Column(children: <Widget>[
        Text(
            _ports.isNotEmpty
                ? "Available Serial Ports"
                : "No serial devices available",
            style: Theme.of(context).textTheme.headline6),
        ..._ports,

        Row(children: <Widget>[
          Text("${_input[0]} "),
          Text("${_input[1]} "),
          Text("${_input[2]} "),
          Text("${_input[3]} "),
          Text("${_input[4]} "),
          Text("${_input[5]} "),
        ]),
        //demonstrating the data inputs on the screen, top left.

        Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <
            Widget>[
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                SfRadialGauge(axes: <RadialAxis>[
                  RadialAxis(
                      minimum: 0,
                      maximum: 160,
                      axisLabelStyle: const GaugeTextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      majorTickStyle: const MajorTickStyle(
                          length: 0.05,
                          lengthUnit: GaugeSizeUnit.factor,
                          thickness: 2,
                          color: Colors.red),
                      ranges: <GaugeRange>[
                        GaugeRange(
                            startValue: 0,
                            endValue: double.parse(_input[4]),
                            color: double.parse(_input[4]) < 100.0
                                ? Colors.green
                                : Colors.red),
                        GaugeRange(
                            startValue: double.parse(_input[4]),
                            endValue: 160,
                            color: const Color.fromARGB(78, 175, 180, 102))
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(
                            knobStyle: const KnobStyle(
                                color: Color.fromARGB(248, 169, 175, 83)),
                            needleColor:
                                const Color.fromARGB(232, 169, 175, 83),
                            value: double.parse(_input[4]))
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                            widget: Text("${_input[4]}Kw",
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold)),
                            angle: 90,
                            positionFactor: 0.5),
                      ])
                ]),
                Column(children: <Widget>[
                  Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                          // shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                          image: const DecorationImage(
                            fit: BoxFit.fill,
                            image: AssetImage('1_5-aoK8IBmXve5whBQM90GA.png'),
                          ))),
                  Text(_input[5],
                      style: const TextStyle(
                          color: Color.fromARGB(255, 7, 236, 15),
                          fontSize: 50,
                          fontWeight: FontWeight.bold)),
                  Row(children: const <Widget>[
                    Icon(
                      Icons.arrow_circle_left,
                      color: Color.fromARGB(78, 175, 180, 102),
                      size: 35.0,
                    ),
                    Icon(
                      Icons.arrow_circle_right,
                      color: Color.fromARGB(78, 175, 180, 102),
                      size: 35.0,
                    ),
                  ]),
                ]),
                SfRadialGauge(axes: <RadialAxis>[
                  RadialAxis(
                      minimum: 0,
                      maximum: 200,
                      axisLabelStyle: const GaugeTextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      majorTickStyle: const MajorTickStyle(
                          length: 0.05,
                          lengthUnit: GaugeSizeUnit.factor,
                          thickness: 2,
                          color: Colors.red),
                      ranges: <GaugeRange>[
                        GaugeRange(
                            startValue: 0,
                            endValue: double.parse(_input[0]),
                            color: Colors.green),
                        //GaugeRange(startValue: 20, endValue: 80, color: Colors.orange),
                        GaugeRange(
                            startValue: double.parse(_input[0]),
                            endValue: 200,
                            color: const Color.fromARGB(78, 175, 180, 102))
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(
                            knobStyle: const KnobStyle(
                                color: Color.fromARGB(248, 169, 175, 83)),
                            needleColor:
                                const Color.fromARGB(232, 169, 175, 83),
                            value: double.parse(_input[0]))
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                            widget: Text("${_input[0]}Km/h",
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold)),
                            angle: 90,
                            positionFactor: 0.5)
                      ])
                ]),
              ]),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(children: <Widget>[
                  Container(
                      alignment: Alignment.center,
                      //color: const Color.fromARGB(255, 135, 243, 11),
                      height: 45,
                      width: 200,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(78, 175, 180, 102),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Container(
                          alignment: Alignment.centerLeft,
                          //color: const Color.fromARGB(255, 135, 243, 11),
                          height: 40,
                          width: 198,
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(223, 9, 12, 31),
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Container(
                            alignment: Alignment.centerLeft,
                            //color: const Color.fromARGB(255, 135, 243, 11),
                            height: 39.5,
                            width: (double.parse(_input[2]) * 200) / 100,
                            decoration: BoxDecoration(
                                color: double.parse(_input[2]) >= 20.0
                                    ? const Color.fromARGB(255, 7, 236, 15)
                                    : const Color.fromARGB(255, 241, 78, 49),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(20))),
                          ))),
                  Text(
                    'Battery ${_input[2]}%',
                    style: const TextStyle(
                      fontSize: 25,
                      // fontWeight: FontWeight.bold,
                      color: Color.fromARGB(137, 175, 180, 102),
                    ),
                  ),
                ]),
                Text(
                    style: TextStyle(
                        color: Color.fromARGB(137, 175, 180, 102),
                        fontSize: 25,
                        fontWeight: FontWeight.bold),
                    "Faults")
              ]),
        ]),

        // SfLinearGauge
      ])),
    ));
  }
}
// Speed, %Throt, %SOC, fault, DCcurrent
