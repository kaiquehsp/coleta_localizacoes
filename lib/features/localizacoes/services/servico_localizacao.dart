import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/localizacao.dart';

enum ResultadoVerificacao {
  permitido,
  servicoDesabilitado,
  permissaoNegada,
  permissaoNegadaPermanentemente,
}


class ServicoLocalizacao {
  static const Duration intervalo = Duration(seconds: 20);

  
  Future<ResultadoVerificacao> verificar() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return ResultadoVerificacao.servicoDesabilitado;
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    switch (permissao) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return ResultadoVerificacao.permitido;
      case LocationPermission.deniedForever:
        return ResultadoVerificacao.permissaoNegadaPermanentemente;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return ResultadoVerificacao.permissaoNegada;
    }
  }

  
  Future<bool> solicitarPermissaoNotificacao() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  
  Stream<Localizacao> posicoes() {
    final configuracao = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      intervalDuration: intervalo,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Coleta de localização ativa',
        notificationText: 'Suas posições estão sendo salvas neste aparelho.',
        notificationChannelName: 'Coleta de localização',
        notificationIcon: AndroidResource(
          name: 'ic_notificacao_localizacao',
          defType: 'drawable',
        ),
        enableWakeLock: true,
        setOngoing: true,
      ),
    );

    return Geolocator.getPositionStream(locationSettings: configuracao).map(
      (posicao) => Localizacao(
        latitude: posicao.latitude,
        longitude: posicao.longitude,
        precisao: posicao.accuracy,
        instante: posicao.timestamp.toUtc(),
      ),
    );
  }

  Future<bool> abrirConfiguracoesPermissao() => Geolocator.openAppSettings();

  Future<bool> abrirConfiguracoesLocalizacao() {
    return Geolocator.openLocationSettings();
  }
}
