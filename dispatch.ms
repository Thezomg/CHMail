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