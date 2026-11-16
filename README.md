<p align="center">
  <img src="assets/branding/banner.svg" alt="Mirante: inteligência territorial para decisões humanas" width="100%">
</p>

# Mirante

**Painel de inteligência territorial que antecipa problemas de clima, recursos e serviços públicos e mostra cada alerta com evidência, nível de confiança e limitações, para que a decisão final continue com uma pessoa.**

> Global Solution 2026.2 · Cross-Platform Application Development · Desafio *Territory Predictive Insights*

---

## Problema e público

> ✏️ **Rascunho:** ajustar quando o território for escolhido.

Ondas de calor, desperdício de água e energia e picos de demanda em serviços públicos costumam ser percebidos só quando já afetam a população. Os dados para antecipá-los existem, mas ficam espalhados e sem leitura clara de quanto se pode confiar neles.

- **Para quem:** gestores públicos (subprefeitura, secretarias) que decidem onde agir primeiro, e cidadãos que querem acompanhar o próprio território e relatar ocorrências.
- **Impacto esperado:** agir antes do problema, com prioridades baseadas em evidência e transparência sobre a incerteza. O impacto é medido por indicadores de benefício social exibidos no app.

## Integrantes

| Nome | RM |
|---|---|
| Leonardo Augusto | RM565564 |
| Pedro Gabriel | RM562242 |
| Alexandre Campão | RM563346 |

## Demonstração visual

> ✏️ **Pendente:** capturar as telas finais e salvar em `assets/screenshots/`. O enunciado penaliza README sem prints de **todas** as telas.

| Tela | Arquivo |
|---|---|
| Consentimento | `assets/screenshots/01-consentimento.png` |
| Visão geral | `assets/screenshots/02-visao-geral.png` |
| Dashboard: clima local | `assets/screenshots/03-painel-clima.png` |
| Dashboard: água e energia | `assets/screenshots/04-painel-recursos.png` |
| Dashboard: serviços públicos | `assets/screenshots/05-painel-servicos.png` |
| Detalhe do indicador | `assets/screenshots/06-indicador.png` |
| Lista de alertas | `assets/screenshots/07-alertas.png` |
| Detalhe do alerta | `assets/screenshots/08-alerta.png` |
| Relatar ocorrência | `assets/screenshots/09-relatar.png` |
| Ajustes | `assets/screenshots/10-ajustes.png` |

## Funcionalidades

- [x] Navegação com rotas nomeadas, parâmetros e quatro abas com estado preservado
- [x] Consentimento explícito antes do primeiro uso, revogável em Ajustes (apaga os dados locais)
- [x] Estado global compartilhado entre telas (tema, contraste, fonte, consentimento)
- [x] Modo escuro, alto contraste e tamanho de texto ajustável
- [x] Componentes padrão de carregamento, erro e lista vazia
- [x] Aviso visível de que os alertas não substituem a decisão humana
- [ ] Três dashboards com gráficos, histórico e tendência
- [ ] Alertas gerados a partir dos dados, com evidência, confiança e limitações
- [ ] Consumo de API (real ou simulada) com cache para uso sem conexão
- [ ] Formulário de ocorrência com validação e gravação local
- [ ] Indicador de benefício social
- [ ] Testes unitários da lógica de alertas e validações

## Dados e alertas

> ✏️ **Pendente:** preencher conforme a implementação.

- **Fontes de dados:** quais são públicas, sintéticas ou autorizadas, com link e período.
- **Como os alertas são gerados:** regras e modelos usados em cada área.
- **Métricas:** como o nível de confiança é calculado e como o modelo foi avaliado.
- **Limitações e vieses:** o que os dados não capturam e quem pode ficar sub-representado.
- **Quando as previsões não são confiáveis:** poucos dados, eventos fora do histórico, falhas de coleta.

## Privacidade e inclusão

- **Consentimento:** tela obrigatória no primeiro uso, explicando quais dados são guardados e como. Pode ser revogado em Ajustes, o que apaga todos os dados do aparelho.
- **Anonimização:** ocorrências não pedem nome, CPF, e-mail nem telefone; a localização é guardada só no nível do bairro.
- **Dados locais:** registros e preferências ficam no aparelho.
- **Acessibilidade:** modo escuro, alto contraste, tamanho de texto ajustável (somado ao do sistema), áreas de toque de 48 px, rótulos para leitores de tela e severidade dos alertas sempre com ícone e texto, nunca só com cor.

## Tecnologias e decisões técnicas

| Tecnologia | Por que escolhemos |
|---|---|
| **Flutter 3.47 / Dart 3.13** | Exigência da disciplina; um código para Android e iOS. |
| **go_router** | Rotas nomeadas com parâmetros (`/painel/:area`), abas que preservam o estado (`StatefulShellRoute`) e `redirect` para exigir o consentimento. |
| **flutter_riverpod** | Separa o estado global (providers) do local (`setState` em formulários). `AsyncValue` padroniza carregamento e erro, e os providers são fáceis de testar. |
| **shared_preferences** | Preferências, consentimento e cache: pouco volume de dados, sem geração de código. |
| **http** | Cliente HTTP simples e oficial do Dart para consumir APIs. |
| **fl_chart** | Gráficos de linha e barra que aceitam as cores do tema. |
| **intl / flutter_localizations** | Datas, números e componentes em pt-BR. |

**Arquitetura** (organizada por funcionalidade):

```text
lib/
├── main.dart                  # inicializa preferências e o ProviderScope
├── app.dart                   # MaterialApp: tema, rotas, escala de fonte
├── core/
│   ├── config/                # território analisado
│   ├── domain/                # modelos compartilhados (áreas do território)
│   ├── router/                # rotas nomeadas e barra de abas
│   ├── storage/               # acesso ao armazenamento local
│   └── theme/                 # cores, espaçamentos e temas
├── shared/widgets/            # componentes reutilizáveis
└── features/<funcionalidade>/
    ├── data/                  # fontes de dados e repositórios
    ├── application/           # providers e regras de estado
    └── presentation/          # telas e widgets da funcionalidade
```

## Como executar

**Pré-requisitos:** Flutter 3.47 ou superior e um emulador Android ou aparelho com depuração USB.

```bash
git clone https://github.com/LeonardoAugustoBacelar/GS-CrossPlatform-2026-2.git
cd GS-CrossPlatform-2026-2
flutter pub get
flutter run
```

**Variáveis de ambiente:** a versão atual não precisa de chaves. Se alguma for adicionada, ela fica em `env.json` (fora do git) e entra no app com `flutter run --dart-define-from-file=env.json`.

**Qualidade:**

```bash
flutter analyze   # deve terminar sem problemas
flutter test
```

**APK de release:** `flutter build apk --release` gera `build/app/outputs/flutter-apk/app-release.apk`.

## Vídeo

> ✏️ **Pendente:** link do vídeo de demonstração (até 3 minutos).

## Licença

Projeto acadêmico · FIAP · Global Solution 2026.2.
