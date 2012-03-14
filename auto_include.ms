/*
    persistence layout:
        mail.<username> array
                |
                +-message: {<sender>, <msg>, 'mail'}
                |
                +-item: {<sender>, '<itemid>,<count>', 'item'}
*/

export(assign(@_mail_debug, false))

proc(_player_mail, @player,
    assign(@mail, get_value(concat('chmail.inbox.', to_lower(@player))))
    
    return(@mail)
)

proc(_update_player_mail, @player, @mail,
    store_value(concat('chmail.inbox.', to_lower(@player)), @mail)
)

proc(_clear_player_mail, @player,
    clear_value(concat('chmail.inbox.', to_lower(@player)))
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

proc(_mail_dispatch, @args,
    # Parse the incoming command, depending on it's first
    # word.
    
    _mail_debug('_mail_dispatch called with ' @args)
    
    # Called with empty command?
    ifelse(array_index_exists(@args, 0),
        assign(@first, @args[0]) # pop first item
        array_remove(@args, 0)
    , # else
        assign(@first, '')	
    )
    
    switch(to_lower(@first),
        # Commands that aren't handled well should show their usage by default.
        
        'send',
            # /mail send <player> <message>
            _mail_debug('_mail_dispatch.send')
            
            # Make sure there is at least 2 items in the args.
            if(array_index_exists(@args, 1),
                # Everything from second item and on is the message.
                _mail_debug('sending' @args[1..] 'to' @args[0])
                
                # Send off the payload.
                if(_send_mail(player(), @args[0], array_implode(@args[1..])),
                    die(concat(color(green), 'Mail successfully sent to ', @args[0]))
                , # else
                    die(concat(color(red), 'Oops, there was an error! Try again later?'))
                )
            , # else
                msg('Usage: /mail send <player> <message>')
            ),

        'senditem',
            # /mail send <player> <item> <count>
            _mail_debug('_mail_dispatch.senditem')
            
            # Check number of arguments.
            if(equals(length(@args), 3),
                # Send off payload.
                
                if(_send_item(@args[0], @args[1], @args[2]),
                    msg(concat(color(green), 'Item(s) successfully sent to ', @args[0]))
                )
            , # else
                msg('Usage: /mail send <player> <item> <count>')
            ),
            
        'accept',
            _mail_debug('_mail_dispatch.accept')
            # /mail accept <id>
            
            # Check arguments.
            if(equals(length(@args), 1),
                # Try to accept items, as many as possible, then delete the mail.
                # If not all items were received, amend the mail and keep it.
                
                if(not(_accept_item(@args[0])),
                    die(concat(color(red), 'Oops, there was an error! Try again later?'))
                )
            , # else
                msg('Usage: /mail accept <id>')
            ),
            
        'read',
            # /mail read [id]
            _mail_debug('_mail_dispatch.read')
            
            # Check args. Don't care about extra args.
            ifelse(array_index_exists(@args, 0),
                # /mail read <id>
                
                _mail_debug('reading id' @args[0])
                
                # Display a single mail.
                ifelse(_read_mail_id(player(), @args[0]),
                    msg('Type /mail clear to clear your mail entries.')
                    msg('Type /mail accept <id> to accept an item.')
                , #else
                    msg(concat(color(red), 'That id does not exist'))
                )
                
                return(true)
            , # else
                # /mail read
                
                _mail_debug('reading mail index')
                
                # Display brief index, max 20 chars per mail.
                if(_read_mail(player()),
                    msg('Type /mail clear to clear your mail entries.')
                    msg('Type /mail accept <id> to accept an item.')
                    msg('Type /mail delete <id> to delete a specific mail.')
                )
                return(true)
            ),
            
        'clear',
            # /mail clear
            _mail_debug('_mail_dispatch.clear')
            
            # Clear all items of mail. 
            # TODO: Should probably make this sensitive to items as well.
            _clear_mail(player()),
            
        'delete',
            # /mail delete <id>
            _mail_debug('_mail_dispatch.delete')
            
            # Check args. Don't care about extras.
            ifelse(array_index_exists(@args, 0),
                _mail_debug('deleting id' @args[0])
                
                # Delete a single mail.
                # TODO: Make sensitive to item mails.
                ifelse(_del_mail(player(), @args[0]),
                    msg(concat(color(green), 'Message with id' @args[0] 'deleted.'))
                , # else
                    msg(concat(color(red), 'That index does not exist!'))
                )
                
                return(true)
            )
            
            msg('Usage: /mail delete <id>'),
            
        # default
        _mail_debug('_mail_dispatch.help')
        
        msg('The following commands are available:')
        msg(concat('- ', color(green), '/mail', color(white), ': show this message'))
        msg(concat('- ', color(green), '/mail send <player> <message>', color(white), ': send <message> to player.'))
        msg(concat('- ', color(green), '/mail senditem <player> <item> <count>', color(white), ': send <count> of <item> to <player> if you have it in your inventory.'))
        msg(concat('- ', color(green), '/mail read [id]', color(white), ': read messages.'))
        msg(concat('- ', color(green), '/mail accept <id>', color(white), ': accept an item a player sent you.'))
        msg(concat('- ', color(green), '/mail clear', color(white), ': clear all messages.'))
        msg(concat('- ', color(green), '/mail delete <id>', color(white), ': delete message <id>.'))
    )
)

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
