bind(player_join, null, null, @event, @server_name,
    assign(@mail, get_value(concat('mail_', to_lower(@event[player]))))

    if(is_null(@mail),
        die()
    , # else
        tmsg(@event[player], concat(color(green), 'You have mail! Type /mail read to see'))
    )
)
