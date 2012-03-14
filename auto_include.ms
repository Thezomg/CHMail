/*
    persistence layout:
    
    chmail
        |
        +- inbox.<username> array
        |           |
        |           +- message: {<sender>, <msg>, 'mail'}
        |           |
        |           +- item: {<sender>, '<itemid>,<count>', 'item'}
        |
        +- options array
            |
            +- <name>: value
            |
            +- <name>: value

*/

include('dispatch.ms')
include('util.ms')


proc(_send_mail, @from, @to, @msg, assign(@type, null),
    # Send an abstract mail to someone.
    
    if(or(
    not(is_string(@type)),
    is_null(@type)),
        # allow for a reasonable default
        assign(@type, 'mail')
    )
    
    assign(@mail, _player_mail(@to))
    
    # Creation of actual mail.
    assign(@msg, array(@from, @msg, to_lower(@type)))
    
    if(is_null(@mail),
        # Be absolutely sure @mail is an array
        assign(@mail, array())
    )
    
    # Add the mail to the list and store it.
    array_push(@mail, @msg)
    _update_player_mail(@to, @mail)
    
    # Let the player know.
    if(ponline(@to),
        tmsg(@to,concat(color(green), 'You have mail! Type /mail read to view.'))
    )
    
    return(true)
)

proc(_send_item, @target, @i, @count,
    # Send items, removing them from this user's inventory.
    
    # Convert any human-readable name to integer form
    assign(@item, _item_name_to_value(@i))
    # Find out how many of the item has
    assign(@itemcount, phas_item(player(), @item))
    
    # Lets not give more than the user has!
    if(gte(@itemcount, @count),
        assign(@taken, ptake_item(player(), @item, @count))
        
        # Double check we are taking the amount we want.
        if(equals(@taken, @count),
            # Send off the payload.
            
            # TODO: MIGHT revert to copying the other code here instead, as it could
            # be talored a but better :/
            _send_mail(player(), @target, concat(@item, ',', @count), 'item')
        , # else
            # Oops, give their junk back.
            pgive_item(player, @item, @count)
            die(concat(color(red), 'Oops, error occurred. Giving back your stuff!'))
        )
    , # else
        msg(concat(color(red), 'You don\'t have enough!'))
        
        return(false)
    )
    
    return(true)
)

proc(_accept_item, @i,
    # Accept an item a user has sent us. If the inv is filled and not all items are given,
    # save the rest for later.
    
    # Grab their mailbox
    assign(@mail, _player_mail(player()))
    assign(@id, subtract(@i, 1))
    
    try(
        # Make sure it's an actual item that we are grabbing.
        switch(@mail[@id][2], 
            'mail',
                assign(@message, concat(color(red), 'There is no item associated with this id.')),
                
            'item',
                assign(@data, reg_split(',', @mail[@id][1])) # id,count
                
                # Keep track of how much was given, so we don't lose
                # items due to a full inv.
                assign(@left, subtract(@data[1], pgive_item(player(), @data[0], @data[1])))
                
                if(equals(@left, 0),
                    # Remove the item mail, as it is no longer useful.
                    
                    # _del_mail assumes a 1-based count, @id is 0-based.
                    _del_mail(player(), add(@id, 1)) 
                    msg(concat(color(green), 'Accepted items sent by' @mail[@id][0], '!'))
                    
                    return(true)
                , # else
                    # Looks like we overflowed. Oops. Save the rest.
                    msg(concat(color(red), 'Looks like your inventory is full.' color(green), 'Saving left over items for later :)'))
                    
                    assign(@mail[@id][1], concat(@data[0], ',', @left))
                    _update_player_mail(player(), @mail)
                    
                    return(true)
                ),
                
            # default
                assign(@message, '(This person sent you -something-, but I have no idea what to do with it!) :(')
        )
        
        msg(concat('[', color(red), @mail[@id][0],color(white),'] ', $message))
        
        return(true)
    , @ex,
        return(false)
    )
)

proc(_read_mail, @player,
    assign(@mail, _player_mail(@player))
    # Index for display
    assign(@i, 1)
    
    # Make sure the user really does have mail.
    if(or(
    is_null(@mail), 
    equals(length(@mail), 0)),
        msg(concat(color(red), 'No mail for' to_lower(@player), '.'))
        return(false)
    , # else
		msg(concat(color(green), 'Inbox for' to_lower(@player), ':'))
		
        foreach(@mail, @msg,
            # Check each message on the fly for it's type.
            switch(@msg[2], 
                'mail',
                    # Display up to 20 characters of the message.
                    # Use /mail read <id> to display full message.
                    
                    if(lt(length(@msg[1]),20),
                        assign(@message, @msg[1])
                    ,
                        assign(@message, concat(substr(@msg[1], 0, 17), '...'))
                    ),
                'item',
                    # Quick n' dirty display of the item involved.
                    
                    assign(@data, reg_split(',', @msg[1])) # {item, count}
                    assign(@message, concat('[ ', @data[1] data_name(@data[0]), ' ]')), # [ <num> <item> ]
                # default
                    assign(@message, '(This person sent you -something-, but I have no idea what to do with it!) :(')
            )
            
            # Actually show the message!
            msg(concat(@i, ') [', color(red), @msg[0], color(white),'] ', @message))
            inc(@i)
        )
        
        return(true)
    )
)

proc(_read_mail_id, @player, @i,
    # Read an individual mail.
    
    # Grab the users mailbox.
    assign(@mail, _player_mail(@player))
    assign(@id, subtract(@i, 1))
    
    try(
        # Check the type of the mail, and act on it.
        # If no mail with this id exists, allow the exception to be raised, and return false later.
        switch(@mail[@id][2], 
            'mail',
                # Plain message
                assign(@message, @mail[@id][1]),
            'item',
                # Item. Show helpful message on how to accept.
                assign(@data, reg_split(',', @mail[@id][1]))
                assign(@message, concat('[ ', @data[1] data_name(@data[0]), ' ] Type', '`/mail accept ', @id, '`', 'to accept.')),
            # default
                assign(@message, '(This person sent you -something-, but I have no idea what to do with it!) :(')
        )
        
        # Display the message or item.
        msg(concat('[', color(red), @mail[@id][0],color(white),'] ', $message))
        
        return(true)
    , @ex,
        # No mail with that id exists (or some other error, but we are expecting this one!)
        return(false)
    )
)

proc(_clear_mail, @player,
    # Get rid of everything.
    _clear_player_mail(@player)
    msg(concat(color(green), 'Mail successfully cleared for ' @player))
)

proc(_del_mail, @player, @id,
    # Delete an individual item.
    
    # Get their mailbox
    assign(@mail, _player_mail(@player))
    assign(@remid, subtract(@id, 1))
    
    # Make sure the id exists
    ifelse(array_index_exists(@mail, @remid),
        # You are the weakest link. * snip *
        array_remove(@mail, @remid)
        _update_player_mail(@player, @mail)
        
        return(true)
    , # else
        return(false)
    )
)
