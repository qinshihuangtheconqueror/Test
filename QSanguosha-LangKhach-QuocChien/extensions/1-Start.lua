extension = sgs.Package("LK_Diy_1", sgs.Package_GeneralPack, true)
talon=sgs.General(extension,"talon","wei",4,true)
darius=sgs.CreateTriggerSkill{
 
    name = "darius",
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return false
        end
        local death = data:toDeath()
        if death.who:objectName() ~= player:objectName() then
            return self:objectName()
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if player:hasShownSkill(self:objectName()) then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        else
            local invoke = room:askForSkillInvoke(player, self:objectName())
            if not invoke then return false end
        end
        return true
    end,
    on_effect = function(self, event, room, player, data)
        local recover = sgs.RecoverStruct()
        recover.who = player
        room:recover(player, recover)
        local death= data:toDeath()
        if death.who:isFriendWith(player) then
            local recover = sgs.RecoverStruct()
            recover.who = player
            room:recover(player, recover)
            room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
        end
    end,
}
garen=sgs.CreateTriggerSkill{
    name = "garen",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    relate_to_place = "head",
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return false
        end
        if player:getPhase() == sgs.Player_Start then
            if player:getHp() < player:getMaxHp() then
                local alive = room:alivePlayerCount()
                if alive <= player:getMaxHp() then
                    return self:objectName()
                end
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if player:hasShownSkill(self:objectName()) then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        else
            local invoke = room:askForSkillInvoke(player, self:objectName())
            if not invoke then return false end
        end
        return true
    end,
    on_effect = function(self, event, room, player, data)
        --[[
            các hiệu ứng khi kích hoạt kĩ năng.
            1. Bạn hồi 2 máu.
            2. Bạn bổ sung bài trên tay tới giới hạn sinh lực.
            3. Bạn loại bỏ phó tướng.
            4. Bạn mất kĩ năng "darius"
            5. Bạn mất kĩ năng "garen"
            6. Bạn nhận kĩ năng "fiora" và "lux"        ]]
    local recover = sgs.RecoverStruct()
        recover.who = player
        recover.recover = 2
        room:recover(player, recover)
        room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 2))
        player:fillHandCards(player:getMaxHp(), self:objectName())
        player:removeGeneral(false); -- Loại bỏ phó tướng
        room:handleAcquireDetachSkills(player, "-garen|-darius|benghuai|fiora!");

    end,
}
fiora=sgs.CreateTriggerSkill{
    --[[
        1. Khi bạn nhận sát thương, bạn rút 1 lá bài.
        2. KHi giới hạn sinh lực của bạn thay đổi, bạn rút 1 lá bài và bỏ 1 lá bài của một người chơi khác.
    ]]
    name = "fiora",
    events = {sgs.Damaged, sgs.MaxHpChanged},
    frequency = sgs.Skill_Compulsory,
    relate_to_skill = "garen",
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then-- Nếu bạn đã chết hoặc không có kỹ năng này
            return false
        end
        if event == sgs.Damaged then -- Khi bạn nhận sát thương
            return self:objectName()
        elseif event == sgs.MaxHpChanged then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        local invoke = false
        if player:hasShownSkill(self:objectName()) then
            invoke = true
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        else
            invoke = room:askForSkillInvoke(player, self:objectName())
        end

        if invoke then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        if event == sgs.Damaged then
            room:drawCards(player, 1, self:objectName())
        elseif event == sgs.MaxHpChanged then
            room:drawCards(player, 2, self:objectName())
        end
    end,
}

talon:addSkill(darius)
talon:addSkill(garen)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("fiora") then skills:append(fiora) end
if not sgs.Sanguosha:getSkill("benghuai") then skills:append(benghuai) end
sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["talon"] = "Gia Cát Đản",
    -- Tên tướng
    ["#talon"] = "Giới Lộ Hao Lý",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["darius"] = "Công Ngao",
    -- Tên kỹ năng
    [":darius"] = " Khi một người chơi chết, bạn hồi 1 máu và tăng 1 giới hạn sinh lực.",
    ["garen"] = "Cử Nghĩa",
    [":garen"] = "Giai đoạn chuẩn bị, nếu giới hạn sinh lực của bạn nhiều hơn số người chơi còn sống, bạn hồi 2 sinh lực, bổ sung bài trên tay tới giới hạn sinh lực, loại bỏ phó tướng, mất kĩ năng Công Ngao và Cử Nghĩa, nhận kĩ năng Băng Phôi và Uy Trọng.",
    ["fiora"] = "Uy Trọng",
    [":fiora"] = "Khi bạn nhận sát thương, bạn rút 1 lá bài. Khi giới hạn sinh lực của bạn thay đổi, bạn rút 1 lá bài và bỏ 1 lá bài của một người chơi khác.",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
camphunhan=sgs.General(extension,"camphunhan","shu",3,false)
    thucthan = sgs.CreateTriggerSkill{
        name = "thucthan",
        events = {sgs.HpRecover},
        frequency = sgs.Skill_Frequent,
        can_trigger = function(self, event, room, player, data)
            if not player or player:isDead() or not player:hasSkill(self:objectName()) then
                return false
            end
            
            local recover = data:toRecover()
            if recover.who and recover.who:objectName() == player:objectName() then
                return self:objectName()
            end
            
            return ""
        end,
        on_cost = function(self, event, room, player, data)
            if room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
            return false
        end,
        on_effect = function(self, event, room, player, data)
            local listTarget = sgs.SPlayerList()  -- Định nghĩa listTarget
            local all_players = room:getAlivePlayers()
            for _, p in sgs.qlist(all_players) do
                listTarget:append(p)
            end
            
            local target = room:askForPlayerChosen(player, listTarget, self:objectName(), "Chọn 1 người chơi để thực hiện kỹ năng 'thucthan'", true, true)
            if target then
                local choice = room:askForChoice(target, self:objectName(), "recover+draw")
                if choice == "recover" then
                    local recover = sgs.RecoverStruct()
                    recover.who = player
                    room:recover(target, recover)
                elseif choice == "draw" then
                    room:drawCards(target, 2, self:objectName())
                end
            end
        end,
    }
thantri=sgs.CreateTriggerSkill{
    --đầu lượt, bạn có thể bỏ tất cả bài trên tay. Nếu theo cách này bạn bỏ đi số bài >= số máu của bạn, bạn hồi 1 máu.
    name = "thantri",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return false
        end
        
        if player:getPhase() == sgs.Player_Start then
            return self:objectName()
        end
        
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        local handcard_num = player:getHandcardNum()
        local hp = player:getHp()
        if handcard_num >= hp then
            local recover = sgs.RecoverStruct()
            recover.who = player
            room:recover(player, recover)
        end
        player:throwAllHandCards()
    end,
}
    

camphunhan:addSkill(thucthan)
camphunhan:addSkill(thantri)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["camphunhan"] = "Cam Phu Nhân Giới",
    -- Tên tướng
    ["#camphunhan"] = "Nội trợ hiền hậu",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["thucthan"] = "Thục Thận",
    -- Tên kỹ năng
    [":thucthan"] = " Khi bạn hồi sinh lực, bạn có thể chọn một người chơi, lệnh họ hồi 1 máu/rút 2 lá bài",
    ["thantri"] = "Thần Trí",
    [":thantri"] = "Đầu lượt, bạn có thể bỏ tất cả bài trên tay. Nếu theo cách này bạn bỏ đi số bài >= số máu của bạn, bạn hồi 1 máu.",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
masew=sgs.General(extension,"masew","qun",4,true)
--khoảng cách từ bạn tới người có sinh lưc<=bạn là 1.
function sgs.CreatedragonSkill(name)
    local dragon_skill = {} 
    dragon_skill.name = "LuaDragon" .. name
    dragon_skill.correct_func = function(self, from, to)
        if from:hasShownSkill(self) then
            if to:getHp() <= from:getHp() then
                return -999
            end
        end
        return 0
    end
    return sgs.CreateDistanceSkill(dragon_skill)
end
LuaDragon_masew = sgs.CreatedragonSkill("masew")
masew:addSkill(LuaDragon_masew)

thecuu=sgs.CreateTargetModSkill{
    name = "thecuu",
    pattern = "Slash",
    extra_target_func = function(self, from, card)
        if from:hasShownSkill(self) then
           local n = 0
              --khi bạn sử dụng slash, bạn có thể chọn thêm X mục tiêu (X là số máu bạn đã mất)
              n = from:getLostHp()
                return n
        end
        return 0
    end,
        
}
masew:addSkill(thecuu)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["masew"] = "Mã Siêu Quần",
    -- Tên tướng
    ["#masew"] = "Tây Lương Đích Mãnh Sư",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["thecuu"] = "Thệ Cừu",
    -- Tên kỹ năng
    [":thecuu"] = "Khi bạn sử dụng [Sát], bạn có thể chọn thêm X mục tiêu (X là số máu bạn đã mất)",
    ["LuaDragon_masew"] = "Truy kích",
    [":LuaDragon_masew"] = "Khoảng cách từ bạn tới người có sinh lực <=bạn là 1.",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
taonhan=sgs.General(extension,"taonhan","wei",4,true)
hoivi=sgs.CreateTriggerSkill{
    --[[ 1. Cuối lượt, bạn có thẻ rút X+2 lá bài, sau đó, bạn lật mặt tướng. 
         2. Nếu vậy, đầu giai đoạn rút bài lượt sau của bạn, bạn phải bỏ X lá(X là số lá vũ khí trên bàn.)]]
    name = "hoivi",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return false
        end
        
        if player:getPhase() == sgs.Player_Finish then
            return self:objectName()
        end
        if player:getPhase() == sgs.Player_Draw and player:getMark("@taonhan") >= 1 then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if player:getPhase() == sgs.Player_Finish then
            if room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
        elseif player:getPhase() == sgs.Player_Draw then
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        local weapon_count = 0
        local equips = player:getEquips()
        
        for _, equip in sgs.qlist(equips) do
            if equip:isKindOf("Weapon") then
                weapon_count = weapon_count + 1
            end
        end
        if player:getPhase() == sgs.Player_Finish then
            room:drawCards(player, weapon_count + 2, self:objectName())
            player:turnOver()
            room:setPlayerMark(player, "@taonhan", player:getMark("@taonhan") + 1)
        elseif player:getPhase() == sgs.Player_Draw then
            room:setPlayerMark(player, "@taonhan", player:getMark("@taonhan") - 1)
            room:askForDiscard(player, self:objectName(), weapon_count, weapon_count, false, true)
        end
    end,
}
taonhan:addSkill(hoivi)
cuthu=sgs.CreateOneCardViewAsSkill{

    name = "cuthu",
    filter_pattern = ".|.|.|equipped",
    response_or_use = true,

    view_as = function(self, card)
    
        --Với chuyển hóa trực tiếp 1 lá thành lá khác thì nên set chất và điểm cho lá đó trực tiếp. Để -1 như ban đầu là sai vì vị trí đó là chất, không phải điểm mà -1.
        --local new_card = sgs.Sanguosha:cloneCard("nullification", -1)
        local nullification = sgs.Sanguosha:cloneCard("nullification", card:getSuit(), card:getNumber())
        
        --Nêu dùng effectiveId thay cho id, để hoạt động luôn chuẩn. một số case hiếm sẽ bị sai nếu dùng ID.
        nullification:addSubcard(card:getEffectiveId())
        nullification:setSkillName(self:objectName())
        nullification:setShowSkill(self:objectName())
        return nullification
    end,
    
    --Vô giải không phải lá chủ động, cần khóa kỹ năng khi rảnh trong giai đoạn ra bài
    enabled_at_play = function(self,player)
        return false
    end,
    
    enabled_at_response = function(self,player,pattern)
        return pattern == "nullification" and player:getHandcardNum() > player:getHp();
    end,
    
    enabled_at_nullification = function(self,player)
        return player:getHandcardNum() > player:getHp() and player:hasEquip()
    end,
}
taonhan:addSkill(cuthu)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["taonhan"] = "Tào Nhân SP",
    -- Tên tướng
    ["#taonhan"] = "Tào Nhân Đích Đại Tướng Quân",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["hoivi"] = "Hội Vi",
    -- Tên kỹ năng
    [":hoivi"] = "Cuối lượt, bạn có thẻ rút X+2 lá bài, sau đó, bạn lật mặt tướng. Nếu vậy, đầu giai đoạn rút bài lượt sau của bạn, bạn phải bỏ X lá(X là số lá vũ khí trên bàn.)",
    ["yanzheng"] = "Cự Thủ",
    [":yanzheng"] = "Bạn có thể sử dụng thẻ trang bị như Vô Giải Khả kích nếu số lá trên tay > số máu.",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
linhthu=sgs.General(extension,"linhthu","qun",3,true)
kietduyen=sgs.CreateTriggerSkill{
    --[[1.Khi bạn gây sát thương cho người khác có số máu >= bạn, bạn có thể tự bỏ 1 thẻ đen, để sát thương này+1.
    2.Khi bạn nhận sát thương từ một người có số máu >=bạn, bạn có thể tự bỏ 1 thẻ đỏ, để sát thương này-1.]]
    name = "kietduyen",
    events = {sgs.DamageCaused, sgs.DamageInflicted},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return false
        end
        
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.to:getHp() >= player:getHp() then
                return self:objectName()
            end
        elseif event == sgs.Inflicted then
            local damage = data:toDamage()
            if damage.from and damage.from:getHp() >= player:getHp() then
                return self:objectName()
            end
        end
        
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if event == sgs.DamageCaused then
            if room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
        elseif event == sgs.DamageInflicted then
            if room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
        end
        return false
    end,  
    on_effect = function(self, event, room, player, data)
        local card = nil
        if event == sgs.DamageCaused then
            card = room:askForCard(player, ".|black|.|hand", "@kietduyen", data, sgs.Card_MethodDiscard)
            if card then
                local damage = data:toDamage()
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        elseif event == sgs.DamageInflicted then
            card = room:askForCard(player, ".|red|.|hand", "@kietduyen", data, sgs.Card_MethodDiscard)
            if card then
                local damage = data:toDamage()
                damage.damage = damage.damage - 1
                data:setValue(damage)
            end
        end
    end,
    


}
linhthu:addSkill(kietduyen)
phantam=sgs.CreateTriggerSkill{
    --Sau khi bạn giết 1 người chơi khác, bạn có thể đổi phó tướng.
    name = "phantam",
    events = {sgs.Death},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) or player:getMark("@linhthu") > 1 then
            return ""
        end
        
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then
            return ""
        end
        
        return self:objectName()
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        if player:canTransform() then
            room:transformDeputyGeneral(player)
        end
        room:setPlayerMark(player, "@linhthu", player:getMark("@linhthu") + 1)
    end,
}
linhthu:addSkill(phantam)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["linhthu"] = "Linh Thư",
    -- Tên tướng
    ["#linhthu"] = "Tình Tùy Mộng Thệ",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["kietduyen"] = "Kiệt duyên",
    -- Tên kỹ năng
    [":kietduyen"] = "Khi bạn gây sát thương cho người khác có số máu >= bạn, bạn có thể tự bỏ 1 thẻ đen, để sát thương này+1. Khi bạn nhận sát thương từ một người có số máu >=bạn, bạn có thể tự bỏ 1 thẻ đỏ, để sát thương này-1.",
    ["phantam"] = "Phần tâm",
    [":phantam"] = "Sau khi bạn giết 1 người chơi khác, bạn có thể đổi phó tướng.",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
