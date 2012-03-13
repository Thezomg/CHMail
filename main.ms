bind(player_join, null, null, @event, @server_name,
    assign(@mail, get_value(concat('mail.', to_lower(@event[player]))))

    if(or(
    is_null(@mail),
    equals(length(@mail), 0)),
        die()
    , # else
        tmsg(@event[player], concat(color(green), 'You have mail! Type /mail read to see'))
    )
)
