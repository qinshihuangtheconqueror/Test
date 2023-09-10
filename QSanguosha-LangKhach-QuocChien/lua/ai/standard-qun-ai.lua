--[[********************************************************************
	Copyright (c) 2013-2015 Mogara

  This file is part of QSanguosha-Hegemony.

  This game is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 3.0
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  See the LICENSE file for more details.

  Mogara
*********************************************************************]]
--华佗
--[[旧青囊
local qingnang_skill = {}
qingnang_skill.name = "qingnang"
table.insert(sgs.ai_skills, qingnang_skill)
qingnang_skill.getTurnUseCard = function(self)
	if not self:willShowForDefence() then return nil end
	if self.player:getHandcardNum() < 1 then return nil end
	if self.player:usedTimes("QingnangCard") > 0 then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local compare_func = function(a, b)
		local v1 = self:getKeepValue(a) + ( a:isRed() and 50 or 0 ) + ( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b) + ( b:isRed() and 50 or 0 ) + ( b:isKindOf("Peach") and 50 or 0 )
		return v1 < v2
	end
	table.sort(cards, compare_func)

	local card_str = ("@QingnangCard=%d&qingnang"):format(cards[1]:getId())
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func.QingnangCard = function(card, use, self)
	local arr1, arr2 = self:getWoundedFriend()
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) then target = arr1[1] end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority.QingnangCard = 4.2
sgs.ai_card_intention.QingnangCard = -100

sgs.dynamic_value.benefit.QingnangCard = true
]]--

local chuli_skill = {}
chuli_skill.name = "chuli"
table.insert(sgs.ai_skills, chuli_skill)
chuli_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:canDiscard(self.player, "he") or self.player:hasUsed("ChuliCard") then return nil end
	self.chuli_id = nil
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	if self:needToThrowArmor() then
		self.chuli_id = self.player:getArmor():getEffectiveId()
		return sgs.Card_Parse("@ChuliCard=.&chuli")
	end
	for _, card in ipairs(cards) do
		if not self:isValuableCard(card) then
			if card:getSuit() == sgs.Card_Spade then
				self.chuli_id = card:getEffectiveId()
				return sgs.Card_Parse("@ChuliCard=.&chuli")
			end
		end
	end
	for _, card in ipairs(cards) do
		if not self:isValuableCard(card) and not (card:isRed() and self:getOverflow() < 2) then
			self.chuli_id = card:getEffectiveId()
			return sgs.Card_Parse("@ChuliCard=.&chuli")
		end
	end
end

sgs.ai_skill_use_func.ChuliCard = function(card, use, self)
	--Global_room:writeToConsole("函数使用除疠")
	local players = self:findPlayerToDiscard("he", false, sgs.Card_MethodDiscard, nil, true)
	local targets = sgs.PlayerList()

	for _, player in ipairs(players) do
		if self:isEnemy(player) and card:targetFilter(targets, player, self.player) then
			targets:append(player)
		end
	end
	for _, player in ipairs(players) do
		if not self:isFriend(player) and card:targetFilter(targets, player, self.player) then
			targets:append(player)
		end
	end
	for _, player in ipairs(players) do
		if self:isFriend(player) and card:targetFilter(targets, player, self.player) then
			targets:append(player)
		end
	end
	if targets:length() > 0 then
		use.card = card
		if use.to then use.to = sgs.PlayerList2SPlayerList(targets) end
	end
--[[旧写法，无法考虑拆队友黑桃
	for _, p in ipairs(targets) do
		local id = self:askForCardChosen(p, "he", "chuli_dismantlement", sgs.Card_MethodDiscard)
		if self:isFriend(p) then
			local chosen_card
			if id then chosen_card = sgs.Sanguosha:getCard(id) end
			if id and chosen_card and (p:hasEquip(chosen_card) or sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade) then
				if not use.card then use.card = card end
				self.chuli_id_choice[p:objectName()] = id
				--Global_room:writeToConsole("使用除疠目标"..p:objectName()..":"..self.chuli_id_choice[p:objectName()])
				if use.to and use.to:length() <3 then use.to:append(p) end
			end
		end
		if id then
			if not use.card then use.card = card end
			self.chuli_id_choice[p:objectName()] = id
			--Global_room:writeToConsole("使用除疠目标"..p:objectName()..":"..self.chuli_id_choice[p:objectName()])
			if use.to and use.to:length() <3 then use.to:append(p) end
		end
	end
]]
end

sgs.ai_skill_cardchosen.chuli = function(self, who, flags, method, disable_list)
	if who:objectName() == self.player:objectName() and self.chuli_id then
		Global_room:writeToConsole("选择自己除疠牌")
		return self.chuli_id
	end
	return self:askForCardChosen(who, flags, "chuli_dismantlement", method, disable_list)
end

sgs.ai_use_value.ChuliCard = 5.7
sgs.ai_use_priority.ChuliCard = 4.6

sgs.ai_card_intention.ChuliCard = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		if self.chuli_id_choice and self.chuli_id_choice[to:objectName()] then
			local em_prompt = { "cardChosen", "chuli", tostring(self.chuli_id_choice[to:objectName()]), from:objectName(), to:objectName() }
			sgs.ai_choicemade_filter.cardChosen.snatch(self, nil, em_prompt)
		end
	end
end

sgs.ai_view_as.jijiu = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getHandPile():contains(card_id)) and card:isRed() and player:getPhase() == sgs.Player_NotActive
		and not player:hasFlag("Global_PreventPeach") and (player:getMark("##qianxi+no_suit_red") == 0 or card:isEquipped()) then
		return ("peach:jijiu[%s:%s]=%d&jijiu"):format(suit, number, card_id)
	end
end

sgs.jijiu_suit_value = {
	heart = 6,
	diamond = 6
}

sgs.ai_cardneed.jijiu = function(to, card)
	return card:isRed()
end

sgs.ai_suit_priority.jijiu= "club|spade|diamond|heart"

--吕布
sgs.ai_skill_cardask["@wushuang-slash-1"] = function(self, data, pattern, target)
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if self:getCardsNum("Slash") < 2 and not (self.player:getHandcardNum() == 1 and self.player:hasSkills(sgs.need_kongcheng)) then return "." end
end

sgs.ai_skill_cardask["@multi-jink-start"] = function(self, data, pattern, target, target2, arg)
	local rest_num = tonumber(arg)
	if rest_num == 1 then return sgs.ai_skill_cardask["slash-jink"](self, data, pattern, target) end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if sgs.ai_skill_cardask["slash-jink"](self, data, pattern, target) == "." then return "." end
	if self.player:hasSkill("kongcheng") then
		if self.player:getHandcardNum() == 1 and self:getCardsNum("Jink") == 1 and target:hasWeapon("GudingBlade") then return "." end
	else
		if self:getCardsNum("Jink") < rest_num and self:hasLoseHandcardEffective() then return "." end
	end
end