--[[

taohuu=sgs.General(extension,"taohuu","wei",4,true)
function sgs.CreatehorseSkill(name)
    local horse_skill = {} 
    horse_skill.name = "Luahorse" .. name
    horse_skill.correct_func = function(self, from, to)
        if from:hasShownSkill(self) then
            --Khoảng cách từ bạn tới người chơi khác -X (X là sinh lực bạn đã mất)
            return -from:getLostHp()
        end
        return 0
    end
    return sgs.CreateDistanceSkill(horse_skill)
end
LuaHorse_taohuu = sgs.CreatehorseSkill("taohuu") 
taohuu:addSkill(LuaHorse_taohuu)
--[[
    class Qingxi : public TriggerSkill
{
public:
    Qingxi() : TriggerSkill("qingxi")
    {
        events << DamageCaused;
    }

//    virtual int getPriority(TriggerEvent triggerEvent) const
//    {
//        if (triggerEvent == DamageCaused)
//            return 5;
//        return TriggerSkill::getPriority(triggerEvent);
//    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (TriggerSkill::triggerable(player) && player->getWeapon() && damage.card && damage.card->isKindOf("Slash")
                && !damage.chain && !damage.transfer && damage.to->isAlive())
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *target = damage.to;
        if (target->isAlive() && room->askForSkillInvoke(player, objectName(), QVariant::fromValue(target))) {
            player->broadcastSkillInvoke(objectName());
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
            const Weapon *card = qobject_cast<const Weapon *>(player->getWeapon()->getRealCard());
            int x = card->getRange();
            if (room->askForDiscard(target, objectName(), x, x, true, false, "@qingxi-discard")) {
                if (player->getWeapon())
                    room->throwCard(player->getWeapon(), player, target);
            } else {
                ++damage.damage;
                data = QVariant::fromValue(damage);
            }
        }
        return false;
    }
};
]]
--[[qingxi=sgs.CreateTriggerSkill{
    name="qingxi",
    events={sgs.DamageCaused},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) or not player:getWeapon() then
            return ""
        end
        
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel") and not damage.chain and not damage.transfer and damage.to:isAlive() then
            return self:objectName()
        end
        
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return ""
    end,
    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        local target = damage.to
        if target:isAlive() then
           local range = player:getWeapon():getRange()
           local handcard_num = target:getHandcardNum()
            local choice = room:askForChoice(target, self:objectName(), "discard+damage")
            if choice == "discard" then
                room:askForDiscard(target, self:objectName(), range, range, true, false, "@qingxi-discard")
                if player:getWeapon() then
                    room:throwCard(player:getWeapon(), player, target)
                end
            else
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
    end,

}
taohuu:addSkill(qingxi)]]
congtontoan=sgs.General(extension,"congtontoan","qun",4,true)
function sgs.CreatemaSkill(name)
    local ma_skill = {} 
    ma_skill.name = "Luama" .. name
    ma_skill.correct_func = function(self, from, to)
        
        if from:hasShownSkill(self) then
            --[[1. khoảng cách từ bạn tới người chơi  khác -X (X là số máu của bạn-1). 
            2.Người chơi khác tính khoảng cách tới bạn +Y(Y là số máu đã mất của bạn -1)
            ]]
        return -from:getHp() +1  
        end
        return 0
    end
    return sgs.CreateDistanceSkill(ma_skill)
end
Luama_congtontoan = sgs.CreatemaSkill("congtontoan")
congtontoan:addSkill(Luama_congtontoan)
function sgs.CreatemaSkill(name)
    local ma1_skill = {} 
    ma1_skill.name = "Luama1" .. name
    ma1_skill.correct_func = function(self, to, from)
        
        if from:hasShownSkill(self) then
            --[[1. khoảng cách từ bạn tới người chơi  khác -X (X là số máu của bạn-1). 
            2.Người chơi khác tính khoảng cách tới bạn +Y(Y là số máu đã mất của bạn -1)
            ]]
        return to:getLostHp() -1 
        end
        return 0
    end
    return sgs.CreateDistanceSkill(ma1_skill)
end
Luama1_congtontoan = sgs.CreatemaSkill("congtontoan")
congtontoan:addSkill(Luama1_congtontoan)
kieumanh = sgs.CreateTriggerSkill{
    -- sau khi bạn gây sát thương bằng slash đen cho 1 người chơi, bạn có thể chọn 1 lá trong vùng trang bị của họ, bỏ lá này. Nếu lá này là kind of Horse, bạn thu lấy nó.
    name = "kieumanh",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return false
        end
        
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card:isKindOf("Slash") and damage.card:isBlack() then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if event == sgs.DamageCaused then
            if room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        local target = damage.to
        local equips = target:getEquips()
        local card = room:askForCardChosen(player, target, "e", self:objectName())
        if card then
                room:throwCard(card, target, player)
         
        end
        if card:isKindOf("Horse") then
            room:obtainCard(player, card)
        end
    end,
}

    
congtontoan:addSkill(kieumanh)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["congtontoan"] = "Công Tôn Toản",
    -- Tên tướng
    ["#congtontoan"] = "Bạch Mã tướng quân",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["kieumanh"] = "Kiêu Mãnh",
    -- Tên kỹ năng
    [":kieumanh"] = "Sau khi bạn gây sát thương bằng sát đen cho 1 người chơi, bạn có thể chọn 1 lá trong vùng trang bị của họ, bỏ lá này. Nếu lá này là Tọa Kỵ, bạn thu lấy nó.",
    ["Luama_congtontoan"] = "Bạch Mã Thuật",
    [":Luama_congtontoan"] = "Khoảng cách từ bạn tới người chơi khác -X (X là số máu của bạn-1).",
    ["Luama1_congtontoan"] = "Mã",
    [":Luama1_congtontoan"] = "Người chơi khác tính khoảng cách tới bạn +Y(Y là số máu đã mất của bạn -1)",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
quansach=sgs.General(extension,"quansach","shu",4,true)
LuaYTZhenwei = sgs.CreateTriggerSkill{
    name = "LuaYTZhenwei" ,
    events = {sgs.SlashMissed} ,
    frequency = sgs.Skill_Frequent ,
    can_trigger = function(self, event, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName())  then
            return false
        end
        
        if event == sgs.SlashMissed then
            local effect = data:toSlashEffect()
            if effect.to:objectName() == player:objectName() then
                return self:objectName()
            end
        end
        return ""
    end ,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
    return false
end,
on_effect = function(self, event, room, player, data)
    local effect = data:toSlashEffect()
     --you can use a Slash on your hand to the target, if this slash deal damage, you draw 1 card.
    local slash = room:askForCard(player, "slash", "@LuaYTZhenwei", data, sgs.Card_MethodUse, effect.to)
    if slash then
        local use = sgs.CardUseStruct()
        use.from = player
        use.to:append(effect.to)
        use.card = slash
        room:useCard(use, false)
        local damage = data:toDamage()
        if damage.damage > 0 then
            room:drawCards(player, 1, self:objectName())
        end
end
end,
        }

quansach:addSkill(LuaYTZhenwei)
phuluc2=sgs.CreateTriggerSkill{
    --khi một người chơi nữ chết, bạn có thể hồi 1 máu, rút 3 lá bài.
    name = "phuluc2",
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return false
        end
        local death = data:toDeath()
        if death.who:objectName() ~= player:objectName() and death.who:isFemale() then
            return self:objectName()
        end
        return ""
    end,

    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
                local recover = sgs.RecoverStruct()
                recover.who = player
                room:recover(player, recover)
                room:drawCards(player, 3, self:objectName())
          end,

}
    
quansach:addSkill(phuluc2)
function sgs.CreatenuSkill(name)
    local nu_skill = {} 
    nu_skill.name = "Luanu" .. name
    nu_skill.correct_func = function(self, from, to)
        if from:hasShownSkill(self) then
            if to:isFemale() then
                return -999
            end
        end
        return 0
    end
    return sgs.CreateDistanceSkill(nu_skill)
end
Luanu_quansach = sgs.CreatenuSkill("quansach")
quansach:addSkill(Luanu_quansach)

sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["quansach"] = "Quan Sách",
    -- Tên tướng
    ["#quansach"] = "Thích Thảng Kiết Hiệp",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["LuaYTZhenwei"] = "Trấn Nam",
    -- Tên kỹ năng
    [":LuaYTZhenwei"] = "Khi Sát của bạn bị thiểm triệt tiêu, bạn có thể tự bỏ 1 lá bài, xem như sử dụng Sát lên cùng mục tiêu. Nếu lá sát này tạo thành sát thương, bạn rút 1 lá",
    ["phuluc2"] = "Phụ Lục",
    [":phuluc2"] = "Khi một người chơi chết, bạn có thể chọn: hồi 1 máu hoặc rút 3 lá bài. Nếu người này là nữ, bạn chấp hành cả 2 hạng mục",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}

--[[boluyensu=sgs.General(extension,"boluyensu","wu",3,true)
antuat = sgs.CreateOneCardViewAsSkill{
    name = "antuat" ,
    filter_pattern = ".!" ,
    view_as = function(self, card)
        local antuat_card = antuatcard:clone()
        antuat_card:addSubcard(card:getId())
        return antuat_card
    end ,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#antuatcard")
    end
}
antuatcard=sgs.CreateSkillCard{
    
    name = "antuatcard",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        if #targets > 0 then
            return false
        end
        if to_select:objectName() == sgs.Self:objectName() then
            return false
        end
        if to_select:isKongcheng() then
            return false
        end
        return true
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local to = room:askForPlayerChosen(targets[1], room:getOtherPlayers(target), self:objectName(), "@antuat-card:" .. target:objectName(), true)
        local card_id = room:askForCardChosen(targets[1], to, "h", self:objectName())
        local card = sgs.Sanguosha:getCard(card_id)
        local suit = card:getSuit()
        local log = sgs.LogMessage()
        log.type = "#antuat"
        log.from = targets[1]
        log.to:append(to)
        log.arg = self:objectName()
        room:sendLog(log)
        room:moveCardTo(card, targets[1], sgs.Player_PlaceHand, false)
        if suit ~= sgs.Card_Spade then
            room:drawCards(source, 1, self:objectName())
        end
        if to:getHandcardNum() > source:getHandcardNum() then
            room:drawCards(to, 1, self:objectName())
        end
    end,
}
boluyensu:addSkill(antuat)
]]
lacthong=sgs.General(extension,"lacthong","wu",3,true)
chieutuyet=sgs.CreateTriggerSkill{
    --khi bạn gây sát thương, bạn có thể chặn sát thương này lại, sau đó, bạn nhận 1 Dragon mark (Nhận tối đa 2 Dragon mark)
    name = "chieutuyet",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) or player:getMark("@dragon") >= 2 then
            return false
        end
        
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from:objectName() == player:objectName() then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if event == sgs.DamageCaused then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        local target = damage.to
        local log = sgs.LogMessage()
        log.type = "#chieutuyet"
        log.from = player
        log.to:append(target)
        log.arg = self:objectName()
        room:sendLog(log)
        damage.damage = 0
        data:setValue(damage)
        room:setPlayerMark(player, "@dragon", player:getMark("@dragon") + 1)
        return true
    end,
}
lacthong:addSkill(chieutuyet)
namchinh=sgs.CreateTriggerSkill{
    --[[Tỏa định kĩ: 
    1. Khi bạn nhận sát thương, bạn bỏ 1 dragon mark, sát thương này -1. 
    2. Mỗi khi bạn mất đi 1 dragon mark, bạn rút 1 lá bài (2 nếu sinh lực của bạn < nguồn sát thương) 
    3.Giai đoạn rút bài ,nếu bạn có dragon mark, bạn rút thêm X lá bài, giới hạn trữ bài + X (X là số dragon mark bạn có)
    ]]
    name = "namchinh",
    events = {sgs.DamageInflicted, sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) or player:getMark("@dragon") == 0 then
            return false
        end
        
        if event == sgs.DamageInflicted then
            return self:objectName()
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Draw then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if event == sgs.DamageInflicted then
                return true
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Draw then
                    return true
                end
            end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            local log = sgs.LogMessage()
            log.type = "#namchinh"
            log.from = player
            log.arg = self:objectName()
            room:sendLog(log)
            damage.damage = damage.damage - 1
            data:setValue(damage)
            room:setPlayerMark(player, "@dragon", player:getMark("@dragon") - 1)
            room:drawCards(player, 1, self:objectName())
            return true
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Draw then
                local count = player:getMark("@dragon")
                room:drawCards(player, count, self:objectName())
            end
        end
    end,
}
lacthong:addSkill(namchinh)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["lacthong"] = "Lạc Thống",
    -- Tên tướng
    ["#lacthong"] = "Kiển Ngạc Phỉ Cung",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["chieutuyet"] = "Chiêu Tuyệt",
    -- Tên kỹ năng
    [":chieutuyet"] = "Khi bạn gây sát thương, bạn có thể chặn sát thương này lại, sau đó, bạn nhận 1 tiêu kí Tuyệt (Nhận tối đa 2 Tuyệt)",
    ["namchinh"] = "Nam Chinh",
    [":namchinh"] = "Tỏa định kĩ: 1. Khi bạn nhận sát thương, bạn bỏ 1 Tuyệt, sát thương này -1. 2. Mỗi khi bạn mất đi 1 Tuyệt, bạn rút 1 lá bài 3.Giai đoạn rút bài ,nếu bạn có Tuyệt, bạn rút thêm X lá bài (X là số Tuyệt bạn có)",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
