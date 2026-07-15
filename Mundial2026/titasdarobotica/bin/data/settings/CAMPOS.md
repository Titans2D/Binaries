# Campos dos JSONs de settings

Este arquivo documenta os JSONs em `src/data/settings`: para que serve cada bloco/campo
e em quais partes do codigo eles sao carregados ou usados.

Os arquivos `alice.json`, `fra.json`, `hel.json`, `Other.json`, `oxsy.json` e `yush.json`
seguem quase a mesma estrutura. `Help.json` parece ser apenas um exemplo resumido.

## Fluxo de carregamento

- `src/sample_player.cpp:353`: chama `Setting::i()->SetTeamName(...)` usando o nome do time adversario.
- `src/setting.cpp:316`: `Setting::SetTeamName` le `./data/settings/teams.conf`.
- `src/setting.cpp:327`: preenche o mapa `mTeamsConfig` com `time adversario -> arquivo json`.
- `src/setting.cpp:329`: se o adversario estiver no mapa, troca `mJsonPath` para o JSON configurado.
- `src/setting.cpp:334`: `Setting::ReadJson` abre o JSON escolhido.
- `src/setting.cpp:344`: carrega o bloco `Strategy`.
- `src/setting.cpp:348`: carrega o bloco `ChainAction`.
- `src/setting.cpp:352`: carrega o bloco `Neck`.
- `src/setting.cpp:356`: carrega o bloco `OffensiveMove`.
- `src/setting.cpp:360`: carrega o bloco `DefenseMove`.
- `src/setting.h:150`: define valores padrao para todos os blocos antes de qualquer JSON ser carregado.

`teams.conf` nao configura comportamento diretamente. Ele apenas decide qual JSON sera usado para cada adversario. Se o adversario nao estiver listado, o padrao em `src/setting.h:165` e `./data/settings/Other.json`.

## Strategy

Campos carregados em `src/setting.cpp:103`.

| Campo | Para que serve | Onde e usado |
| --- | --- | --- |
| `Formation` | Escolhe o tipo de formacao. Valores vistos: `433` e `HeliosFra`. | `src/strategy.cpp:954` converte para `FormationType`; `src/strategy.cpp:956` escolhe `updateFormationFra`; `src/strategy.cpp:960` escolhe `updateFormation433`; tambem influencia logicas ofensivas em `src/move_off/bhv_offensive_move.cpp:68` e `src/move_off/bhv_scape.cpp:82`. |
| `TeamTactic` | Escolhe a tatica geral do time. Hoje o codigo mapeia `Normal` para a tatica normal. | `src/strategy.cpp:953` chama `stringToTeamTactic`; `src/strategy.h:292` faz o mapeamento. |
| `MoveBeforeSetPlay` | Permite movimentacao antes de certas bolas paradas. | `src/setplay/bhv_set_play_free_kick.cpp:76`, `:141`, `:434`; `src/setplay/bhv_set_play_kick_in.cpp:80`, `:137`, `:435`. |

## ChainAction

Campos carregados em `src/setting.cpp:7`. Este bloco controla busca, avaliacao e geracao de acoes com bola.

