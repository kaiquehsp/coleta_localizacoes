# Coleta de Localizações

Aplicativo Flutter para Android que coleta a localização do aparelho, salva as posições em um banco SQLite local e as apresenta em uma lista e em um mapa interativo.

Atividade 1 da disciplina **Programação para Dispositivos Móveis I** — Prof. Arley.

## Integrantes

- Kaique Henrique
- Matheus Soldesi

## Funcionalidades

### Coleta de localização

- Botões **Iniciar coleta**, **Parar coleta**, **Consultar histórico**, **Ver mapa** e **Configurações de permissão**.
- Verifica se o serviço de localização está ativo e solicita a permissão quando necessário.
- Orienta o usuário quando a permissão é negada ou precisa ser habilitada nas configurações.
- Recebe as posições por um stream, com alta precisão e intervalo solicitado de 20 segundos.
- Mantém um serviço em primeiro plano, com notificação visível, enquanto a coleta está ativa.
- Continua coletando ao navegar entre as telas e ao minimizar o aplicativo.
- Salva cada posição recebida, evitando assinaturas duplicadas e gravações sobrepostas.
- Habilita os botões de iniciar e parar conforme o estado da coleta.

### Histórico

- Mostra as últimas 100 localizações, da mais recente para a mais antiga.
- Exibe data e hora locais, latitude e longitude com seis casas decimais e precisão em metros com uma casa decimal.
- Permite atualizar a lista sem interromper a coleta.
- Permite limpar todo o histórico, inclusive os registros anteriores aos 100 exibidos, após uma confirmação.

### Mapa interativo

- Mostra as últimas 100 posições como marcadores sobre um mapa de ruas do OpenStreetMap.
- Destaca a localização mais recente em vermelho.
- Enquadra os pontos ao carregar os dados e tem um botão para enquadrá-los novamente.
- Tem um botão para atualizar os registros.
- Mostra os dados de uma localização ao tocar em seu marcador.
- Trata os estados de carregamento, erro e histórico vazio.

### Persistência

Os dados ficam no banco local `localizacoes.db`, na tabela `localizacoes`, e permanecem disponíveis após fechar e reabrir o aplicativo.

| Coluna      | Tipo    | Descrição                                   |
| ----------- | ------- | ------------------------------------------- |
| `id`        | INTEGER | Chave primária com autoincremento           |
| `latitude`  | REAL    | Obrigatória                                 |
| `longitude` | REAL    | Obrigatória                                 |
| `precisao`  | REAL    | Obrigatória, em metros                      |
| `instante`  | TEXT    | Obrigatória, em UTC no formato ISO 8601     |

O limite de 100 registros vale apenas para as consultas: registros antigos não são excluídos automaticamente.

### Ícone

O aplicativo tem um ícone próprio, com a imagem original em `assets/icons/localizacoes.png` e os recursos do Android, incluindo o ícone adaptativo, em `android/app/src/main/res/`.

## Como executar

Pré-requisitos: Flutter SDK e um aparelho ou emulador Android com localização.

```bash
flutter pub get
flutter analyze
flutter run
```

## Estrutura do projeto

```text
lib/
├── main.dart                                # Inicializa o Flutter
├── app.dart                                 # MaterialApp e tela inicial
└── features/localizacoes/
    ├── models/localizacao.dart              # Registro tipado e conversão de mapas
    ├── data/
    │   ├── database/banco_localizacoes.dart # Abertura do banco e criação da tabela
    │   └── repositories/
    │       └── repositorio_localizacoes.dart # Inserir, consultar e excluir
    ├── services/
    │   ├── servico_localizacao.dart         # GPS, permissões e stream de posições
    │   └── cache_mapa.dart                  # Cache das imagens do mapa
    └── presentation/
        ├── screens/
        │   ├── tela_coleta.dart             # Controles e assinatura do stream
        │   ├── tela_localizacoes.dart       # Histórico
        │   └── tela_mapa.dart               # Carregamento e estados do mapa
        └── widgets/
            ├── item_localizacao.dart        # Dados de uma localização
            └── mapa_localizacoes.dart       # Ruas, marcadores e interações
```

## Observações

- **Plataforma:** o projeto é configurado apenas para Android.
- **Privacidade:** as posições ficam somente no aparelho. Não há banco remoto nem backend, e arquivos de banco são ignorados pelo Git.
- **Mapa:** os dados são do [OpenStreetMap](https://www.openstreetmap.org/copyright). O aplicativo exibe a atribuição, identifica-se nas requisições e mantém as imagens em cache na pasta privada do aplicativo, conforme a [política de uso dos tiles](https://operations.osmfoundation.org/policies/tiles/).
- **Intervalo:** os 20 segundos são um valor solicitado e podem variar conforme o sistema operacional e a disponibilidade de localização.
- **Encerramento:** a coleta não é reiniciada automaticamente após o encerramento do processo ou a reinicialização do aparelho.
