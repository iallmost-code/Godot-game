extends VBoxContainer
# Town Merchant: buy potions and gear, sell or dismantle, and enhance at the Forge.
const Catalog=preload("res://data/catalog.gd")
const Maps=preload("res://data/maps.gd")
const Style=preload("res://ui/style.gd")
const ItemText=preload("res://ui/item_text.gd")
var state
var map_id="town"
var tab="potions"
var note=""
func bind(s,_bindings=null):
    state=s
    refresh()
func set_context(id: String):
    map_id=id
    refresh()
func town() -> Dictionary: return Maps.definition(map_id)
func in_town() -> bool: return town().get("safe",false)
func town_level() -> int: return int(town().get("level",1))
func open_tab(id: String):
    tab=id
    note=""
    refresh()
func buy_potion(id: String,count: int):
    var info=Catalog.consumables()[id]
    note=("Bought %d %s." % [count,info.name]) if state.buy_consumable(id,count,town_level()) else "Not enough coins."
    refresh()
func buy_gear(id: String):
    note=("Bought %s." % Catalog.items()[id].name) if state.buy_item(id) else ("Inventory full." if state.inventory.size()>=state.INVENTORY_LIMIT else "Not enough coins.")
    refresh()
func sell(uid: int,dismantle: bool):
    var inst=state.instance(uid)
    var name=ItemText.title(inst)
    var amount=state.dismantle(uid) if dismantle else state.sell(uid)
    note=("%s %s for %d %s." % ["Dismantled" if dismantle else "Sold",name,amount,"Shards" if dismantle else "coins"]) if amount>0 else "Worn gear cannot be sold."
    refresh()
func bulk(dismantle: bool):
    var total=0
    var count=0
    for uid in state.worse_gear():
        var gained=state.dismantle(uid) if dismantle else state.sell(uid)
        if gained>0:
            total+=gained
            count+=1
    note=("%s %d items for %d %s." % ["Dismantled" if dismantle else "Sold",count,total,"Shards" if dismantle else "coins"]) if count>0 else "Nothing weaker than your worn gear."
    refresh()
func forge(uid: int):
    var inst=state.instance(uid)
    var name=ItemText.title(inst)
    match state.forge(uid):
        "success": note="Success! %s is now +%d." % [Catalog.items()[inst.id].name,inst.plus]
        "fail": note="The forge failed. %s keeps its +%d; the materials were used up." % [name,inst.plus]
        "max": note="%s is already at +%d." % [name,Catalog.MAX_PLUS]
        _: note="Not enough Shards or coins."
    refresh()
func row(parent: Node,text: String,detail: String) -> HBoxContainer:
    var line=HBoxContainer.new()
    parent.add_child(line)
    var block=VBoxContainer.new()
    block.custom_minimum_size.x=520
    block.add_theme_constant_override("separation",0)
    line.add_child(block)
    block.add_child(Style.label(text,15))
    if detail!="": block.add_child(Style.label(detail,12,Color("617180")))
    return line
