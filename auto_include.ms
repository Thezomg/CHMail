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
        |   |
        |   +- <name>: value
        |   |
        |   +- <name>: value
        |
        +- poptions.<username> array
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
        tmsg(@to, color(green), 'You have mail! Type /mail read to view.')
    )
    
    return(true)
)

proc(_send_hand_item, @target, @i, @count,
    if(equals(player(), '~console'),
        msg(color(red), 'You are console. You have no hand!')
        return(false)
    )
    
    assign(@hand, pinv(player(), null))
        
    # If there's nothing there, there's not much else to do
    if(is_null(@hand),
        msg(color(red), 'There\'s nothing in your hand!')
        return(false)
    , # else
        assign(@item, concat(@hand['type'], ':', @hand['data']))
        
        # How many of the item is in their hand?
        assign(@handcount, @hand['qty'])
        
        # If an amount wasn't specified, grab the whole thing
        if(equals(@count, 'i1'),
            _mail_debug('No amount was specified. Sending everything.')
            
            set_pinv(player(), array(null: null))
            
            _mail_debug('Removed item')
            
            # No checking necessary. B)
            _send_mail(player(), @target, concat(@item, ',', @handcount), 'item')
            
            return(true)
        , # else
            # Did the user specify more than they had?
            _mail_debug(sconcat('Seeing if', @handcount, 'is greater than or equal to', @count))
            
            if(gte(@handcount, @count),
                assign(@left, subtract(@handcount, @count))
                
                if(equals(@left, 0),
                    set_pinv(array(null: null))
                    
                    _mail_debug('Removed item')
                , # else
                    assign(@leftovers, @hand)
                    array_set(@leftovers, 'qty', @left)
                    
                    set_pinv(player(), array(null: @leftovers))
                    
                    _mail_debug(sconcat('Leaving item in hand with' @leftovers))
                )
                
                # Locked 'n ready, cap'n!
                _send_mail(player(), @target, concat(@item, ',', @count), 'item')
                
                return(true)
            , # else
                msg(color(red), 'You don\'t have enough of the item!')
                return(false)
            )
        )
    )
)

proc(_send_item, @target, @i, @c,
    # Send items, removing them from this user's inventory.
    
    # Use the item in their hand if they specified "hand"
    if(equals_ic(@i, 'hand'),
        return(_send_hand_item(@target, @i, @c))
    , # else
        assign(@item, _item_name_to_value(@i))
        
        # Find out how many of the item the user has
        if(equals(player(), '~console'),
            assign(@itemcount, 99999999)
        , # else
            assign(@itemcount, phas_item(player(), @item))
        )
        
        # If no amount was specified, assume 1
        if(equals(@c, 'i1'),
            assign(@count, 1)
        , # else
            assign(@count, @c)
        )
    
        # Lets not give more than the user has!
        _mail_debug(sconcat('Seeing if' @itemcount 'is greater than' @count))
        
        if(gte(@itemcount, @count),
            if(equals(player(), '~console'),
                assign(@taken, @count)
            , #else
                assign(@taken, ptake_item(player(), @item, @count))
            )
            
            # Double check we are taking the amount we want.
            if(equals(@taken, @count),
                # Send off the payload.
                    
                # TODO: MIGHT revert to copying the other code here instead, as it could
                # be tailored a bit better :/
                _send_mail(player(), @target, concat(@item, ',', @count), 'item')
                
                return(true)
            , # else
                # Oops, give their junk back.
                pgive_item(player(), @item, @taken)
                
                msg(color(red), 'Oops, error occurred. Giving back your stuff!')
                
                return(false)
            )
        , # else
            msg(color(red), 'You don\'t have enough of this item!')
            return(false)
        )
    )
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
                    msg(color(green), 'Accepted items sent by' @mail[@id][0], '!')
                    
                    return(true)
                , # else
                    # Looks like we overflowed. Oops. Save the rest.
                    msg(color(red), 'Looks like your inventory is full.' color(green), 'Saving left over items for later :)')
                    
                    assign(@mail[@id][1], concat(@data[0], ',', @left))
                    _update_player_mail(player(), @mail)
                    
                    return(true)
                ),
                
            # default
                assign(@message, '(This person sent you -something-, but I have no idea what to do with it!) :(')
        )
        
        msg('[', color(red), @mail[@id][0],color(white),'] ', $message)
        
        return(true)
    , @ex,
        return(false)
    )
)

proc(_read_index, @player, @page,
    assign(@inbox, _player_mail(@player))
    
    # Make sure the user really does have mail.
    if(or(
    is_null(@inbox), 
    equals(length(@inbox), 0)),
        msg(color(red), 'No mail for' to_lower(@player), '.')
        return(false)
    , # else
        # Page the inbox, to not clutter the chatarea too much.
        assign(@pages, ceil(divide(length(@inbox), 4)))
        
        # Make sure the page exists.
        if(gt(@page, @pages),
            die(concat(color(red), 'Invalid inbox page! ( only' @pages 'exist )'))
        )
        
        msg(color(green), 'Inbox for' to_lower(@player), ': [ Page' @page 'of' @pages ']')
        
        # Slice the actual pages we want
        assign(@mail, _page(@inbox, 5, @page))
        
        # Index for display
        # Depends on which page we are on!
        assign(@id, multiply(subtract(@page, 1), 5))
        
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
            msg(add(@id, 1), ') [', color(red), @msg[0], color(white),'] ', @message)
            inc(@id)
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
        msg('[', color(red), @mail[@id][0],color(white),'] ', $message)
        
        return(true)
    , @ex,
        # No mail with that id exists (or some other error, but we are expecting this one!)
        return(false)
    )
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