taoanh=sgs.General(extension,"taoanh","wei",4,false)
taoanh:addCompanion("caocao")
taoanh:addCompanion("caopi")

phucgian=sgs.CreateTriggerSkill{
    --Khi sinh lực của bạn >= 2, bạn nhận kĩ năng jianxiong, khi sinh lực của bạn <=2, bạn nhận kĩ năng xingshang
    name = "phucgian",
    events = {sgs.HpChanged},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return false
        end
        
        if event == sgs.HpChanged then
            if player:getHp() >= 2 then
                if not player:hasSkill("jianxiong") then
                    return self:objectName()
                end
            elseif player:getHp() <= 2 then
                if not player:hasSkill("xingshang") then
                    return self:objectName()
                end
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if event == sgs.HpChanged then
            if player:getHp() >= 2 then
                    return true
                end
            elseif player:getHp() <= 2 then
                    return true
                end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        if event == sgs.HpChanged then
            if player:getHp() >= 2 then
              room:handleAcquireDetachSkills(player,"jianxiong")
            elseif player:getHp() <= 2 then
              room:handleAcquireDetachSkills(player,"-jianxiong|xingshang!")
            end
        end
    end,

}
taoanh:addSkill(phucgian)

LuaFanjianCard = sgs.CreateSkillCard{
    name = "LuaFanjianCard",	
    on_effect = function(self, effect)
        local player = effect.from
        local target = effect.to
        local room = player:getRoom()
        local card_id = target:getRandomHandCardId()
        local card = sgs.Sanguosha:getCard(card_id)
        local suit = room:askForSuit(player, "LuaFanjian")
        room:getThread():delay()
        room:showCard(target, card_id)
        if card:getSuit() == suit then
        --nếu là cơ thì bạn hồi 1 máu
            if suit == sgs.Card_Heart then
                local recover = sgs.RecoverStruct()
                recover.who = player
                room:recover(player, recover)
            elseif suit == sgs.Card_Diamond then
                room:drawCards(player, 1, "LuaFanjian")
            elseif suit == sgs.Card_Club then
                room:askForDiscard(target, "LuaFanjian", 1, 1, false, true)
            elseif suit == sgs.Card_Spade then
                --bạn nhận feiying
                room:acquireSkill(player, "feiying")
             end
    end

end,
}
LuaFanjian = sgs.CreateZeroCardViewAsSkill{
    name = "LuaFanjian",	
    view_as = function()
        return LuaFanjianCard:clone()
    end,	
    enabled_at_play = function(self, player)
        return (not player:isKongcheng()) and (not player:hasUsed("#LuaFanjianCard"))
    end
}
ngao=sgs.CreateTriggerSkill{
    --sau khi bạn gây sát thương cho 1 người chơi, bạn có thể chọn 1 suit, sau đó chọn 1 lá trên tay người chơi này và mở ra. Nếu suit bạn chọn và suit lá bài mở ra giống nhau: là heart, bạn hồi 1 máu, spade bạn rút 1 lá, club người chơi này turn over, diamond bạn nhận kĩ năng tuxi
    name = "ngao",
    events = {sgs.DamageCaused,sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return false
        end
        
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from:objectName() == player:objectName() and player:getMark("@taoanh") == 0 then
                return self:objectName()
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if event == sgs.DamageCaused then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                return true
            end
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        if event==sgs.DamageCaused then
        local damage = data:toDamage()
        local target = damage.to
        local card_id = room:askForCardChosen(player, target, "h", self:objectName())
        local card = sgs.Sanguosha:getCard(card_id)
        local suit = room:askForSuit(player, "ngao")
        room:showCard(target, card_id)
        if card:getSuit() == suit then
            if suit == sgs.Card_Heart then
                local recover = sgs.RecoverStruct()
                recover.who = player
                room:recover(player, recover)
            elseif suit == sgs.Card_Diamond then
                room:drawCards(player, 1, "ngao")
            elseif suit == sgs.Card_Club then
                target:turnOver()
            elseif suit == sgs.Card_Spade then
                room:handleAcquireDetachSkills(player,"feiying")
            end
        end
        room:setPlayerMark(player, "@taoanh", player:getMark("@taoanh") + 1)
        
    elseif event==sgs.EventPhaseStart then
        room:handleAcquireDetachSkills(player,"-feiying")
        room:setPlayerMark(player, "@taoanh", 0)
    end
    end,
}
taoanh:addSkill(ngao)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["taoanh"] = "Tào Anh",
    -- Tên tướng
    ["#taoanh"] = "Thiên Hạ Đệ Nhất Thần Thương",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["phucgian"] = "Phục Gian",
    -- Tên kỹ năng
    [":phucgian"] = "Khi sinh lực của bạn >= 2, bạn nhận kĩ năng Gian Hùng, khi sinh lực của bạn <=2, bạn nhận kĩ năng Hành Thương",
    ["ngao"] = "Lăng Nhân",
    [":ngao"] = "Sau khi bạn gây sát thương cho 1 người chơi, bạn có thể chọn 1 chất, sau đó chọn 1 lá trên tay người chơi này và mở ra. Nếu chất bạn chọn và chất lá bài mở ra giống nhau: là Cơ, bạn hồi 1 máu, Rô bạn rút 1 lá, Chuồn người chơi này lật mặt tướng, Bích bạn nhận kĩ năng Phi Ảnh tới hết lượt sau",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}

taothuan=sgs.General(extension,"taothuan","wei",4,true)
taothuan:addCompanion("caocao")
taothuan:addCompanion("caoren")
function sgs.CreateloveSkill(name)
    local love_skill = {} 
    love_skill.name = "LuaLove" .. name
    love_skill.correct_func = function(self, from, to)
        if from:hasShownSkill(self) then
            if to:getHandcardNum() >= from:getHandcardNum() then
                return -999
            end
        end
        return 0
    end
    return sgs.CreateDistanceSkill(love_skill)
end
LuaLove_taothuan = sgs.CreateloveSkill("taothuan")
taothuan:addSkill(LuaLove_taothuan)
thiengiap=sgs.CreateTriggerSkill{
    --đầu lượt, bạn có thể lệnh bạn và tất cả người chơi cùng thế lực rút 1 lá và bỏ 1 lá. Nếu lá bạn bỏ là:
    --1. Cơ bản: bạn rút 1 lá bài.
    --2. Trang bị: bạn xem như sử dụng 1 Slash
    --3. Cẩm nang: bạn hủy 1 lá của 1 người chơi khác.
  name="thiengiap",
    events={sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) or player:getPhase() ~= sgs.Player_Start then
            return ""
        end
        return self:objectName()
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return ""
    end,
    on_effect = function(self, event, room, player, data) 
        room:drawCards(player, 1, self:objectName())
        local card = room:askForCard(player, ".", "@thiengiap", sgs.QVariant(), sgs.Card_MethodDiscard)
        if card:isKindOf("BasicCard") then
            room:drawCards(player, 1, self:objectName())
        elseif card:isKindOf("EquipCard") then
            local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@thiengiap", true)
            slash:setSkillName(self:objectName())
            local use = sgs.CardUseStruct()
            use.from = player
            use.to: append(target)
            use.card = slash
            room:useCard(use, false)
        elseif card:isKindOf("TrickCard") then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@thiengiap", true)
            local card_id = room:askForCardChosen(player, target, "h", self:objectName())
            room:throwCard(card_id, target, player)
        end
        
        local players = room:getOtherPlayers(player)
        for _,p in sgs.qlist(players) do
        if p:isFriendWith(player) then
                room:drawCards(p, 1, self:objectName())
                room:askForDiscard(p, self:objectName(), 1, 1, false, true)
    end

end
end,
       
       
}
taothuan:addSkill(thiengiap)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["taothuan"] = "Tào Thuần",
    -- Tên tướng
    ["#taothuan"] = "Hổ báo Kỵ thủ",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["LuaLove_taothuan"] = "Hổ Kỵ",
    -- Tên kỹ năng
    [":LuaLove_taothuan"] = "Tỏa định kĩ: Khoảng cách từ bạn tới người chơi có bài trên tay không lớn hơn bạn là 1 ",
    ["thiengiap"] = "Thiên Giáp",
    [":thiengiap"] = "đầu lượt, bạn có thể lệnh bạn và tất cả người chơi cùng thế lực rút 1 lá và bỏ 1 lá. Nếu lá bạn bỏ là: 1. Cơ bản: bạn rút 1 lá bài. 2. Trang bị: bạn xem như sử dụng 1 Sát. 3. Cẩm nang: bạn hủy 1 lá của 1 người chơi khác.",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
quythuoc=sgs.General(extension,"quythuoc","wei",4,true)
quythuoc:addCompanion("caozhen")
quythuoc:setHeadMaxHpAdjustedValue(-1);
phunghu=sgs.CreateTriggerSkill{
    --Khi gây sát thương cho 1 người khác bằng lá [Sát] đỏ, bạn có thể chặn sát thương lại và lệnh người đó chọn: bỏ tất cả bài trên tay (ít nhất 1 lá) hoặc loại bỏ phó tướng.
    name = "phunghu",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_NotFrequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return false
        end
        
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") and not damage.card:isBlack() then
            return self:objectName()
        end
        
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
        local target = damage.to
        local choice = room:askForChoice(target, self:objectName(), "discard+remove")
        if choice == "discard" then
            local handcard_num = target:getHandcardNum()
            if handcard_num > 0 then
                room:askForDiscard(target, self:objectName(), handcard_num, handcard_num, false, true)
            end
        elseif choice == "remove" then
            target:removeGeneral(false)
        end
        return true
    end,


    
}
quythuoc:addSkill(phunghu)
phungvu=sgs.CreateTriggerSkill{
    --đầu lượt, bạn có thể đặt chồng tướng hoặc tự giảm 1 sinh lực.Nếu vậy, bạn chọn và nhận 1 trong các kỹ năng sau đến hết lượt: xunxun, quhu, luoyi, shensu, jushou. Sau đó, bạn có thể tự giảm 1 máu, chọn và nhận thêm 1 kỹ năng (theo cách này, không thể nhận kỹ năng đã có trên bàn).
    name = "phungvu",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    relate_to_place = "head",

    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return false
        end
        
        if player:getPhase() == sgs.Player_Start or player:getPhase()==sgs.Player_Finish then
            return self:objectName()
        end
        
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if player:getPhase() == sgs.Player_Start then
            if room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
        elseif player:getPhase() == sgs.Player_Finish then
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        if player:getPhase() == sgs.Player_Start then
        local skill_list = {"qiangxi", "quhu", "luoyi", "shensu", "jushou", "huyuan"}
            local skill_name = room:askForChoice(player, self:objectName(), table.concat(skill_list, "+"))
            room:handleAcquireDetachSkills(player, skill_name)
            player:hideGeneral(false)
            player:setPlayerDisableShow(player,"d",self:objectName())
            --sau đó, họ có thể tự giảm 1 máu, chọn và nhận thêm 1 kỹ năng (theo cách này, không thể nhận kỹ năng đã có trên bàn).  
            if room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName(), player)
                local skill_list = {"qiangxi", "quhu", "luoyi", "shensu", "jushou", "huyuan"}
                local skill_name = room:askForChoice(player, self:objectName(), table.concat(skill_list, "+"))
                room:handleAcquireDetachSkills(player, skill_name)
                local recover = sgs.RecoverStruct()
            recover.who = player
            room:loseHp(player, 1)
            end
        elseif player:getPhase() == sgs.Player_Finish then
        room:handleAcquireDetachSkills(player, "-qiangxi|-quhu|-luoyi|-shensu|-jushou|-huyuan")
        --cho phép người chơi mở deputy khi kết thúc lượt

        end
    end,
}
quythuoc:addSkill(phungvu)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["quythuoc"] = "Tào Sảng",
    -- Tên tướng
    ["#quythuoc"] = "Thác Cô Phụ Chính",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["phunghu"] = "Phụng Hư",
    -- Tên kỹ năng
    [":phunghu"] = "Khi gây sát thương cho 1 người khác bằng lá [Sát] đỏ, bạn có thể chặn sát thương lại và lệnh người đó chọn: bỏ tất cả bài trên tay (ít nhất 1 lá) hoặc loại bỏ phó tướng.",
    ["phungvu"] = "Phùng Vũ",
    [":phungvu"] = "đầu lượt, bạn có thể úp phó tướng đến hết lượt.Nếu vậy, bạn chọn và nhận 1 trong các kỹ năng sau đến hết lượt: xunxun, quhu, luoyi, shensu, jushou. Sau đó, bạn có thể tự giảm 1 máu, chọn và nhận thêm 1 kỹ năng (theo cách này, không thể nhận kỹ năng đã có trên bàn).",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}