| Campo | Para que serve | Onde e usado |
| --- | --- | --- |
| `ChainNodeNumber` | Limite de nos/estados avaliados na busca da cadeia de acoes. | `src/chain_action/action_chain_graph.cpp:132`, em `M_max_evaluate_limit`. |
| `ChainDeph` | Profundidade maxima da cadeia de acoes. O nome esta escrito assim no codigo. | `src/chain_action/action_chain_graph.cpp:131`, em `M_max_chain_length`. |
| `UseShootSafe` | Ativa criterios mais seguros na geracao/avaliacao de chute. | `src/chain_action/shoot_generator.cpp:735`. |
| `DribblePosCountLow` | Fator da avaliacao de drible para baixa pressao/contagem de posicoes. | `src/chain_action/short_dribble_generator.cpp:1155`. |
| `DribblePosCountHigh` | Fator da avaliacao de drible para alta pressao/contagem de posicoes. | `src/chain_action/short_dribble_generator.cpp:1156`. |
| `DribbleAlwaysDanger` | Define se dribles devem sempre passar pela avaliacao de perigo. | `src/chain_action/short_dribble_generator.cpp:1239`. |
| `DribbleAlwaysDangerExceptPrioritiseDribble` | Excecao para nao forcar perigo quando o drible esta priorizado. | `src/chain_action/short_dribble_generator.cpp:1243`. |
| `DribbleBallCollisionNoise` | Margem extra usada em checagens de colisao da bola no drible. | `src/chain_action/short_dribble_generator.cpp:441` e `:916`. |
| `DribbleUseDoubleKick` | Permite ou bloqueia geracao de dribles com double kick. | `src/chain_action/short_dribble_generator.cpp:514` e `:677`. Observacao: em `src/setting.cpp:39` o codigo checa `DribbleBallCollisionNoise` antes de ler `DribbleUseDoubleKick`, o que parece um erro de guarda. |
| `DribblePosCountMaxFrontOpp` | Limite de adversarios/posicoes a frente considerados no custo do drible. | `src/chain_action/short_dribble_generator.cpp:1153`. |
| `DribblePosCountMaxBehindOpp` | Limite de adversarios/posicoes atras considerados no custo do drible. | `src/chain_action/short_dribble_generator.cpp:1154`. |
| `DangerEvalBack` | Tabela de penalidade/perigo quando a bola esta no campo defensivo. | `src/chain_action/action_chain_graph.cpp:716`. |
| `DangerEvalMid` | Tabela de penalidade/perigo quando a bola esta no meio. | `src/chain_action/action_chain_graph.cpp:718`. |
| `DangerEvalForward` | Tabela de penalidade/perigo para campo ofensivo fora da area central de finalizacao. | `src/chain_action/action_chain_graph.cpp:722`. |
| `DangerEvalPenalty` | Tabela de penalidade/perigo para alvos perto da area/gol adversario. | `src/chain_action/action_chain_graph.cpp:720`. |
| `SlowPass` | Altera a geracao de passes para considerar passes lentos. | `src/chain_action/strict_check_pass_generator.cpp:1226`, `:1315`, `:1475`. |
| `TryFindOneKickPassOppClose` | Tenta encontrar passe de primeira quando ha adversario proximo. | `src/chain_action/strict_check_pass_generator.cpp:1224`. |

As tabelas `DangerEval*` sao usadas em `calc_danger_eval_for_target` (`src/chain_action/action_chain_graph.cpp:704` em diante). O codigo escolhe a tabela conforme a posicao da bola/alvo e usa a distancia do adversario mais proximo ao alvo como indice aproximado.

## Neck

Campos carregados em `src/setting.cpp:116`. Este bloco controla a decisao de visao/pescoco e o preditor de proximo passe.

| Campo | Para que serve | Onde e usado |
| --- | --- | --- |
| `PredictionDNNPath` | Caminho do arquivo de rede neural para predicao de passe. | `src/neck/next_pass_predictor.cpp:17`, em `ReadFromKeras`. |
| `UsePredictionDNN` | Liga/desliga o uso do preditor DNN. | `src/neck/neck_decision.cpp:85`, em `M_use_pass_predictor`. |
| `UsePPIfChain` | Permite usar preditor de passe mesmo quando a chain encontra passe. | `src/neck/neck_decision.cpp:86`. |
| `IgnoreChainPass` | Ignora alvo de passe vindo da chain para o preditor. | `src/neck/neck_decision.cpp:87`. |
| `IgnoreChainPassByDist` | Ignora alvo de passe da chain conforme criterio de distancia. | `src/neck/neck_decision.cpp:88`. |

## OffensiveMove

Campos carregados em `src/setting.cpp:130`. Este bloco controla desmarque e movimentacao ofensiva sem bola.