sgs.ai_skill_cardask["@multi-jink"] = sgs.ai_skill_cardask["@multi-jink-start"]

sgs.ai_skill_invoke.wushuang = function(self, data)
	if not self:willShowForAttack() and not self:willShowForDefence() then return false end
	local use = self.player:getTag("WushuangData"):toCardUse()
	local current_trigger = self.player:getTag("WushuangTarget"):toPlayer()
	local index = use.to:indexOf(current_trigger)
	Global_room:writeToConsole("无双当前触发："..index)
	local left_trigger = sgs.SPlayerList()
	if use.to:length() > index + 1 then
		for i = index, use.to:length() - 1, 1 do
			left_trigger:append(use.to:at(i))--会出现空值？
		end
	end

	if use.card then
		if use.card:isKindOf("Duel") then
			if use.from:objectName() == self.player:objectName() then
				for _, p in sgs.qlist(left_trigger) do
					if self:isFriend(p) then return false end
				end
				return true
			else
				for _, c in sgs.qlist(self.player:getHandcards()) do
					if isCard("Slash", c, self.player) then
						return true
					end
				end
				return false
			end
		end
		for _, p in sgs.qlist(left_trigger) do
			if self:isFriend(p) then return false end
		end
		return true
	end
	return false
end

sgs.ai_skill_playerchosen["wushuang_extra"] = function(self, targets, max_num, min_num)--可参考usecardduel
	--local use = self.player:getTag("WushuangUsedata"):toCardUse()
	Global_room:writeToConsole("无双决斗额外选择")
	local result = {}
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "hp")
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) and #result < max_num and not table.contains(result, target) then
			  table.insert(result, target)
		end
	end
	for _, target in ipairs(targetlist) do
		if not self:isFriendWith(target) and #result < max_num and not table.contains(result, target) then
			  table.insert(result, target)
		end
	end
	return result
end

sgs.ai_cardneed.wushuang = function(to, card, self)
	return isCard("Duel", card, to) or isCard("Slash", card, to) or card:isKindOf("Halberd")
end

--貂蝉
function SmartAI:getLijianCard()
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")

	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not acard:isKindOf("Peach") and not acard:isKindOf("JadeSeal") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				  and not acard:isKindOf("Peach") and not acard:isKindOf("JadeSeal") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	return card_id
end

function SmartAI:findLijianTarget(card_name, use)
	local duel = sgs.cloneCard("duel")

	local findFriend_maxSlash = function(self, first)
		local maxSlash = 0
		local friend_maxSlash
		for _, friend in ipairs(self.friends_noself) do
			if friend:isMale() and self:trickIsEffective(duel, first, friend) then
				if (getCardsNum("Slash", friend, self.player) > maxSlash) then
					maxSlash = getCardsNum("Slash", friend, self.player)
					friend_maxSlash = friend
				end
			end
		end

		if friend_maxSlash then
			local safe = false
			if first:hasShownSkills("fankui|ganglie") then
				if (first:getHp() <= 1 and first:isKongcheng()) then safe = true end
			elseif (getCardsNum("Slash", friend_maxSlash, self.player) >= getCardsNum("Slash", first, self.player)) then safe = true end
			if safe then return friend_maxSlash end
		end
		return nil
	end

	if not self.player:hasUsed(card_name) then
		self:sort(self.enemies, "defense")
		local males, others = {}, {}
		local first, second
		local zhugeliang_kongcheng, xunyu

		for _, enemy in ipairs(self.enemies) do
			if enemy:isMale() then
				if enemy:hasShownSkill("kongcheng") and enemy:isKongcheng() then zhugeliang_kongcheng = enemy
				elseif enemy:hasShownSkill("jieming") then xunyu = enemy
				else
					for _, anotherenemy in ipairs(self.enemies) do
						if anotherenemy:isMale() and anotherenemy:objectName() ~= enemy:objectName() then
							if #males == 0 and self:trickIsEffective(duel, enemy, anotherenemy) then
								table.insert(males, enemy)
							end
							if #males == 1 and self:trickIsEffective(duel, males[1], anotherenemy) then
								if not anotherenemy:hasShownSkills("jizhi|jiang") then
									table.insert(males, anotherenemy)
								else
									table.insert(others, anotherenemy)
								end
								if #males >= 2 then break end
							end
						end
					end
				end
				if #males >= 2 then break end
			end
		end

		if #males >= 1 and males[1]:getHp() == 1 then--新增配合吕布张绣
			local afriend = findFriend_maxSlash(self, males[1])
			if afriend and afriend:objectName() ~= males[1]:objectName() then
				return males[1], afriend
			end
			local lvbu = sgs.findPlayerByShownSkillName("wushuang")
			local zhangxiu = sgs.findPlayerByShownSkillName("congjian")
			if lvbu and lvbu:getHp() > 1 and lvbu:getHandcardNum() > 1 then
				afriend  =lvbu
			end
			if zhangxiu and zhangxiu:getHp() > 1 and zhangxiu:getHandcardNum() > 1 then
				afriend = zhangxiu
			end
			if afriend and afriend:objectName() ~= males[1]:objectName() and afriend:objectName() ~= self.player:objectName() then
				return males[1], afriend
			end
		end

		if #males == 1 then
			if #others >= 1 and not others[1]:isLocked(duel) then
				table.insert(males, others[1])
			elseif xunyu and not xunyu:isLocked(duel) then
				if getCardsNum("Slash", males[1], self.player) < 1 then
					table.insert(males, xunyu)
				else
					local drawcards = 0
					for _, enemy in ipairs(self.enemies) do
						local x = enemy:getMaxHp() > enemy:getHandcardNum() and math.min(5, enemy:getMaxHp() - enemy:getHandcardNum()) or 0
						if x > drawcards then drawcards = x end
					end
					if drawcards <= 2 then
						table.insert(males, xunyu)
					end
				end
			end
		end

		if #males == 1 and #self.friends_noself > 0 then
			self:log("Only 1")
			first = males[1]
			if zhugeliang_kongcheng and self:trickIsEffective(duel, first, zhugeliang_kongcheng) then
				table.insert(males, zhugeliang_kongcheng)
			else
				local friend_maxSlash = findFriend_maxSlash(self, first)
				if friend_maxSlash then table.insert(males, friend_maxSlash) end
			end
		end

		if #males >= 2 then
			first = males[1]
			second = males[2]
			if first and second and first:objectName() ~= second:objectName() and not second:isLocked(duel) then
				return first, second
			end
		end
	end
end

local lijian_skill = {}
lijian_skill.name = "lijian"
table.insert(sgs.ai_skills, lijian_skill)
lijian_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("LijianCard") or self.player:isNude() then
		return
	end
	local card_id = self:getLijianCard()
	if card_id then return sgs.Card_Parse("@LijianCard=" .. card_id .. "&lijian") end
end

