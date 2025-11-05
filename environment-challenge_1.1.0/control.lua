script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    pcall(player.exit_cutscene)
    player.insert{name="wood", count=200}
    end)