import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

enum ServerStatus { online, offline, connecting }

class SocketService with ChangeNotifier {
  ServerStatus _serverStatus = ServerStatus.connecting;
  late Socket _socket;
  ServerStatus get serverStatus => _serverStatus;
  Socket get socket => _socket;

  SocketService() {
    _initConfig();
  }

  void _initConfig() {
    _socket = io(
        'http://192.168.0.150:3001/',
        OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build());

    _socket.onConnect((_) {
      _serverStatus = ServerStatus.online;
      notifyListeners();
    });

    _socket.onDisconnect((_) {
      _serverStatus = ServerStatus.offline;
      notifyListeners();
    });

    _socket.on('nuevo-mensaje', (payload) {
      print('Nuevo-mensaje: $payload');
    });
  }
}