sgs.ai_skill_use_func.LijianCard = function(card, use, self)
	local first, second = self:findLijianTarget("LijianCard", use)
	if first and second then
		use.card = card
		if use.to then
			use.to:append(first)
			use.to:append(second)
		end
	end
end

sgs.ai_use_value.LijianCard = 8.5
sgs.ai_use_priority.LijianCard = 4
sgs.dynamic_value.damage_card.LijianCard = true

sgs.ai_skill_invoke.biyue = function(self, data)
	if not self:willShowForDefence() then
		return false
	end
	return not self:needKongcheng(self.player, true)
end

--袁绍
local luanji_skill = {}
luanji_skill.name = "luanji"
table.insert(sgs.ai_skills, luanji_skill)
luanji_skill.getTurnUseCard = function(self)
	local willShow = false
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("Vine") then
			willShow = true
			break
		end
	end
	--配合许攸
	local xuyou = sgs.findPlayerByShownSkillName("chenglve")
	if xuyou and self.player:isFriendWith(xuyou) then
		willShow = true
	end

	if not self.player:hasShownSkill("luanji") and not willShow then return nil end

	local archery = sgs.cloneCard("archery_attack")
	local first_found, second_found = false, false
	local first_card, second_card
	local usedsuits = self.player:property("luanjiUsedSuits"):toString():split("+")

	if self.player:getHandcardNum() + self.player:getHandPile():length() >= 2 then
		local cards = self.player:getHandcards()
		for _, id in sgs.qlist(self.player:getHandPile()) do
			cards:prepend(sgs.Sanguosha:getCard(id))
		end
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		local useAll = false
		local hasSamesuit = false
		local heartKeepnum, diamondKeepnum, spadeKeepnum, clubKeepnum = 0,0,0,0

		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 and not enemy:hasArmorEffect("Vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player)
				and self:isWeak(enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
			end
		end

		for _, c in ipairs(cards) do
			if useAll then
				if isCard("ArcheryAttack", c, self.player) or isCard("BefriendAttacking", c, self.player) then
					if c:getSuit() == sgs.Card_Heart then
						heartKeepnum = heartKeepnum +1
					elseif c:getSuit() == sgs.Card_Diamond then
						diamondKeepnum = diamondKeepnum + 1
					elseif c:getSuit() == sgs.Card_Spade then
						spadeKeepnum = spadeKeepnum + 1
					elseif c:getSuit() == sgs.Card_Club then
						clubKeepnum = clubKeepnum + 1
					end
				end
			else
				if isCard("Peach", c, self.player) or isCard("ExNihilo", c, self.player)
				or isCard("BefriendAttacking", c, self.player) or isCard("AllianceFeast", c, self.player)
				or isCard("ArcheryAttack", c, self.player) or isCard("JadeSeal", c, self.player) then
					if c:getSuit() == sgs.Card_Heart then
						heartKeepnum = heartKeepnum +1
					elseif c:getSuit() == sgs.Card_Diamond then
						diamondKeepnum = diamondKeepnum + 1
					elseif c:getSuit() == sgs.Card_Spade then
						spadeKeepnum = spadeKeepnum + 1
					elseif c:getSuit() == sgs.Card_Club then
						clubKeepnum = clubKeepnum + 1
					end
				end
			end
		end
		--去除保留牌的花色，优先使用同色
		if self:getSuitNum("heart", false, self.player) > 1 + heartKeepnum or
		self:getSuitNum("diamond", false, self.player) > 1 + diamondKeepnum or
		self:getSuitNum("spade", false, self.player) > 1 + spadeKeepnum or
		self:getSuitNum("club", false, self.player) > 1 + clubKeepnum then
		   hasSamesuit = true
	   end

		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player)
								or isCard("BefriendAttacking", fcard, self.player) or isCard("AllianceFeast", fcard, self.player)
								or isCard("ArcheryAttack", fcard, self.player) or isCard("JadeSeal", fcard, self.player))
			if useAll then
				fvalueCard = isCard("ArcheryAttack", fcard, self.player) or isCard("BefriendAttacking", fcard, self.player)
			end
			if not fvalueCard and not table.contains(usedsuits, sgs.Sanguosha:getCard(fcard:getId()):getSuitString()) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player) or isCard("JadeSeal", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard and (scard:getSuit() == first_card:getSuit() or not hasSamesuit)--新万箭齐发
						and not svalueCard and not table.contains(usedsuits, sgs.Sanguosha:getCard(scard:getId()):getSuitString()) then

						local card_str = ("archery_attack:luanji[%s:%s]=%d+%d&luanji"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = { isDummy = true }
						self:useTrickCard(archeryattack, dummy_use)
						if dummy_use.card then
							second_card = scard
							second_found = true
							break
						end
					end
				end
				if second_card then break end
			end
		end
	end

	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		if table.contains(usedsuits, sgs.Sanguosha:getCard(first_id):getSuitString())--前边也有检测
		or table.contains(usedsuits, sgs.Sanguosha:getCard(second_id):getSuitString()) then
			return nil
		end
		local card_str = ("archery_attack:luanji[%s:%s]=%d+%d&luanji"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
end

sgs.ai_skill_choice["luanji_draw"] = function(self, choices, data)
	return "yes"
end

--颜良＆文丑
sgs.ai_skill_invoke.shuangxiong = function(self, data)
	if self.player:isSkipped(sgs.Player_Play) or (self.player:getHp() < 2 and not (self:getCardsNum("Slash") > 1 and self.player:getHandcardNum() >= 3)) or #self.enemies == 0 then
		return false
	end
	if self.player:hasSkill("luanji") and self.player:getHandcardNum() >= 5 then return false end
	if not self:willShowForAttack() and self.player:getHandcardNum() < 5 then return false end

	local duel = sgs.cloneCard("duel")

	local dummy_use = { isDummy = true }
	self:useTrickCard(duel, dummy_use)

	if (self.player:getHandcardNum() >= 3 and dummy_use.card) then
		return true
	end
	return false
end

sgs.ai_cardneed.shuangxiong = function(to, card, self)
	return not self:willSkipDrawPhase(to)
end

local shuangxiong_skill = {}
shuangxiong_skill.name = "shuangxiong"
table.insert(sgs.ai_skills, shuangxiong_skill)
shuangxiong_skill.getTurnUseCard = function(self)
	if self.player:getMark("##shuangxiong+no_suit_black") + self.player:getMark("##shuangxiong+no_suit_red") == 0 then return nil end
	local black_mark = self.player:getMark("##shuangxiong+no_suit_black")
	local red_mark = self.player:getMark("##shuangxiong+no_suit_red")

	local cards = self.player:getCards("h")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)

	local card
	for _, acard in ipairs(cards) do
		if (acard:isRed() and red_mark > 0) or (acard:isBlack() and black_mark > 0) then
			card = acard
			break
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("duel:_shuangxiong[%s:%s]=%d&"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

--贾诩
local luanwu_skill = {}
luanwu_skill.name = "luanwu"
table.insert(sgs.ai_skills, luanwu_skill)
luanwu_skill.getTurnUseCard = function(self)
	if self.player:getMark("@chaos") <= 0 then return end
	local good, bad = 0, 0
	if self.player:hasShownSkill("baoling") then good = good + 0.8 end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) then
			if self:isFriend(player) then bad = bad + 1.5
			elseif player:hasShownOneGeneral() then  good = good + 0.8
			else good = good + 0.4
			end
		end
	end
	local alive = self.room:alivePlayerCount()
	if good < alive/4 then return end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if player:isRemoved() then
			continue
		end
		local hp = math.max(player:getHp(), 1)
		if getCardsNum("Analeptic", player, self.player) > 0 then
			if self:isFriend(player) then good = good + 1.0 / hp
			else bad = bad + 1.0 / hp
			end
		end

		local has_slash = (getCardsNum("Slash", player, self.player) > 0)
		local can_slash = false
		if not can_slash then
			for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
				if player:distanceTo(p) <= player:getAttackRange() then can_slash = true break end
			end
		end
		if not has_slash or not can_slash then
			if self:isFriend(player) then good = good + math.max(getCardsNum("Peach", player, self.player), 1)
			else bad = bad + math.max(getCardsNum("Peach", player, self.player), 1)
			end
		end

		if getCardsNum("Jink", player, self.player) == 0 then
			local lost_value = 0
			if player:hasShownSkills(sgs.masochism_skill) then lost_value = player:getHp() / 2 end
			local hp = math.max(player:getHp(), 1)
			if self:isFriend(player) then bad = bad + (lost_value + 1) / hp
			else good = good + (lost_value + 1) / hp
			end
		end
	end

	if good > bad then return sgs.Card_Parse("@LuanwuCard=.&luanwu") end
end

sgs.ai_skill_use_func.LuanwuCard = function(card, use, self)
	use.card = card
end

sgs.dynamic_value.damage_card.LuanwuCard = true

sgs.ai_skill_cardask["@luanwu-slash"] = function(self)
	local players = {}
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if player:hasFlag("SlashAssignee") then table.insert(players, player) end
	end
	local slashes = self:getCards("Slash")

	if #slashes == 0 then return "." end
	self:sort(players, "defenseSlash")
	for _, slash in ipairs(slashes) do
		local targets = {}
		local EXT = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, slash)
		for _, friend in ipairs(players) do
			if not self.player:canSlash(friend, slash) then continue end
			if self:isFriend(friend) and not self:hasHeavySlashDamage(self.player, slash, friend)
				and not self:slashProhibit(slash, friend) and self:slashIsEffective(slash, friend)
				and self:isPriorFriendOfSlash(friend, slash, self.player)
				and not table.contains(targets, friend:objectName()) then
				table.insert(targets, friend:objectName())
			end
		end

		for _, enemy in ipairs(players) do
			if not self.player:canSlash(enemy, slash) then continue end
			if self:isEnemy(enemy) and not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy)
				and sgs.isGoodTarget(enemy, players, self) and not table.contains(targets, enemy:objectName()) then
				table.insert(targets, enemy:objectName())
			end
		end

		for _, friend in ipairs(players) do
			if not self.player:canSlash(friend, slash) then continue end
			if self:isFriend(friend) and not self:hasHeavySlashDamage(self.player, slash, friend)
				and not self:slashProhibit(slash, friend) and self:slashIsEffective(slash, friend)
				and (self:needDamagedEffects(friend, self.player, true) or self:needToLoseHp(friend, self.player, true))
				and not table.contains(targets, friend:objectName()) then
				table.insert(targets, friend:objectName())
			end
		end

		if self:isWeak() then
			for _, enemy in ipairs(players) do
				if not self.player:canSlash(enemy, slash) then continue end
				if not table.contains(targets, enemy:objectName()) and self:isEnemy(enemy) then
					table.insert(targets, enemy:objectName())
				end
			end
		end

		if self:isWeak() then
			for _, friend in ipairs(players) do
				if not self.player:canSlash(friend, slash) then continue end
				if not table.contains(targets, friend:objectName()) and self:isFriend(friend) and (not self:isFriend(friend) or getKnownCard(friend, self.player, "Jink", true) > 0) then
					table.insert(targets, friend:objectName())
				end
			end
		end

		if #targets > 0 then
			return slash:toString() .. "->" .. table.concat(targets, "+", 1, EXT)
		end
	end
	return "."
