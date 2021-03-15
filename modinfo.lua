name =						" JesterOK mod"
version = 					"4.0.0"
description =				"Version: "..version
author =					"Cunning fox"

forumthread = 				""

dont_starve_compatible 		= false
reign_of_giants_compatible	= false
dst_compatible 				= true
priority 					= -1.2578
api_version 				= 10

all_clients_require_mod 	= true
client_only_mod 			= false

configuration_options = {
	{
		name = "mobs",
		label = "",
		options = {
			{
				description = "",
				data = {moose = true},
			}
		},
		default = {moose = true},
	},
	{
		name = "glommer",
		label = "",
		options = {
			{
				description = "",
				data = 100,
			}
		},
		default = 100,
	},
	{
		name = "hide_name",
		label = "",
		options = {
			{
				description = "",
				data = false,
			}
		},
		default = false,
	},
	{
		name = "discord",
		label = "",
		options = {
			{
				description = "",
				data = "",
			}
		},
		default = "",
	},
	{
		name = "donate",
		label = "",
		options = {
			{
				description = "",
				data = "",
			}
		},
		default = "",
	},
}