/mob/living/silicon
	gender = NEUTER
	robot_talk_understand = 1
	voice_name = "synthesized voice"
	var/syndicate = 0
	var/datum/ai_laws/laws = null//Now... THEY ALL CAN ALL HAVE LAWS
	immune_to_ssd = 1
	var/list/hud_list[9]
	var/list/speech_synthesizer_langs = list()	//which languages can be vocalized by the speech synthesizer






	var/obj/item/device/camera/siliconcam/aiCamera = null //photography

	var/sensor_mode = 0 //Determines the current HUD.
	#define SEC_HUD 1 //Security HUD mode
	#define MED_HUD 2 //Medical HUD mode

/mob/living/silicon/proc/show_laws()
	return

/mob/living/silicon/drop_item()
	return

/mob/living/silicon/emp_act(severity)
	switch(severity)
		if(1)
			src.take_organ_damage(20)
			Stun(rand(5,10))
		if(2)
			src.take_organ_damage(10)
			Stun(rand(1,5))
	flash_eyes(affect_silicon = 1)
	src << "\red <B>*BZZZT*</B>"
	src << "\red Warning: Electromagnetic pulse detected."
	..()

/mob/living/silicon/proc/damage_mob(var/brute = 0, var/fire = 0, var/tox = 0)
	return

/mob/living/silicon/IsAdvancedToolUser()
	return 1

/mob/living/silicon/bullet_act(var/obj/item/projectile/Proj)


	if(!Proj.nodamage)
		switch(Proj.damage_type)
			if(BRUTE)
				adjustBruteLoss(Proj.damage)
			if(BURN)
				adjustFireLoss(Proj.damage)

	Proj.on_hit(src,2)

	return 2

/mob/living/silicon/apply_effect(var/effect = 0,var/effecttype = STUN, var/blocked = 0)
	return 0//The only effect that can hit them atm is flashes and they still directly edit so this works for now
/*
	if(!effect || (blocked >= 2))	return 0
	switch(effecttype)
		if(STUN)
			stunned = max(stunned,(effect/(blocked+1)))
		if(WEAKEN)
			weakened = max(weakened,(effect/(blocked+1)))
		if(PARALYZE)
			paralysis = max(paralysis,(effect/(blocked+1)))
		if(IRRADIATE)
			radiation += min((effect - (effect*getarmor(null, "rad"))), 0)//Rads auto check armor
		if(STUTTER)
			stuttering = max(stuttering,(effect/(blocked+1)))
		if(EYE_BLUR)
			eye_blurry = max(eye_blurry,(effect/(blocked+1)))
		if(DROWSY)
			drowsyness = max(drowsyness,(effect/(blocked+1)))
	updatehealth()
	return 1*/

/proc/islinked(var/mob/living/silicon/robot/bot, var/mob/living/silicon/ai/ai)
	if(!istype(bot) || !istype(ai))
		return 0
	if (bot.connected_ai == ai)
		return 1
	return 0


// this function shows the health of the pAI in the Status panel
/mob/living/silicon/proc/show_system_integrity()
	if(!src.stat)
		stat(null, text("System integrity: [round((health/maxHealth)*100)]%"))
	else
		stat(null, text("Systems nonfunctional"))


// This is a pure virtual function, it should be overwritten by all subclasses
/mob/living/silicon/proc/show_malf_ai()
	return 0


// this function displays the station time in the status panel
/mob/living/silicon/proc/show_station_time()
	stat(null, "Station Time: [worldtime2text()]")


// this function displays the shuttles ETA in the status panel if the shuttle has been called
/mob/living/silicon/proc/show_SSshuttle_eta()
	if(SSshuttle.online && SSshuttle.location < 2)
		var/timeleft = SSshuttle.timeleft()
		if (timeleft)
			stat(null, "ETA-[(timeleft / 60) % 60]:[add_zero(num2text(timeleft % 60), 2)]")


// This adds the basic clock, shuttle recall timer, and malf_ai info to all silicon lifeforms
/mob/living/silicon/Stat()
	..()
	if(statpanel("Status"))
		show_station_time()
		show_SSshuttle_eta()
		show_system_integrity()
		show_malf_ai()

// this function displays the stations manifest in a separate window
/mob/living/silicon/proc/show_station_manifest()
	var/dat
	dat += "<h4>Crew Manifest</h4>"
	if(data_core)
		dat += data_core.get_manifest(1) // make it monochrome
	dat += "<br>"
	src << browse(dat, "window=airoster")
	onclose(src, "airoster")

//can't inject synths
/mob/living/silicon/can_inject(var/mob/user, var/error_msg)
	if(error_msg)
		user << "<span class='alert'>The armoured plating is too tough.</span>"
	return 0


//Silicon mob language procs

/mob/living/silicon/can_speak(datum/language/speaking)
	return universal_speak || (speaking in src.speech_synthesizer_langs)	//need speech synthesizer support to vocalize a language

/mob/living/silicon/add_language(var/language, var/can_speak=1)
	if (..(language) && can_speak)
		speech_synthesizer_langs.Add(all_languages[language])

/mob/living/silicon/remove_language(var/rem_language)
	..(rem_language)

	for (var/datum/language/L in speech_synthesizer_langs)
		if (L.name == rem_language)
			speech_synthesizer_langs -= L

/mob/living/silicon/check_languages()
	set name = "Check Known Languages"
	set category = "IC"
	set src = usr

	var/dat = "<b><font size = 5>Known Languages</font></b><br/><br/>"

	for(var/datum/language/L in languages)
		dat += "<b>[L.name] (:[L.key])</b><br/>Speech Synthesizer: <i>[(L in speech_synthesizer_langs)? "YES":"NOT SUPPORTED"]</i><br/>[L.desc]<br/><br/>"

	src << browse(dat, "window=checklanguage")
	return

/mob/living/silicon/proc/toggle_sensor_mode()
	//set name = "Set Sensor Augmentation" // Dunno, but it loops if open. ~Zve
	//set desc = "Augment visual feed with internal sensor overlays."
	var/sensor_type = input("Please select sensor type.", "Sensor Integration", null) in list("Security", "Medical","Disable")
	switch(sensor_type)
		if ("Security")
			sensor_mode = SEC_HUD
			src << "<span class='notice'>Security records overlay enabled.</span>"
		if ("Medical")
			sensor_mode = MED_HUD
			src << "<span class='notice'>Life signs monitor overlay enabled.</span>"
		if ("Disable")
			sensor_mode = 0
			src << "Sensor augmentations disabled."

/mob/living/silicon/proc/write_laws()
	if(laws)
		var/text = src.laws.write_laws()
		return text

/mob/living/silicon/flash_eyes(intensity = 1, override_blindness_check = 0, affect_silicon = 0, visual = 0, type = /obj/screen/fullscreen/flash/noise)
	if(affect_silicon)
		return ..()
