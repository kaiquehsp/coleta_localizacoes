import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


class CacheMapa {
  static const int _tamanhoMaximo = 200 * 1024 * 1024; 

  Future<MapCachingProvider> preparar() async {
    final pasta = await getApplicationCacheDirectory();
    return BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: join(pasta.path, 'mapa'),
      maxCacheSize: _tamanhoMaximo,
    );
  }
}