bangduccong=sgs.General(extension,"bangduccong","qun",3,true)
LuaZhihengCard = sgs.CreateSkillCard{
    name = "LuaZhihengCard",
    target_fixed = true,
    mute = true,
    on_use = function(self, room, source)
        if source:isAlive() then
            local judge = sgs.JudgeStruct()
            judge.pattern = "."
            judge.good = true
            judge.reason = self:objectName()
            judge.who = source
            room:judge(judge)
            if judge.card:getSuit() == sgs.Card_Heart then
                local target = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName(), "@LuaZhiheng", true)
                if not target then return end -- Kiểm tra nếu người chơi chọn hủy kích hoạt
                local recover = sgs.RecoverStruct()
                recover.who = target
                room:recover(target, recover)
            elseif judge.card:getSuit() == sgs.Card_Diamond then
                local target = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName(), "@LuaZhiheng", true)
                if not target then return end -- Kiểm tra nếu người chơi chọn hủy kích hoạt
                room:drawCards(target, 1, self:objectName())
            elseif judge.card:getSuit() == sgs.Card_Club then
                local targets = room:askForPlayersChosen(source, room:getAlivePlayers(), self:objectName(), 1, 3, "@LuaZhiheng", true)
                if targets:isEmpty() then return end -- Kiểm tra nếu người chơi chọn hủy kích hoạt
                for _, target in sgs.qlist(targets) do
                    room:setPlayerProperty(target, "chained", sgs.QVariant(true))
                end
            elseif judge.card:getSuit() == sgs.Card_Spade then
                local target1 = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName(), "@LuaZhiheng", true)
                if not target1 then return end -- Kiểm tra nếu người chơi chọn hủy kích hoạt
                local equips = target1:getEquips()
                if equips:isEmpty() then return end
                local card_id = room:askForCardChosen(source, target1, "e", self:objectName())
                if card_id == -1 then return end -- Kiểm tra nếu người chơi chọn hủy kích hoạt
                local target2 = room:askForPlayerChosen(source, room:getOtherPlayers(target1), self:objectName(), "@LuaZhiheng", true)
                if not target2 then return end -- Kiểm tra nếu người chơi chọn hủy kích hoạt
                room:moveCardTo(sgs.Sanguosha:getCard(card_id), target2, sgs.Player_PlaceEquip, false)
            end
        end
    end
}



LuaZhiheng = sgs.CreateViewAsSkill{
    name = "LuaZhiheng",
    n = 1,
    view_filter = function(self, selected, to_select)
        return not sgs.Self:isJilei(to_select)
    end,
    view_as = function(self, cards)
        if #cards == 1 then
        local zhiheng_card = LuaZhihengCard:clone()
        zhiheng_card:addSubcard(cards[1])
        return zhiheng_card
        else
            return nil
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuaZhihengCard") and player:canDiscard(player, "he")
    end,
    enabled_at_response = function(self, target, pattern)
        return pattern == "@zhiheng"
    end
}
bangduccong:addSkill(LuaZhiheng)
thaoan = sgs.CreateTriggerSkill{
    name = "thaoan" ,
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return false
        end
        
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
                if use.card:isNDTrick(false) then
                    return self:objectName()
                end
            end
        end
        return ""
    end,
    on_cost=function(self,event,room,player,data)
        local invoke=false
        if player:hasShownSkill(self:objectName()) then
            invoke=true
            room:sendCompulsoryTriggerLog(player,self:objectName(),true)
        else
            invoke=room:askForSkillInvoke(player,self:objectName())
        end
    end,
    on_effect = function(self, event, room, player, data)
        player:setFlags("-thaoanTarget")
        player:setFlags("thaoanTarget")
        local use = data:toCardUse()
            if player:isAlive() and player:hasFlag("thaoanTarget") then
                player:setFlags("-thaoanTarget")
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
                end
            end,
    
}
bangduccong:addSkill(thaoan)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["bangduccong"] = "Bành Đức Công",
    -- Tên tướng
    ["#bangduccong"] = "Đức Ý Cử Thế",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["LuaZhiheng"] = "Chính Tâm",
    [":LuaZhiheng"] = "Một lần trong giai đoạn hành động, bạn có thể bỏ 1 lá bài trên tay, lật phán xét. Nếu là Cơ, bạn lệnh 1 người hồi 1 máu, Rô, bạn lệnh 1 người rút 1 lá, Chuồn, bạn lệnh tối đa 3 người vào trạng thái xích, Bích, bạn lệnh 1 người chọn 1 lá trang bị của 1 người chơi khác và đặt lên trang bị của mình.",
    ["thaoan"] = "Thao ẩn",
    [":thaoan"] = "Khi bạn trở thành mục tiêu của thẻ công cụ có thời gian, hủy bỏ nó.",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}

vuongdi=sgs.General(extension,"vuongdi","wei",4,false)
LuaZhenlie = sgs.CreateTriggerSkill{
    name = "LuaZhenlie" ,
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return false
        end
        
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
                if use.card:isKindOf("Slash") or use.card:isNDTrick() then
                    return self:objectName()
                end
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName(), player)
            player:setFlags("-ZhenlieTarget")
            player:setFlags("ZhenlieTarget")
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()
        local target = use.from
            local recover = sgs.RecoverStruct()
            recover.who = player
            room:loseHp(player, 1)
            if player:isAlive() and player:hasFlag("ZhenlieTarget") then
                player:setFlags("-ZhenlieTarget")
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
                if player:canDiscard(use.from, "he") then
                    local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
                    room:throwCard(id, use.from, player)
                end
            end
    end,
    
}
vuongdi:addSkill(LuaZhenlie)
LuaMiji = sgs.CreateTriggerSkill{
	name = "LuaMiji" ,
	events = {sgs.EventPhaseStart} ,
    frequency = sgs.Skill_Frequent ,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) or player:getPhase() ~= sgs.Player_Finish then
            return false
        end
        
        return self:objectName()
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)

        local count = player:getLostHp()
        if count == 0 then return end
        room:drawCards(player, count, self:objectName())
        if not player:isKongcheng() then
            local targets = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 0, count, "@LuaMiji", true)
            if not targets:isEmpty() then
                for _, target in sgs.qlist(targets) do
                    local card_id = room:askForCardChosen(player, player, "h", self:objectName(), false, sgs.Card_MethodNone)
                    room:obtainCard(target, sgs.Sanguosha:getCard(card_id), false)
                end
            end
        end
    end,
       
}
vuongdi:addSkill(LuaMiji)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["vuongdi"] = "Vương Dị",
    -- Tên tướng
    ["#vuongdi"] = "Quyết Ý Đích Cân Quắc",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["LuaZhenlie"] = "Trinh Liệt",
    [":LuaZhenlie"] = "Khi bạn trở thành mục tiêu của thẻ công cụ hoặc Sát, bạn có thể tự mất 1 máu, hủy bỏ lá này lên bạn, sau đó hủy 1 lá của nguồn gây sát thương này.",
    ["LuaMiji"] = "Mật Tịch",
    [":LuaMiji"] = "Khi kết thúc lượt, bạn rút X lá bài (X là số máu bạn đã mất), sau đó, bạn chọn tối đa X người chơi khác, mỗi người chọn 1 lá bài từ tay bạn.",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
local skills = sgs.SkillList()


--[[******************
    建立一些通用内容
]]--******************
--建立空卡

MemptyCard = sgs.CreateSkillCard{
	name = "MemptyCard",
	target_fixed = true,
}
--建立table-qlist函数
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for _, x in ipairs(theTable) do
		result:append(x)
	end
	return result
end

listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end

--建立获取服务器玩家函数
function getServerPlayer(room, name)
	for _, p in sgs.qlist(room:getAllPlayers(true)) do
		if p:objectName() == name then return p end
	end
	return nil
end

function skillTriggerable(player, name)
	return player ~= nil and player:isAlive() and player:hasSkill(name)
end
sunhuan=sgs.General(extension,"sunhuan","wu",4,true)
nizhan = sgs.CreateTriggerSkill{
	name = "nizhan",
	events = {sgs.EventPhaseChanging, sgs.ConfirmMoveCards},
    can_trigger = function(self, event, room, player, data)
		local skill_list = {}
		local name_list = {}
		if event == sgs.EventPhaseChanging and player and player:isAlive() then
		    local change = data:toPhaseChange()
		    if change.to == sgs.Player_NotActive then
				local skill_owners = room:findPlayersBySkillName(self:objectName())
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skillTriggerable(skill_owner, self:objectName()) and player ~= skill_owner and
							(skill_owner:hasFlag("GlobalLoseAllHandCards") or skill_owner:getCardUsedTimes("Jink+Nullification") > 0) then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
		    end
		end
		return table.concat(skill_list,"|"), table.concat(name_list,"|")
	end,
    on_cost = function(self, event, room, target, data, player)
		local source_data = sgs.QVariant()
		source_data:setValue(target)
		if player:askForSkillInvoke(self:objectName(), source_data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
		
	end,
    on_effect = function(self, event, room, target, data, player)		
		local choices = {}
		if player:canSlash(target, false) then
			table.insert(choices, "slash")
		end
		if player:canGetCard(target, "he") then
			table.insert(choices, "extraction")
		end
		if #choices == 0 then return false end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices,"+"), data, "@nizhan-choose::" .. target:objectName(), "extraction+slash")
		if choice == "extraction" then
			local card_id = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodGet)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
			room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
		elseif choice == "slash" then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("_nizhan")
			room:useCard(sgs.CardUseStruct(slash, player, target), false)
		end
	end,
}

nizhaneffect = sgs.CreateTriggerSkill{
	name = "#nizhan-effect",
	events = {sgs.TargetChosen},
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() then return "" end
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.card:getSkillName() == "nizhan" then
			local target = use.to:at(use.index)
			if target and target:isAlive() then
				return self:objectName() .. ":" .. target:objectName()
			end
		end
	end,
    on_cost = function(self, event, room, target, data, player)
		return true
	end,
	on_effect = function(self, event, room, target, data, player)
		local use = data:toCardUse()
		
		local log = sgs.LogMessage()
		log.type = "#NizhanEffect"
		log.from = player
		log.to:append(target)
		room:sendLog(log)
		
		target:addQinggangTag(use.card)
		
		return false
	end,
}

sunhuan:addSkill(nizhan)
sunhuan:addSkill(nizhaneffect)
extension:insertRelatedSkills("nizhan", "#nizhan-effect")

sgs.LoadTranslationTable{
	["#sunhuan"] = "Tông Thất Nhan Uyên",
	["sunhuan"] = "Tôn Hoàn",
	["illustrator:sunhuan"] = "Thinking",
	["designer:sunhuan"] = "Mộng Yểm Cuồng Triều",
	["nizhan"] = "Nghịch Trảm",
	[":nizhan"] = "Khi kết thúc lượt của người khác, nếu bạn đã triệt tiêu lá bài do họ sử dụng trong lượt này hoặc bạn đã mất đi lá cuối cùng trên tay, bạn có thể chọn 1 mục:\n1. Bạn thu lấy 1 lá của họ;\n2. Bạn xem như sử dụng 1 [Sát] với họ;\n▶ Sau khi bạn xác định mục tiêu của [Sát] này, ứng với mỗi mục tiêu, bạn vô hiệu phòng cụ của họ đến khi xác định số sát thương cuối cùng mà họ phải nhận.",

	["@nizhan-choose"] = "Nghịch Trảm: Chọn 1 hiệu ứng cho %dest",
	["nizhan:extraction"] = "Thu 1 lá",
	["nizhan:slash"] = "Xem như sử dụng [Sát]",

	["#NizhanEffect"] = "%from đã vô hiệu phòng cụ của %to",
	
	["cv:sunhuan"] = "Tịch Kính Jnrio",
    ["$nizhan1"] = "诸位莫急，守住此城即为大功一件！",
	["$nizhan2"] = "玄德公，战场上还识得我么？！",
    ["~sunhuan"] = "此坞未就，桓愧对主公………" ,
	
}
taothuc=sgs.General(extension,"taothuc","wei",3,true)
LuaJiushivs = sgs.CreateViewAsSkill{
    name = "LuaJiushi",
    n = 0,
    view_filter = function(self, selected, to_select)
        return sgs.Self:isJilei(to_select)
    end,
    view_as = function(self, cards)
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
        analeptic:setSkillName(self:objectName())
        return analeptic
    end,
    enabled_at_play = function(self, player)
        return sgs.Analeptic_IsAvailable(player) and player:faceUp()
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, "analeptic") and player:faceUp()
    end
}
LuaJiushi = sgs.CreateTriggerSkill{
    name = "LuaJiushi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.PreCardUsed, sgs.Damaged},
    view_as_skill = LuaJiushivs,
    can_trigger = function(self, event, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return ""
        end
        if event == sgs.PreCardUsed then
            return self:objectName()
        elseif event == sgs.Damaged then
                return self:objectName()
            end
        end,
    on_cost = function(self, event, room, player, data)
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            local card = use.card
            if card:getSkillName() == "LuaJiushi" then
               return true
            end
        elseif event == sgs.Damaged then
            if room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
            return false
            end
        end,
    on_effect = function(self, event, room, player, data)
        if event == sgs.PreCardUsed then
            if player:faceUp() then
                player:turnOver()
            end
        elseif event == sgs.Damaged then
         --chọn 1 người chơi, người này turn over, nếu là bạn, bạn rút 1 lá.
          local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@jiushi", true)
            if target then
                if not target:faceUp() then
                    target:turnOver()
                end
                if target:isChained() then
                    room:setPlayerProperty(target, "chained", sgs.QVariant(false))
                end
                    room:drawCards(player, 1, self:objectName())
                end
        end
    end,
        }

taothuc:addSkill(LuaJiushi)
listIndexOf = function(theqlist, theitem)
    local index = 0
    for _, item in sgs.qlist(theqlist) do
        if item == theitem then return index end
        index = index + 1
    end
end
LuaLuoying = sgs.CreateTriggerSkill{
    name = "LuaLuoying",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardMoveOntime},
    can_trigger = function(self, event, player, data)
        if not player or player:isDead() or not player:hasSkill(self:objectName()) then
            return ""
        end
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if (move.from == nil) or (move.from:objectName() == player:objectName()) then return "" end
            if move.to_place == sgs.Player_DiscardPile then
                if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then

                    return self:objectName()
                elseif move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE then
                    return self:objectName()
                end
            end
        return ""
    end,
    on_cost=function(self,event,room,player,data)
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
      
     
    on_effect = function(self, event, room, player, data)
        local move = data:toMoveOneTime()
        local card_ids = sgs.IntList()
        local i = 0
        for _, card_id in sgs.qlist(move.card_ids) do
            if sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Club then
                card_ids:append(card_id)
            end
            i = i + 1
        end
        if card_ids:isEmpty() then
            return false
        elseif player:askForSkillInvoke(self:objectName(), data) then
            while not card_ids:isEmpty() do
                room:fillAG(card_ids, player)
                local id = room:askForAG(player, card_ids, true, self:objectName())
                if id == -1 then
                    room:clearAG(player)
                    break
                end
                card_ids:removeOne(id)
                room:clearAG(player)
            end
            if not card_ids:isEmpty() then
                for _, id in sgs.qlist(card_ids) do
                    if move.card_ids:contains(id) then
                        move.from_places:removeAt(listIndexOf(move.card_ids, id))
                        move.card_ids:removeOne(id)
                        data:setValue(move)
                    end
                    room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
                    if not player:isAlive() then break end
                end
            end
        end
        return false
    end,

    --[[on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if (move.from == nil) or (move.from:objectName() == player:objectName()) then return false end
        if (move.to_place == sgs.Player_DiscardPile)
                and ((bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
                or (move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE)) then
            local card_ids = sgs.IntList()
            local i = 0
            for _, card_id in sgs.qlist(move.card_ids) do
                if (sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Club)
                        and (((move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE)
                        and (move.from_places:at(i) == sgs.Player_PlaceJudge)
                        and (move.to_place == sgs.Player_DiscardPile))
                        or ((move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_JUDGEDONE)
                        and (room:getCardOwner(card_id):objectName() == move.from:objectName())
                        and ((move.from_places:at(i) == sgs.Player_PlaceHand) or (move.from_places:at(i) == sgs.Player_PlaceEquip)))) then
                    card_ids:append(card_id)
                end
                i = i + 1
            end
            if card_ids:isEmpty() then
                return false
            elseif player:askForSkillInvoke(self:objectName(), data) then
                while not card_ids:isEmpty() do
                    room:fillAG(card_ids, player)
                    local id = room:askForAG(player, card_ids, true, self:objectName())
                    if id == -1 then
                        room:clearAG(player)
                        break
                    end
                    card_ids:removeOne(id)
                    room:clearAG(player)
                end
                if not card_ids:isEmpty() then
                    for _, id in sgs.qlist(card_ids) do
                        if move.card_ids:contains(id) then
                            move.from_places:removeAt(listIndexOf(move.card_ids, id))
                            move.card_ids:removeOne(id)
                            data:setValue(move)
                        end
                        room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
                        if not player:isAlive() then break end
                    end
                end
            end
        end
        return false
    end
}
]]
}
taothuc:addSkill(LuaLuoying)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["taothuc"] = "Tào Thực",
    -- Tên tướng
    ["#taothuc"] = "Tửu Tinh Đích Đại Thần",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["LuaJiushi"] = "Tửu Tinh",
    [":LuaJiushi"] = "Khi cần dùng Tửu, bạn có thể lật tướng, xem như dùng Tửu. Khi nhận sát thương, bạn chọn 1 người chơi khác, nếu người này đang úp mặt, họ lật mặt, nếu họ đang bị xích, họ bỏ xích.",
    ["LuaLuoying"] = "Lạc Dương",
    [":LuaLuoying"] = "Khi 1 lá bài bị đưa vào chồng bài bỏ, nếu lá bài đó là lá Chuồn, bạn có thể chọn 1 lá bài trên tay của người chơi khác và đưa vào tay bạn.",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
