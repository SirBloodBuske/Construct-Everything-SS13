/obj/item/device/radio/intercom
	name = "station intercom"
	desc = "Talk through this."
	icon_state = "intercom"
	anchored = 1
	w_class = 4.0
	canhear_range = 2
	use_power = 1
	idle_power_usage = 1
	active_power_usage = 3
	flags = CONDUCT | NOBLOODY
	var/number = 0
	var/anyai = 1
	var/mob/living/silicon/ai/ai = list()
	var/last_tick //used to delay the powercheck
	var/buildstage = 2 //2 is built, 1 is building, 0 is frame.
	var/wiresexposed = 0
	var/wirescut = 0



/obj/item/weapon/intercom_electronics
	name = "intercom electronics"
	icon = 'icons/obj/doors/door_assembly.dmi'
	icon_state = "door_electronics"
	desc = "A circuit. It has a label on it, it says \"Can transmit anywhere!\""
	w_class = 2.0
	m_amt = 50
	g_amt = 50

/obj/item/device/radio/intercom/New(loc, dir, building)
	processing_objects += src
	if(loc)
		src.loc = loc

	if(dir)
		src.dir = dir

	if(building)
		buildstage = 0
		wiresexposed = 1
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -24 : 24)
		pixel_y = (dir & 3)? (dir ==1 ? -24 : 24) : 0



/obj/item/device/radio/intercom/Del()
	processing_objects -= src
	..()
/obj/item/device/radio/intercom/examine()
	if (buildstage < 2)
		usr << "<span class='warning'>It is not wired.</span>"
	if (buildstage < 1)
		usr << "<span class='warning'>The circuit is missing.</span>"
/obj/item/device/radio/intercom/update_icon()

	if(wiresexposed)
		switch(buildstage)
			if(2)
				icon_state="intercom"
			if(1)
				icon_state="intercom-p-open"
			if(0)
				icon_state="intercom-frame"

/obj/item/device/radio/intercom/attack_ai(mob/user as mob)
	src.add_fingerprint(user)
	spawn (0)
		attack_self(user)

/obj/item/device/radio/intercom/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/item/device/radio/intercom/attack_hand(mob/user as mob)
	src.add_fingerprint(user)
	spawn (0)
		attack_self(user)

/obj/item/device/radio/intercom/receive_range(freq, level)
	if (!on)
		return -1
	if(!(0 in level))
		var/turf/position = get_turf(src)
		if(isnull(position) || !(position.z in level))
			return -1
	if (!src.listening)
		return -1
	if(freq in ANTAG_FREQS)
		if(!(src.syndie))
			return -1//Prevents broadcast of messages over devices lacking the encryption

	return canhear_range


/obj/item/device/radio/intercom/hear_talk(mob/M as mob, msg)
	if(!src.anyai && !(M in src.ai))
		return
	..()

/obj/item/device/radio/intercom/process()
	if(((world.timeofday - last_tick) > 30) || ((world.timeofday - last_tick) < 0))
		last_tick = world.timeofday

		if(!src.loc)
			on = 0
		else
			var/area/A = src.loc.loc
			if(!A || !isarea(A) || !A.master)
				on = 0
			else
				on = A.master.powered(EQUIP) // set "on" to the power status

		if(!on)
			icon_state = "intercom-p"





obj/item/device/radio/intercom/attackby(obj/item/W as obj, mob/user as mob, params)
	src.add_fingerprint(user)

	if (istype(W, /obj/item/weapon/screwdriver) && buildstage == 2)
		wiresexposed = !wiresexposed
		user << "<span class='notice'>The wires have been [wiresexposed ? "exposed" : "unexposed"]</span>"
		update_icon()
		return

	if(wiresexposed)
		switch(buildstage)
			if(2)
				if(istype(W, /obj/item/weapon/wirecutters))  // cutting the wires out
					if (wires.wires_status == 31) // all wires cut
						user << "<span class='notice'>You cut the wires!</span>"
						playsound(src.loc, 'sound/items/Wirecutter.ogg', 50, 1)
						var/obj/item/stack/cable_coil/new_coil = new /obj/item/stack/cable_coil()
						new_coil.amount = 5
						new_coil.loc = user.loc
						wirescut = 1
						buildstage = 1
						update_icon()
				if (wiresexposed && ((istype(W, /obj/item/device/multitool) || istype(W, /obj/item/weapon/wirecutters))))
				return attack_hand(user)

			if(1)
				if(istype(W, /obj/item/stack/cable_coil))
					var/obj/item/stack/cable_coil/coil = W
					if(coil.amount < 5)
						user << "<span class='notice'>You need more cable for this!</span>"
						return

					coil.amount -= 5
					if(!coil.amount)
						del(coil)

					wirescut = 0
					buildstage = 2
					user << "<span class='notice'>You wire \the [src]!</span>"
					update_icon()

				else if(istype(W, /obj/item/weapon/crowbar))
					user << "<span class='notice'>You pry out the circuit!</span>"
					playsound(get_turf(src), 'sound/items/Crowbar.ogg', 50, 1)
					spawn(20)
						var/obj/item/weapon/intercom_electronics/circuit = new /obj/item/weapon/intercom_electronics()
						circuit.loc = user.loc
						buildstage = 0
						update_icon()
			if(0)
				if(istype(W, /obj/item/weapon/intercom_electronics))
					user << "<span class='notice'>You insert the circuit!</span>"
					del(W)
					wirescut = 1
					buildstage = 1
					update_icon()

				else if(istype(W, /obj/item/weapon/wrench))
					user << "<span class='notice'>You remove the intercom assembly from the wall!</span>"
					new /obj/item/mounted/frame/intercom(get_turf(user))
					playsound(get_turf(src), 'sound/items/Ratchet.ogg', 50, 1)
					del(src)
		return 0
