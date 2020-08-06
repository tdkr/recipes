db.getCollection('game_config_copy').find().forEach(function (doc){
    for (k in doc.game_cfg_map) {
        var field = "game_cfg_map."+k+".custom_config"
        var update = {$unset:{}}
        update.$unset[field]=null
        print({"field":field, "result":db.getCollection('game_config_copy').update({"_id": doc._id}, update)})
    }
})