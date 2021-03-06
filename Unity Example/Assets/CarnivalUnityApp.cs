﻿using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class CarnivalUnityApp : MonoBehaviour {
	List<CarnivalMessage> theMessages = null;

	void Start () {
		//Start up the engine
		Carnival.StartEngineIOS(""); //Pop in your SDK Key 
		Carnival.StartEngineAndroid("", ""); //Pop in your SDK Key and Google Project Number

		Carnival.SetUserID("unity-user-1234");
		//Carnival.SetUserEmail("unity-user-1234@carnival.io");

		// Set up Handlers 
		Carnival.OnErrorEvent += (object sender, CarnivalErrorEventArgs e) => {
			Debug.Log (e.ErrorDescription);
		};

		// Set Location
		Carnival.UpdateLocation (-44.01899F,176.565915F);

		//Log an event 
		Carnival.LogEvent ("User started playing game");

		//Set Some Custom Attributes
		Carnival.SetString ("Some String", "Unity-String");
		Carnival.SetBool (true, "Unity-Boolean");
		Carnival.SetFloat (3.141F, "Unity-Float");
		Carnival.SetDate (DateTime.Now, "Unity-Date");
		Carnival.SetInteger (123, "Unity-Integer");

		//Remove some Custom Attributes
		Carnival.RemoveAttribute ("Unity-Integer");

		Carnival.SetInAppNotificationsEnabled(true);

		//Get some messages
		Carnival.OnMessagesReceivedEvent += (object sender, CarnivalMessagesReceivedEvent e) => {
			if (e.messages != null) {
				CarnivalMessage message = e.messages[0];
				Debug.Log ("First carnival message");
				Debug.Log (message.title);
				Debug.Log (message.messageID);
				Debug.Log (message.createdAt);
				Debug.Log (message.imageURL);
				Debug.Log (message.videoURL);
				Debug.Log (message.type);
				Debug.Log (message.text);
				Carnival.RegisterImpression(message, CarnivalImpressionType.StreamView); 
			}
			this.theMessages = e.messages;
		};
		Carnival.GetMessages();

		//Get the unread count
		Carnival.OnUnreadCountReceivedEvent += (object sender, CarnivalUnreadCountReceivedEvent e) => {
			Debug.Log (e.UnreadCount);
		};
		Carnival.UnreadCount();

		Carnival.OnDeviceIdReceivedEvent += (object sender, CarnivalDeviceIDReceivedEvent e) => {
			Debug.Log ("DeviceId: " + e.DeviceID);
		};
		Carnival.DeviceID();
	}
	public void OnMDClick() {
		if (this.theMessages == null || this.theMessages.Count > 0) {
			Carnival.ShowMessageDetail (this.theMessages [0]);

			//Not required, but an example of marking a message as read
			Carnival.MarkMessageAsRead (this.theMessages [0]);
		} else {
			Debug.Log ("There are no messages to show");
		}
	}
}