| Campo | Para que serve | Onde e usado |
| --- | --- | --- |
| `Is9BrokeOffside` | Permite comportamento especifico do jogador 9 para atacar/quebrar linha de impedimento, especialmente com `HeliosFra`. | `src/move_off/bhv_offensive_move.cpp:66`; `src/move_off/bhv_scape.cpp:81`. |
| `UnmarkingAlgorithms` | Lista de algoritmos de desmarque avaliados em ordem. Valores vistos: `main`, `2019`, `voronoi`. | `src/move_off/bhv_offensive_move.cpp:154`, iterando cada algoritmo. |
| `MainUnmarkPassPredictionDNN` | Caminho da DNN usada no desmarque principal para predicao de passe. | `src/move_off/bhv_unmark.cpp:813`, em `ReadFromKeras`. |
| `UseUnmarkPassPredictionDNN` | Liga/desliga a predicao por DNN no desmarque. | `src/move_off/bhv_unmark.cpp:669`. |
| `UseThPassSimInVoroScape` | Usa simulacao de through pass na avaliacao de pontos do Voronoi/scape. | `src/move_off/bhv_scape_voronoi.cpp:419`. |

## DefenseMove

Campos carregados em `src/setting.cpp:152`. Este bloco controla marcacao, bloqueio e selecao de adversarios ofensivos.

| Campo | Para que serve | Onde e usado |
| --- | --- | --- |
| `BackBlockMaxXToDefHPosX` | Limite em X entre alvo de bloqueio/adversario e linha/posicao defensiva. | `src/move_def/bhv_mark_decision_greedy.cpp:236`; `src/move_def/bhv_mark_execute.cpp:86`. |
| `BlockGoToOppPos` | Permite que o bloqueio mire diretamente a posicao do adversario. | `src/move_def/bhv_block.cpp:648`. |
| `GoToDefendX` | Ajusta execucao de marcacao para respeitar X defensivo. | `src/move_def/bhv_mark_execute.cpp:106`. |
| `FixThMarkY` | Ajusta/fixa o Y em execucoes de marcacao. | `src/move_def/bhv_mark_execute.cpp:546`. |
| `PassBlock` | Liga comportamento especifico de bloqueio de passe. | `src/move_def/bhv_block.cpp:641`. |
| `StartMidMark` | Limiar de X da bola para usar `MidMark` em vez de marcacao perto do gol. | `src/move_def/bhv_mark_decision_greedy.cpp:188`; tambem afeta execucao em `src/move_def/bhv_mark_execute.cpp:75`. |
| `StaticOffensiveOpp` | Lista inicial/fixa de adversarios tratados como ofensivos. | `src/move_def/bhv_mark_decision_greedy.cpp:206`; pode ser recalculada em `src/calculate_offensive_opponents.h:53`, `:87`, `:114`. |
| `BlockZ_CB_Next` | Peso de bloqueio para zagueiros centrais contra o proximo alvo/acao. | `src/move_def/bhv_block.cpp:356`. |
| `BlockZ_CB_Forward` | Peso de bloqueio para zagueiros centrais contra jogadores avancados. | `src/move_def/bhv_block.cpp:358`. |
| `BlockZ_LB_RB_Forward` | Peso de bloqueio para laterais contra jogadores avancados. | `src/move_def/bhv_block.cpp:363`. |
| `MidTh_PosFinderHPosXNegativeTerm` | Termo subtraido do X da home position ao calcular posicao de marcacao. | `src/move_def/mark_position_finder.cpp:91`. |
| `MidTh_PosFinderBackDistXPlusTerm` | Termo somado a distancia para tras no calculo de posicao de marcacao. | `src/move_def/mark_position_finder.cpp:148`. |
| `MidProj_HPosMaxDistBlock` | Limite de distancia ate home position para bloqueio quando ha projecao no meio. | `src/move_def/bhv_mark_decisions.cpp:624`. |

### DefenseMove: campos `MidTh_*`

Os campos `MidTh_*` sao usados principalmente em `src/move_def/bhv_mark_decisions.cpp` para selecionar candidatos e limites de marcacao/bloqueio no meio.

