# Como trabalhamos

Guia rápido do trio. Prazo final: **19/11/2026, até 23h55**, pelo portal da FIAP.

## Cronograma

| Dia | Meta |
|---|---|
| **17/11 (ter)** | Território escolhido · camada de dados (API + sintéticos + cache) · 3 dashboards com gráficos |
| **18/11 (qua)** | Motor de alertas e telas de alerta · formulário com validação · uso sem conexão · indicador de benefício social |
| **19/11 (qui)** | Revisão de acessibilidade · testes · prints e README · vídeo · APK em Releases · **tornar o repositório público** · envio do .txt **até 22h**, com folga |

> O repositório fica privado até o dia da entrega, para que nenhum outro grupo copie o código: plágio zera a nota dos dois grupos. **Repositório privado na hora da correção também zera**, então torná-lo público é obrigatório antes do envio: `gh repo edit --visibility public --accept-visibility-change-consequences`.

## Frentes de trabalho

| Frente | O que entra | Responsável |
|---|---|---|
| Dados | Repositórios, API real (Open-Meteo) e dados sintéticos, cache offline | _a definir_ |
| Dashboards | Os 3 painéis com `fl_chart`: histórico, tendência, cards | _a definir_ |
| Alertas | Regras e previsões, nível de confiança, limitações, telas, testes unitários | _a definir_ |
| Formulário e persistência | Relatar ocorrência, limiares de alerta, gravação local | _a definir_ |
| Entrega | README, prints, vídeo, APK, arquivo .txt | todos |

## Fluxo no git

1. `main` precisa rodar **sempre**. Nada quebrado entra nela.
2. Uma branch por tarefa: `git switch -c feat/painel-clima`.
3. Commits pequenos, com mensagem em português no imperativo, dizendo o quê e por quê:
   `Adiciona gráfico de chuva acumulada ao painel de clima`.
4. Antes de subir: `git pull --rebase origin main`.
5. Abra um Pull Request. Outro integrante revisa e faz o merge.
6. **Cada um commita com a própria conta.** A avaliação olha os commits ao longo do desenvolvimento.

## Antes de cada commit

```bash
dart format .
flutter analyze   # zero problemas
flutter test
```

## Regras do projeto (vêm direto do critério de avaliação)

- **Navegação:** sempre `context.goNamed(AppRoutes.x, pathParameters: {...})`. Nunca caminho escrito à mão.
- **Visual:** cores do `Theme.of(context).colorScheme` ou `context.severity`; espaçamentos de `AppSpacing`. Nada de `Color(0x...)` ou números soltos nas telas.
- **Estados:** dados assíncronos passam por `AsyncValueView` (carregamento, erro e vazio).
- **Alertas:** todo alerta tem evidência, nível de confiança, limitações e o `HumanDecisionBanner`. O app **nunca** executa uma ação sozinho: só sugere.
- **Acessibilidade:** botão só com ícone leva `tooltip`; severidade sempre com ícone e texto, não só com cor; testar com a fonte em 160% (Ajustes).
- **Privacidade:** nenhum campo de nome, CPF, e-mail ou telefone; localização no máximo por bairro.
- **Limpeza:** sem `print`, sem código comentado, sem imports sem uso. Os `TODO` do esqueleto somem até a entrega.
- **Segredos:** chave de API só em `env.json`, que está no `.gitignore`.
