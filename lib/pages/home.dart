import 'dart:io';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [
    Band(id: '1', name: 'Metallica', votes: 5),
    Band(id: '2', name: 'U2', votes: 10),
    Band(id: '3', name: 'Guns and Roses', votes: 15),
    Band(id: '4', name: 'Rammstein', votes: 20),
    Band(id: '5 ', name: 'Soda Stereo', votes: 25),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('activeBands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  //al destruir pantalla dejar de escuchar al socket y al evento
  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('activeBands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Band names',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 10.0),
            child: socketService.serverStatus == ServerStatus.online
                ? Icon(
                    Icons.check_circle,
                    color: Colors.blue[300],
                  )
                : const Icon(
                    Icons.offline_bolt,
                    color: Colors.red,
                  ),
          )
        ],
      ),
      body: Column(children: <Widget>[
        _showGraph(),
        Expanded(
            child: ListView.builder(
          itemCount: bands.length,
          itemBuilder: (context, i) => _bandTile(bands[i]),
        ))
      ]),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add), elevation: 1, onPressed: addNewBand),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        print('id: ${band.id}');
        socketService.socket.emit('delete-band', {'id': band.id});
      },
      background: Container(
        padding: const EdgeInsets.only(left: 8.0),
        color: Colors.red,
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Delete Band',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0, 2)),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(band.name),
        trailing: Text(
          '${band.votes}',
          style: const TextStyle(fontSize: 20),
        ),
        onTap: () {
          socketService.socket.emit('vote-band', {'id': band.id});
          print(band.name);
          print(band.id);
        },
      ),
    );
  }

  addNewBand() {
    final textController = TextEditingController();

    //Dialogo para mostrar solo en dispositivos Android
    if (Platform.isAndroid) {
      return showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('New band name'),
              content: TextField(
                controller: textController,
              ),
              actions: <Widget>[
                MaterialButton(
                    child: const Text('Add'),
                    textColor: Colors.blue,
                    elevation: 5,
                    onPressed: () => addBandToList(textController.text))
              ],
            );
          });
    }

//Dialogo para mostrar solo en dispositivos IoS
    showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: const Text('New band name'),
            content: CupertinoTextField(
              controller: textController,
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Add'),
                onPressed: () => addBandToList(textController.text),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Dissmis'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  void addBandToList(String name) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    if (name.length > 1) {
      socketService.socket.emit('add-band', {'name': name});
      print(name);
    }

    Navigator.pop(context);
  }

  Widget _showGraph() {
    Map<String, double> dataMap = {};
    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    return Container(
      padding: const EdgeInsets.only(top: 10.0),
      width: double.infinity,
      height: 200,
      child: PieChart(
        dataMap: dataMap,
        chartType: ChartType.ring,
        chartValuesOptions: const ChartValuesOptions(
            showChartValuesInPercentage: true, decimalPlaces: 0),
      ),
    );
  }
}
