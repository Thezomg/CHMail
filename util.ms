export(assign(@_mail_debug, false))

proc(_player_mail, @player,
    assign(@mail, get_value(concat('chmail.inbox.', to_lower(@player))))
    
    return(@mail)
)

proc(_update_player_mail, @player, @mail,
    store_value(concat('chmail.inbox.', to_lower(@player)), @mail)
)

proc(_get_option, @n,
    assign(@name, to_lower(@n))
    assign(@id, concat('chmail.options.', @name))
    
    if(has_value(@id),
        assign(@opt, get_value(@id))
    , # else
        assign(@opt, null)
    )
    
    return(@opt)
)

proc(_set_option, @n, @value,
    assign(@name, to_lower(@n))
    assign(@id, concat('chmail.options.', @name))
    
    store_value(@id, @value)
)

proc(_clear_option, @n,
    assign(@name, to_lower(@n))
    assign(@id, concat('chmail.options.', @name))
    
    clear_value(@id)
)

proc(_get_poption, @player, @n,
    assign(@name, to_lower(@n))
    assign(@id, concat('chmail.poptions.', to_lower(@player), '.', @name))
    
    if(has_value(@id),
        assign(@opt, get_value(@id))
    , # else
        assign(@opt, null)
    )
    
    return(@opt)
)

proc(_set_poption, @player, @n, @value,
    assign(@name, to_lower(@n))
    assign(@id, concat('chmail.poptions.', to_lower(@player), '.', @name))
    
    store_value(@id, @value)
)

proc(_clear_poption, @player, @n,
    assign(@name, to_lower(@n))
    assign(@id, concat('chmail.poptions.', to_lower(@player), '.', @name))
    
    clear_value(@id)
)

proc(_clear_poptions, @player,
    assign(@options, get_values(concat('chmail.poptions.', to_lower(@player))))
    
    foreach(@options, @option,
        clear_value(@option)
    )
)
    

proc(_clear_player_mail, @player,
    clear_value(concat('chmail.inbox.', to_lower(@player)))
)

proc(_clear_all_mail,
    assign(@inboxes, get_values(concat('chmail.inbox')))
    
    foreach(@inboxes, @inbox,
        clear_value(@inboxes)
    )
)

proc(_item_name_to_value, @i,
    # Translates an item's human-readable name, if present, into its
    # integer equivalent. Keeps damage values in mind.
    
    assign(@parts, reg_split(':', @i)) # {item [, damage]}
    
    switch(length(@parts),
        # Check to see if damage data was included.
        2,
            assign(@item, data_values(@parts[0]))
            
            # Make sure the value returned was sane. If not, bail.
            if(not(is_null(@item)),
                assign(@retn, concat(@item, ':', @parts[1]))
            , # else
                assign(@retn, null)
            ),
        1,
            assign(@retn, data_values(@parts[0])),
        # default
        assign(@retn, null)
    )
    
    return(@retn)
)

proc(_mail_debug, @msg,
    import(@_mail_debug)
    
    if(equals(@_mail_debug, true),
        console(@msg)
    )
)
