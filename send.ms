proc(_send_mail, @from, @to, @msg, assign(@type, null),
    # Send an abstract mail to someone.
    
    # Restrict permissions for this.
    if(not(has_permission(player(), 'chmail.send')),
        die(concat(color(red), 'You do not have the required permissions to send mail!'))
    )
    
    # Keep the user from sending messages too quickly,
    # unless they have an overriding permission.
    assign(@timeout, _get_option('sendtimeout', 10))
    assign(@cooleddown, _cooleddown(@timeout, 'send'))
    assign(@hasperms, has_permission(player(), 'chmail.send.bypasstimeout'))
    
    if(not(@cooleddown) && not(@hasperms),
        die(concat(color(red), 'You need to wait' @timeout 'seconds between messages!'))
    )
    
    if(not(is_string(@type)) || is_null(@type),
        # allow for a reasonable default
        assign(@type, 'mail')
    )
    
    # Grab the player's mailbox
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
        tmsg(@to, color(green), 'You have mail! Type `/mail inbox` to view.')
    )
    
    return(true)
)
