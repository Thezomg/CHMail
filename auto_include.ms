proc(_isonline, @player, @msg,
    assign(@ap, all_players())
    foreach(@ap, @p,
            if(equals(to_lower(@player), to_lower(@p)), return(true))
    )

    return(false)
)

proc(_mail_dispatch, @args,
    assign(@permerror, 'You do not have permission for this command.')
    
    ifelse(array_index_exists(@args, 0),
        assign(@first, array_remove(@args, 0)) # pop first item
    , # else
        assign(@first, '')
    )
    
    if(not(has_permission('mail')),
        msg(@permerror)
        return(false)
    )
    
    switch(to_lower(@first),
        'send',
            if(not(has_permission('mail.send')),
                msg(@permerror)
                return(false)
            )
            
            if(array_index_exists(@args, 1),
                # /mail send Deaygo It lives!
                _send_mail(player(), @args[0], array_implode(@args[1..]))
                return(true)
            )
            
            msg('Usage: /mail send <player> <message>') 
            ,
            
        'read',
            ifelse(array_index_exists(@args, 0),
                # /mail read 1
                _read_mail_id(player(), @args[0]) 
                return(true)
            , # else
                # /mail read
                _read_mail(player()) 
                return(true)
            ),
            
        'readother',
            ifelse((has_permission('mail.readother')),
                ifelse(array_index_exists(@args, 1),
                    # /mail readother Deaygo 1
                    _read_mail_id(@args[0], @args[1]) 
                    return(true)
                , # else
                    # /mail readother Deaygo
                    if(array_index_exists(@args, 0),
                        _read_mail(@args[0]) 
                        return(true)
                    )
                )
                , # else
                    msg(@permerror)
                    return(false)
            )
            
            msg('Usage: /mail readother <player> [id]')
            ,
            
        'clear',
            # /mail clear
            _clear_mail(player()),
            
        'clearother',
            # /mail clearother <player>
            if(not(has_permission('mail.clearother')),
                msg(@permerror)
                return(false)
            )
            
            if(array_index_exists(@args, 0),
                _clear_mail(@args[0])
                return(true)
            )
            
            msg('Usage: /mail clearother <player>'),
            
        msg('The following commands are available:')
        msg('- /mail: show this message')
        msg('- /mail read [id]: read messages')
        msg('- /mail readother <player> [id]: read messages for <player>')
        msg('- /mail clear: clear all messages')
        msg('- /mail send <player> <message>: send <message> to player.')
    )
)

proc(_send_mail, @from, @to, @msg,
    assign(@mail, get_value(concat('mail_', to_lower($to))))
    assign(@msg, array(@from, @msg));
    
    if(is_null(@mail),
        assign(@mail, array())
    )
    
    array_push(@mail, @msg);
    store_value(concat('mail_', to_lower(@to)), @mail);
    msg(concat(color(green), 'Mail successfully sent to ', @to, color(white)))
    
    if(_isonline(@to),
        tmsg(@to,concat(color(green), 'You have mail! Type /mail read to view.', color(white)))
    )
)

proc(_read_mail, @player,
    assign(@mail, get_value(concat('mail_', to_lower(@player))))
    assign(@i, 1);
    if(is_null(@mail),
        msg(concat(color(red), 'You have no mail', color(white)))
    ,
        foreach(@mail,@msg,
            if(lt(length(@msg[1]),20),
                assign(@message, @msg[1])
            ,
                assign(@message, concat(substr(@msg[1], 0, 17), '...'))
            )
            msg(concat(@i, ') [', color(red), @msg[0], color(white),'] ', @message))
            inc(@i);
        )
        msg('Type /mail clear to clear your mail entries.')
    )
)

proc(_read_mail_id, @player, @id,
    assign(@mail, get_value(concat('mail_', to_lower(@player))))
    try(
        msg(concat('[', color(red), @mail[subtract(@id, 1)][0],color(white),'] ', @mail[subtract(@id, 1)][1]))
        msg('Type /mail clear to clear your mail entries.')
    ,@ex,
        msg(concat(color(red), 'That message does not exist', color(white)))
    )
)

proc(_clear_mail, @player,
    store_value(concat('mail_', to_lower(@player)), null)
    msg(concat(color(green), 'Mail successfully cleared for ' @player, color(white)))
)