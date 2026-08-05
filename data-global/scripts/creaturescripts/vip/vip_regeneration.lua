-- VIP: regeneracao adicional de 10 de vida e 20 de mana a cada 3 segundos.
--
-- Feito com uma CONDITION_REGENERATION propria em vez de um globalevent que
-- varre os online: assim quem soma o HP/mana e' a propria engine, no tick dela,
-- e nao um laco em Lua a cada 3s.
--
-- O SUBID e' o que faz esta condicao COEXISTIR com a regeneracao normal do
-- jogador (comida, soul, etc.) -- condicoes sao indexadas por tipo+subid, entao
-- sem um subid proprio esta aqui substituiria a outra.
--
-- TICKS = -1 deixa permanente, e condicao permanente e' salva no blob
-- `players.conditions`. Por isso o script tambem PRECISA remove-la de quem
-- deixou de ser VIP: senao o beneficio ficaria para sempre em quem perdeu o VIP.

local VIP_REGEN_SUBID = 31001

local config = {
	health = 10,
	mana = 20,
	intervalMs = 3000,
}

local function buildCondition()
	local condition = Condition(CONDITION_REGENERATION, CONDITIONID_DEFAULT)
	condition:setParameter(CONDITION_PARAM_SUBID, VIP_REGEN_SUBID)
	condition:setParameter(CONDITION_PARAM_TICKS, -1)
	condition:setParameter(CONDITION_PARAM_HEALTHGAIN, config.health)
	condition:setParameter(CONDITION_PARAM_HEALTHTICKS, config.intervalMs)
	condition:setParameter(CONDITION_PARAM_MANAGAIN, config.mana)
	condition:setParameter(CONDITION_PARAM_MANATICKS, config.intervalMs)
	return condition
end

local vipRegeneration = CreatureEvent("VipRegeneration")

function vipRegeneration.onLogin(player)
	if not player then
		return true
	end

	local has = player:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT, VIP_REGEN_SUBID) ~= nil

	if player:isVip() then
		if not has then
			player:addCondition(buildCondition())
		end
	elseif has then
		player:removeCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT, VIP_REGEN_SUBID)
	end

	return true
end

vipRegeneration:register()