didiet=sgs.CreateTriggerSkill{
    --1.Mỗi lượt chơi 1 lần, khi bạn gây sát thương cho người khác, bạn có thể tự giảm 1 sinh lực, lệnh này sát thương tăng thêm X điểm (X = sinh lực của người đó - số sát thương nhận lần này, nếu X = 0 thì không nhắc phát động kỹ năng). 
    --2. Sau khi kết toán sát thương, người chơi đó hồi X sinh lực.
    name = "didiet",
    events = {sgs.DamageCaused,sgs.DamageComplete,sgs.Player_Finish},
    frequency = sgs.Skill_NotFrequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from:objectName() == player:objectName() and  player:getMark("@didiet1") ==0 then
                return self:objectName()
            end
        elseif event == sgs.DamageComplete then
            local damage = data:toDamage()
            if damage.from:objectName() == player:objectName() then    
            return self:objectName()
            end
        elseif event == sgs.Player_Finish then
            if player:getMark("@didiet1") ==1 then
                return self:objectName()
            end
        end
            
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if event == sgs.DamageCaused then
            if room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
        elseif event == sgs.DamageComplete then
            return true
    elseif event == sgs.Player_Finish then
        return true
        end

        return false
    end,
    on_effect = function(self, event, room, player, data)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            local target = damage.to
            local count = target:getHp() - damage.damage
            if count > 0 then
                local recover = sgs.RecoverStruct()
                recover.who = player
                room:loseHp(player, 1)
                damage.damage = damage.damage + count
                data:setValue(damage)
                room:setPlayerMark(target, "@didiet", count)
                room:setPlayerMark(player, "@didiet1", 1)
            end
        elseif event == sgs.DamageComplete then
            local damage = data:toDamage()
            local target = damage.to
            local count = target:getMark("@didiet")
            if count > 0 then
                local recover = sgs.RecoverStruct()
                recover.who = player
                recover.recover = count
                room:recover(target, recover)
                room:setPlayerMark(target, "@didiet", 0)
        elseif event == sgs.Player_Finish then
            room:setPlayerMark(player, "@didiet1", 0)
        end
    end
end,
}
baotamnuong=sgs.General(extension,"baotamnuong","shu",3,true)
baotamnuong:addCompanion("quansach")
vonuong = sgs.CreateTriggerSkill{
	name = "vonuong",
	events = {sgs.CardUsed},
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
				if not player:hasFlag("vonuong1Used") or not player:hasFlag("vonuong2Used") then
					return self:objectName()
						end
					end
				end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		local use= data:toCardUse()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if (not player:hasFlag("vonuong1Used") and p:isFriendWith(player))
					or (not player:hasFlag("vonuong2Used") and p:isFriendWith(player)) then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local prompt = "@vonuong"
			
			if not player:hasFlag("vonuong1Used") then
				prompt = prompt .. "-draw"
			end
			if not player:hasFlag("vonuong2Used")then
				prompt = prompt .. "-claim"
			end
			
			local target = room:askForPlayerChosen(player, targets, self:objectName(), prompt, true, true)
		    if target then
				local d = sgs.QVariant()
		        d:setValue(target)
		        player:setTag("vonuong_target", d)
				room:broadcastSkillInvoke(self:objectName(), player)
		        return true
			end
		end
		return false
	end,
    on_effect = function(self, event, room, player, data)
		local target = player:getTag("vonuong_target"):toPlayer()
		player:removeTag("vonuong_target")
		if target and target:isAlive() then
			--chọn 1 người chơi isFriendWith(player), người này chọn 1 mục:
            --1. Họ rút 1 lá, bạn thu lại lá Slash này
            --2. Bạn rút 1 lá, họ thu lấy lá Slash này
            local use = data:toCardUse()
            --lấy ra thông tin lá bài này
            local card = use.card
			local choices = {}
			if not player:hasFlag("vonuong1Used") and target:isFriendWith(player) then
				table.insert(choices, "draw")
			end
			if not player:hasFlag("vonuong2Used") and target:isFriendWith(player) then
				table.insert(choices, "claim")
			end
			
			local d = sgs.QVariant()
			d:setValue(target)
			local choice = room:askForChoice(target, "vonuong_choice", table.concat(choices,"+"), d, "@vonuong-choice::".. target:objectName(), "draw+claim")
			if choice == "draw" then
				room:setPlayerFlag(player, "vonuong1Used")
                --target draw 1 card, you claim back your slash
                room:drawCards(target, 1, self:objectName())
                room:obtainCard(player, card, false)
			elseif choice == "claim" then
				room:setPlayerFlag(player, "vonuong2Used")
                --you draw 1 card, target claims back your slash
                room:drawCards(player, 1, self:objectName())
                room:obtainCard(target, card, false)
                end
			end
		return false
	end,
}
baotamnuong:addSkill(vonuong)
huathan=sgs.CreateTriggerSkill{
    --Khi bạn thoát khoải trạng thái hấp hối, bạn lệnh 1 người chơi nhận kĩ năng "wusheng" and dangxian
    name = "huathan",
    events = {sgs.QuitDying},
    frequency = sgs.Skill_Limited,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        return self:objectName()
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        player:loseSkill(self:objectName())
        local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@huathan", true)
        if target then
            room:acquireSkill(target, "wusheng")
            room:acquireSkill(target, "dangxian")
        end
    end,

}
baotamnuong:addSkill(huathan)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["baotamnuong"] = "Bào Tam Nương",
    -- Tên tướng
    ["#baotamnuong"] = "Nam Trung Võ Nương",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["vonuong"] = "Vô Nương",
    [":vonuong"] = "Khi bạn dùng 1 lá Sát, bạn có thể chọn 1 người chơi khác, người này chọn 1 mục:\n1. Họ rút 1 lá, bạn thu lại lá Sát này\n2. Bạn rút 1 lá, họ thu lấy lá Sát này",
    ["huathan"] = "Hứa Thân",
    [":huathan"] = "Hạn định kĩ: Khi bạn thoát khoải trạng thái hấp hối, bạn lệnh 1 người chơi nhận kĩ năng Võ thánh và Đương Tiên",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