| Campo | Para que serve | Onde e usado |
| --- | --- | --- |
| `MidTh_BackInMark` | Permite adversarios de tras como candidatos a marcacao. | `src/move_def/bhv_mark_decisions.cpp:389`, `:402`. |
| `MidTh_BackInBlock` | Permite adversarios de tras como candidatos a bloqueio. | `src/move_def/bhv_mark_decisions.cpp:390`, `:398`. |
| `MidTh_HalfInMark` | Permite adversarios do meio como candidatos a marcacao. | `src/move_def/bhv_mark_decisions.cpp:408`, `:421`. |
| `MidTh_HalfInBlock` | Permite adversarios do meio como candidatos a bloqueio. | `src/move_def/bhv_mark_decisions.cpp:409`, `:417`. |
| `MidTh_ForwardInMark` | Permite adversarios avancados como candidatos a marcacao. | `src/move_def/bhv_mark_decisions.cpp:427`, `:440`. |
| `MidTh_ForwardInBlock` | Permite adversarios avancados como candidatos a bloqueio. | `src/move_def/bhv_mark_decisions.cpp:428`, `:436`. |
| `MidTh_RemoveNearOpps` | Remove/filtra adversarios candidatos que estejam muito proximos entre si. | `src/move_def/bhv_mark_decisions.cpp:67`. |
| `MidTh_DistanceNearOpps` | Distancia minima para considerar dois candidatos proximos. | `src/move_def/bhv_mark_decisions.cpp:502`. |
| `MidTh_XNearOpps` | Tolerancia em X usada no filtro de adversarios proximos. | `src/move_def/bhv_mark_decisions.cpp:485`. |
| `MidTh_PosDistZ` | Peso da distancia ate a posicao atual na avaliacao. | `src/move_def/bhv_mark_decisions.cpp:194`. |
| `MidTh_HPosDistZ` | Peso da distancia ate a home position na avaliacao. | `src/move_def/bhv_mark_decisions.cpp:193`. |
| `MidTh_PosMaxDistMark` | Distancia maxima ate a posicao atual para aceitar marcacao. | `src/move_def/bhv_mark_decisions.cpp:286` e ajustes em `:300`, `:305`, `:316`, `:321`. |
| `MidTh_HPosMaxDistMark` | Distancia maxima ate home position para aceitar marcacao. | `src/move_def/bhv_mark_decisions.cpp:285` e ajustes em `:299`, `:304`, `:315`, `:320`, `:331`. |
| `MidTh_HPosYMaxDistMark` | Diferenca maxima em Y ate home position para aceitar marcacao. | `src/move_def/bhv_mark_decisions.cpp:287` e ajustes em `:290`, `:301`, `:306`, `:317`, `:322`. |
| `MidTh_PosMaxDistBlock` | Distancia maxima ate a posicao atual para aceitar bloqueio. | `src/move_def/bhv_mark_decisions.cpp:254`. |
| `MidTh_HPosMaxDistBlock` | Distancia maxima ate home position para aceitar bloqueio. | `src/move_def/bhv_mark_decisions.cpp:253`, com ajustes em `:258`, `:262`. |
| `MidTh_HPosYMaxDistBlock` | Diferenca maxima em Y ate home position para aceitar bloqueio. | `src/move_def/bhv_mark_decisions.cpp:255`. |

### DefenseMove: campos `MidNear_*`

Usados quando a logica de marcacao esta no modo `MidNear`, tambem em `src/move_def/bhv_mark_decisions.cpp`.

