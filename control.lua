script.on_event(
    defines.events.on_player_created,
    function(event)
        local player = game.players[event.player_index]
        
        player.remove_item({name="iron-plate", count=8})

        player.insert{name="assembling-machine-2", count=1}
        player.insert{name="solidifier", count=1}
        player.insert{name="pipe", count=50}
        player.insert{name="pipe-to-ground", count=50}
        player.insert{name="iron-axe", count=1}
        player.insert{name="offshore-pump", count=1}
        player.insert{name="boiler", count=1}
        player.insert{name="steam-engine", count=1}
        player.insert{name="small-electric-pole", count=10}
		player.insert{name="oil-refinery", count=10}

        player.force.technologies["automation"].researched = true
    end
)