shitao = sgs.General(extension, "shitao", "shu")
shitao:addCompanion("wolong")
shitao:addCompanion("diy_xushu")
shitao:setHeadMaxHpAdjustedValue()
jiange = sgs.CreateOneCardViewAsSkill{   
	name = "jiange",
	response_or_use = true,
	view_filter = function(self, card)
		if card:getTypeId() == sgs.Card_TypeBasic then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		slash:setShowSkill(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}

qianxueselect = sgs.CreateViewAsSkill{
	name = "qianxueselect",
	expand_pile = "#qianxue",
	response_pattern = "@@qianxueselect",
	view_filter = function(self, selected, to_select)
		if #selected < sgs.Self:getMark("qianxuecount") then
			local ids = sgs.Self:getPile("#qianxue")
			if not ids:contains(to_select:getId()) then return false end
			if to_select:getTypeId() == sgs.Card_TypeBasic then
				for _, id in sgs.qlist(ids) do
					local c2 = sgs.Sanguosha:getCard(id)
					if c2:getTypeId() ~= sgs.Card_TypeBasic and not table.contains(selected, c2) then
						return false
					end
				end
			end
			return true
		end
		return false
	end, 
    view_as = function(self, cards)
		if #cards == 0 then return nil end
		for _,card in ipairs(cards) do
			if card:getTypeId() == sgs.Card_TypeBasic then
				local ids = sgs.Self:getPile("#qianxue")
				for _, id in sgs.qlist(ids) do
					local c2 = sgs.Sanguosha:getCard(id)
					if c2:getTypeId() ~= sgs.Card_TypeBasic and not table.contains(cards, c2) then
						return nil
					end
				end
				break
			end
		end
		
		local skillcard = MemptyCard:clone()
		for _,card in ipairs(cards) do
			skillcard:addSubcard(card)
		end
		return skillcard
	end,
}

qianxue = sgs.CreateTriggerSkill{
	name = "qianxue",
	events = {sgs.EventPhaseChanging, sgs.ConfirmMoveCards},
	relate_to_place = "head",
    can_trigger = function(self, event, room, player, data)
		local skill_list = {}
		local name_list = {}
		if event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
		    if change.to == sgs.Player_NotActive then
			    local discardpile = room:getTag("GlobalRoundDisCardPile"):toList()
				local can_trigger_cheak = false
				for _, card_data in sgs.qlist(discardpile) do
					local card_id = card_data:toInt()
					if room:getCardPlace(card_id) == sgs.Player_DiscardPile and not sgs.Sanguosha:getCard(card_id):isKindOf("ThreatenEmperor") then
						can_trigger_cheak = true
						break
					end
				end
				if can_trigger_cheak then
					local skill_owners = room:findPlayersBySkillName(self:objectName())
					for _, skill_owner in sgs.qlist(skill_owners) do
						if skillTriggerable(skill_owner, self:objectName()) and (skill_owner:hasFlag("GlobalLoseAllHandCards") or
						        skill_owner:hasFlag("GlobalLoseAllEquips") or skill_owner:hasFlag("GlobalLoseAllDelayedTricks")) then
							table.insert(skill_list, self:objectName())
							table.insert(name_list, skill_owner:objectName())
						end
					end
				end
		    end
		end
		return table.concat(skill_list,"|"), table.concat(name_list,"|")
	end,
    on_cost = function(self, event, room, p, data, player)
		local x = 0
		if player:hasFlag("GlobalLoseAllHandCards") then
			x = x + 1
		end
		if player:hasFlag("GlobalLoseAllEquips") then
			x = x + 1
		end
		if player:hasFlag("GlobalLoseAllDelayedTricks") then
			x = x + 1
		end
		if player:askForSkillInvoke(self:objectName(), sgs.QVariant("invoke:::" .. tostring(x))) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
		
	end,
    on_effect = function(self, event, room, p, data, player)
		local x = 0
		if player:hasFlag("GlobalLoseAllHandCards") then
			x = x + 1
		end
		if player:hasFlag("GlobalLoseAllEquips") then
			x = x + 1
		end
		if player:hasFlag("GlobalLoseAllDelayedTricks") then
			x = x + 1
		end
		if x == 0 then return false end
		local cards = sgs.IntList()
		local discardpile = room:getTag("GlobalRoundDisCardPile"):toList()
		for _, card_data in sgs.qlist(discardpile) do
			local card_id = card_data:toInt()
			if room:getCardPlace(card_id) == sgs.Player_DiscardPile and not sgs.Sanguosha:getCard(card_id):isKindOf("ThreatenEmperor") then
				cards:append(card_id) 
			end
		end
		if cards:isEmpty() then return false end
		room:setPlayerMark(player, "qianxuecount", x)
        room:notifyMoveToPile(player, cards, "qianxue", sgs.Player_PlaceTable, true, true)
        local to_get = room:askForCard(player, "@@qianxueselect", "@qianxue-select:::" .. tostring(x), data, sgs.Card_MethodNone)
        room:setPlayerMark(player, "qianxuecount", 0)
        room:notifyMoveToPile(player, cards, "qianxue", sgs.Player_PlaceTable, false, false)

        if to_get:subcardsLength() > 0 then
            room:obtainCard(player, to_get, true)
        end
		
	end,
}

zhuhu = sgs.CreateTriggerSkill{
	name = "zhuhu",
	events = {sgs.DeathFinished, sgs.GeneralTransformed},
	frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
		local skill_list = {}
		local name_list = {}

		local zhuhuTriggerable = function(splayer)
			if not skillTriggerable(splayer, "zhuhu") then return false end
			if splayer:getActualGeneral1():ownSkill("zhuhu") then
				return not splayer:getActualGeneral2():isDoubleKingdoms()
			end
			return splayer:getActualGeneral2():ownSkill("zhuhu")
		end

		if event == sgs.DeathFinished and zhuhuTriggerable(player) then
		    local death = data:toDeath()
			if death.who and death.who:isFriendWith(player) then
				table.insert(skill_list, self:objectName())
				table.insert(name_list, player:objectName())
		    end
		elseif event == sgs.GeneralTransformed then
			local skill_owners = room:findPlayersBySkillName(self:objectName())
			for _, skill_owner in sgs.qlist(skill_owners) do
				if zhuhuTriggerable(skill_owner) and skill_owner:isFriendWith(player) then
					table.insert(skill_list, self:objectName())
					table.insert(name_list, skill_owner:objectName())
				end
			end
			
		end
		return table.concat(skill_list,"|"), table.concat(name_list,"|")
	end,
    on_cost = function(self, event, room, p, data, player)
		local invoke = false
		if player:hasShownSkill(self:objectName()) then
			invoke = true
			room:sendCompulsoryTriggerLog(player, self:objectName())
		else
		    invoke = player:askForSkillInvoke(self, data)
		end
		if invoke then
			room:broadcastSkillInvoke(self:objectName(), player)
            return true
		end
		return false
	end,
    on_effect = function(self, event, room, p, data, player)
		if player:getActualGeneral1():ownSkill("zhuhu") then
            room:exchangeHeadAndDeputyGeneral(player)
        elseif player:getActualGeneral2():ownSkill("zhuhu") and player:isChained() then
            room:setPlayerProperty(player, "chained", sgs.QVariant(false))
		end
		if player:canTransform() then
			room:transformDeputyGeneral(player)
		end
	end,
}

shitao:addSkill(jiange)
shitao:addSkill(qianxue)
shitao:addSkill(zhuhu)

if not sgs.Sanguosha:getSkill("qianxueselect") then skills:append(qianxueselect) end

sgs.LoadTranslationTable{
	
    ["#shitao"] = "Đồng Tiến Cộng Thoái",
    ["shitao"] = "Thạch Thao",
	["illustrator:shitao"] = "Dật Danh",
	["designer:shitao"] = "Mộng Yểm Cuồng Triều",
    ["jiange"] = "Kiếm Ca",
    [":jiange"] = "Bạn có thể chuyển hóa sử dụng/đánh ra lá phi cơ bản thành [Sát].",
    ["qianxue"] = "Tiềm Học",
    [":qianxue"] = "Chủ tướng kỹ, Giảm 0.5 máu gốc: Khi 1 người kết thúc lượt, bạn có thể thu lấy tối đa X lá trong những lá đã tiến vào chồng bài bỏ trong lượt này (X là số vùng của bạn mà đã mất đi lá cuối cùng trong lượt này);\n▶ Bạn cần ưu tiên thu lấy những lá phi cơ bản trước;\n▶ Bạn không thể thu lấy [Hiệp Thiên Tử Dĩ Lệnh Chư Hầu].",
    ["zhuhu"] = "Trục Cốc",
    [":zhuhu"] = "Tỏa định kỹ: Sau khi người cùng thế lực với bạn đổi Phó tướng hoặc trận vong, bạn thực hiện lần lượt:\n- Nếu vị trí của tướng này là:\n * Chủ tướng: Bạn hoán đổi Chủ tướng và Phó tướng\n * Phó tướng: Bạn thoát khỏi trạng thái xích;\n- Bạn đổi Tướng này.",
    ["qianxue:invoke"] = "Có thể phát động »Tiềm Học«, thu lấy tối đa %arg lá tiến vào chồng bài bỏ lượt này (ưu tiên lá phi cơ bản)",
    ["@qianxue-select"] = "Tiềm học: Chọn tối đa %arg lá, ưu tiên phi cơ bản.",
    ["#qianxue"] = "Tiềm Học",

	["cv:shitao"] = "Thủy Thương Túc",
	["$jiange1"] = "Đã cầm kiếm là phải quyết tâm, đoạn tuyệt với đời",
	["$jiange2"] = "Ngô chí bất hảo thiên lý tài, duy nguyện trảm tận bách lý hung",
	["$qianxue1"] = "Học đến giờ vẫn chưa thấy đã, phải tốn thêm tiền rồi!",
	["$qianxue2"] = "Nguyên Trực, đoạn này nên giải thế nào?",
	["$zhuhu1"] = "Nguyên Trực đã đi, mỗ cũng cáo từ",
	["$zhuhu2"] = "Loạn lạc rồi sẽ biến mất, mọi chuyện sẽ lại yên bình. Huynh đệ ai cũng có, nhưng liệu có được như bằng hữu?",
	["~shitao"] = "Cùng người hận địch, cùng người giết địch, cũng cùng người đi xuống!",
}
camam=sgs.CreateTriggerSkill{
    --giai đoạn bỏ bài, nếu bạn bỏ >=2 lá, bạn có thể lệnh tất cả người chơi hồi 1 máu hoặc tự giảm 1 máu.
    name = "camam",
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Discard then
                local x= player:getMark("GlobalRuleDisCardCount")
                if x >= 2 then
                    return self:objectName()
                end
            end
        end
            
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        local choice = room:askForChoice(player, "camam","heal+loseHp", data)
        if choice == "heal" then
            local recover = sgs.RecoverStruct()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:recover(p, recover)
            end
        elseif choice == "loseHp" then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:loseHp(p, 1)
            end
        end
    end,

}
hoitru=sgs.CreateTriggerSkill{
    --cuối giai đoạn bỏ bài, bạn có thể gây 1 sát thương cho người chơi có sinh lực là X(X là số lá bài bạn đã bỏ giai đoạn này)
    name = "hoitru",
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Discard then
                    return self:objectName()
                end
            end
            
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        local x= player:getMark("GlobalRuleDisCardCount")
        --you can only choose the one who has x hp
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHp() == x then
                targets:append(p)
            end
        end
        if not targets:isEmpty() then
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@hoitru", true, true)
            if target then
                local damage = sgs.DamageStruct()
                damage.from = player
                damage.to = target
                damage.damage = 1
                room:damage(damage)
            end
        end
    end,
}
yentru=sgs.CreateTriggerSkill{
    --in the beginning of your turn, you can choose a player, let him choose 1 of the following:
    --1. Let you obtain all of his equip cards, then you and he draw 1 card.
    --2. The next time he receives damage, he take extra 1 damage.
    name = "yentru",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
   can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            local target= room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@yentru", true, true)
            if target then
                local equips = target:getEquips()
                if not equips:isEmpty() then
                local choice = room:askForChoice(target, "damage", "obtain", data)
                if choice == "obtain" then
                room:obtainCard(player, equips, true)
                room:drawCards(player, 1, self:objectName())
                room:drawCards(target, 1, self:objectName())
                else
                 --they discard 1 card
                        local card_id = room:askForCardChosen(player, target, "he", self:objectName())
                        room:throwCard(card_id, target, target)
                end
                end
            end
        end
    end,

    
}

quymenh=sgs.CreateTriggerSkill{
    --1.when you deal damage to a player, you card discard 2 cards, he lose 1hp.
    --2.when you receive damage from a player, he can discard 2 cards, then you lose 1 hp. When you lose hp, you draw 1 card.
    name = "quymenh",
    events = {sgs.DamageCaused, sgs.Damaged},
    frequency = sgs.Skill_Frequent, 
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from and damage.from:isAlive() and damage.from:hasSkill(self:objectName()) then
                return self:objectName()
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.to and damage.to:isAlive() and damage.to:hasSkill(self:objectName()) then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from and damage.from:isAlive() and damage.from:hasSkill(self:objectName()) then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName(), player)
                    return true
                end
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            local target = damage.from
            if damage.to and damage.to:isAlive() and damage.to:hasSkill(self:objectName()) then
                if room:askForSkillInvoke(target, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName(), target)
                    return true
                end
            end
        end
        return false
    end,
    on_effect = function(self,event,room,player,data)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            local target = damage.to
            local player= damage.from
            if player:isKongcheng() then return "" end
            room:askForDiscard(player, self:objectName(), 2, 2, false, true)
            room:loseHp(target, 1)
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            local player = damage.to
            local target = damage.from
            if target: isKongcheng() then return "" end
            room:askForDiscard(target, self:objectName(), 2, 2, false, true)
            room:loseHp(player, 1)
        end
        
    end
}
hoangkhung=sgs.CreateTriggerSkill{
    -- Ngoài lượt của bạn, sau khi bạn trở thành mục tiêu duy nhất của lá Sát hoặc Cẩm Nang phổ thông, nếu bạn không có bài trên tay thì bạn rút 2 lá bài.
    name = "hoangkhung",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card and (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.to:length() == 1 and use.to:contains(player) and player:isKongcheng() then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        return true
    end,
    on_effect = function(self,event,room,player,data)
        room:drawCards(player, 2, self:objectName())
    end
}
--[[dieutoan=sgs.CreateTriggerSkill{
    --after you use a basic card or a trickcard, you can lose 1 hp or 1 hplimits, considered as you used it again
    name = "dieutoan",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and (use.card:isKindOf("BasicCard") or use.card:isNDTrick(true)) then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self,event,room,player,data)
        local choice = room:askForChoice(player, "dieutoan", "loseHp+loseHpLimit", data)
        if choice == "loseHp" then
            room:loseHp(player, 1)
            local use = data:toCardUse()
            local card = use.card
            local new_use = sgs.CardUseStruct()
            new_use.card = card
            new_use.from = player
            new_use.to = use.to
            room:useCard(new_use, false)
        elseif choice == "loseHpLimit" then
            room:loseMaxHp(player, 1)
            --player xem như vừa sử dụng lá bài này lần thứ 2.
            local use = data:toCardUse()
            local card = use.card
            local new_use = sgs.CardUseStruct()
            new_use.card = card
            new_use.from = player
            new_use.to = use.to
            room:useCard(new_use, false)
        end
    end,
}]]
tonhao= sgs.General(extension, "tonhao", "wu", 4)
tanthuc = sgs.CreateTriggerSkill{
	name = "tanthuc",
    relate_to_place = "head",
	can_preshow = false,
    can_trigger = function(self, event, room, player, data)
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		return false
	end,
}

tanthuccompulsory = sgs.CreateTriggerSkill{
	name = "#tanthuc-compulsory",
	events = {sgs.GeneralShowed},
	frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
		if event == sgs.GeneralShowed then
			if player:cheakSkillLocation("tanthuc", data) and player:getMark("tanthucUsed") == 0 then
                return self:objectName()
			end
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, "tanthuc")
        room:broadcastSkillInvoke("tanthuc", player)
            room:addPlayerMark(player, "tanthucUsed")
        return true
	end,
    on_effect = function(self, event, room, player, data)
		--1. Bạn hồi 2 máu, tăng 2 giới hạn máu.
        --2. Bạn rút bài bằng số người chơi đang bị thương trên bàn.
        --3. Bạn loại bỏ phó tướng.
        --4. Bạn nhận kĩ năng quymenh va dieutoan
        room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 2))
        local recover = sgs.RecoverStruct()
        recover.who = player
        recover.recover = 2
        room:recover(player, recover)
        local x = 0
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:isWounded() or p:isFriendWith(player) then
                x = x + 1
            end
        end
        room:drawCards(player, x, "tanthuc")
            player:removeGeneral(false);
            room:acquireSkill(player, "quymenh")
            room:acquireSkill(player, "hoangkhung")
        
        end


}
tonhao:addSkill(tanthuc)
tonhao:addSkill(tanthuccompulsory)
extension:insertRelatedSkills("tanthuc", "#tanthuc-compulsory")
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("quymenh") then skills:append(quymenh) end
if not sgs.Sanguosha:getSkill("hoangkhung") then skills:append(hoangkhung) end
sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable{
    ["LK_Diy_1"] = "Lãng Khách DIY 1" ,
    --Tên Pack
    
    ["tonhao"] = "Tôn Hạo",
    -- Tên tướng
    ["#tonhao"] = "Thời nhật hạt tang",
    -- Xưng hào sẽ thêm dấu # ở trước mã của tướng
    
    
    ["tanthuc"] = "Tàn Thực",
    [":tanthuc"] = "Tỏa định kỹ: Khi bạn lật mở tướng này lần đầu tiên, bạn thực hiện lần lượt:\n1. Hồi 2 máu, tăng 2 giới hạn máu;\n2. Rút bài bằng số người chơi đang bị thương trên bàn;\n3. Loại bỏ phó tướng;\n4. Nhận kĩ năng Quy Mệnh và Diệu Toán.",
    ["quymenh"] = "Quy Mệnh",
    [":quymenh"] = "Khi bạn gây/nhận sát thương cho 1 người chơi, nguồn sát thương có thể bỏ 2 lá bài, lệnh người bị thương tự giảm 1 máu.",
    -- Mô tả kỹ năng, thêm dấu : trước mã của kỹ năng

}
toncan=sgs.General(extension, "toncan", "shu", 3)
toncan:addCompanion("liubei")
khiemnha=sgs.CreateTriggerSkill{
    --when you become target of trickcard, you can give a card to a player you choose.
    name = "khiemnha",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("TrickCard") and use.to:length() > 0 and use.to:contains(player) then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self,event,room,player,data)
        local target=room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@khiemnha", true, true)
        if target then
            local card_id = room:askForCardChosen(player, player, "he", self:objectName())
            room:obtainCard(target, card_id, false)
        end
    end,
}
toncan:addSkill(khiemnha)
thuyetminh=sgs.CreateTriggerSkill{
    --when you finish your play phase, you can pindian with a player you choose, if you win, you draw 2 card, else the player discard 1 of your card.
    name = "thuyetminh",
    events = {sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) or player:getPhase() ~= sgs.Player_Play or player:isKongcheng() then
            return ""
        end
        return self:objectName()
    end,
    on_cost = function(self, event, room, player, data)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self,event,room,player,data)
        --list all targets that are not kongcheng
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not p:isKongcheng() then
                targets:append(p)
            end
        end
        local target=room:askForPlayerChosen(player, targets, self:objectName(), "@thuyetminh", true, true)
        if target then
            local success = player:pindian(target, self:objectName(), nil)
            if success then
                room:drawCards(player, 2, self:objectName())
            else
                local card_id = room:askForCardChosen(target, player, "he", self:objectName())
                room:throwCard(card_id, player, target)
            end
        end
    end,
}
toncan:addSkill(thuyetminh)
--[[lynho=sgs.General(extension, "lynho", "qun", 3)
lynho:addCompanion("jiaxu")
lynho:addCompanion("dongzhuo")
lienke = sgs.CreateTriggerSkill{
	name = "lienke",
	events = {sgs.CardsMoveOneTime},
    can_trigger = function(self, event, room, player, data)
		if skillTriggerable(player, self:objectName()) and not player:hasFlag("lienkeUsed") then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive and current:objectName() == player:objectName() then
				local move_datas = data:toList()
				for _, move_data in sgs.qlist(move_datas) do
					local move = move_data:toMoveOneTime()
					local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
						if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
							if move.from and move.from:isAlive() and move.from:getPhase() == sgs.Player_NotActive then
									return self:objectName()
								end
							end
						end
					end
				end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		local current = room:getCurrent()
		if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive and current:objectName() == player:objectName() then
			local targets = sgs.SPlayerList()
				targets:append(current)
			local move_datas = data:toList()
			for _, move_data in sgs.qlist(move_datas) do
				local move = move_data:toMoveOneTime()
				local reasonx = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
						if move.from and move.from:isAlive() and move.from:getPhase() == sgs.Player_NotActive then
							if move.from:objectName() ~= player:objectName() then
								local move_from = getServerPlayer(room, move.from:objectName())
								if move_from then
									targets:append(move_from)
								end
							end
						end
                    end
                end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "lienke-invoke::" .. current:objectName(), true, true)
				if target then
					local d = sgs.QVariant()
					d:setValue(target)
					player:setTag("lienke_target", d)
					player:setFlags("lienkeUsed")
					room:broadcastSkillInvoke(self:objectName(), player)
					return true
				end
			end
		end
		return false
	end,
    on_effect = function(self, event, room, player, data)
		--you deal 1 damage to player who has lost card.
        local target = player:getTag("lienke_target"):toPlayer()
        player:removeTag("lienke_target")
        local damage = sgs.DamageStruct()
        damage.from = player
        damage.to = target
        damage.damage = 1
        room:damage(damage)
    end,
}
lynho:addSkill(lienke)
]]
godchudu=sgs.General(extension, "godchudu", "wu", 4)
godchudu:addSkill(camam)
Fire = function(player,target,damagePoint)
    local damage = sgs.DamageStruct()
    damage.from = player
    damage.to = target
    damage.damage = damagePoint
    damage.nature = sgs.DamageStruct_Fire
    player:getRoom():damage(damage)
