import 'package:flutter/material.dart';

import '../../models/localizacao.dart';


class ItemLocalizacao extends StatelessWidget {
  const ItemLocalizacao({super.key, required this.localizacao});

  final Localizacao localizacao;

  static String _formatarInstante(DateTime instante) {
    final local = instante.toLocal();
    String doisDigitos(int valor) => valor.toString().padLeft(2, '0');
    return '${doisDigitos(local.day)}/${doisDigitos(local.month)}/${local.year} '
        '${doisDigitos(local.hour)}:${doisDigitos(local.minute)}:'
        '${doisDigitos(local.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.place),
      title: Text(_formatarInstante(localizacao.instante)),
      subtitle: Text(
        'Latitude: ${localizacao.latitude.toStringAsFixed(6)}\n'
        'Longitude: ${localizacao.longitude.toStringAsFixed(6)}\n'
        'Precisão: ${localizacao.precisao.toStringAsFixed(1)} m',
      ),
    );
  }
}
