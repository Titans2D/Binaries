# ThunderLeagueCompetitionFormat

Nas competições de futebol 2D é necessário enviar apenas o **binário** do nosso time
(executáveis do jogador e do coach) junto com as dependências mínimas de runtime
(formações, `data/`, lib, logo). Os `.cpp` ficam no repositório `ThunderLeague`; aqui
guardamos só o resultado da compilação no formato que os organizadores esperam.

> **A partir de setembro/2026 o time foi migrado para a base `cyrus-soccer-simulation-team`.**
> Isso muda o que precisa ser copiado para cá — em especial a pasta `data/` (nova e
> obrigatória) e a fork da `librcsc` utilizada.

## Layout do pacote (flat)

Tudo fica na raiz do repositório (não há mais a pasta `src/`):

```
start                 # launcher chamado pelos organizadores: ./start <host> <basedir> <num>
kill                  # encerra os processos thunder_player / thunder_coach
start.sh              # launcher local para testes (sobe 11 jogadores + coach)
team.yml              # metadados do time (country)
thunder_player        # executável dos jogadores
thunder_coach         # executável do online coach
player.conf
coach.conf
thunder_logo.xpm      # team graphic
formations-dt/        # formações no formato Helios-DT (F433_*, F523_*, Fhel_*)
data/                 # settings/*.json, settings/teams.conf, deep/*  (obrigatório!)
lib/                  # librcsc da fork Cyrus2D (librcsc.so.18*)
```

## Como atualizar o repo

Os caminhos de origem abaixo assumem uma build feita a partir do repositório
`ThunderLeague` na branch migrada, com a `librcsc` da Cyrus2D instalada em
`~/local/cyruslib` (ver README do `ThunderLeague`):

```sh
cd ~/Documents/Thunder/ThunderLeague
rm -rf build && mkdir build && cd build
cmake .. -DLIBRCSC_LIB=$HOME/local/cyruslib/lib/librcsc.so \
         -DLIBRCSC_INCLUDE_DIR=$HOME/local/cyruslib/include
make -j$(nproc)
```

Isso gera tudo em `build/src/`. Depois, na raiz deste repositório:

1. **Executáveis** — sempre que o código principal mudar:
   ```sh
   cp <ThunderLeague>/build/src/thunder_player .
   cp <ThunderLeague>/build/src/thunder_coach  .
   ```
   Os nomes `thunder_player` / `thunder_coach` são fixados no `src/CMakeLists.txt` do
   `ThunderLeague`; se voltarem a ser `sample_*`, atualize também `start` e `kill`.

2. **`formations-dt/`** — sempre que as formações mudarem:
   ```sh
   rm -rf formations-dt && cp -r <ThunderLeague>/build/src/formations-dt .
   ```
   A base CYRUS usa este conjunto (Helios-DT), **não** as antigas famílias `433-/442-/343-`.

3. **`data/`** — sempre que os arquivos de `data/` mudarem (raro, mas obrigatório enviar):
   ```sh
   rm -rf data && cp -r <ThunderLeague>/build/src/data .
   ```
   Sem `data/deep/helios_golie_origin` o goleiro aborta o carregamento da rede e o time
   joga em **modo degradado silencioso** (partida roda, mas placar/comportamento anormais).
   `data/settings/teams.conf` + `*.json` são o scouting por adversário.

4. **`player.conf` / `coach.conf`** — vêm de `build/src/`, com **`team_name : ThunderLeague`**
   (a base ship com `CYRUS`). O campo `version` acompanha a versão do protocolo do
   rcssserver (hoje `18`).

5. **`lib/`** — sempre que a versão da `librcsc` mudar. Usar a fork **Cyrus2D**
   (`~/local/cyruslib/lib`), **não** a de `/usr/local/lib`:
   ```sh
   rm -f lib/*
   cp $HOME/local/cyruslib/lib/librcsc.so.18.0.0 lib/
   ln -s librcsc.so.18.0.0 lib/librcsc.so.18
   ln -s librcsc.so.18     lib/librcsc.so
   ```
   A fork Cyrus2D (buildada por CMake) **não gera `librcsc.la`** — não é necessário em
   runtime com `LD_LIBRARY_PATH`.

6. **`thunder_logo.xpm`** — só muda se trocarmos o brasão. `start`/`start.sh` passam
   `--team_graphic_file thunder_logo.xpm`.

## Verificação antes de enviar

Testar **a partir de uma cópia limpa** do pacote (não da árvore de build), para pegar
dependência faltando:

```sh
tmp=$(mktemp -d) && git archive HEAD | tar -x -C "$tmp" && cd "$tmp"

# 1. o binário só pode depender de libs de sistema + da librcsc embarcada
LD_LIBRARY_PATH=./lib ldd thunder_player | grep -v '/lib/x86_64-linux-gnu\|linux-vdso\|ld-linux'
#    -> deve mostrar só ./lib/librcsc.so.18

# 2. partida completa contra o rcssserver, conferindo no rcssmonitor
rcssserver &
./start localhost "$tmp" 1
for n in $(seq 2 11); do ./start localhost "$tmp" $n; done
./start localhost "$tmp" 12
#    -> confirmar nos logs que ./data/deep/helios_golie_origin carregou (goleiro)

# 3. pênaltis
rcssserver server::nr_normal_halfs 0 server::nr_extra_halfs 0
```

Outras boas práticas:
- usar a mesma versão de `rcssserver`/`rcssmonitor` da competição;
- rodar em uma máquina/container **sem** `librcsc` de sistema, para provar que o bundle
  é auto-contido;
- olhar uma partida inteira no monitor procurando comportamento anormal.
