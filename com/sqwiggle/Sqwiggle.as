﻿package com.sqwiggle {	import flash.display.LoaderInfo;	import flash.display.Sprite;	import flash.display.SimpleButton;	import flash.display.StageAlign;	import flash.display.StageScaleMode;	import flash.external.ExternalInterface;	import flash.net.NetConnection;	import flash.net.URLRequestMethod;	import flash.events.MouseEvent;	import flash.events.Event;	import flash.media.Video;	import flash.events.Event;	import flash.utils.Dictionary;	import fl.transitions.Tween;	import fl.transitions.easing.*;	import com.sqwiggle.Member;	import com.sqwiggle.Conversation;	import com.sqwiggle.Conversations;	import com.sqwiggle.VideoPanel;	import com.sqwiggle.Api;	import com.sqwiggle.events.ApiEvent;	import com.sqwiggle.events.ConversationEvent;		import com.pusher.Pusher;	import com.pusher.auth.PostAuthorizer;	public class Sqwiggle extends Sprite {				private var parameters 			:Object;		private var self      			:Self;		private var conversations		:Object;		private var panel				:VideoPanel;		private var pusher				:Pusher;		private var api					:Api;		private var environment			:String;		private var leaveConvo:SimpleButton;				public function Sqwiggle() {			parameters = LoaderInfo(this.root.loaderInfo).parameters;			environment = parameters.environment;						// stop stage from scaling			stage.align = StageAlign.TOP_LEFT;			stage.scaleMode = StageScaleMode.NO_SCALE;						// allows us to hook into chrome's page visibility API 			// and disable video feeds when the tab is not focussed			ExternalInterface.addCallback('visibilityHidden', visibilityHidden);			ExternalInterface.addCallback('visibilityVisible', visibilityVisible);						// setup API options			if (environment == 'development') {				Api.setup('/api/v1', parameters.authToken);			} else {				Api.setup('http://www.sqwiggle.com/api/v1', parameters.authToken);			}						// create video panel			self = new Self(parameters.userId);			self.addEventListener("Connected", pusherConnect);			panel = new VideoPanel(self);			addChild(panel);					leaveConvo = new LeaveConversationButton();			leaveConvo.visible = false;			leaveConvo.addEventListener(MouseEvent.MOUSE_DOWN, leaveConversation);			addChild(leaveConvo);						// shuffle the video feeds as the video panel is resized			stage.addEventListener(Event.RESIZE, panel.relayout);		}						public static function trace(... args) {			ExternalInterface.call('Sqwiggle.log', 'Flash: ' + args.join(', '));		}						private function visibilityHidden():void {			Sqwiggle.trace("visibilityHidden");			panel.hideVideos();		}						private function visibilityVisible():void {			Sqwiggle.trace("visibilityVisible");			panel.showVideos();		}						private function pusherConnect(event:Event):void {			Sqwiggle.trace("pusherConnect");			ExternalInterface.call("Sqwiggle.stream.pusherConnect");						// setup pusher lib			if (environment == 'development') {				Pusher.authorizer = new PostAuthorizer('/api/v1/pusher/auth?auth_token=' + parameters.authToken);				pusher = new Pusher('fd4dd9eb82163e6920a0', 'http://localhost');			} else {				Pusher.authorizer = new PostAuthorizer('http://www.sqwiggle.com/api/v1/pusher/auth?auth_token=' + parameters.authToken);				pusher = new Pusher('fd4dd9eb82163e6920a0', 'http://www.sqwiggle.com');			}						// subscribe to the correct channel and bind the events we care about			pusher.subscribeAsPresence(parameters.companyId);			pusher.bind('pusher_internal:subscription_succeeded', pusherJoinedRoom);			pusher.bind('pusher_internal:member_added', pusherMemberJoined);			pusher.bind('pusher_internal:member_removed', pusherMemberLeft);			pusher.bind('conversations-update', pusherConversationUpdate);			// connect to socket			pusher.connect();		}						/*		 * pusherJoinedRoom		 *		 * When joining a chat for the first time this method is called		 * to connect all of the existing participants in the video call.		*/		private function pusherJoinedRoom(event):void {			Sqwiggle.trace('pusherJoinedRoom', JSON.stringify(event));						var presence = event.presence;						for(var i in presence.hash) {				var member = presence.hash[i];				addMember(i, member.peer_id, member.name);			}						conversations = new Conversations(self, panel.members);			conversations.addEventListener("conversationsupdated", updateLeaveButton);			conversations.addEventListener("conversationstarted", showConversationStartedNotification);		}						/*		 * pusherMemberJoined		 *		 * When an existing user joins the room and needs adding to the		 * video panel		*/		private function pusherMemberJoined(event):void {			Sqwiggle.trace('pusherMemberJoined', JSON.stringify(event));						addMember(event.user_id, event.user_info.peer_id, event.user_info.name);		}						/*		 * pusherMemberLeft		 *		 * When an existing user leaves the room or is otherwise disconnected		 * from the video feed.		*/		private function pusherMemberLeft(event):void {			Sqwiggle.trace('pusherMemberLeft', JSON.stringify(event));						panel.removeMember(event.user_id);		}						/*		 * pusherConversationUpdate		 *		 * When any existing conversation in this workroom changes because		 * a user leaves or joins the conversation.		*/		private function pusherConversationUpdate(event):void {			Sqwiggle.trace('pusherConversationUpdate', JSON.stringify(event));						conversations.updateMembers(event);		}						private function updateLeaveButton(event:Event):void {						var conversation = conversations.getConversationForMember(self);						// TODO: check for size of group			if (conversation) {				Sqwiggle.trace('in conversation', conversation.id);				leaveConvo.visible = true;			} else {				leaveConvo.visible = false;			}		}						private function showConversationStartedNotification(event:ConversationEvent):void {						ExternalInterface.call('Sqwiggle.workroom.showConversationNotification', event.data);		}				/*		 * addMember		 *		 * When a new user joins the chat this method is called to connect		 * them to the stream		*/		public function addMember(memberId:String, peerId:String, userName:String):void {			Sqwiggle.trace('addMember', memberId, peerId);						// prevent multiple connections if the user opens another tab			if (self.userId === memberId) return;						// create a new member			var member:Member = new Member(memberId, peerId, userName);			member.addEventListener(MouseEvent.CLICK, addToConversation);						// add to the video panel			panel.addMember(member);		}						private function leaveConversation(event:MouseEvent):void {						var options = new Object();			var conversation = conversations.getConversationForMember(self);			options.user_id = self.userId;			options.conversation_id = conversation.id;						// let everyone know that we want to leave			var request = Api.postRequest('/conversations/users/remove', options);		}						private function addToConversation(event:MouseEvent):void {			Sqwiggle.trace('addToConversation');						var member = event.currentTarget;			var conversation = conversations.getConversationForMember(self);			var existing = conversations.getConversationForMember(member);			var options:Object;			var request:ApiDelegate;						// this user is already in a convo			if (existing) {				if (conversation) {					Sqwiggle.trace('Both users already in a conversation', member.userId);				} else {										// make an API request to join this users conversation					options = new Object();					options.user_id = self.userId;					options.conversation_id = existing.id;						request = Api.postRequest('/conversations/users/add', options);					request.addEventListener(Event.COMPLETE, function(event:ApiEvent) {												// success						existing.addMember(self);					});				}						// they are free to join us 			} else {				if (!conversation) {					Sqwiggle.trace('starting new conversation');					conversation = new Conversation();				}								// make an API request to add this user to our conversation				options = new Object();				options.user_id = member.userId;								if (conversation) {					options.conversation_id = conversation.id;				}				request = Api.postRequest('/conversations/users/add', options);				request.addEventListener(Event.COMPLETE, function(event:ApiEvent) {										// success					conversation.addMember(self);					conversation.addMember(member);				});			}		}	}}