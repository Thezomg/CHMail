proc(_isonline, @player, @msg,
        assign(@ap, all_players())
        foreach(@ap, @p,
                if(equals(to_lower(@player), to_lower(@p)), return(true))
        )

        return(false)
)