end

sgs.ai_skill_invoke.weimu = function(self, data)
	local use = data:toCardUse()
	if not use.card then return false end
	if use.card:isKindOf("ThreatenEmperor") then return false end
	if self.player:isChained() then
		if use.card:isKindOf("FightTogether") then return false end
		if use.card:isKindOf("IronChain") then return false end
	end
	if use.card:isKindOf("ImperialOrder") then
		if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
			local reward = true
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:hasShownOneGeneral() then
					reward = false
					break
				end
			end
			if reward then return true end
		else
			return false
		end
	end
	if self:isWeak() then return true end
	if not self:willShowForDefence() then return false end
	return true
end

sgs.ai_skill_invoke.wansha = function(self, data)
	return not self:isFriend(data:toDying().who)
end

--庞德
--[[
sgs.ai_skill_invoke.mengjin = function(self, data)
	if not self:willShowForAttack() then return false end
	local effect = data:toSlashEffect()
	if self:isEnemy(effect.to) then
		if self:doNotDiscard(effect.to) then
			return false
		end
	end
	if self:isFriend(effect.to) then
		return self:needToThrowArmor(effect.to) or self:doNotDiscard(effect.to)
	end
	return not self:isFriend(effect.to)
end]]--旧技能

sgs.ai_skill_invoke.jianchu = function(self,data)
	local target = data:toPlayer()
	if not target then return false end
	return not self:isFriend(target) and not self:doNotDiscard(target, "he")
end

sgs.ai_skill_cardchosen.jianchu = function(self, who, flags, method, disable_list)
	if flags:match("e") then
		local id = self:askForCardChosen(who, "e", "jianchu_dismantlement", method, disable_list)
		if id then
			return id
		end
	else
		return self:askForCardChosen(who, flags, "jianchu_dismantlement", method, disable_list)
	end

end

function sgs.ai_cardneed.jianchu(to, card, self)
	return card:isKindOf("Slash") or card:isKindOf("Analeptic")
end

