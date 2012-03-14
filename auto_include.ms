assign(@_mail_debug, false)

proc(_item_name_to_value, @i,
    assign(@parts, reg_split(':', @i))
    
    switch(length(@parts),
        2,
            assign(@item, data_values(@parts[0]))
            
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
    if(equals(@_mail_debug, true),
        console(@msg)
    )
)

proc(_mail_dispatch, @args,
    _mail_debug('_mail_dispatch called with ' @args)
    
    ifelse(array_index_exists(@args, 0),
        assign(@first, @args[0]) # pop first item
        array_remove(@args, 0)
    , # else
        assign(@first, '')	
    )
    
    switch(to_lower(@first),
        'send',
            # /mail send <player> <message>
            _mail_debug('switching to send')

            if(array_index_exists(@args, 1),
                _mail_debug('sending' @args[1..] 'to' @args[0])
                
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
            _mail_debug('switching to senditem')
            
            if(equals(length(@args), 3),
                if(_send_item(@args[0], @args[1], @args[2]),
                    msg(concat(color(green), 'Item(s) successfully sent to ', @args[0]))
                )
            , # else
                msg('Usage: /mail send <player> <item> <count>')
            ),
            
        'accept',
            # /mail accept <id>
            
            if(equals(length(@args), 1),
                if(not(_accept_item(@args[0])),
                    die(concat(color(red), 'Oops, there was an error! Try again later?'))
                )
            , # else
                msg('Usage: /mail accept <id>')
            ),
            
        'read',
            # /mail read [id]
            _mail_debug('switching to read')
            
            ifelse(array_index_exists(@args, 0),
                # /mail read <id>
                _mail_debug('reading id' @args[0])
                
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
                
                _read_mail(player())
                
                return(true)
            ),
            
        'clear',
            # /mail clear
            _mail_debug('switching to clear')
            
            _clear_mail(player()),
            
        'delete',
            # /mail delete <id>
            _mail_debug('switching to delete')
            
            ifelse(array_index_exists(@args, 0),
                _mail_debug('deleting id' @args[0])
                
                ifelse(_del_mail(player(), @args[0]),
                    msg(concat(color(green), 'Message with id' @args[0] 'deleted.'))
                , # else
                    msg(concat(color(red), 'That index does not exist!'))
                )
                
                return(true)
            )
            
            msg('Usage: /mail delete <id>'),
            
        # default
        _mail_debug('defaulting to help')
        
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
    if(or(
    not(is_string(@type)),
    is_null(@type)),
        assign(@type, 'mail')
    )
    
    assign(@mail, get_value(concat('mail.', to_lower(@to))))
    assign(@msg, array(@from, @msg, to_lower(@type)))
    
    if(is_null(@mail),
        assign(@mail, array())
    )
    
    array_push(@mail, @msg)
    store_value(concat('mail.', to_lower(@to)), @mail)
    
    if(ponline(@to),
        tmsg(@to,concat(color(green), 'You have mail! Type /mail read to view.'))
    )
    
    return(true)
)

proc(_send_item, @target, @i, @count,
    assign(@item, _item_name_to_value(@i))
    assign(@itemcount, phas_item(player(), @item))
    
    if(gte(@itemcount, @count),
        assign(@taken, ptake_item(player(), @item, @count))
        
        if(equals(@taken, @count),
            _send_mail(player(), @target, concat(@item, ',', @count), 'item')
        , # else
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
    assign(@mail, get_value(concat('mail.', to_lower(player()))))
    assign(@id, subtract(@i, 1))
    
    try(
        switch(@mail[@id][2], 
            'mail',
                assign(@message, concat(color(red), 'There is no item associated with this id.')),
            'item',
                assign(@data, reg_split(',', @mail[@id][1]))
                assign(@left, subtract(@data[1], pgive_item(player(), @data[0], @data[1])))
                
                if(equals(@left, 0),
                    _del_mail(player(), add(@id, 1))
                    
                    msg(concat(color(green), 'Accepted items sent by' @mail[@id][0], '!'))
                    
                    return(true)
                , # else
                    msg(concat(color(red), 'Looks like your inventory is full.' color(green), 'Saving left over items for later :)'))
                    
                    assign(@mail[@id][1], concat(@data[0], ',', @left))
                    store_value(concat('mail.', to_lower(player())), @mail)
                    
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
    assign(@mail, get_value(concat('mail.', to_lower(@player))))
    assign(@i, 1)
    
    if(or(
    is_null(@mail), 
    equals(length(@mail), 0)),
        msg(concat(color(red), 'No mail for' to_lower(@player), '.'))
    , # else
		msg(concat(color(green), 'Inbox for' to_lower(@player), ':'))
		
        foreach(@mail, @msg,
            switch(@msg[2], 
                'mail',
                    if(lt(length(@msg[1]),20),
                        assign(@message, @msg[1])
                    ,
                        assign(@message, concat(substr(@msg[1], 0, 17), '...'))
                    ),
                'item',
                    assign(@data, reg_split(',', @msg[1]))
                    assign(@message, concat('[ ', @data[1] data_name(@data[0]), ' ]')),
                # default
                    assign(@message, '(This person sent you -something-, but I have no idea what to do with it!) :(')
            )
            
            msg(concat(@i, ') [', color(red), @msg[0], color(white),'] ', @message))
            inc(@i)
        )
    )
)

proc(_read_mail_id, @player, @i,
    assign(@mail, get_value(concat('mail.', to_lower(@player))))
    assign(@id, subtract(@i, 1))
    
    try(
        switch(@mail[@id][2], 
            'mail',
                assign(@message, @mail[@id][1]),
            'item',
                assign(@data, reg_split(',', @mail[@id][1]))
                assign(@message, concat('[ ', @data[1] data_name(@data[0]), ' ] Type', '`/mail accept ', @id, '`', 'to accept.')),
            # default
                assign(@message, '(This person sent you -something-, but I have no idea what to do with it!) :(')
        )
        
        msg(concat('[', color(red), @mail[@id][0],color(white),'] ', $message))
        
        return(true)
    , @ex,
        return(false)
    )
)

proc(_clear_mail, @player,
    clear_value(concat('mail.', to_lower(@player)))
    msg(concat(color(green), 'Mail successfully cleared for ' @player))
)

proc(_del_mail, @player, @id,
    assign(@mail, get_value(concat('mail.', to_lower(@player))))
    assign(@remid, subtract(@id, 1))
    
    ifelse(array_index_exists(@mail, @remid),
        array_remove(@mail, @remid)
        store_value(concat('mail.', to_lower(@player)), @mail)
        
        return(true)
    , # else
        return(false)
    )
)
