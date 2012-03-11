proc(_isonline, @pl, @msg,
    assign(@ap, all_players())
    assign(@player, to_lower(@pl))
    
    foreach(@ap, @p,
        if(equals(@player, to_lower(@p)), 
            return(true)
        )
    )

    return(false)
)

proc(_mail_dispatch, @args,
    ifelse(array_index_exists(@args, 0),
        assign(@first, array_remove(@args, 0)) # pop first item
    , # else
        assign(@first, '')
    )
    
    switch(to_lower(@first),
        'send',
            # /mail send <player> <message>
            
            if(array_index_exists(@args, 1),
                if(_send_mail(player(), @args[0], array_implode(@args[1..])),
                    msg(concat(color(green), 'Mail successfully sent to ', @args[0]))
                )
                
                return(true)
            )
            
            msg('Usage: /mail send <player> <message>'),
            
        'read',
            # /mail read [id]
            
            ifelse(array_index_exists(@args, 0),
                # /mail read <id>
                
                ifelse(_read_mail_id(player(), @args[0]),
                    msg('Type /mail clear to clear your mail entries.')
                , #else
                    msg(concat(color(red), 'That id does not exist'))
                )
                
                return(true)
            , # else
                # /mail read
                
                _read_mail(player())
                
                return(true)
            ),
            
        'clear',
            # /mail clear
            
            _clear_mail(player()),
            
        'delete',
            # /mail delete <id>
            
            ifelse(array_index_exists(@args, 0),
                ifelse(_del_mail(player(), @args[0]),
                    msg(concat(color(green), 'Message with id' @args[0] 'deleted.'))
                , # else
                    msg(concat(color(red), 'That index does not exist!'))
                )
                
                return(true)
            )
            
            msg('Usage: /mail delete <id>'),
            
        # default
            
        msg('The following commands are available:')
        msg(concat('- ', color(green), '/mail', color(white), ': show this message'))
        msg(concat('- ', color(green), '/mail send <player> <message>', color(white), ': send <message> to player.'))
        msg(concat('- ', color(green), '/mail read [id]', color(white), ': read messages'))
        msg(concat('- ', color(green), '/mail clear', color(white), ': clear all messages'))
        msg(concat('- ', color(green), '/mail delete <id>', color(white), ': delete message <id>'))
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
    
    if(_isonline(@to),
        tmsg(@to,concat(color(green), 'You have mail! Type /mail read to view.'))
    )
    
    return(true)
)

proc(_read_mail, @player,
    assign(@mail, get_value(concat('mail_', to_lower(@player))))
    assign(@i, 1)
    
    if(is_null(@mail),
        msg(concat(color(red), 'No mail for' to_lower(@player), '.'))
    , # else
        foreach(@mail, @msg,
            if(lt(length(@msg[1]),20),
                assign(@message, @msg[1])
            ,
                assign(@message, concat(substr(@msg[1], 0, 17), '...'))
            )
            
            msg(concat(@i, ') [', color(red), @msg[0], color(white),'] ', @message))
            inc(@i)
        )
    )
)

proc(_read_mail_id, @player, @id,
    assign(@mail, get_value(concat('mail_', to_lower(@player))))
    
    try(
        msg(concat('[', color(red), @mail[subtract(@id, 1)][0],color(white),'] ', @mail[subtract(@id, 1)][1]))
        return(true)
    , @ex,
        return(false)
    )
)

proc(_clear_mail, @player,
    store_value(concat('mail_', to_lower(@player)), null)
    msg(concat(color(green), 'Mail successfully cleared for ' @player))
)

proc(_del_mail, @player, @id,
    assign(@mail, get_value(concat('mail_', to_lower(@player))))
    assign(@remid, subtract(@id, 1))
    
    ifelse(array_index_exists(@mail, @remid),
        array_remove(@mail, @remid)
        store_value(concat('mail_', to_lower(@player)), @mail)
        
        return(true)
    , # else
        return(false)
    )
)