--张角
sgs.ai_skill_cardask["@guidao-card"]=function(self, data)
	if sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") <= 1
	and not self.player:hasShownGeneral1() and self.player:inHeadSkills("guidao") and not self:isWeak() then--君主
		return "."
	end
	if not (self:willShowForAttack() or self:willShowForDefence() ) then return "." end
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		all_cards:prepend(sgs.Sanguosha:getCard(id))
	end
	if all_cards:isEmpty() then return "." end

	local needTokeep = judge.card:getSuit() ~= sgs.Card_Spade
						and sgs.ai_AOE_data and self:playerGetRound(judge.who) < self:playerGetRound(self.player) and self:findLeijiTarget(self.player, 50)
						and (self:getCardsNum("Jink") > 0 or self:hasEightDiagramEffect()) and self:getFinalRetrial() == 1
	if not needTokeep then
		local who = judge.who
		if who:getPhase() == sgs.Player_Judge and not who:getJudgingArea():isEmpty() and who:containsTrick("lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if self.player:hasSkill("leiji") then keptspade = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isBlack() and not card:hasFlag("using") then
			if card:getSuit() == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptblack == 1 then return "." end
	if keptspade == 1 and not self.player:hasSkill("leiji") then return "." end

	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			self:sortByUseValue(cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(sgs.Sanguosha:getCard(card_id)) then
		local card = sgs.Sanguosha:getCard(card_id)
		return "$" .. card_id
	end

	return "."
end

function sgs.ai_cardneed.guidao(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if player:containsTrick("lightning") and self:getFinalRetrial(to, "lightning") == 1  then
			return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and not self.player:hasSkill("hongyan")
		end
		if self:isFriend(player) and self:willSkipDrawPhase(player) and self:getFinalRetrial(to, "supply_shortage") == 1 then
			return card:getSuit() == sgs.Card_Club and self:hasSuit("club", true, to)
		end
	end
	if to:hasShownSkill("leiji") and self:getFinalRetrial(to, "leiji")then
		return card:isBlack()
	end
end

function SmartAI:findLeijiTarget(player, leiji_value, slasher)
	if not player:hasShownSkill("leiji") then return end
	if slasher then
		if not self:slashIsEffective(sgs.cloneCard("slash"), player, slasher, slasher:hasWeapon("QinggangSword")) then return nil end
		if self:canLiegong(player, slasher) and self:isEnemy(player, slasher) then
			return nil
		end
		if not self:hasSuit("spade", true, player) and player:getHandcardNum() < 3 then return nil end
		local hasJink
		if getKnownCard(player, self.player, "Jink", true) > 0 then hasJink = true end
		if not hasJink and player:getHandcardNum() >= 3 and getCardsNum("Jink", player, self.player) >= 1 and sgs.card_lack[player:objectName()]["Jink"] ~= 1 then hasJink = true end
		if not hasJink and not self:isWeak(player) and self:hasEightDiagramEffect(player) and not slasher:hasWeapon("QinggangSword") then hasJink = true end
		if not hasJink then return end
	end
	local getCmpValue = function(enemy)
		local value = 0
		local damage = {}
		damage.to = enemy
		damage.from = player
		damage.nature = sgs.DamageStruct_Thunder
		damage.damage = 2
		if not self:damageIsEffective_(damage) then return 99 end
		if enemy:hasShownSkill("hongyan") then return 99 end
		if self:cantbeHurt(enemy, player, 2) or self:objectiveLevel(enemy) < 3
			or (enemy:isChained() and not self:isGoodChainTarget_(damage)) then return 100 end
		if not sgs.isGoodTarget(enemy, self.enemies, self) then value = value + 50 end
		if enemy:hasArmorEffect("SilverLion") then value = value + 20 end
		if enemy:hasShownSkills(sgs.exclusive_skill) then value = value + 10 end
		if enemy:hasShownSkills(sgs.masochism_skill) then value = value + 5 end
		if enemy:isChained() and self:isGoodChainTarget_(damage) and #(self:getChainedEnemies(player)) > 1 then value = value - 25 end
		if enemy:isLord() then value = value - 5 end
		value = value + enemy:getHp() + sgs.getDefenseSlash(enemy, self) * 0.01
		return value
	end

	local cmp = function(a, b)
		return getCmpValue(a) < getCmpValue(b)
	end

	local enemies = self:getEnemies(player)
	table.sort(enemies, cmp)
	for _, enemy in ipairs(enemies) do
		if getCmpValue(enemy) < leiji_value then return enemy end
	end
	return nil
end

sgs.ai_skill_playerchosen.leiji = function(self, targets)
	if sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") <= 1
	and not self.player:hasShownGeneral1() and self.player:inHeadSkills("leiji") and not self:isWeak() then--君主
		return nil
	end
	self:updatePlayers()
	if not self:willShowForAttack() then return nil end
	local getCmpValue = function(enemy)
		local value = 0
		local damage = {}
		damage.to = enemy
		damage.from = self.player
		damage.nature = sgs.DamageStruct_Thunder
		damage.damage = 2
		if not self:damageIsEffective_(damage) then return 99 end
		if enemy:hasShownSkill("hongyan") then return 99 end
		if self:cantbeHurt(enemy, self.player, 2) or self:objectiveLevel(enemy) < 3
			or (enemy:isChained() and not self:isGoodChainTarget_(damage)) then return 100 end
		if not sgs.isGoodTarget(enemy, self.enemies, self) then value = value + 50 end
		if enemy:hasArmorEffect("SilverLion") then value = value + 20 end
		if enemy:hasShownSkills(sgs.exclusive_skill) then value = value + 10 end
		if enemy:hasShownSkills(sgs.masochism_skill) then value = value + 5 end
		if enemy:isChained() and self:isGoodChainTarget_(damage) and #(self:getChainedEnemies(self.player)) > 1 then value = value - 25 end
		if enemy:isLord() then value = value - 5 end
		value = value + enemy:getHp() + sgs.getDefenseSlash(enemy, self) * 0.01
		return value
	end

	local cmp = function(a, b)
		return getCmpValue(a) < getCmpValue(b)
	end

	local enemies = self:getEnemies(self.player)
	table.sort(enemies, cmp)
	for _, enemy in ipairs(enemies) do
		if getCmpValue(enemy) < 100 then return enemy end
	end
end

function SmartAI:needLeiji(to, from)
	return self:findLeijiTarget(to, 50, from)
end

sgs.ai_playerchosen_intention.leiji = 80

function sgs.ai_slash_prohibit.leiji(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if self:canLiegong(to, from) then return false end
	if from:hasShownSkills("tieqi|tieqi_xh") then return false end
	if from:hasShownSkill("jianchu") and (to:hasEquip() or to:getCardCount(true) == 1) then
		return false
	end
	if (to:getMark("##qianxi+no_suit_red") + to:getMark("##qianxi+no_suit_black") > 0) and (not self:hasEightDiagramEffect(to) or IgnoreArmor(from, to)) then
		return false
	end
	local hcard = to:getHandcardNum()
	if (from:getHp() >= 4 and (getCardsNum("Peach", from, to) > 0 or from:hasShownSkill("ganglie"))) or from:hasShownSkill("hongyan") and #self.friends == 1 then
		return false
	end
	if sgs.card_lack[to:objectName()]["Jink"] == 2 then return true end
	if getKnownCard(to, Global_room:getCurrent(), "Jink", true) >= 1 or (self:hasSuit("spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if self:hasEightDiagramEffect(to) then return true end
end

sgs.guidao_suit_value = {
	spade = 3.9,
	club = 2.7
}

sgs.ai_suit_priority.guidao= "diamond|heart|club|spade"

--蔡文姬
sgs.ai_skill_discard.beige = function(self)
	local damage = self.player:getTag("beige_data"):toDamage()
	if damage.from and self:isFriend(damage.from) and not damage.from:faceUp() and damage.to:getPile("incantation"):length() > 0 then		--和张宝的配合
		local id = damage.to:getPile("incantation"):first()
		if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade then
			return self:askForDiscard("dummy_reason", 1, 1, false, true)
		end
	end
	if damage.to and not self:isFriend(damage.to) or damage.from and self:isFriend(damage.from) then return {} end
	if not self:willShowForMasochism() then return {} end
	return self:askForDiscard("dummy_reason", 1, 1, false, true)
end

function sgs.ai_cardneed.beige(to, card)
	return to:getCardCount(true) <= 2
end

function sgs.ai_slash_prohibit.duanchang(self, from, to)
	if to:getHp() > 1 or #(self:getEnemies(from)) == 1 then return false end
	if (from:getActualGeneral1():getKingdom() == "careerist" or from:isLord())
	and to:getHp() == 1 and #(self:getEnemies(from)) > 1 then--多个敌人时的野心家或君主
		return true
	end
	if from:getMaxHp() == 3 and from:getArmor() and from:getDefensiveHorse() then return false end
	if from:getMaxHp() <= 3 or (from:isLord() and self:isWeak(from)) then return true end
	return false
end

sgs.ai_skill_choice.duanchang = function(self, choices, data)
	local who = data:toPlayer()
	local needToDuanchangSkills = ""
	if self:isFriend(who) then
		if who:getHeadSkillList():length() >= who:getDeputySkillList():length() then
			return "deputy_general"
		end
	else
		if who:getHeadSkillList():length() >= who:getDeputySkillList():length() then
			return "head_general"
		end
	end

	local skills = (sgs.priority_skill .. "|" .. sgs.masochism_skill .. "|" .. sgs.recover_skill .. "|"
					.. sgs.wizard_skill .. "|" .. sgs.cardneed_skill):split("|")
	for _, skill in ipairs(skills) do
		if who:hasShownSkill(skill) then
			if self.player:isFriendWith(who) then--现在可以用sgs.general_value来判断武将强度
				return who:inHeadSkills(skill) and "deputy_general" or "head_general"
			else
				return who:inHeadSkills(skill) and "head_general" or "deputy_general"
			end
		end
	end

	return "head_general"
end

--马腾
local xiongyi_skill = {}
xiongyi_skill.name = "xiongyi"
table.insert(sgs.ai_skills, xiongyi_skill)
xiongyi_skill.getTurnUseCard = function(self)
	if self.player:getMark("@arise") < 1 then return end

	if self.player:hasShownSkill(sgs.Sanguosha:getSkill("baoling")) then
		return sgs.Card_Parse("@XiongyiCard=.&xiongyi")
	end
	for _, friend in ipairs(self.friends) do
		if (self:objectiveLevel(friend) == 2 or self.player:isFriendWith(friend)) and self:isWeak(friend) then
			return sgs.Card_Parse("@XiongyiCard=.&xiongyi")
		end
	end
	if string.find(sgs.gameProcess(), "qun>>>") then--sgs.gameProcess() == "qun>>>"
		return sgs.Card_Parse("@XiongyiCard=.&xiongyi")
	end
end

sgs.ai_skill_use_func.XiongyiCard = function(card, use, self)
	use.card = card
end

sgs.ai_card_intention.XiongyiCard = -80
sgs.ai_use_priority.XiongyiCard = 9.31

--孔融
sgs.ai_skill_invoke.mingshi = true

sgs.ai_skill_invoke.lirang = function(self, data)
	if not self:willShowForAttack() then
		return false
	end
	for _, afriend in ipairs(self.friends_noself) do
		if not self:needKongcheng(afriend, true) then return true end
	end
	return false
end

sgs.ai_skill_use["@@liranggive"] = function(self, prompt)
	--self.player:speak("开始判断礼让")
	if not self:willShowForAttack() or #self.friends_noself == 0 then return "." end
	--local card_ids = self.player:property("lirang_this_time"):toString() ~= "" and self.player:property("lirang_this_time"):toString():split("+") or {}

	local card_ids = self.player:getTag("lirang_forAI"):toString():split("+")

	self:updatePlayers()
	local cards = {}

	for _, card_id in ipairs(card_ids) do
		--[[self.player:speak(sgs.Sanguosha:getCard(card_id):getLogName())]]--
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end

	local card, friend = self:getCardNeedPlayer(cards, self.friends_noself)
	if card and friend then return "@LirangGiveCard=" .. card:getEffectiveId() .. "->" .. friend:objectName() end
	if #self.friends_noself > 0 then
		self:sort(self.friends_noself, "handcard")
		for _, afriend in ipairs(self.friends_noself) do
			if not self:needKongcheng(afriend, true) then
				return "@LirangGiveCard=" .. cards[1]:getEffectiveId() .. "->" .. afriend:objectName()
			end
		end
	end
	return "."
end
sgs.ai_skill_askforyiji.lirang = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end

	local new_friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if not self:needKongcheng(friend, true) then table.insert(new_friends, friend) end
	end

	if #new_friends > 0 then
		local card, target = self:getCardNeedPlayer(cards, new_friends)
		if card and target then
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
			if not card:hasFlag("visible") then card:setFlags(flag) end--记录方便盗书，是否增加主动盗书配合？
			return target, card:getEffectiveId()
		end
		self:sort(new_friends, "defense")
		self:sortByKeepValue(cards, true)
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), new_friends[1]:objectName())
		if not cards[1]:hasFlag("visible") then cards[1]:setFlags(flag) end
		return new_friends[1], cards[1]:getEffectiveId()
	else
		return nil, -1
	end
end
--纪灵
sgs.ai_skill_playerchosen.shuangren = function(self, targets)--考虑不对其他目标使用牌？
	if self.player:isKongcheng() then return nil end
	if not self:willShowForAttack() then return nil end
	if self.player:hasFlag("shuangxiong") and self.player:hasSkill("shuangxiong") then return nil end

	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxNumberCard()
	local max_point = max_card:getNumber()

	local slash = sgs.cloneCard("slash")
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {}}
	local zhangjiao = sgs.findPlayerByShownSkillName("leiji")
	if zhangjiao and self:isFriend(zhangjiao) then
		table.insert(dummy_use.current_targets, zhangjiao:objectName())
	end
	self.player:setFlags("slashNoDistanceLimit")
	self:useBasicCard(slash, dummy_use)
	self.player:setFlags("-slashNoDistanceLimit")

	if dummy_use.card and not dummy_use.to:isEmpty() then
		for _, enemy in sgs.qlist(dummy_use.to) do
			local enemy_max_card = self:getMaxNumberCard(enemy)
			local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
			if max_point > enemy_max_point then
				self.shuangren_card = max_card:getEffectiveId()
				return enemy
			end
		end
		for _, enemy in sgs.qlist(dummy_use.to) do
			if max_point >= 10 then
				self.shuangren_card = max_card:getEffectiveId()
				return enemy
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.shuangren(minusecard, self, requestor)
	local maxcard = self:getMaxNumberCard()
	return self:isFriend(requestor) and self:getMinNumberCard() or (maxcard:getNumber() < 6 and minusecard or maxcard)
end

sgs.ai_skill_playerchosen["shuangren_slash"] = sgs.ai_skill_playerchosen.zero_card_as_slash
sgs.ai_playerchosen_intention.shuangren = 20
sgs.ai_cardneed.shuangren = sgs.ai_cardneed.bignumber

--田丰
sgs.ai_skill_invoke.suishi = function(self, data)
	local event = data:toInt()
	if event == sgs.Death then return false end
	return true
end

sgs.ai_skill_playerchosen.sijian = function(self, targets)
	return self:findPlayerToDiscard()
end

sgs.ai_playerchosen_intention.sijian = function(self, from, to)
	local intention = 80
	if (to:hasShownSkill("kongcheng") and to:getHandcardNum() == 1) or self:needToThrowArmor(to) then
		intention = 0
	end
	sgs.updateIntention(from, to, intention)
end

function sgs.ai_cardneed.sijian(to, card, self)
	return to:isKongcheng() and not self:needKongcheng(to)
end

--潘凤
--[[旧技能
sgs.ai_skill_invoke.kuangfu = function(self, data)
	local damage = data:toDamage()
	if damage.to:hasShownSkills(sgs.lose_equip_skill) then
		return self:isFriend(damage.to) and not self:isWeak(damage.to)
	end
	local benefit = (damage.to:getCards("e"):length() == 1 and damage.to:getArmor() and self:needToThrowArmor(damage.to))
	if self:isFriend(damage.to) then return benefit end
	return not benefit
end

sgs.ai_skill_cardchosen.kuangfu = function(self, who, flags, method, disable_list)
	if self:isFriend(who) then
		if who:getArmor() and self:needToThrowArmor(who) then return who:getArmor():getEffectiveId() end
		if who:getArmor() and self:evaluateArmor(who:getArmor(), who) < -5 then return who:getArmor():getEffectiveId() end
		if who:hasShownSkills(sgs.lose_equip_skill) and self:isWeak(who) then
			if who:getWeapon() then return who:getWeapon():getEffectiveId() end
			if who:getOffensiveHorse() then return who:getOffensiveHorse():getEffectiveId() end
		end
	else
		if self.player:hasSkills("kuangfu+xishe") and who:hasEquip() then--配合不臣黄祖
			if not self.player:getWeapon() and who:getWeapon() then
				return who:getWeapon():getId()
			elseif not self.player:getOffensiveHorse() and who:getOffensiveHorse() then
				return who:getOffensiveHorse():getId()
			elseif not self.player:getDefensiveHorse() and who:getDefensiveHorse() then
				return who:getDefensiveHorse():getId()
			elseif not self.player:getArmor() and who:getArmor() then
				return who:getArmor():getId()
			elseif self.player:getTreasure() and who:getTreasure() then
				return who:getTreasure():getEffectiveId()
			end
		end
		local dangerous = self:getDangerousCard(who)
		if dangerous then return dangerous end
		if who:getArmor() and who:getArmor():isKindOf("EightDiagram") and not self:needToThrowArmor(who) then return who:getArmor():getEffectiveId() end
		if who:hasShownSkills("jijiu|beige|weimu|qingcheng") and not self:doNotDiscard(who, "e", false, 1) then
			if who:getPile("wooden_ox"):length() > 1 or who:hasTreasure("JadeSeal") then return who:getTreasure():getEffectiveId() end
			if who:getDefensiveHorse() then return who:getDefensiveHorse():getEffectiveId() end
			if who:getArmor() and who:getArmor() and not self:needToThrowArmor(who) then return who:getArmor():getEffectiveId() end
			if who:getOffensiveHorse() and (not who:hasShownSkills("jijiu") or who:getOffensiveHorse():isRed()) then return who:getOffensiveHorse():getEffectiveId() end
			if who:getWeapon() and (not who:hasShownSkills("jijiu") or who:getWeapon():isRed()) then return who:getWeapon():getEffectiveId() end
		end
		local valuable = self:getValuableCard(who)
		if valuable then return valuable end
		if not self:doNotDiscard(who, "e") then
			if who:getArmor() and self:isWeak() then return who:getArmor():getEffectiveId() end
			if who:getTreasure() then return who:getTreasure():getEffectiveId() end
			if who:getArmor() then return who:getArmor():getEffectiveId() end
			if who:getWeapon() then return who:getWeapon():getEffectiveId() end
			if who:getDefensiveHorse() then return who:getDefensiveHorse():getEffectiveId() end
			if who:getOffensiveHorse() then return who:getOffensiveHorse():getEffectiveId() end
		end
	end
end

sgs.ai_skill_choice.kuangfu = function(self, choices)
	return "move"
end
]]

sgs.ai_skill_playerchosen.kuangfu = function(self, targets)
	local target = self:findPlayerToDiscard("e", false, sgs.Card_MethodGet, targets)
	if target then
		return target
	end
	for _, p in sgs.qlist(targets) do
		Global_room:writeToConsole("狂斧目标防御值：" ..sgs.getDefenseSlash(p, self))
		if p:isKongcheng() then
			return p
		end
		local knownJink = getKnownCard(p, self.player, "Jink", true, "he")
		if sgs.card_lack[p:objectName()]["Jink"] == 1 and knownJink == 0 then
			return p
		end
		local unknownJink = getCardsNum("Jink", p, self.player)
		if self.player:hasShownSkills("wushuang|wushuang_lvlingqi") and knownJink < 2 and unknownJink < 1.5 then
			return p
		end
		if self.player:hasShownSkill("jianchu") and (p:getCards("e"):length() > 1 or p:getHandcardNum() <= 1) then
			return p
		end
		if self.player:hasWeapon("DragonPhoenix") and p:getHandcardNum() <= 1 then
			return p
		end
	end
	local target_list = sgs.QList2Table(targets)
	self:sort(target_list, "equip_defense" ,true)
	local no_loss = false
	if self:getOverflow() > 1 or self.player:getHandcardNum() < 2 then
		no_loss = true
	end
	if self.player:hasWeapon("Axe") and self.player:getCardCount(true) > 4 then
		no_loss = true
	end
	if no_loss then
		return target_list[1]
	end
	return {}
end

--邹氏
sgs.ai_skill_invoke.huoshui = true

local qingcheng_skill = {}
qingcheng_skill.name = "qingcheng"
table.insert(sgs.ai_skills, qingcheng_skill)
qingcheng_skill.getTurnUseCard = function(self, inclusive)
	local equipcard
	if self:needToThrowArmor() and self.player:getArmor():isBlack() then
		equipcard = self.player:getArmor()
	else
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("EquipCard") and card:isBlack() then
				equipcard = card
				break
			end
		end
		if not equipcard then
			for _, card in sgs.qlist(self.player:getCards("he")) do
				if card:isKindOf("EquipCard") and card:isBlack() and not card:isKindOf("Armor") and not card:isKindOf("DefensiveHorse") then
					equipcard = card
				end
			end
		end
	end
	if equipcard then
		local card_id = equipcard:getEffectiveId()
		local card_str = ("@QingchengCard=" .. card_id .. "&qingcheng")
		local qc_card = sgs.Card_Parse(card_str)

		assert(qc_card)

		return qc_card
	end

	local handcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(handcards)
	for _, c in ipairs(handcards) do
		if c:isBlack() then
			return sgs.Card_Parse("@QingchengCard=" .. c:getEffectiveId() .. "&qingcheng")
		end
	end
end


sgs.ai_skill_use_func.QingchengCard = function(card, use, self)
	self.qingcheng = nil
	local zhonghui = self.room:findPlayerBySkillName("quanji")
	if zhonghui and zhonghui:getPile("power_pile"):length() > 3 and zhonghui:hasShownAllGenerals() and self:isEnemy(zhonghui) then
		use.card = card
		if not use.isDummy and use.to then
			self.qingcheng = "zhonghui"
			Global_room:writeToConsole("倾城钟会:"..self.qingcheng)
			use.to:append(zhonghui)
		end
		return
	end
	local sunchen = self.room:findPlayerBySkillName("shilu")
	if sunchen and sunchen:getMark("#massacre") > 2  and sunchen:hasShownAllGenerals() and self:isEnemy(sunchen) then
		use.card = card
		if not use.isDummy and use.to then
			self.qingcheng = "sunchen"
			Global_room:writeToConsole("倾城孙綝:"..self.qingcheng)
			use.to:append(sunchen)
		end
		return
	end
	local gongsunyuan = self.room:findPlayerBySkillName("zisui")
	if gongsunyuan and gongsunyuan:getPile("&disloyalty"):length() > 1 and gongsunyuan:hasShownAllGenerals() and self:isEnemy(gongsunyuan) then
		use.card = card
		if not use.isDummy and use.to then
			self.qingcheng = "gongsunyuan"
			Global_room:writeToConsole("倾城公孙渊:"..self.qingcheng)
			use.to:append(gongsunyuan)
		end
		return
	end
	local zhoutai = self.room:findPlayerBySkillName("buqu")
	if zhoutai and zhoutai:hasShownAllGenerals() and (self:isFriend(zhoutai) and zhoutai:getPile("scars"):length() > 3) then
		use.card = card
		if not use.isDummy and use.to then
			self.qingcheng = "zhoutai"
			Global_room:writeToConsole("倾城周泰:"..self.qingcheng)
			use.to:append(zhoutai)
		end
		return
	end

	local dummy_use = {isDummy = true, to = sgs.SPlayerList()}
	local slash = sgs.cloneCard("Slash")
	self:useBasicCard(slash, dummy_use)
	if (dummy_use.card and dummy_use.to:length() > 0) then
		for _, p in sgs.qlist(dummy_use.to) do
			if not self:isFriend(p) and p:hasShownAllGenerals() then
				if p:hasSkill("buqu") and p:getHp() == 1 and sgs.getDefenseSlash(p, self) < 2
				and p:getPile("scars"):length() >= 0 and p:getPile("scars"):length() < 4 then
					use.card = card
					if not use.isDummy and use.to then
						self.qingcheng = "zhoutai"
						Global_room:writeToConsole("倾城周泰:"..self.qingcheng)
						use.to:append(zhoutai)
					end
					return
				end
				local skill_table = (sgs.masochism_skill .. "|" .. sgs.defense_skill .. "|" .. sgs.save_skill):split("|")
				for _, skill_name in ipairs(skill_table) do
					if (p:hasShownSkill(skill_name)) then
						use.card = card
						if ((not use.isDummy) and use.to) then
							self.qingcheng = (p:inHeadSkills(skill_name) and p:getGeneral():objectName() or p:getGeneral2():objectName())
							use.to:append(p)
						end
						return
					end
				end
			end
		end
	end
end

sgs.ai_skill_choice.qingcheng = function(self, choices)
	--Global_room:writeToConsole("倾城选择:"..choices)
	local choice_table = choices:split("+")
	if self.qingcheng and table.contains(choice_table, self.qingcheng) then
		--Global_room:writeToConsole("倾城预选:"..self.qingcheng)
		return self.qingcheng
	end
	local general1 = sgs.Sanguosha:getGeneral(choice_table[1])
	local general2 = sgs.Sanguosha:getGeneral(choice_table[2])
	local m = (sgs.masochism_skill .. "|" .. sgs.defense_skill .. "|" .. sgs.save_skill):split("|")
	for _, sk in ipairs(m) do
		local skill = sgs.Sanguosha:getSkill(sk)
		if general1:getSkillList(true, true):contains(skill) then return choice_table[1] end
		if general2:getSkillList(true, true):contains(skill) then return choice_table[2] end
	end
	return choice_table[#choice_table]
end

sgs.ai_skill_playerchosen["qingcheng_second"] = function(self, targets)
	local zhonghui = self.room:findPlayerBySkillName("quanji")
	if zhonghui and zhonghui:getPile("power_pile"):length() > 3  and zhonghui:hasShownAllGenerals() and self:isEnemy(zhonghui) then
		return zhonghui
	end
	local sunchen = self.room:findPlayerBySkillName("shilu")
	if sunchen and sunchen:getMark("#massacre") > 2  and sunchen:hasShownAllGenerals() and self:isEnemy(sunchen) then
		return sunchen
	end
	local gongsunyuan = self.room:findPlayerBySkillName("zisui")
	if gongsunyuan and gongsunyuan:getPile("&disloyalty"):length() > 1 and gongsunyuan:hasShownAllGenerals() and self:isEnemy(gongsunyuan) then
		return gongsunyuan
	end
	local zhoutai = self.room:findPlayerBySkillName("buqu")
	if zhoutai and zhoutai:hasShownAllGenerals() and (self:isFriend(zhoutai) and zhoutai:getPile("scars"):length() > 3) then
		return zhoutai
	end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

sgs.ai_use_value.QingchengCard = 6
sgs.ai_use_priority.QingchengCard = sgs.ai_use_priority.ArcheryAttack + 0.1
sgs.ai_card_intention.QingchengCard = 100
