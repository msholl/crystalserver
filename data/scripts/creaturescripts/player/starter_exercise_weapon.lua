-- Kit inicial (CoxaOT): o jogador escolhe UMA exercise weapon basica, de 500 cargas.
--
-- POR QUE VAI PARA A PURSE: a entrega usa player:addItemStoreInbox, a MESMA funcao
-- que a Store usa em GameStore.processChargesPurchase. Com "movable" nil o
-- addItemStoreInboxEx (data/libs/functions/player.lua:495) poe dono no item e grava
-- ITEM_ATTRIBUTE_STORE. A partir dai o motor barra o item em trade
-- (game.cpp:5198 e 5279) e impede tirar do inbox para o chao (game.cpp:2168/2181),
-- que era exatamente o pedido: o jogador usa no dummy, mas nao repassa para outro.
-- O destino e o CONST_SLOT_STORE_INBOX, que e o slot da purse.
--
-- POR QUE REAPARECE: a janela volta a cada login enquanto a escolha nao for feita.
-- Sem isso, quem fechasse a janela no primeiro login ficaria sem o item para sempre
-- (getLastLoginSaved() so vale zero uma vez).

local KV_ESCOLHA = "coxaot.exercise-inicial" -- nil = nunca ofertado | "pendente" | id escolhido
local CARGAS = 500

local opcoes = {
	28552, -- exercise sword
	28553, -- exercise axe
	28554, -- exercise club
	28555, -- exercise bow
	28556, -- exercise rod
	28557, -- exercise wand
	44065, -- exercise shield
	50293, -- exercise wraps
}

local function entregar(player, itemId)
	local iType = ItemType(itemId)
	local item = player:addItemStoreInbox(itemId, CARGAS)
	if not item then
		player:sendTextMessage(MESSAGE_LOOK, "Nao consegui entregar sua arma de treino. Tente de novo no proximo login.")
		return false
	end

	item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, string.format("Kit inicial de %s. Use em um exercise dummy para treinar.", configManager.getString(configKeys.SERVER_NAME)))
	player:kv():set(KV_ESCOLHA, itemId)
	player:sendTextMessage(MESSAGE_LOOK, string.format("Voce recebeu %s com %d cargas na sua purse. Use em um exercise dummy para treinar.", iType:getName(), CARGAS))
	return true
end

local function abrirEscolha(playerId)
	local player = Player(playerId)
	if not player or player:kv():get(KV_ESCOLHA) ~= "pendente" then
		return
	end

	local janela = ModalWindow({
		title = "Kit inicial",
		message = "Escolha sua arma de treino.\nEla vai para a sua purse e nao pode ser passada para outro jogador.",
	})

	for _, itemId in ipairs(opcoes) do
		local iType = ItemType(itemId)
		if iType then
			janela:addChoice(iType:getName(), function(chooser, button, choice)
				if button.name ~= "Escolher" then
					return true
				end
				entregar(chooser, itemId)
				return true
			end)
		end
	end

	janela:addButton("Escolher")
	janela:addButton("Depois")
	janela:setDefaultEnterButton(0)
	janela:setDefaultEscapeButton(1)
	janela:sendToPlayer(player)
end

local kitExercise = CreatureEvent("KitExerciseInicial")

function kitExercise.onLogin(player)
	local estado = player:kv():get(KV_ESCOLHA)

	if estado == nil then
		-- So personagem novo entra na fila. getLastLoginSaved() == 0 e o mesmo
		-- criterio do send_first_items.lua, que entrega o resto do kit.
		if player:getLastLoginSaved() ~= 0 then
			return true
		end
		player:kv():set(KV_ESCOLHA, "pendente")
		estado = "pendente"
	end

	if estado == "pendente" then
		-- atraso curto: no instante do login o cliente ainda esta montando a tela
		addEvent(abrirEscolha, 2000, player:getId())
	end

	return true
end

kitExercise:register()