| Campo | Para que serve | Onde e usado |
| --- | --- | --- |
| `MidNear_StartX` | Limiar de X da bola para trocar entre logicas de marcacao. | `src/move_def/bhv_mark_decisions.cpp:76`. |
| `MidNear_BackInMark` | Permite adversarios de tras na marcacao `MidNear`. | `src/move_def/bhv_mark_decisions.cpp:708`, `:721`. |
| `MidNear_BackInBlock` | Permite adversarios de tras no bloqueio `MidNear`. | `src/move_def/bhv_mark_decisions.cpp:709`, `:717`. |
| `MidNear_HalfInMark` | Permite adversarios do meio na marcacao `MidNear`. | `src/move_def/bhv_mark_decisions.cpp:727`, `:740`. |
| `MidNear_HalfInBlock` | Permite adversarios do meio no bloqueio `MidNear`. | `src/move_def/bhv_mark_decisions.cpp:728`, `:736`. |
| `MidNear_ForwardInMark` | Permite adversarios avancados na marcacao `MidNear`. | `src/move_def/bhv_mark_decisions.cpp:746`, `:759`. |
| `MidNear_ForwardInBlock` | Permite adversarios avancados no bloqueio `MidNear`. | `src/move_def/bhv_mark_decisions.cpp:747`, `:755`. |
| `MidNear_OppsDistXToBall` | Filtro em X entre adversario e bola. | `src/move_def/bhv_mark_decisions.cpp:781`. |
| `MidNear_OppsDistXToHPos2X` | Filtro em X entre adversario e base/home position defensiva. | `src/move_def/bhv_mark_decisions.cpp:783`. |
| `MidNear_PosMaxDistMark` | Distancia maxima ate a posicao atual para aceitar marcacao. | `src/move_def/bhv_mark_decisions.cpp:610`. |
| `MidNear_HPosMaxDistMark` | Distancia maxima ate home position para aceitar marcacao. | `src/move_def/bhv_mark_decisions.cpp:609`. |
| `MidNear_PosMaxDistBlock` | Distancia maxima ate a posicao atual para aceitar bloqueio. | `src/move_def/bhv_mark_decisions.cpp:613`. |
| `MidNear_HPosMaxDistBlock` | Distancia maxima ate home position para aceitar bloqueio. | `src/move_def/bhv_mark_decisions.cpp:612`, com ajuste em `:618`. |

Observacao: em `src/setting.cpp:281` e `:287`, o carregamento repete `MidNear_HPosMaxDistBlock`, mas nao le `MidNear_HPosMaxDistMark` nem `MidNear_PosMaxDistBlock` nesses pontos. Os valores padrao desses campos ficam em `src/setting.h:134` e `:135`.

### DefenseMove: campos `Goal_*`

Usados na marcacao/bloqueio mais perto do proprio gol, principalmente em `src/move_def/bhv_mark_decisions.cpp`.

| Campo | Para que serve | Onde e usado |
| --- | --- | --- |
| `Goal_ForwardInMark` | Permite adversarios avancados na marcacao perto do gol. | `src/move_def/bhv_mark_decisions.cpp:903`, `:912`. |
| `Goal_ForwardInBlock` | Permite adversarios avancados no bloqueio perto do gol. | `src/move_def/bhv_mark_decisions.cpp:904`, `:908`. |
| `Goal_PosMaxDistMark` | Distancia maxima ate a posicao atual para aceitar marcacao perto do gol. | `src/move_def/bhv_mark_decisions.cpp:1048`, com ajuste em `:1093`. |
| `Goal_HPosMaxDistMark` | Distancia maxima ate home position para aceitar marcacao perto do gol. | `src/move_def/bhv_mark_decisions.cpp:1047`, com ajuste em `:1092`. |
| `Goal_OffsideMaxDistMark` | Distancia maxima ate a linha de impedimento para aceitar marcacao. | `src/move_def/bhv_mark_decisions.cpp:1049`, com ajuste em `:1094`. |
| `Goal_PosMaxDistBlock` | Distancia maxima ate a posicao atual para aceitar bloqueio perto do gol. | `src/move_def/bhv_mark_decisions.cpp:1053`, com ajuste em `:1057`. |
| `Goal_HPosMaxDistBlock` | Distancia maxima ate home position para aceitar bloqueio perto do gol. | `src/move_def/bhv_mark_decisions.cpp:1052`, com ajuste em `:1056`. |
| `Goal_OffsideMaxDistBlock` | Distancia maxima ate a linha de impedimento para aceitar bloqueio. | `src/move_def/bhv_mark_decisions.cpp:1054`, com ajuste em `:1058`. |

## Observacoes importantes

- `Help.json` usa `DeffenseMove`, mas o codigo le apenas `DefenseMove` em `src/setting.cpp:360`; portanto esse bloco de `Help.json` nao e aplicado como configuracao real.
- Campos ausentes usam os valores padrao definidos em `src/setting.h`.
- Os campos sao todos opcionais do ponto de vista do parser: cada leitura e protegida por `HasMember`.
- Alguns campos tem nomes com grafia herdada do codigo, como `ChainDeph`; alterar o nome no JSON sem alterar o codigo quebra o carregamento.
