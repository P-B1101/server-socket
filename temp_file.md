Server side:
	init_server_settings{
		ports,  ### TCP and UDP ports on server
		excpected_clients_and, ### android_interface:1, android_camera:4, raspberrypi_3d_camera:1,  jrun:0, ....
		...
	}
	
	preparing_network{
		discover_clients{
			FN:broadcast_over_network
			FN:listein_for_broadcast_response ==> complete client_table ==> go to next if all connected
		}
		
		config_connection_for_each_clients{
			foreach client in client_table{
				FN:Connect_to_client(ip,port,type,FN_listener)
			}
		}
	}
	
	main{
		call:test_scenario
		or 
		call:main_scenario
	}
	
	on_recived{
		FN_listener:on_recived_responce_of_ask_time ==> val or nan
		FN_listener:on_recived_responce_of_start_camera ==> val or nan
		FN_listener:on_recived_responce_of_send_file ==> val or nan
	}
	
	test_scenario or main_scenario{
		FN:ask_time()
		FN:start_camera()
		FN:send_file()
	}
	
	low_level_functions{
		connecting_to_client,sending_message,sending_file,_on_recive,.....
	}
	
===============================================================
Client side:
	init_client_settings{
		ports,  ### TCP and UDP ports on client
		client_type,
		client_position,
		...
	}
	
	preparing_network{
		listen to server, ==> FN:send info to server
	}
	
	main{
		liten for command
	}
	
	on_command{
		FN_listener:on_start_recording ==> FN:Recording ==> ...
		FN_listener:on_send_file ==> FN:Send_file
	}
	
		low_level_functions{
		connecting_to_server,sending_message,sending_file,_on_recive,.....
	}
	
