/obj/item/weapon/gun
	name = "gun"
	desc = "It's a gun. It's pretty terrible, though."
	icon = 'icons/obj/gun.dmi'
	icon_state = "detective"
	item_state = "gun"
	flags =  FPRINT | TABLEPASS | CONDUCT
	slot_flags = SLOT_BELT
	m_amt = 2000
	w_class = 3.0
	throwforce = 5
	throw_speed = 4
	throw_range = 5
	force = 5.0
	origin_tech = "combat=1"
	attack_verb = list("struck", "hit", "bashed")
	var/obj/item/ammo_casing/chambered = null
	var/fire_sound = 'sound/weapons/Gunshot.ogg'
	var/silenced = 0
	var/recoil = 0
	var/clumsy_check = 1
	var/tmp/list/mob/living/target //List of who yer targeting.
	var/tmp/lock_time = -100
	var/tmp/mouthshoot = 0 ///To stop people from suiciding twice... >.>
	var/automatic = 0 //Used to determine if you can target multiple people.
	var/tmp/mob/living/last_moved_mob //Used to fire faster at more than one person.
	var/tmp/told_cant_shoot = 0 //So that it doesn't spam them with the fact they cannot hit them.
	var/firerate = 1 	// 0 for one bullet after tarrget moves and aim is lowered,
						//1 for keep shooting until aim is lowered
	var/fire_delay = 6
	var/last_fired = 0

	proc/ready_to_fire()
		if(world.time >= last_fired + fire_delay)
			last_fired = world.time
			return 1
		else
			return 0

	proc/process_chamber()
		return 0

	proc/special_check(var/mob/M) //Placeholder for any special checks, like detective's revolver.
		return 1

	proc/shoot_with_empty_chamber(mob/living/user as mob|obj)
		user << "<span class='warning'>*click*</span>"
		return

	proc/shoot_live_shot(mob/living/user as mob|obj)
		if(recoil)
			spawn()
				shake_camera(user, recoil + 1, recoil)

		if(silenced)
			playsound(user, fire_sound, 10, 1)
		else
			playsound(user, fire_sound, 50, 1)
			user.visible_message("<span class='danger'>[user] fires [src]!</span>", "<span class='danger'>You fire [src]!</span>", "You hear a [istype(src, /obj/item/weapon/gun/energy) ? "laser blast" : "gunshot"]!")

	emp_act(severity)
		for(var/obj/O in contents)
			O.emp_act(severity)


/obj/item/weapon/gun/afterattack(atom/A as mob|obj|turf|area, mob/living/user as mob|obj, flag, params)
	if(flag)	return //It's adjacent, is the user, or is on the user's person
	if(istype(target, /obj/machinery/recharger) && istype(src, /obj/item/weapon/gun/energy))	return//Shouldnt flag take care of this?
	if(user && user.client && user.client.gun_mode && !(A in target))
		PreFire(A,user,params) //They're using the new gun system, locate what they're aiming at.
	else
		Fire(A,user,params) //Otherwise, fire normally.

/obj/item/weapon/gun/proc/Fire(atom/target as mob|obj|turf|area, mob/living/user as mob|obj, params, reflex = 0)//TODO: go over this
	//Exclude lasertag guns from the CLUMSY check.
	if(clumsy_check)
		if(istype(user, /mob/living))
			var/mob/living/M = user
			if ((CLUMSY in M.mutations) && prob(50))
				M << "<span class='danger'>[src] blows up in your face.</span>"
				M.take_organ_damage(0,20)
				M.drop_item()
				del(src)
				return

	if (!user.IsAdvancedToolUser())
		user << "\red You don't have the dexterity to do this!"
		return
	if(istype(user, /mob/living))
		var/mob/living/M = user
		if (HULK in M.mutations)
			M << "\red Your meaty finger is much too large for the trigger guard!"
			return
	if(ishuman(user))
		if(user.dna && user.dna.mutantrace == "adamantine")
			user << "\red Your metal fingers don't fit in the trigger guard!"
			return

	add_fingerprint(user)

	if(!special_check(user))
		return

	if (!ready_to_fire())
		if (world.time % 3) //to prevent spam
			user << "<span class='warning'>[src] is not ready to fire again!"
		return
	if(chambered)
		if(!chambered.fire(target, user, params, , silenced))
			shoot_with_empty_chamber(user)
		else
			shoot_live_shot(user)
	else
		shoot_with_empty_chamber(user)
	process_chamber()
	update_icon()

	if(user.hand)
		user.update_inv_l_hand()
	else
		user.update_inv_r_hand()


/obj/item/weapon/gun/proc/can_fire()
	return chambered

/obj/item/weapon/gun/proc/can_hit(var/mob/living/target as mob, var/mob/living/user as mob)
	return chambered.BB.check_fire(target,user)

/obj/item/weapon/gun/proc/click_empty(mob/user = null)
	if (user)
		user.visible_message("*click click*", "\red <b>*click*</b>")
		playsound(user, 'sound/weapons/empty.ogg', 100, 1)
	else
		src.visible_message("*click click*")
		playsound(src.loc, 'sound/weapons/empty.ogg', 100, 1)

/obj/item/weapon/gun/proc/isHandgun()
	return 1
/*
/obj/item/weapon/gun/attack(mob/living/M as mob, mob/living/user as mob, def_zone)
	//Suicide handling.
	if (M == user && user.zone_sel.selecting == "mouth" && !mouthshoot)
		mouthshoot = 1
		M.visible_message("\red [user] sticks their gun in their mouth, ready to pull the trigger...")
		world << "[chambered.BB], [chambered]"
		if(!do_after(user, 40))
			M.visible_message("\blue [user] decided life was worth living")
			mouthshoot = 0
			return
		if (chambered)
			world << "azaza"
			user.visible_message("<span class = 'warning'>[user] pulls the trigger.</span>")
			if(silenced)
				playsound(user, fire_sound, 10, 1)
			else
				playsound(user, fire_sound, 50, 1)
			if(istype(chambered.BB, /obj/item/projectile/beam/lastertag))
				user.show_message("<span class = 'warning'>You feel rather silly, trying to commit suicide with a toy.</span>")
				mouthshoot = 0
				return

			chambered.BB.on_hit(M)
			if (chambered.BB.damage_type != HALLOSS)
				user.apply_damage(chambered.BB.damage*2.5, chambered.BB.damage_type, "head", used_weapon = "Point blank shot in the mouth with \a [chambered.BB]")
				user.death()
			else
				user << "<span class = 'notice'>Ow...</span>"
				user.apply_effect(110,AGONY,0)
			chambered.BB = null
			del(chambered.contents)
			mouthshoot = 0
			process_chamber()
			return
		else
			click_empty(user)
			mouthshoot = 0
			return

	if (chambered)
		//Point blank shooting if on harm intent or target we were targeting.
		if(user.a_intent == "hurt")
			user.visible_message("\red <b> \The [user] fires \the [src] point blank at [M]!</b>")
			chambered.BB.damage *= 1.3
			Fire(M,user)
			return
		else if(target && M in target)
			Fire(M,user) ///Otherwise, shoot!
			return
	else
		return ..()  */