func refresh():
    Style.clear(self)
    if not in_town():
        add_child(Style.section("MERCHANT"))
        add_child(Style.label("Merchants trade in towns. Stand beside a town's Merchant and press Up,\nor open this tab while you are in any town.",16))
        add_child(Style.label("You can still dismantle gear anywhere from the Inventory.",14,Color("25758a")))
        return
    add_child(Style.section("MERCHANT  /  %s  •  Coins %d  •  Shards %d" % [town().name.to_upper(),state.coins,state.shards]))
    var tabs=HBoxContainer.new()
    add_child(tabs)
    for entry in [["potions","Buy Potions"],["gear","Buy Gear"],["sell","Sell / Dismantle"],["forge","Forge"]]:
        var id=entry[0]
        var button=Style.button(entry[1],func(): open_tab(id))
        button.modulate=Color("b7d88a") if id==tab else Color.WHITE
        tabs.add_child(button)
    if note!="": add_child(Style.label(note,15,Color("25758a")))
    match tab:
        "potions":
            for id in Catalog.consumables():
                var info=Catalog.consumables()[id]
                var effect="Restores %d %s" % [info.amount,"MP" if info.kind=="mp" else "HP"] if info.has("amount") else ("Fully restores HP and MP" if info.kind=="full" else "Restores %d%% of max %s" % [int(info.pct*100),"MP" if info.kind=="mp" else "HP"])
                var line=row(self,"%s  —  %d coins" % [info.name,info.price],"%s  •  You have %d" % [effect,int(state.consumables.get(id,0))]+("" if town_level()>=info.town else "  •  Sold in towns of level %d+" % info.town))
                for count in [1,10,100]:
                    var button=Style.button("Buy %d" % count,func(): buy_potion(id,count))
                    button.disabled=town_level()<info.town or state.coins<info.price*count
                    line.add_child(button)
        "gear":
            add_child(Style.label("Stock for this town's level. Weapons match your job's weapon type.",13))
            for id in Catalog.shop_gear(town_level(),state.preferred_weapon()):
                var inst={"uid":-1,"id":id,"plus":0}
                var line=row(self,"%s  —  %d coins" % [Catalog.items()[id].name,state.buy_price(id)],ItemText.requirement(state,inst)+"  •  "+ItemText.stats_line(state,inst))
                var button=Style.button("Buy",func(): buy_gear(id))
                button.disabled=state.coins<state.buy_price(id) or state.inventory.size()>=state.INVENTORY_LIMIT
                line.add_child(button)
        "sell":
            var worse=state.worse_gear().size()
            var bulk_row=HBoxContainer.new()
            add_child(bulk_row)
            var sell_all=Style.button("Sell all worse gear (%d)" % worse,func(): bulk(false))
            sell_all.disabled=worse==0
            bulk_row.add_child(sell_all)
            var dismantle_all=Style.button("Dismantle all worse gear (%d)" % worse,func(): bulk(true))
            dismantle_all.disabled=worse==0
            bulk_row.add_child(dismantle_all)
            var any=false
            for inst in state.inventory.duplicate():
                if state.is_equipped(inst.uid): continue
                any=true
                var uid=inst.uid
                var line=row(self,ItemText.title(inst),ItemText.stats_line(state,inst)+"  •  "+ItemText.compare(state,inst))
                line.add_child(Style.button("Sell %d" % state.sell_value(inst),func(): sell(uid,false)))
                line.add_child(Style.button("Dismantle %d" % state.shard_yield(inst),func(): sell(uid,true)))
            if not any: add_child(Style.label("Only your worn gear is in your bag.",14))
        "forge":
            add_child(Style.label("Enhance gear up to +%d with Shards and coins. A failed attempt keeps the item's level and only uses the materials." % Catalog.MAX_PLUS,13))
            var ordered=[]
            for slot in Catalog.GEAR_SLOTS:
                if state.equipped.has(slot): ordered.append(state.instance(state.equipped[slot]))
            for inst in state.inventory:
                if not state.is_equipped(inst.uid): ordered.append(inst)
            for inst in ordered:
                var uid=inst.uid
                var cost=state.forge_cost(inst)
                var detail=("At maximum +%d." % Catalog.MAX_PLUS) if cost.is_empty() else "Next: +%d  •  %d%% chance  •  %d Shards + %d coins" % [inst.plus+1,int(cost.chance*100),cost.shards,cost.coins]
                var line=row(self,ItemText.title(inst)+("  (worn)" if state.is_equipped(uid) else ""),ItemText.stats_line(state,inst)+"  •  "+detail)
                var button=Style.button("Forge",func(): forge(uid))
                button.disabled=cost.is_empty() or state.shards<cost.get("shards",0) or state.coins<cost.get("coins",0)
                line.add_child(button)
