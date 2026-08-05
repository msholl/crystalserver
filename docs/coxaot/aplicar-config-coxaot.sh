#!/bin/bash
# Aplica no config.lua as decisoes do CoxaOT Global.
#
# POR QUE ESTE ARQUIVO EXISTE: o config.lua e' gitignored (.gitignore:371),
# porque carrega a senha do MySQL. Sem isto, toda a configuracao do servidor
# viveria apenas na VPS e nos backups -- e uma reinstalacao do zero perderia
# todas as decisoes abaixo.
#
# NAO contem segredo: host/usuario/senha do banco continuam vindo do
# docker/.env, aplicados pelo docker/config.sh no primeiro boot.
#
# Uso:  ./docs/coxaot/aplicar-config-coxaot.sh /opt/crystalserver/config.lua
set -euo pipefail

LUA="${1:-config.lua}"
[ -f "$LUA" ] || { echo "nao encontrei $LUA (o primeiro boot gera a partir do .dist)"; exit 1; }

set_lua() {
	local key="$1" value="$2"
	if ! grep -qE "^${key} = " "$LUA"; then
		echo "  ! chave '${key}' nao existe no config.lua -- upstream mudou?" >&2
		return 1
	fi
	sed -i "s|^${key} = .*|${key} = ${value}|" "$LUA"
	echo "  ${key} = ${value}"
}

echo "Identidade"
set_lua ip                '"188.220.168.161"'
set_lua serverName        '"CoxaOT Global"'
set_lua serverMotd        '"Bem-vindo ao CoxaOT Global!"'
set_lua ownerName         '"CoxaOT"'
set_lua ownerEmail        '"matheus@conecta-soft.com.br"'
set_lua location          '"Brazil"'

echo "Rates (as faixas em si ficam em data/stages.lua, versionado)"
# rateUseStages = true e o que faz o data/stages.lua valer; os rate* abaixo
# sao so o fallback usado se ele for desligado.
set_lua rateUseStages     'true'
set_lua rateExp           '50'
set_lua rateSkill         '10'
set_lua rateMagic         '10'
set_lua rateLoot          '3'
set_lua bestiaryKillMultiplier '2'

echo "Premium e VIP"
# freePremium da acesso premium a todos; o VIP continua sendo so quem tem
# premdays, porque Player::isVip() (player.cpp) ignora o freePremium.
set_lua freePremium       'true'
set_lua vipSystemEnabled  'true'
set_lua vipBonusExp       '10'
set_lua vipKeepHouse      'false'
# prazo unico para todos, decisao do dono (o default do upstream e 30)
set_lua houseLoseAfterInactivity '10 -- days; 0 = never'

echo "Store"
# O SERVIDOR e quem diz ao cliente onde buscar os icones da Store: este valor
# chega pelo onStoreInit e o cliente o adota (game_store.lua). O default do
# upstream e http://127.0.0.1/, ou seja o localhost DO JOGADOR -- todos os
# icones dao 404 e viram "?" na interface.
set_lua coinImagesURL     '"https://global.coxaot.com/images/store/"'

echo
echo "pronto. reinicie o servidor para o config.lua ser relido."
echo
cat <<'NOTA'
Fora do config.lua, dois ajustes vivem no MyAAC (/var/www/myaac/config.local.php):

  $config['client_link'] = 'https://global.coxaot.com/download/CoxaOT-Crystal.zip';
      o default do MyAAC aponta para as releases do gameclient do zimbadev, que
      nem tem arquivo publicado para 15.25.

E os administradores do site sao por accounts.web_flags (FLAG_ADMIN = 1,
FLAG_SUPER_ADMIN = 2, em common.php), nao por accounts.type:

  UPDATE accounts SET web_flags = 3 WHERE email IN ('...');
NOTA