end
function toSet(self)
    local set = {}
    for _,ele in pairs(self)do
        if not table.contains(set,ele) then
            table.insert(set,ele)
        end
    end
    return set
end
LuaGreatYeyanCard = sgs.CreateSkillCard{
    name="LuaGreatYeyanCard",
    will_throw = true,
    skill_name = "LuaYeyan",
    filter = function(self, targets, to_select)
        local i = 0
        for _,p in pairs(targets)do
            if p:objectName() == to_select:objectName() then
                i = i + 1
            end
        end
        local maxVote = math.max(3-#targets,0)+i
        return maxVote
    end,
    feasible = function(self, targets)
        if self:getSubcards():length() ~= 4 then return false end
        local all_suit = {}
        for _,id in sgs.qlist(self:getSubcards())do
            local c = sgs.Sanguosha:getCard(id)
            if not table.contains(all_suit,c:getSuit()) then
                table.insert(all_suit,c:getSuit())
            else
                return false
            end
        end
        if #toSet(targets) == 1 then
            return true
        elseif #toSet(targets) == 2 then
            return #targets == 3
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local criticaltarget = 0
        local totalvictim = 0
        local map = {}
        for _,sp in pairs(targets)do
            if map[sp:objectName()] then
                map[sp:objectName()] = map[sp:objectName()] + 1
            else
                map[sp:objectName()] = 1
            end
        end
        
        if #targets == 1 then
            map[targets[1]:objectName()] = map[targets[1]:objectName()] + 2
        end
        local target_table = sgs.SPlayerList()
        for sp,va in pairs(map)do
            if va > 1 then criticaltarget = criticaltarget + 1  end
            totalvictim = totalvictim + 1
            for _,p in pairs(targets)do
                if p:objectName() == sp then
                    target_table:append(p)
                    break
                end
            end
        end
        if criticaltarget > 0 then
            room:removePlayerMark(source, "@flame")	
            room:loseHp(source, 3)	
            room:sortByActionOrder(target_table)
            for _,sp in sgs.qlist(target_table)do
                Fire(source, sp, map[sp:objectName()])
            end
        end
    end,
}
LuaSmallYeyanCard = sgs.CreateSkillCard{
    name="LuaSmallYeyanCard",
    will_throw = true,
    skill_name = "LuaYeyan",
    filter = function(self, targets, to_select)
        return #targets < 3
    end,
    feasible = function(self, targets)
        return #targets > 0
    end,
    on_use = function(self, room, source, targets)
        room:removePlayerMark(source, "@flame")
        for _,sp in sgs.list(targets)do
            Fire(source, sp, 1)
        end
    end,
}
LuaYeyanVS = sgs.CreateViewAsSkill{ 
    name = "LuaYeyan",
    n = 4,
    view_filter = function(self, selected, to_select)
        if to_select:isEquipped() or sgs.Self:isJilei(to_select) then
            return false
        end
        for _,ca in sgs.list(selected)do
            if ca:getSuit() == to_select:getSuit() then return false end
        end
        return true
    end,
    view_as = function(self,cards) 
        if #cards == 0 then
            return LuaSmallYeyanCard:clone()
        end
        if #cards == 4 then
            local YeyanCard = LuaGreatYeyanCard:clone()
            for _,card in ipairs(cards) do
                YeyanCard:addSubcard(card)
            end
            return YeyanCard
        end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@flame") > 0
    end
}
LuaYeyan = sgs.CreateTriggerSkill{
        name = "LuaYeyan",
        frequency = sgs.Skill_Limited,
        limit_mark = "@flame",
        view_as_skill = LuaYeyanVS ,
        on_trigger = function() 
        end
}
godchudu:addSkill(LuaYeyan)



--[[foreach (ServerPlayer *p, room->getAlivePlayers()) {
    if (p == player) continue;
    if (p->hasShownGeneral1() && !p->getActualGeneral1Name().contains("sujiang")) {
        targets << p;
        continue;
    }
    if (p->hasShownGeneral2() && !p->getActualGeneral2Name().contains("sujiang")) {
        targets << p;
        continue;
    }
}
ServerPlayer *to = room->askForPlayerChosen(player, targets, objectName(), "@bianhua-invoke", true, true);
if (to != NULL) {
    QStringList choicelist;
    if (to->hasShownGeneral1() && !to->getActualGeneral1Name().contains("sujiang")) {
        choicelist << to->getActualGeneral1Name();
    }
    if (to->hasShownGeneral2() && !to->getActualGeneral2Name().contains("sujiang")) {
        choicelist << to->getActualGeneral2Name();
    }
    QString choice = room->askForChoice(player, objectName(), choicelist.join("+"), QVariant::fromValue(to), "@bianhua-choose");
    const General *general = Sanguosha->getGeneral(choice);
    LogMessage log;
    log.type = "#bianhua-choice";
    log.from = player;
    log.arg = choice;
    room->sendLog(log);
    room->addPlayerMark(player, "##" + choice);
    room->setPlayerProperty(player, "bianhua-choice", choice);
    QList<const Skill *> skills = general->getVisibleSkillList();
    foreach (const Skill *skill, skills) {
        if (skill->isLordSkill() || skill->isAttachedLordSkill()) continue;
        if (skill->relateToPlace(player->inDeputySkills(objectName()))) continue;
        if (skill == this) continue;
        room->acquireSkill(player, skill, true, player->inHeadSkills(objectName()));
        if (!skill->getLimitMark().isEmpty()) {
            room->setPlayerMark(player, skill->getLimitMark(), 1);
        }
    }
    player->setGender(general->getGender());
} else {
    room->setPlayerProperty(player, "maxhp", player->getMaxHp() + 1);

    LogMessage log;
    log.type = "#GainMaxHp";
    log.from = player;
    log.arg = QString::number(1);
    room->sendLog(log);

    if (player->canRecover()) {
        RecoverStruct recover;
        recover.who = player;
        room->recover(player, recover);
    }
    room->addPlayerMark(player, "@careerist");
}]]
tanmat=sgs.General(extension, "tanmat", "shu", 3)
tanmat:addCompanion("liubei")
chuyendoi=sgs.CreateTriggerSkill{
    --whenever you become target of Slash, you can pindian with the user. if you win, Slash invalid with you.
    name = "chuyendoi",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) or player:isKongcheng() then
            return ""
        end
        
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") and use.to:contains(player) and not use.from:isKongcheng() then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
       
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self,event,room,player,data)
        local use = data:toCardUse()
        local target = use.from
        local success = player:pindian(target, self:objectName(), nil)
        if success then
            local nullified_list = use.nullified_list
            table.insert(nullified_list, player:objectName())
            use.nullified_list = nullified_list
            data:setValue(use)
        end
    end,
}
tanmat:addSkill(chuyendoi)
gianchinh = sgs.CreateTriggerSkill{
	name = "gianchinh",
	events = {sgs.TargetChoosing},
    can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetChoosing and player and player:isAlive() then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.from and use.from:isAlive() then
				local skill_list = {}
				local name_list = {}
				local skill_owners = room:findPlayersBySkillName(self:objectName())
				for _, skill_owner in sgs.qlist(skill_owners) do
					if skillTriggerable(skill_owner, self:objectName()) and player ~= skill_owner and not use.to:contains(skill_owner) and not skill_owner:isKongcheng() and use.from:inMyAttackRange(skill_owner) then
						table.insert(skill_list, self:objectName())
						table.insert(name_list, skill_owner:objectName())
					end
				end
				return table.concat(skill_list,"|"), table.concat(name_list,"|")
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, skill_owner)
		if skill_owner:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), skill_owner)
			return true
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, skill_owner)
			--put a card in your hand to drawpile
            local card=room:askForCard(skill_owner, ".", "@gianchinh-put", data, sgs.Card_MethodNone)
            if card then
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, skill_owner:objectName(), "gianchinh", "")
                room:moveCardTo(card, nil, sgs.Player_DrawPile, reason, false)
            end
            local use = data:toCardUse()
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(use.to) do
				if p:isAlive() and use.to:contains(p) then
					targets:append(p)
				end
            end
			if not targets:isEmpty() then
				local prompt = "@gianchinh-target:" .. player:objectName() .. "::" .. use.card:objectName()
				skill_owner:setTag("gianchinhUsedata", data)
				local target = room:askForPlayerChosen(skill_owner, targets, "gianchinh_target", prompt)
				skill_owner:removeTag("gianchinhUsedata")
				room:doAnimate(1, skill_owner:objectName(), target:objectName())
				sgs.Room_cancelTarget(use, target)
                data:setValue(use)
                use.to:append(skill_owner)
                data:setValue(use)
                end
		return ""
        end,
}
tanmat:addSkill(gianchinh)
--[[
    TianbianCard::TianbianCard()
{
    target_fixed = true;
}

const Card *TianbianCard::validateInResponse(ServerPlayer *user) const
{
    Room *room = user->getRoom();
    LogMessage log;
    log.from = user;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);
    room->notifySkillInvoked(user, "tianbian");
    user->broadcastSkillInvoke("tianbian");

    int id = room->drawCard();
    return Sanguosha->getCard(id);
}

class TianbianViewAsSkill : public ZeroCardViewAsSkill
{
public:
    TianbianViewAsSkill() : ZeroCardViewAsSkill("tianbian")
    {
        response_pattern = "pindian";
    }

    virtual const Card *viewAs() const
    {
        return new TianbianCard;
    }
};

class Tianbian : public TriggerSkill
{
public:
    Tianbian() : TriggerSkill("tianbian")
    {
        events << PindianVerifying;
        view_as_skill = new TianbianViewAsSkill;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        PindianStruct *pindian = data.value<PindianStruct *>();
        if (TriggerSkill::triggerable(player) && ((pindian->from == player && pindian->from_card->getSuit() == Card::Heart)
                || (pindian->to == player && pindian->to_card->getSuit() == Card::Heart)))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        PindianStruct *pindian = data.value<PindianStruct *>();
        bool isFrom = (pindian->from == player);

        LogMessage log;
        log.type = "$TianbianNumber";
        log.from = player;
        log.arg = objectName();
        log.arg2 = QString::number(13);
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        player->broadcastSkillInvoke(objectName());
        if (isFrom)
            pindian->from_number = 13;
        else
            pindian->to_number = 13;

        return false;
    }
};

]]
tianbiancard=sgs.CreateSkillCard{
    name = "tianbiancard",
    target_fixed = true,
    will_throw = true,
    skill_name = "tianbian",
    on_use = function(self, room, source, targets)
        local id = room:drawCard()
        local card = sgs.Sanguosha:getCard(id)
    end,
}
tianbianvs=sgs.CreateViewAsSkill{
    name = "tianbian",
    n = 0,
    view_as = function(self, cards)
        return tianbiancard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "pindian"
    end,
}
tianbian=sgs.CreateTriggerSkill{
    name = "tianbian",
    events = {sgs.PindianVerifying},
    view_as_skill = tianbianvs,
    --[[on_trigger = function(self, event, room, player, data)
        local pindian = data:toPindian()
        if pindian.from == player and pindian.from_card:getSuit() == sgs.Card_Heart then
            room:notifySkillInvoked(player, self:objectName())
            player:broadcastSkillInvoke(self:objectName())
            pindian.from_number = 13
        elseif pindian.to == player and pindian.to_card:getSuit() == sgs.Card_Heart then
            room:notifySkillInvoked(player, self:objectName())
            player:broadcastSkillInvoke(self:objectName())
            pindian.to_number = 13
        end
        data:setValue(pindian)
        return false
    end,]]
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        if event == sgs.PindianVerifying then
            local pindian = data:toPindian()
            if (pindian.from == player and pindian.from_card:getSuit() == sgs.Card_Heart) or (pindian.to == player and pindian.to_card:getSuit() == sgs.Card_Heart) then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
       
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self,event,room,player,data)
        local pindian = data:toPindian()
        if pindian.from == player and pindian.from_card:getSuit() == sgs.Card_Heart then
            pindian.from_number = 13
        elseif pindian.to == player and pindian.to_card:getSuit() == sgs.Card_Heart then
            pindian.to_number = 13
        end
        data:setValue(pindian)
        return false
    end,
}
tanmat:addSkill(tianbian)
sgs.LoadTranslationTable{

}
--[[ZhanjueCard::ZhanjueCard()
{
    handling_method = Card::MethodNone;
    will_throw = false;
}

bool ZhanjueCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Duel *duel = new Duel(Card::SuitToBeDecided, -1);
    duel->addSubcards(Self->getHandcards());
    duel->setSkillName("zhanjue");

    return duel && duel->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, duel, targets);
}

void ZhanjueCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *player = card_use.from;

    QList<ServerPlayer *> to = card_use.to;

    Duel *duel = new Duel(Card::SuitToBeDecided, -1);
    duel->addSubcards(player->getHandcards());
    duel->setSkillName("zhanjue");
    room->useCard(CardUseStruct(duel, player, to));

    room->addPlayerMark(player, "zhanjuedraw", 1);
    player->drawCards(1, "zhanjue");
    QStringList damaged_tag = duel->tag["GlobalCardDamagedTag"].toStringList();

    QList<ServerPlayer *> allplayers = room->getAlivePlayers();
    foreach (ServerPlayer *p, allplayers) {
        if (damaged_tag.contains(p->objectName())) {
            if (p == player)
                room->addPlayerMark(player, "zhanjuedraw", 1);
            p->drawCards(1, "zhanjue");
        }
    }

}

class ZhanjueVS : public ZeroCardViewAsSkill
{
public:
    ZhanjueVS() : ZeroCardViewAsSkill("zhanjue")
    {

    }

    const Card *viewAs() const
    {

        return new ZhanjueCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("zhanjuedraw") < 2 && !player->isKongcheng();
    }
};

class Zhanjue : public TriggerSkill
{
public:
    Zhanjue() : TriggerSkill("zhanjue")
    {
        view_as_skill = new ZhanjueVS;
        events << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *) const
    {
        return false;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.from == Player::Play)
            room->setPlayerMark(player, "zhanjuedraw", 0);
    }
};]]
luukham=sgs.General(extension, "luukham", "shu", 4)
luukham:addCompanion("liubei")
--[[
    void ZhanjueCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *player = card_use.from;

    QList<ServerPlayer *> to = card_use.to;

    Duel *duel = new Duel(Card::SuitToBeDecided, -1);
    duel->addSubcards(player->getHandcards());
    duel->setSkillName("zhanjue");
    room->useCard(CardUseStruct(duel, player, to));

    room->addPlayerMark(player, "zhanjuedraw", 1);
    player->drawCards(1, "zhanjue");
    QStringList damaged_tag = duel->tag["GlobalCardDamagedTag"].toStringList();

    QList<ServerPlayer *> allplayers = room->getAlivePlayers();
    foreach (ServerPlayer *p, allplayers) {
        if (damaged_tag.contains(p->objectName())) {
            if (p == player)
                room->addPlayerMark(player, "zhanjuedraw", 1);
            p->drawCards(1, "zhanjue");
        }
    }

}
]]

zhanjuecard=sgs.CreateSkillCard{
    name = "zhanjuecard",
    target_fixed = false,
    will_throw = false,
    skill_name = "zhanjue",
    filter = function(self, targets, to_select)
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, -1)
       return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName() and not sgs.Self:isProhibited(to_select, duel)
    end,
    feasible = function(self, targets)
        return #targets > 0
    end,
    on_use = function(self, room, source, targets)
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, -1)
        duel:addSubcards(source:getHandcards())
        duel:setSkillName("zhanjue")
        room:useCard(sgs.CardUseStruct(duel, source, targets))
        room:addPlayerMark(source, "zhanjuedraw", 1)
        source:drawCards(1, "zhanjue")
        local damaged_tag = duel:getTag("GlobalCardDamagedTag"):toStringList()
        local allplayers = room:getAlivePlayers()
        for _,p in sgs.qlist(allplayers)do
            if damaged_tag:contains(p:objectName()) then
                if p == source then
                    room:addPlayerMark(source, "zhanjuedraw", 1)
                end
                p:drawCards(1, "zhanjue")
            end
        end
    end,
}

zhanjuevs=sgs.CreateZeroCardViewAsSkill{
    name = "zhanjue",
    n = 0,
    view_as = function(self, cards)
        return zhanjuecard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("zhanjuedraw") < 2 and not player:isKongcheng()
    end,
}
zhanjue=sgs.CreateTriggerSkill{
    name = "zhanjue",
    events = {sgs.EventPhaseChanging},
    view_as_skill = zhanjuevs,
    can_trigger = function(self, event, room, player, data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_Play then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
       
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return false
    end,
    on_effect = function(self,event,room,player,data)
        room:setPlayerMark(player, "zhanjuedraw", 0)
    end,
}
luukham:addSkill(zhanjue)
boluyensu=sgs.General(extension, "boluyensu", "wu", 3)
boluyensu:addCompanion("sunquan")
LuaAnxuCard = sgs.CreateSkillCard{
    name = "LuaAnxuCard",
    filter = function(self, targets, to_select, player)
        if to_select:objectName() == player:objectName() then return false end
        if #targets == 0 then
            return true
        elseif #targets == 1 then
            return to_select:getHandcardNum() ~= targets[1]:getHandcardNum()
        else
            return false
        end
    end,
    feasible = function(self, targets)
        return #targets == 2
    end,
    on_use = function(self, room, source, targets)
        local from, to
        if targets[1]:getHandcardNum() < targets[2]:getHandcardNum() then
            from = targets[1]
            to = targets[2]
        else
            from = targets[2]
            to = targets[1]
        end
        local id = room:askForCardChosen(from, to, "h", "LuaAnxu")
        local cd = sgs.Sanguosha:getCard(id)
        from:obtainCard(cd)
        room:showCard(from, id)
        if cd:getSuit() ~= sgs.Card_Spade then
            source:drawCards(1, "LuaAnxu")
        end
    end
}
LuaAnxu = sgs.CreateZeroCardViewAsSkill{
    name = "LuaAnxu",
    view_as = function(self) 
        return LuaAnxuCard:clone()
    end, 
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuaAnxuCard")
    end,
}
boluyensu:addSkill(LuaAnxu)
trunguc=sgs.CreateTriggerSkill{
    --when you die, you can choose a player, let him draw 3 cards, restore 1 health, and gain skill LuaAnxu
    name = "trunguc",
    events = {sgs.Death},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
       
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return ""
    end,
    on_effect = function(self,event,room,player,data)
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "trunguc-invoke", true, true)
        if target then
            target:drawCards(3, "trunguc")
            local recover = sgs.RecoverStruct()
            recover.who = player
            room:recover(target, recover)
            room:acquireSkill(target, "LuaAnxu")
        end
    end,

}
boluyensu:addSkill(trunguc)
simalang=sgs.General(extension, "simalang", "wei", 3)
simalang:addCompanion("simayi")
LuaYTChengxiangCard = sgs.CreateSkillCard{
    name = "LuaYTChengxiang" ,
    filter = function(self, targets, to_select)
        return #targets < self:subcardsLength()
    end ,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        if effect.to:isWounded() then
            local recover = sgs.RecoverStruct()
            recover.card = self
            recover.who = effect.from
            room:recover(effect.to, recover)
        else
            effect.to:drawCards(2)
        end
    end
}
LuaYTChengxiangVS = sgs.CreateViewAsSkill{
    name = "LuaYTChengxiang" ,
    n = 3 ,
    view_filter = function(self, selected, to_select)
        if #selected >= 3 then return false end
        local sum = 0
        for _, card in ipairs(selected) do
            sum = sum + card:getNumber()
        end
        sum = sum + to_select:getNumber()
        return sum <= sgs.Self:getMark("LuaYTChengxiang")
    end ,
    view_as = function(self, cards)
        local sum = 0
        for _, c in ipairs(cards) do
            sum = sum + c:getNumber()
        end
        if sum == sgs.Self:getMark("LuaYTChengxiang") then
            local card = LuaYTChengxiangCard:clone()
            for _, c in ipairs(cards) do
                card:addSubcard(c)
            end
            return card
        else
            return nil
        end
    end ,
    enabled_at_play = function()
        return false
    end ,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@LuaYTChengxiang"
    end
}
LuaYTChengxiang = sgs.CreateTriggerSkill{
    name = "LuaYTChengxiang" ,
    events = {sgs.Damaged} ,
    view_as_skill = LuaYTChengxiangVS ,

    can_trigger=function(self,event,room,player,data)
        if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
            return ""
        end
        if event == sgs.Damaged then
           return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
       
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return ""
    end,
    on_effect = function(self,event,room,player,data)
        local damage = data:toDamage()
        local card = damage.card
        if card == nil then return false end
        local point = card:getNumber()
        if (point < 1) or (point > 13) then return false end
        if player:isNude() then return false end
        room:setPlayerMark(player, "LuaYTChengxiang", point)
        local prompt = "@chengxiang-card:::" .. tostring(point)
        room:askForUseCard(player, "@@LuaYTChengxiang", prompt)
        return ""
    end,
}
simalang:addSkill(LuaYTChengxiang)
quanbinh=sgs.CreateTriggerSkill{
    --when you finish your turn, you can choose a player whose handcard number is not greater than 2, let him draw 1 card.
    name = "quanbinh",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    can_trigger = function(self, event, room, player, data)
        if not player or not player:hasSkill(self:objectName()) then
            return ""
        end
        
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
       
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        return ""
    end,
    on_effect = function(self,event,room,player,data)
       --choose at max X+1(X is your lost health)
         local x = player:getLostHp()
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "quanbinh-invoke", true, true)
            if target:getHandcardNum() <= 2 then
                target:drawCards(x+1, "quanbinh")
            end
    end,
}
simalang:addSkill(quanbinh)
ngaoda=sgs.CreateTriggerSkill{
            name = "ngaoda",
            events = {sgs.Dying,sgs.HpRecover},
            frequency = sgs.Skill_Frequent,
            can_trigger = function(self, event, room, player, data)
                if not player or player:isDead()  or not player:hasSkill(self:objectName()) then
                    return ""
                end
                    if event == sgs.Dying then
                        local dying = data:toDying()
                        if dying.who:objectName() ~= player:objectName() then
                            return self:objectName()
                        end
                elseif event == sgs.HpRecover then
                    local recover = data:toRecover()
                    if recover.who:objectName() == player:objectName() then
                        return self:objectName()
                    end
                end
                return ""
            end,
            on_cost = function(self, event, room, player, data)
                if event == sgs.Dying then
                        if room:askForSkillInvoke(player, self:objectName(), data) then
                            room:broadcastSkillInvoke(self:objectName(), player)
                            return true
                        end
                    end
                return ""
            end,
            on_effect = function(self,event,room,player,data)
                if event == sgs.Dying then
                local dying = data:toDying()
                local target = dying.who
                local equips = target:getEquips()
                if equips:isEmpty() then return end
                local card_id = room:askForCardChosen(player, target, "e", self:objectName())
                if card_id == -1 then return end -- Kiểm tra nếu người chơi chọn hủy kích hoạt
                room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, sgs.Player_PlaceEquip, false)
                elseif event == sgs.HpRecover then
                    local equips = player:getEquips()
        if equips:isEmpty() then return end
        local card_id = room:askForCardChosen(player, player, "e", self:objectName())
        if card_id == -1 then return end -- Kiểm tra nếu người chơi chọn hủy kích hoạt
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "ngaoda1-invoke", true, true)
        room:moveCardTo(sgs.Sanguosha:getCard(card_id), target, sgs.Player_PlaceEquip, false)
                end
            end,
                }

trieuthongtrieuquang=sgs.General(extension, "trieuthongtrieuquang", "shu", 4)
trieuthongtrieuquang:addCompanion("zhaoyun")
dieutan = sgs.CreateOneCardViewAsSkill{
	name = "dieutan",
	filter_pattern = "BasicCard|.|.|hand",
    response_or_use = true,
	view_filter = function(self, card)
        local usereason = sgs.Sanguosha:getCurrentCardUseReason()
        if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return card:isKindOf("BasicCard")
        elseif usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == "slash" or pattern == "jink" or pattern == "peach" or pattern == "analeptic" then
                return card:isKindOf("BasicCard")
    end
    end
    end,    
    view_as = function(self, to_select)
		local card_name = sgs.Self:getTag("dieutan"):toString()
		if card_name ~= "" then
			local card = sgs.Sanguosha:cloneCard(card_name)
			card:setCanRecast(false)
			card:addSubcard(to_select:getId())
			card:setSkillName("dieutan")
			card:setShowSkill("dieutan")
			return card
		end
	end,
    enabled_at_play = function(self, player)
		return player:usedTimes("ViewAsSkill_dieutanCard") < 1
	end,
    enabled_at_response = function(self, player, pattern)
        return pattern=="slash" or pattern=="jink" or pattern=="peach" or pattern=="analeptic"
    end,
	vs_card_names = function(self, selected)
		if #selected == 1 then
			return "Slash+Jink+Peach+Analeptic"
		end
		return ""
	end,
}
trieuthongtrieuquang:addSkill(dieutan)
jiange = sgs.CreateOneCardViewAsSkill{   
	name = "jiange",
	response_or_use = true,
	view_filter = function(self, card)
		if card:getTypeId() == sgs.Card_TypeBasic then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		slash:setShowSkill(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
   
return extension